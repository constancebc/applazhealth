"use strict";
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");
const crypto = require("node:crypto");
const policy = require("./policy");
const storage = require("../wellness/policy");
const db = () => getFirestore(admin.app(), "applaz-wellness");
const hash = text => crypto.createHash("sha256").update(text).digest("hex");
const account = uid => db().collection("privateAccounts").doc(uid);
const shared = id => db().collection("collaborativeNotebooks").doc(id);
const key = value => {
  if (typeof value !== "string" || !value || /[.#$\[\]/]/.test(value)) throw new Error("Invalid notebook or user.");
  return value;
};
const endpoint = handler => functions.runWith({timeoutSeconds: 60, maxInstances: 10}).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in to collaborate.");
  try { return await handler(data || {}, context.auth.uid); }
  catch (error) { throw new functions.https.HttpsError("failed-precondition", error.message || "Please try again."); }
});
async function readState(tx, ref, meta) {
  const refs = Array.from({length: meta.snapshotChunks || 0}, (_, i) => ref.collection("snapshot").doc(String(i)));
  if (!refs.length) return meta.document || {initialized: true, notebooks: [], meals: []};
  const chunks = await tx.getAll(...refs);
  return JSON.parse(chunks.map(snap => snap.data().text).join(""));
}
function writeState(tx, ref, meta, document) {
  const chunks = storage.snapshotChunks(document);
  chunks.forEach((text, i) => tx.set(ref.collection("snapshot").doc(String(i)), {text}));
  for (let i = chunks.length; i < (meta.snapshotChunks || 0); i++) tx.delete(ref.collection("snapshot").doc(String(i)));
  tx.set(ref, {snapshotChunks: chunks.length, document: admin.firestore.FieldValue.delete()}, {merge: true});
}
async function profile(uid) {
  const ref = admin.database().ref("Users/" + uid);
  const [username, photo] = await Promise.all([admin.database().ref("UsernamesWithEmail/" + uid + "/username").get(), ref.child("photo").get()]);
  let name = username.val();
  if (typeof name !== "string") name = (await ref.child("User Name").get()).val();
  return {id: uid, name: typeof name === "string" ? name : "Someone", photo: typeof photo.val() === "string" ? photo.val() : ""};
}
let directoryCache = [], directoryTime = 0, directoryLoad;
async function usernameDirectory() {
  if (Date.now() - directoryTime < 30000) return directoryCache;
  if (!directoryLoad) directoryLoad = admin.database().ref("UsernamesWithEmail").get().then(snapshot => {
    const names = [];
    snapshot.forEach(child => { const value = child.val(); if (typeof value.username === "string" && value.account_disable !== "true" && value.account_disable !== true) names.push({id: child.key, name: value.username.toLowerCase()}); });
    directoryCache = names; directoryTime = Date.now(); return names;
  }).finally(() => { directoryLoad = null; });
  return directoryLoad;
}
async function alert(recipient, id, actor, notebook, type, invitationID = "") {
  await account(recipient).collection("collaborationAlerts").doc(id).set({actorID: actor.id, userName: actor.name, photo: actor.photo, notebookID: notebook.id, notebookName: notebook.name, type, invitationID, timestamp: Date.now() / 1000});
  if (!process.env.FIREBASE_DATABASE_EMULATOR_HOST) {
    try {
      const devices = (await admin.database().ref("Users/" + recipient + "/tokens").get()).val() || {};
      const tokens = Object.values(devices).filter(token => typeof token === "string");
      for (let i = 0; i < tokens.length; i += 500) await admin.messaging().sendEachForMulticast({tokens: tokens.slice(i, i + 500), notification: {title: "Applaz", body: actor.name + (type === "notebookInvite" ? " invited you to " : " joined ") + notebook.name}, data: {type, id: notebook.id, recipientID: recipient}});
    } catch (_) { /* The private in-app alert is already saved if push delivery is unavailable. */ }
  }
}
function fromLegacy(value, id, now) {
  const notes = [];
  for (const [noteID, note] of Object.entries(value)) {
    if (note && typeof note === "object" && typeof note["Title name"] === "string") notes.push({id: noteID, title: note["Title name"], body: note["Note name"] || "", richHTML: note["Note name"] || "", items: [], isChecklist: false, updatedAt: now});
  }
  return {id, name: value["Category Name"] || "Notebook", kind: "text", items: [], notes, createdAt: now, updatedAt: now, isDeleted: false, isPrivate: value.isPrivateNote !== false};
}
exports.collaborationDirectory = endpoint(async (data, uid) => {
  const following = (await admin.database().ref("Users/" + uid + "/followings").get()).val() || {};
  const ids = Object.keys(following).filter(id => following[id] === true || following[id] === "true");
  const people = await Promise.all(ids.map(profile));
  const query = typeof data.query === "string" ? data.query.trim().toLowerCase().replace(/^@/, "") : "";
  if (query) {
    // Search the existing username directory without replacing production access rules.
    // Only public profile fields are returned; email values never leave this function.
    const users = await usernameDirectory();
    const matches = users.filter(person => person.id !== uid && person.name.includes(query) && !people.some(p => p.id === person.id)).map(person => person.id);
    people.push(...await Promise.all(matches.map(profile)));
  }
  return {people: people.filter(p => !query || p.name.toLowerCase().includes(query)).map(p => ({...p, following: ids.includes(p.id)}))};
});
exports.collaborationInvite = endpoint(async (data, uid) => {
  const kind = data.kind === "legacy" ? "legacy" : "health";
  const sourceID = data.sourceID ? key(data.sourceID) : "";
  const id = data.notebookID ? key(data.notebookID) : hash(uid + ":" + kind + ":" + sourceID);
  const ref = shared(id);
  let initial;
  if (!data.notebookID) {
    if (!sourceID) throw new Error("Choose a notebook first.");
    if (kind === "legacy") {
      const snap = await admin.database().ref("Users/" + uid + "/Notes/" + sourceID).get();
      if (!snap.exists()) throw new Error("This notebook no longer exists.");
      initial = fromLegacy(snap.val(), sourceID, Date.now());
    } else {
      const owner = (await account(uid).get()).data() || {};
      const own = await db().runTransaction(tx => readState(tx, account(uid), owner));
      initial = own.notebooks.find(n => n.id === sourceID && !n.isDeleted);
      if (!initial && data.notebook?.id === sourceID && !data.notebook.isDeleted) initial = data.notebook;
      if (!initial) throw new Error("Save this notebook before inviting friends.");
    }
  }
  const actor = await profile(uid);
  const meta = await db().runTransaction(async tx => {
    const [snap, member] = await Promise.all([tx.get(ref), tx.get(ref.collection("members").doc(uid))]);
    if (snap.exists) { policy.requireMember(member.data()); if (snap.data().deleted) throw new Error("This notebook was deleted."); return snap.data(); }
    if (data.notebookID) throw new Error("This notebook no longer exists.");
    const value = {id, owner: uid, ownerName: actor.name, kind, sourceID, name: initial.name, revision: 0, deleted: false, updatedAt: Date.now()};
    writeState(tx, ref, {}, initial);
    tx.set(ref, value, {merge: true});
    tx.set(ref.collection("members").doc(uid), {role: "owner", joinedAt: Date.now()});
    tx.set(account(uid).collection("collaborations").doc(id), {notebookID: id});
    return value;
  });
  const recipients = [...new Set(data.recipients || [])].filter(person => person !== uid).map(key);
  for (const recipient of recipients) {
    await admin.auth().getUser(recipient);
    if ((await ref.collection("members").doc(recipient).get()).exists) continue;
    const invitationID = hash(id + ":" + recipient);
    const invitation = db().collection("notebookInvitations").doc(invitationID);
    await db().runTransaction(async tx => {
      const existing = await tx.get(invitation);
      if (existing.data()?.status === "pending") return;
      tx.set(invitation, {notebookID: id, recipient, inviter: uid, owner: meta.owner, status: "pending", name: meta.name, createdAt: Date.now()});
    });
    await alert(recipient, invitationID, actor, meta, "notebookInvite", invitationID);
  }
  return {notebookID: id};
});
exports.collaborationRespond = endpoint(async (data, uid) => {
  const invitationID = key(data.invitationID);
  const inv = db().collection("notebookInvitations").doc(invitationID);
  const result = await db().runTransaction(async tx => {
    const snap = await tx.get(inv); const value = snap.data();
    const status = policy.reply(value, uid, data.accept === true);
    const ref = shared(value.notebookID); const notebook = (await tx.get(ref)).data();
    if (!notebook || notebook.deleted) throw new Error("This notebook is no longer available.");
    if (status === "accepted") {
      tx.set(ref.collection("members").doc(uid), {role: uid === notebook.owner ? "owner" : "editor", joinedAt: Date.now()});
      tx.set(account(uid).collection("collaborations").doc(value.notebookID), {notebookID: value.notebookID});
    }
    tx.update(inv, {status, respondedAt: Date.now()});
    return {status, notebook, inviter: value.inviter};
  });
  await account(uid).collection("collaborationAlerts").doc(invitationID).delete();
  if (result.status === "accepted") {
    const actor = await profile(uid);
    for (const target of new Set([result.inviter, result.notebook.owner])) if (target !== uid) await alert(target, hash(invitationID + ":accepted"), actor, result.notebook, "notebookAccepted");
  }
  return {status: result.status, notebookID: result.notebook.id};
});
exports.collaborationList = endpoint(async (_, uid) => {
  const index = await account(uid).collection("collaborations").get();
  const notebooks = await Promise.all(index.docs.map(async entry => {
    const ref = shared(entry.id); const [snap, member] = await Promise.all([ref.get(), ref.collection("members").doc(uid).get()]);
    if (!snap.exists || snap.data().deleted || !member.exists) return null;
    return {...snap.data(), role: member.data().role, snapshotChunks: undefined};
  }));
  const alerts = await account(uid).collection("collaborationAlerts").get();
  return {notebooks: notebooks.filter(Boolean), alerts: alerts.docs.map(doc => ({eventID: doc.id, ...doc.data()}))};
});
exports.collaborationRead = endpoint(async (data, uid) => db().runTransaction(async tx => {
  const ref = shared(key(data.notebookID)); const [snap, member] = await Promise.all([tx.get(ref), tx.get(ref.collection("members").doc(uid))]);
  policy.requireMember(member.data()); const meta = snap.data(); if (!meta || meta.deleted) throw new Error("This notebook is no longer available.");
  return {notebook: await readState(tx, ref, meta), role: member.data().role, revision: meta.revision};
}));
exports.collaborationEdit = endpoint(async (data, uid) => {
  const ref = shared(key(data.notebookID));
  if (data.note) key(data.note.id);
  if (data.deleteNoteID) key(data.deleteNoteID);
  const result = await db().runTransaction(async tx => {
    const [snap, member] = await Promise.all([tx.get(ref), tx.get(ref.collection("members").doc(uid))]);
    policy.requireMember(member.data()); const meta = snap.data(); if (!meta || meta.deleted) throw new Error("This notebook is no longer available.");
    const current = await readState(tx, ref, meta);
    const ownerRef = account(meta.owner); const ownerMeta = (await tx.get(ownerRef)).data() || {};
    const ownerDocument = meta.kind === "health" ? await readState(tx, ownerRef, ownerMeta) : null;
    let notebook; let photoStorageFull = false;
    if (data.deleteNoteID) {
      notebook = {...current, notes: current.notes.filter(note => note.id !== data.deleteNoteID), updatedAt: Date.now()};
    } else notebook = policy.editNote(current, data.note, data.baseUpdatedAt);
    // Keep photos separate from text capacity, using the owner's existing photo allowance.
    if (ownerDocument) {
      const candidate = {notebooks: [...ownerDocument.notebooks.filter(n => n.id !== meta.sourceID), {...notebook, id: meta.sourceID}], meals: ownerDocument.meals};
      const accepted = storage.photoCapacity(candidate, ownerDocument);
      photoStorageFull = accepted.photoStorageFull;
      notebook = accepted.document.notebooks.find(n => n.id === meta.sourceID);
      writeState(tx, ownerRef, ownerMeta, accepted.document);
      tx.set(ownerRef, {publicPending: {...(ownerMeta.publicPending || {}), [meta.sourceID]: notebook.updatedAt}}, {merge: true});
    }
    writeState(tx, ref, meta, notebook);
    tx.set(ref, {revision: meta.revision + 1, updatedAt: Date.now(), name: notebook.name}, {merge: true});
    return {notebook, meta, photoStorageFull};
  });
  if (result.meta.kind === "legacy") {
    const source = admin.database().ref("Users/" + result.meta.owner + "/Notes/" + result.meta.sourceID);
    if (data.deleteNoteID) await source.child(key(data.deleteNoteID)).remove();
    else await source.child(key(data.note.id)).update({"Title name": data.note.title, "Note name": (data.note.richHTML || data.note.body) + (data.note.attachments || []).map(photo => "<p><img src=\"data:image/jpeg;base64," + photo + "\" /></p>").join(""), Key: data.note.id});
  }
  return {notebook: result.notebook, photoStorageFull: result.photoStorageFull};
});
exports.collaborationDelete = endpoint(async (data, uid) => {
  const ref = shared(key(data.notebookID));
  const meta = await db().runTransaction(async tx => {
    const [snap, member] = await Promise.all([tx.get(ref), tx.get(ref.collection("members").doc(uid))]);
    policy.requireOwner(member.data()); const meta = snap.data();
    if (!meta || meta.owner !== uid) throw new Error("This notebook no longer exists.");
    const ownerRef = account(uid); const ownerMeta = (await tx.get(ownerRef)).data() || {};
    const doc = meta.kind === "health" ? await readState(tx, ownerRef, ownerMeta) : null;
    if (doc) {
      for (const n of doc.notebooks) if (n.id === meta.sourceID) { n.isDeleted = true; n.updatedAt = Date.now(); n.notes = []; n.items = []; }
      writeState(tx, ownerRef, ownerMeta, doc);
    }
    tx.set(ref, {deleted: true, updatedAt: Date.now()}, {merge: true}); return meta;
  });
  if (meta.kind === "legacy") await admin.database().ref("Users/" + uid + "/Notes/" + meta.sourceID).remove();
  return {deleted: true};
});

