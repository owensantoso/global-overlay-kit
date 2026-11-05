import { test } from "node:test";
import assert from "node:assert/strict";
import { PhoneRelay } from "./relay.mjs";
const snapshot = {
  width: 1200,
  height: 800,
  player: {
    id: "same-player",
    x: 1190,
    y: 30,
    vx: 200,
    vy: 0,
    width: 48,
    height: 72,
    facing: "right",
    animation: "walk",
    asset: null,
  },
};
const input = { left: false, right: true, jump: false, run: false };
function fixture() {
  let now = 0;
  const r = new PhoneRelay({
    secret: "native-only",
    publicURL: "https://example.test/phone-world/",
    now: () => now,
  });
  let nativeSequence = 0;
  const native = (extra = {}) =>
    r.native("native-only", {
      instanceID: "native-1",
      sequence: ++nativeSequence,
      enabled: true,
      snapshot,
      layout: { edge: "right", alignment: 0, scale: 0.4 },
      ...extra,
    });
  const join = native();
  const token = new URLSearchParams(new URL(join.joinURL).hash.slice(1)).get(
    "token",
  );
  let sequence = 0;
  const phone = (extra = {}) =>
    r.phone(token, {
      clientID: "phone-1234",
      sequence: ++sequence,
      viewport: { width: 390, height: 650 },
      input,
      ...extra,
    });
  return {
    r,
    native,
    phone,
    advance: (n) => {
      now += n;
    },
    token,
  };
}
test("pairing preserves one native entity and computes adjacent portrait viewport", () => {
  const f = fixture();
  const p = f.phone();
  assert.equal(p.snapshot.player.id, "same-player");
  assert.equal(p.region.x, 1200);
  assert.equal(p.region.y, 0);
  assert.equal(p.region.width, 320);
  assert.equal(f.native().input.right, true);
});
test("all four edges and alignment use bottom-left world coordinates", () => {
  const f = fixture();
  f.phone();
  for (const edge of ["left", "right", "top", "bottom"]) {
    const r = f.native({ layout: { edge, alignment: 1, scale: 0.4 } }).region;
    assert.ok(r);
    if (edge === "left") assert.equal(r.x, -320);
    if (edge === "top") assert.equal(r.y, 800);
    if (edge === "bottom") assert.equal(r.y, -r.height);
    if (edge === "right") assert.equal(r.y, 800 - r.height);
  }
});
test("unpaired and competing phones are rejected; expired seat can reconnect", () => {
  const f = fixture();
  assert.throws(() => f.r.phone("wrong", {}), /QR code/);
  f.phone();
  assert.throws(() => f.phone({ clientID: "other-1234" }), /Another phone/);
  f.advance(800);
  assert.equal(f.phone({ clientID: "other-1234" }).connected, true);
});
test("input expires and native disappearance hides state", () => {
  const f = fixture();
  f.phone();
  f.advance(800);
  const n = f.native();
  assert.equal(n.connected, false);
  assert.equal(n.input.right, false);
  assert.equal(n.region, null);
  f.advance(1600);
  const p = f.phone();
  assert.equal(p.nativeOnline, false);
  assert.equal(p.snapshot, null);
});
test("rotation invalidates old pairing and releases input", () => {
  const f = fixture();
  f.phone();
  const n = f.native({ rotate: true });
  assert.equal(n.connected, false);
  assert.throws(() => f.phone(), /QR code/);
  assert.equal(n.input.right, false);
});
test("reject nonfinite geometry, input types and competing authorities", () => {
  const f = fixture();
  assert.throws(
    () => f.phone({ viewport: { width: NaN, height: 900 } }),
    /Invalid phone/,
  );
  assert.throws(
    () => f.phone({ input: { ...input, left: "true" } }),
    /Invalid phone/,
  );
  assert.throws(
    () => f.native({ snapshot: { ...snapshot, width: Infinity } }),
    /Invalid world/,
  );
  assert.throws(() => f.native({ instanceID: "native-2" }), /Another native/);
  assert.throws(() => f.r.native(f.token, {}), /Native authorization/);
});
test("explicit disconnect retires pairing and snapshot", () => {
  const f = fixture();
  f.phone();
  f.native({ enabled: false });
  assert.equal(f.r.nativeOnline, false);
  assert.throws(() => f.phone(), /QR code/);
});

test("late held input cannot supersede release or refresh heartbeat", () => {
  const f = fixture();
  f.phone({ sequence: 10 });
  f.phone({ sequence: 12, input: { ...input, right: false } });
  f.phone({ sequence: 11 });
  assert.equal(f.native().input.right, false);
  f.advance(800);
  f.phone({ sequence: 11 });
  assert.equal(f.native().connected, false);
});

test("late native snapshot cannot reopen a disconnected session", () => {
  const f = fixture();
  f.native({ sequence: 10 });
  f.native({ sequence: 12, enabled: false });
  assert.equal(f.native({ sequence: 11 }).nativeOnline, false);
});
test("movement releases before the phone disconnect grace expires", () => {
  const f = fixture();
  f.phone();
  f.advance(450);
  const reply = f.native();
  assert.equal(reply.connected, true);
  assert.equal(reply.input.right, false);
});
