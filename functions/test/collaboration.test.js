"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const p = require("../collaboration/policy");
test("accepted editors may edit but only owners may delete a notebook", () => {
  p.requireMember({role: "editor"}); p.requireOwner({role: "owner"});
  assert.throws(() => p.requireOwner({role: "editor"}));
  assert.throws(() => p.requireMember(null));
  assert.throws(() => p.requireMember({role: "invited"}));
});
test("only the invited account may accept or decline", () => {
  const inv = {recipient: "alice", status: "pending"};
  assert.equal(p.reply(inv, "alice", true), "accepted");
  assert.equal(p.reply(inv, "alice", false), "declined");
  assert.throws(() => p.reply(inv, "bob", true));
  assert.equal(p.reply({...inv, status: "declined"}, "alice", true), "declined");
});
test("editing one shared note preserves other notes and rejects stale overwrites", () => {
  const a = {id: "a", title: "A", body: "before", items: [], updatedAt: 10};
  const notebook = {notes: [a, {id: "b", title: "B", body: "leave this alone", items: [], updatedAt: 20}]};
  const result = p.editNote(notebook, {...a, body: "after"}, 10, 30);
  assert.equal(result.notes[0].body, "after"); assert.equal(result.notes[1].body, "leave this alone");
  assert.throws(() => p.editNote(result, {...a, body: "stale"}, 10));
  assert.equal(notebook.notes[0].body, "before");
});

test("legacy mirroring cannot turn an editor's direct delete into notebook deletion", () => {
  assert.equal(p.mayMirrorLegacy({role: "editor"}, "USER", true), false);
  assert.equal(p.mayMirrorLegacy({role: "editor"}, "USER", false), true);
  assert.equal(p.mayMirrorLegacy({role: "owner"}, "USER", true), true);
  assert.equal(p.mayMirrorLegacy(null, "UNAUTHENTICATED", false), false);
});
