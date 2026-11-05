import { test } from "node:test";
import assert from "node:assert/strict";
import { PhoneRelay } from "./relay.mjs";

const released = { left: false, right: false, jump: false, run: false };
const baseSnapshot = {
  width: 1200,
  height: 800,
  player: {
    id: "same-player",
    x: 1190,
    y: 40,
    vx: 200,
    vy: 0,
    width: 48,
    height: 72,
    facing: "right",
    animation: "walk",
    asset: null,
  },
  screens: [],
  seams: [],
};
function fixture() {
  let now = 0,
    nativeSequence = 0;
  const sequences = new Map();
  const r = new PhoneRelay({
    secret: "native-only",
    publicURL: "https://example.test/phone-world/",
    now: () => now,
  });
  let snapshot = structuredClone(baseSnapshot);
  const native = (extra = {}) =>
    r.native("native-only", {
      instanceID: "native-1",
      sequence: ++nativeSequence,
      enabled: true,
      snapshot,
      ...extra,
    });
  const first = native();
  let token = new URLSearchParams(new URL(first.joinURL).hash.slice(1)).get(
    "token",
  );
  const phone = (clientID = "client-0001", extra = {}) => {
    sequences.set(clientID, (sequences.get(clientID) ?? 0) + 1);
    return r.phone(token, {
      clientID,
      sequence: sequences.get(clientID),
      viewport: { width: 390, height: 650 },
      input: { ...released },
      ...extra,
    });
  };
  const place = (ids) => {
    snapshot = {
      ...structuredClone(baseSnapshot),
      screens: ids.map((id, index) => ({
        id,
        x: 1200 + index * 320,
        y: 0,
        width: 320,
        height: 530,
      })),
      seams: ids.map((id, index) => ({
        from: index === 0 ? "mac" : ids[index - 1],
        to: id,
        x1: 1200 + index * 320,
        y1: 0,
        x2: 1200 + index * 320,
        y2: 530,
      })),
    };
    return native();
  };
  return {
    r,
    native,
    phone,
    place,
    token,
    advance: (ms) => {
      now += ms;
    },
    setToken: (value) => {
      token = value;
    },
  };
}

test("one QR pairs three stable independent screens without eviction", () => {
  const f = fixture();
  const one = f.phone();
  const two = f.phone("client-0002", { viewport: { width: 844, height: 280 } });
  const three = f.phone("client-0003");
  assert.equal(one.region, null);
  assert.deepEqual(
    [one.phone.label, two.phone.label, three.phone.label],
    ["Phone 1", "Phone 2", "Phone 3"],
  );
  assert.equal(new Set([one.phone.id, two.phone.id, three.phone.id]).size, 3);
  assert.match(one.phone.id, /^[a-f0-9-]{36}$/);
  const n = f.place([one.phone.id, two.phone.id, three.phone.id]);
  assert.deepEqual(
    n.phones.map((p) => p.connected),
    [true, true, true],
  );
  assert.deepEqual(n.phones[1].viewport, { width: 844, height: 280 });
  const reply = f.phone();
  assert.equal(reply.snapshot.player.id, "same-player");
  assert.equal(reply.region.x, 1200);
  assert.deepEqual(
    reply.seams.map((s) => s.label),
    ["To Mac", "To Phone 2"],
  );
  assert.equal(f.phone("client-0002").region.x, 1520);
  assert.deepEqual(
    f.phone("client-0002").seams.map((s) => s.label),
    ["To Phone 1", "To Phone 3"],
  );
});

test("same client reload retains ID, number and updates only its viewport", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002");
  const again = f.phone("client-0001", {
    sequence: 100,
    viewport: { width: 800, height: 300 },
  });
  assert.deepEqual(again.phone, one.phone);
  const n = f.native();
  assert.deepEqual(n.phones[0].viewport, { width: 800, height: 300 });
  assert.deepEqual(n.phones[1].viewport, { width: 390, height: 650 });
  assert.equal(n.phones[1].id, two.phone.id);
});