async function syncHealthNotebook(uid, before, notebook) {
  const ref = shared(hash(uid + ":health:" + notebook.id));
  return db().runTransaction(async tx => {
    const snap = await tx.get(ref); const meta = snap.data();
    if (!meta || meta.deleted) return null;
    const current = await readState(tx, ref, meta);
    const ownerRef = account(uid); const ownerMeta = (await tx.get(ownerRef)).data() || {};
    const document = await readState(tx, ownerRef, ownerMeta);
    if (notebook.isDeleted) { tx.set(ref, {deleted: true, updatedAt: Date.now()}, {merge: true}); return null; }
    const changed = new Map(current.notes.map(note => [note.id, note]));
    for (const note of notebook.notes) if (!changed.has(note.id) || note.updatedAt > changed.get(note.id).updatedAt) changed.set(note.id, note);
    for (const note of before?.notes || []) if (!notebook.notes.some(n => n.id === note.id)) changed.delete(note.id);
    const merged = {...notebook, notes: [...changed.values()]};
    if (JSON.stringify(merged) === JSON.stringify(current)) return current;
    merged.updatedAt = Math.max(Date.now(), notebook.updatedAt + 1, current.updatedAt + 1);
    writeState(tx, ref, meta, merged);
    tx.set(ref, {name: merged.name, revision: meta.revision + 1, updatedAt: Date.now()}, {merge: true});
    const index = document.notebooks.findIndex(n => n.id === notebook.id);
    if (index >= 0) {
      document.notebooks[index] = merged; writeState(tx, ownerRef, ownerMeta, document);
      tx.set(ownerRef, {publicPending: {...(ownerMeta.publicPending || {}), [notebook.id]: merged.updatedAt}}, {merge: true});
    }
    return merged;
  });
}
exports.syncHealthNotebook = syncHealthNotebook;
exports.collaborationLegacyChanged = functions.database.ref("/Users/{owner}/Notes/{sourceID}").onWrite(async (change, context) => {
  const ref = shared(hash(context.params.owner + ":legacy:" + context.params.sourceID));
  const after = change.after.val(); const before = change.before.val() || {};
  const content = value => ({name: value["Category Name"], privacy: value.isPrivateNote, notes: Object.entries(value).filter(([, note]) => note && typeof note === "object" && typeof note["Title name"] === "string").map(([id, note]) => ({id, title: note["Title name"], body: note["Note name"]})).sort((a, b) => a.id.localeCompare(b.id))});
  // Public likes/comments remain available to readers who are not collaborators.
  if (after && JSON.stringify(content(before)) === JSON.stringify(content(after))) return;
  const now = Date.parse(context.timestamp);
  const result = await db().runTransaction(async tx => {
    const snap = await tx.get(ref); const meta = snap.data(); if (!meta || meta.deleted) return null;
    const actor = context.auth?.uid;
    const member = actor ? (await tx.get(ref.collection("members").doc(actor))).data() : null;
    if (!policy.mayMirrorLegacy(member, context.authType, !after)) return {restore: true};
    if (!after) { tx.set(ref, {deleted: true, updatedAt: now}, {merge: true}); return; }
    const current = await readState(tx, ref, meta);
    const notes = new Map(current.notes.map(note => [note.id, note]));
    let changed = current.name !== after["Category Name"];
    for (const note of fromLegacy(after, meta.sourceID, now).notes) {
      const prior = before[note.id]; const existing = notes.get(note.id);
      const differs = !prior || prior["Title name"] !== note.title || prior["Note name"] !== note.body;
      if (differs && (!existing || now >= existing.updatedAt) && (!existing || existing.title !== note.title || (existing.richHTML || existing.body) !== note.body)) { notes.set(note.id, note); changed = true; }
    }
    for (const id of Object.keys(before)) if (before[id] && typeof before[id] === "object" && before[id]["Title name"] !== undefined && !after[id]) { if (notes.delete(id)) changed = true; }
    if (!changed) return;
    current.notes = [...notes.values()]; current.name = after["Category Name"] || current.name; current.updatedAt = now;
    writeState(tx, ref, meta, current); tx.set(ref, {name: current.name, revision: meta.revision + 1, updatedAt: now}, {merge: true});
    return null;
  });
  if (result?.restore) await admin.database().ref("Users/" + context.params.owner + "/Notes/" + context.params.sourceID).transaction(current => {
    if (current === null) return change.before.val();
    // Do not replace a newer owner edit that arrived after the rejected event.
    if (JSON.stringify(content(current)) === JSON.stringify(content(after || {}))) {
      for (const [id, note] of Object.entries(before)) {
        if (note && typeof note === "object" && typeof note["Title name"] === "string") current[id] = {...note, ...(current[id] || {}), "Title name": note["Title name"], "Note name": note["Note name"] || ""};
      }
      for (const field of ["Category Name", "isPrivateNote"]) {
        if (before[field] !== undefined) current[field] = before[field]; else delete current[field];
      }
      for (const [id, note] of Object.entries(after || {})) if (note && typeof note === "object" && typeof note["Title name"] === "string" && !before[id]) delete current[id];
      return current;
    }
    return;
  });
});
