"use strict";
const crypto = require("node:crypto");
const CREDIT_MICRO_USD = 4000;
function fail(message) { throw new Error(message); }
function verifiedPeriod(transaction, now = Date.now()) {
  if (transaction.bundleId !== "com.applaz" || transaction.productId !== "299") fail("Wrong subscription.");
  if (transaction.revocationDate || transaction.expiresDate <= now || transaction.purchaseDate > now + 60000) fail("Subscription is inactive.");
  const trial = transaction.offerDiscountType === "FREE_TRIAL";
  if (!transaction.originalTransactionId || !transaction.transactionId) fail("Missing transaction identity.");
  return {transactionID: transaction.transactionId, originalID: transaction.originalTransactionId,
    expiresAt: transaction.expiresDate, capacity: trial ? 10 : 100, trial,
    environment: transaction.environment};
}
function renewWallet(wallet, period, uid) {
  if (wallet && wallet.uid !== uid) fail("This purchase is linked to another Applaz account.");
  if (wallet && wallet.transactionID === period.transactionID) return {...wallet, expiresAt: period.expiresAt};
  if (wallet && wallet.purchaseDate > period.purchaseDate) fail("An older transaction cannot reset credits.");
  // Accelerated sandbox renewals must not create unlimited real API spending.
  const spentSandbox = wallet?.sandboxSpent || 0;
  return {uid, ...period, remaining: period.environment === "Sandbox" ? Math.max(0, Math.min(period.capacity, 10 - spentSandbox)) : period.capacity,
    sandboxSpent: spentSandbox};
}
function reserve(wallet, cost, now = Date.now()) {
  if (!wallet || wallet.expiresAt <= now) fail("Your subscription has expired. Restore or renew to continue.");
  if (wallet.remaining < cost) fail("You’ve used this period’s AI credits. They renew with your next verified billing period.");
  return {...wallet, remaining: wallet.remaining - cost,
    sandboxSpent: (wallet.sandboxSpent || 0) + (wallet.environment === "Sandbox" ? cost : 0)};
}
function requestPayload(data) {
  const question = String(data.question || "").trim();
  const context = String(data.context || "");
  if (Buffer.byteLength(question) > 3000 || Buffer.byteLength(context) > 12000) fail("Select a shorter note or question.");
  if (!question && !data.image) fail("Write a question or choose a meal photo.");
  const meal = data.meal === true;
  let image;
  if (data.image) {
    if (!meal || typeof data.image !== "string" || data.image.length > 26668 || !/^[A-Za-z0-9+/]*={0,2}$/.test(data.image)) fail("Invalid meal photo.");
    image = Buffer.from(data.image, "base64");
    if (!image.length || image.length > 20000 || image[0] !== 255 || image[1] !== 216) fail("Meal photos must be JPEG and at most 20 KB.");
  }
  if (!/^[A-Za-z0-9-]{16,64}$/.test(data.requestID || "")) fail("Invalid request identity.");
  const structured = data.structured === true && !meal;
  const metrics = structured ? (data.metrics || []) : [];
  if (!Array.isArray(metrics) || metrics.length > 5 || Buffer.byteLength(context + JSON.stringify(metrics)) > (structured ? 9500 : 12000)) fail("Select a shorter note or chart period.");
  const metricIDs = new Set();
  for (const metric of metrics) {
    if (!metric || typeof metric.id !== "string" || metric.id.length > 120 || metricIDs.has(metric.id) || typeof metric.title !== "string" || metric.title.length > 120 || typeof metric.unit !== "string" || metric.unit.length > 40 || !Array.isArray(metric.points) || metric.points.length > 32) fail("Invalid chart dataset.");
    metricIDs.add(metric.id);
    if (metric.points.some(p => typeof p.label !== "string" || p.label.length > 80 || !Number.isFinite(p.value) || Math.abs(p.value) > 10000000)) fail("Invalid chart values.");
  }
  return {question, context, image, meal, structured, metrics, cost: image ? 2 : 1, requestID: data.requestID,
    digest: crypto.createHash("sha256").update(JSON.stringify({question, context, meal, structured, metrics, image: data.image || ""})).digest("hex")};
}
function mergeDocument(current = {}, incoming) {
  if (!incoming || !Array.isArray(incoming.notebooks) || !Array.isArray(incoming.meals)) fail("Invalid notebook data.");
  const merge = (a = [], b, notebookPrivacy = false) => {
    const records = new Map(a.map(x => [x.id, x]));
    for (const x of b) {
      if (!x || typeof x.id !== "string" || x.id.length > 100 || typeof x.updatedAt !== "number" || x.updatedAt > Date.now() + 300000) fail("Invalid record.");
      const old = records.get(x.id);
      let value = !old || x.updatedAt > old.updatedAt ? {...x} : {...old};
      if (notebookPrivacy) {
        if (!old) { value.visibilityRevision = 0; }
        else {
          const revision = old.visibilityRevision || 0;
          const intent = typeof x.visibilityIntent === "string" && /^[A-Za-z0-9-]{16,64}$/.test(x.visibilityIntent) && x.visibilityIntent !== old.visibilityIntent;
          if (intent && (x.visibilityRevision || 0) === revision) {
            value.isPrivate = x.isPrivate !== false; value.visibilityRevision = revision + 1; value.visibilityIntent = x.visibilityIntent;
            value.updatedAt = Math.max(Date.now(), old.updatedAt + 1, value.updatedAt);
          } else {
            value.isPrivate = old.isPrivate; value.visibilityRevision = revision; value.visibilityIntent = old.visibilityIntent;
          }
        }
      }
      records.set(x.id, value);
    }
    return [...records.values()];
  };
  const result = {initialized: true, notebooks: merge(current.notebooks, incoming.notebooks, true), meals: merge(current.meals, incoming.meals)};
  return result;
}
function chartResponse(value, metrics) {
  if (!value || typeof value.answer !== "string" || value.answer.length > 5000 || !Array.isArray(value.sources) || value.sources.length > 8 || value.sources.some(s => typeof s !== "string" || s.length > 200)) fail("Invalid AI response.");
  if (value.chart !== null) {
    const chart = value.chart;
    if (!chart || !metrics.some(m => m.id === chart.metricID) || !["line", "bar"].includes(chart.kind) || typeof chart.title !== "string" || chart.title.length > 120) fail("The chart couldn’t be grounded in your records. Try a different question.");
  }
  return value;
}
function chatThread(value) {
  if (!value || !/^[A-Za-z0-9-]{16,64}$/.test(value.id || "") || typeof value.title !== "string" || value.title.length > 200 || !value.scope || typeof value.scope.key !== "string" || value.scope.key.length > 200 || !Array.isArray(value.messages) || value.messages.length > 122 || typeof value.updatedAt !== "number" || value.updatedAt > Date.now() + 300000 || Buffer.byteLength(JSON.stringify(value)) > 500000) fail("This conversation is too large. Start a new chat; your saved history stays available.");
  for (const message of value.messages) {
    if (!message || !["user", "assistant"].includes(message.role) || typeof message.text !== "string" || message.text.length > 10000) fail("Invalid conversation message.");
  }
  return value;
}
module.exports = {chartResponse, chatThread, CREDIT_MICRO_USD, verifiedPeriod, renewWallet, reserve, requestPayload, mergeDocument};