test("live placed inputs merge and one phone releases only its own input", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002");
  f.place([one.phone.id, two.phone.id]);
  f.phone("client-0001", { input: { ...released, left: true, jump: true } });
  f.phone("client-0002", { input: { ...released, right: true, run: true } });
  assert.deepEqual(f.native().input, {
    left: true,
    right: true,
    jump: true,
    run: true,
  });
  f.phone("client-0001");
  assert.deepEqual(f.native().input, { ...released, right: true, run: true });
});

test("per-phone input and heartbeat expire independently while descriptors remain", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002");
  f.place([one.phone.id, two.phone.id]);
  f.phone("client-0001", { input: { ...released, left: true } });
  f.advance(300);
  f.phone("client-0002", { input: { ...released, right: true } });
  f.advance(150);
  const n = f.native();
  assert.equal(n.input.left, false);
  assert.equal(n.input.right, true);
  assert.deepEqual(
    n.phones.map((p) => p.connected),
    [true, true],
  );
  f.advance(350);
  const later = f.native();
  assert.equal(later.connected, true);
  assert.deepEqual(
    later.phones.map((p) => p.connected),
    [false, true],
  );
  assert.equal(later.phones[0].id, one.phone.id);
  assert.deepEqual(f.phone().phone, one.phone);
});

test("sequences are per phone; late input cannot supersede release or extend heartbeat", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002");
  f.place([one.phone.id, two.phone.id]);
  f.phone("client-0001", { sequence: 10, input: { ...released, left: true } });
  f.phone("client-0002", { sequence: 3, input: { ...released, right: true } });
  f.phone("client-0001", { sequence: 12 });
  f.phone("client-0001", { sequence: 11, input: { ...released, left: true } });
  assert.deepEqual(f.native().input, { ...released, right: true });
  f.advance(800);
  f.phone("client-0001", { sequence: 11 });
  assert.equal(f.native().phones[0].connected, false);
});

test("inactive middle and downstream screens use native geometry and cannot send input", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002"),
    three = f.phone("client-0003");
  f.place([one.phone.id, two.phone.id, three.phone.id]);
  f.phone("client-0003", { input: { ...released, right: true } });
  f.place([one.phone.id]);
  const middle = f.phone("client-0002"),
    downstream = f.phone("client-0003", {
      input: { ...released, right: true },
    });
  assert.equal(middle.connected, true);
  assert.equal(middle.region, null);
  assert.equal(downstream.region, null);
  assert.deepEqual(downstream.seams, []);
  assert.deepEqual(f.native().input, released);
});

test("eight retained slots limit new clients without evicting disconnected screens", () => {
  const f = fixture(),
    ids = [];
  for (let i = 1; i <= 8; i++) ids.push(f.phone(`client-000${i}`).phone.id);
  assert.throws(() => f.phone("client-0009"), /Eight phone screens/);
  f.advance(800);
  assert.throws(() => f.phone("client-0009"), /Eight phone screens/);
  assert.equal(f.phone().phone.id, ids[0]);
  assert.equal(f.native().phones.length, 8);
});

test("recover is monotonic once per fresh request and only for a placed screen", () => {
  const f = fixture(),
    one = f.phone();
  f.phone("client-0001", { recover: true });
  assert.equal(f.native().recoverSequence, 0);
  f.place([one.phone.id]);
  f.phone("client-0001", { sequence: 10, recover: true });
  f.phone("client-0001", { sequence: 10, recover: true });
  assert.equal(f.native().recoverSequence, 1);
});

test("session rotation retires all descriptors and old QR input", () => {
  const f = fixture();
  f.phone();
  f.phone("client-0002");
  const n = f.native({ rotate: true });
  assert.equal(n.connected, false);
  assert.deepEqual(n.phones, []);
  assert.throws(() => f.phone(), /QR code/);
  const token = new URLSearchParams(new URL(n.joinURL).hash.slice(1)).get(
    "token",
  );
  f.setToken(token);
  assert.equal(f.phone().phone.label, "Phone 1");
});

