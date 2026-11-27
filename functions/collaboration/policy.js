"use strict";
function requireMember(member) {
  if (!member || !["owner", "editor"].includes(member.role)) throw new Error("Accept the invitation to open this notebook.");
}
function requireOwner(member) {
  requireMember(member);
  if (member.role !== "owner") throw new Error("Only the owner can delete this notebook.");
}
function reply(invitation, uid, accept) {
  if (!invitation || invitation.recipient !== uid) throw new Error("This invitation belongs to another account.");
  if (invitation.status !== "pending") return invitation.status;
  return accept ? "accepted" : "declined";
}
function editNote(notebook, change, baseUpdatedAt, now = Date.now()) {
  if (!change || typeof change.id !== "string" || !change.id || typeof change.title !== "string" || typeof change.body !== "string" || !Array.isArray(change.items)) throw new Error("This note couldn’t be saved.");
  for (const item of change.items) {
    if (!item || typeof item.id !== "string" || typeof item.title !== "string" || (item.detail !== undefined && typeof item.detail !== "string") || !Array.isArray(item.checkedDates) || item.checkedDates.some(day => typeof day !== "string")) throw new Error("This checklist couldn’t be saved.");
  }
  if (change.richHTML !== undefined && typeof change.richHTML !== "string") throw new Error("Invalid note content.");
  if (change.attachments !== undefined && (!Array.isArray(change.attachments) || change.attachments.some(photo => {
    if (typeof photo !== "string" || photo.length > 26668 || !/^[A-Za-z0-9+/]*={0,2}$/.test(photo)) return true;
    const bytes = Buffer.from(photo, "base64"); return !bytes.length || bytes.length > 20000 || bytes[0] !== 255 || bytes[1] !== 216;
  }))) throw new Error("This photo couldn’t be prepared.");
  const result = JSON.parse(JSON.stringify(notebook));
  const index = result.notes.findIndex(note => note.id === change.id);
  const prior = result.notes[index];
  if (prior && prior.updatedAt !== baseUpdatedAt) throw new Error("Someone updated this note. Reopen it to review their changes.");
  const note = {...change, updatedAt: now};
  if (index < 0) result.notes.push(note); else result.notes[index] = note;
  result.updatedAt = now;
  return result;
}
module.exports = {requireMember, requireOwner, reply, editNote};

function mayMirrorLegacy(member, authType, deleting) {
  if (authType === "ADMIN") return true;
  if (authType !== "USER" || !member || !["owner", "editor"].includes(member.role)) return false;
  return !deleting || member.role === "owner";
}
module.exports.mayMirrorLegacy = mayMirrorLegacy;