function publicNotebook(notebook) {
  if (!/^[A-Za-z0-9-]{1,100}$/.test(notebook.id || "")) fail("Invalid notebook identity.");
  const version = notebook.updatedAt;
  if (notebook.isDeleted || notebook.isPrivate !== false || notebook.id === "start-here-v1") return {wellnessManaged: true, wellnessUpdatedAt: version, isPrivateNote: true};
  const escape = text => String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const result = {wellnessManaged: true, wellnessUpdatedAt: version, "Category Name": String(notebook.name || "Notebook").slice(0, 150), "Category Key": "wellness-" + notebook.id, isPrivateNote: false};
  for (const note of notebook.notes || []) {
    if (!/^[A-Za-z0-9-]{1,100}$/.test(note.id || "")) fail("Invalid note identity.");
    let body = "<p>" + escape(note.body).replace(/\n/g, "<br>") + "</p>";
    if (note.isChecklist) {
      const items = note.items || [];
      const checked = item => (item.checkedDates || []).includes(item.recurrence === "once" ? "once" : item.isWeekly ? notebook.lastCheckinWeek : notebook.lastCheckinDay);
      body += "<p>" + items.filter(checked).length + " of " + items.length + " complete</p><ul>" + items.map(item => "<li>" + (checked(item) ? "☑ " : "☐ ") + escape(item.title) + (item.detail ? " · " + escape(item.detail) : "") + "</li>").join("") + "</ul>";
    }
    // Meal logs, dated health reflections and all AI conversations remain private.
    for (const photo of note.attachments || []) {
      if (typeof photo !== "string" || photo.length > 26668 || !/^[A-Za-z0-9+/]*={0,2}$/.test(photo)) fail("Invalid shared photo.");
      const bytes = Buffer.from(photo, "base64");
      if (bytes.length > 20000 || bytes[0] !== 255 || bytes[1] !== 216) fail("Shared photos must be JPEG and at most 20 KB.");
      body += "<p><img src=\"data:image/jpeg;base64," + photo + "\" /></p>";
    }
    result[note.id] = {"Title name": String(note.title || "Note").slice(0, 200), "Note name": body, Key: note.id};
  }
  return result;
}
module.exports.publicNotebook = publicNotebook;