test("native outage hides all snapshots and old instance cannot replace a live world", () => {
  const f = fixture();
  f.phone();
  assert.throws(
    () => f.native({ instanceID: "other-native" }),
    /Another native/,
  );
  f.advance(1600);
  assert.equal(f.phone().snapshot, null);
  const takeover = f.native({ instanceID: "new-native" });
  assert.deepEqual(takeover.phones, []);
  assert.throws(() => f.native(), /Another native/);
});

test("auth, malformed geometry and nonfinite inputs fail without changing authority", () => {
  const f = fixture();
  assert.throws(() => f.r.phone("wrong", {}), /QR code/);
  assert.throws(() => f.r.native(f.token, {}), /Native authorization/);
  assert.throws(
    () => f.phone("client-0001", { viewport: { width: NaN, height: 900 } }),
    /Invalid phone/,
  );
  assert.throws(
    () => f.phone("client-0001", { input: { ...released, left: "true" } }),
    /Invalid phone/,
  );
  assert.throws(
    () => f.native({ snapshot: { ...baseSnapshot, width: Infinity } }),
    /Invalid world/,
  );
  assert.throws(
    () =>
      f.native({
        snapshot: {
          ...baseSnapshot,
          screens: [{ id: "mac", x: 0, y: 0, width: 200, height: 300 }],
        },
      }),
    /Invalid world screen/,
  );
  assert.throws(
    () =>
      f.native({
        snapshot: {
          ...baseSnapshot,
          seams: [{ from: "mac", to: "unknown", x1: 1, y1: 1, x2: 1, y2: 2 }],
        },
      }),
    /Invalid world seam/,
  );
});

test("explicit disconnect clears all phones and stale native snapshot cannot reopen it", () => {
  const f = fixture();
  f.phone();
  f.native({ sequence: 10 });
  f.native({ sequence: 12, enabled: false });
  assert.equal(f.r.nativeOnline, false);
  assert.throws(() => f.phone(), /QR code/);
  const stale = f.native({ sequence: 11 });
  assert.equal(stale.nativeOnline, false);
  assert.deepEqual(stale.phones, []);
});

test("explicit removal retires just that client and new QR scan gets a new numbered slot", () => {
  const f = fixture(),
    one = f.phone(),
    two = f.phone("client-0002");
  f.place([one.phone.id, two.phone.id]);
  const removed = f.native({ removeIDs: [one.phone.id] });
  assert.deepEqual(
    removed.phones.map((p) => p.id),
    [two.phone.id],
  );
  assert.throws(
    () => f.phone(),
    (error) => error.status === 410,
  );
  f.advance(800);
  assert.throws(
    () => f.phone(),
    (error) => error.status === 410,
  );
  const newScan = f.phone("fresh-client-0001");
  assert.equal(newScan.phone.label, "Phone 3");
  assert.notEqual(newScan.phone.id, one.phone.id);
  assert.equal(f.phone("client-0002").phone.label, "Phone 2");
  assert.throws(
    () => f.native({ removeIDs: [two.phone.id, two.phone.id] }),
    /Invalid native/,
  );
  assert.throws(
    () => f.native({ removeIDs: "not-an-array" }),
    /Invalid native/,
  );
});

test("phone region preserves explicit quarter-turn and defaults older screens to zero", () => {
  const f = fixture(),
    phone = f.phone();
  const screen = { id: phone.phone.id, x: 1200, y: 0, width: 640, height: 320 };
  f.native({
    snapshot: { ...baseSnapshot, screens: [{ ...screen, rotation: 90 }] },
  });
  assert.deepEqual(f.phone().region, {
    x: 1200,
    y: 0,
    width: 640,
    height: 320,
    rotation: 90,
  });
  f.native({ snapshot: { ...baseSnapshot, screens: [screen] } });
  assert.equal(f.phone().region.rotation, 0);
  assert.throws(
    () =>
      f.native({
        snapshot: { ...baseSnapshot, screens: [{ ...screen, rotation: 45 }] },
      }),
    /Invalid world screen/,
  );
});