// Photo capacity never prevents text/checklist updates from being stored.
function photoCapacity(document, prior = {}, limit = 500000) {
  const result = JSON.parse(JSON.stringify(document));
  const old = new Map();
  for (const n of prior.notebooks || []) for (const note of n.notes || []) {
    const counts = new Map();
    for (const photo of note.attachments || []) counts.set(photo, (counts.get(photo) || 0) + 1);
    old.set(n.id + "/" + note.id, counts);
  }
  let used = 0, blocked = false;
  const pending = [];
  for (const n of result.notebooks) {
    if (n.isDeleted) { n.notes = []; n.items = []; continue; }
    for (const note of n.notes || []) {
      const accepted = []; const existing = old.get(n.id + "/" + note.id) || new Map();
      for (const photo of note.attachments || []) {
        if (typeof photo !== "string" || photo.length > 26668 || !/^[A-Za-z0-9+/]*={0,2}$/.test(photo)) fail("Invalid photo.");
        const bytes = Buffer.from(photo, "base64");
        if (!bytes.length || bytes.length > 20000 || bytes[0] !== 255 || bytes[1] !== 216) fail("Photos must be JPEG and at most 20 KB.");
        if (existing.get(photo) > 0) { existing.set(photo, existing.get(photo) - 1); accepted.push(photo); used += bytes.length; }
        else pending.push({accepted, photo, size: bytes.length});
      }
      note.attachments = accepted;
    }
  }
  for (const item of pending) {
    if (used + item.size <= limit) { item.accepted.push(item.photo); used += item.size; }
    else blocked = true;
  }
  return {document: result, photoStorageFull: blocked, photoBytes: used};
}
function snapshotChunks(document) {
  const characters = Array.from(JSON.stringify(document)); const chunks = [];
  for (let i = 0; i < characters.length; i += 150000) chunks.push(characters.slice(i, i + 150000).join(""));
  return chunks;
}
module.exports.photoCapacity = photoCapacity;
module.exports.snapshotChunks = snapshotChunks;
