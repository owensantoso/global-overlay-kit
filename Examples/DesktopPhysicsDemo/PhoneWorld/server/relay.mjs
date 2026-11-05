import { randomBytes, timingSafeEqual } from "node:crypto";

const released = () => ({ left: false, right: false, jump: false, run: false });
const finite = (n, min, max) =>
  typeof n === "number" && Number.isFinite(n) && n >= min && n <= max;
export class RelayError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}
export class PhoneRelay {
  constructor({ secret, publicURL, now = Date.now }) {
    this.secret = secret;
    this.publicURL = publicURL;
    this.now = now;
    this.nativeAt = -Infinity;
    this.phoneAt = -Infinity;
    this.snapshot = null;
    this.layout = null;
    this.nativeID = null;
    this.recoverSequence = 0;
    this.nativeSequence = -1;
    this.rotate();
  }
  rotate() {
    this.token = randomBytes(24).toString("hex");
    this.clientID = null;
    this.phoneAt = -Infinity;
    this.viewport = null;
    this.input = released();
    this.phoneSequence = -1;
  }
  equal(a, b) {
    if (typeof a !== "string" || typeof b !== "string") return false;
    const aa = Buffer.from(a),
      bb = Buffer.from(b);
    return aa.length === bb.length && timingSafeEqual(aa, bb);
  }
  get nativeOnline() {
    return this.now() - this.nativeAt < 1500;
  }
  get phoneOnline() {
    return this.nativeOnline && this.now() - this.phoneAt < 750;
  }
  get region() {
    if (!this.phoneOnline || !this.snapshot || !this.viewport) return null;
    const { width: mw, height: mh } = this.snapshot;
    const width = Math.min(1600, Math.max(140, mh * this.layout.scale));
    const height = Math.min(
      1800,
      Math.max(140, (width * this.viewport.height) / this.viewport.width),
    );
    const { edge, alignment: a } = this.layout;
    if (edge === "right") return { x: mw, y: (mh - height) * a, width, height };
    if (edge === "left")
      return { x: -width, y: (mh - height) * a, width, height };
    if (edge === "bottom")
      return { x: (mw - width) * a, y: -height, width, height };
    return { x: (mw - width) * a, y: mh, width, height };
  }
  native(auth, data) {
    if (!this.equal(auth, this.secret))
      throw new RelayError(401, "Native authorization required");
    if (
      !data ||
      typeof data.instanceID !== "string" ||
      data.instanceID.length > 80 ||
      !Number.isSafeInteger(data.sequence) ||
      data.sequence < 0
    )
      throw new RelayError(400, "Invalid native instance");
    if (this.nativeOnline && this.nativeID !== data.instanceID)
      throw new RelayError(409, "Another native world is connected");
    if (
      this.nativeID === data.instanceID &&
      data.sequence <= this.nativeSequence
    )
      return this.nativeReply();
    if (!data.enabled) {
      this.nativeSequence = data.sequence;
      this.nativeAt = -Infinity;
      this.snapshot = null;
      this.rotate();
      return {
        connected: false,
        nativeOnline: false,
        input: released(),
        region: null,
        recoverSequence: this.recoverSequence,
      };
    }
    const s = data.snapshot,
      l = data.layout;
    if (
      !s ||
      !finite(s.width, 100, 10000) ||
      !finite(s.height, 100, 10000) ||
      !l ||
      !["left", "right", "top", "bottom"].includes(l.edge) ||
      !finite(l.alignment, 0, 1) ||
      !finite(l.scale, 0.2, 0.9)
    )
      throw new RelayError(400, "Invalid world layout");
    if (s.player !== null) {
      const p = s.player;
      if (
        !p ||
        typeof p.id !== "string" ||
        p.id.length > 80 ||
        !["left", "right"].includes(p.facing) ||
        !["x", "y", "vx", "vy"].every((k) => finite(p[k], -100000, 100000)) ||
        !finite(p.width, 1, 2048) ||
        !finite(p.height, 1, 2048)
      )
        throw new RelayError(400, "Invalid player");
    }
    if (this.nativeID !== data.instanceID || data.rotate) this.rotate();
    this.nativeSequence = data.sequence;
    this.nativeID = data.instanceID;
    this.nativeAt = this.now();
    this.snapshot = s;
    this.layout = l;
    return this.nativeReply();
  }
  nativeReply() {
    return {
      connected: this.phoneOnline,
      nativeOnline: this.nativeOnline,
      joinURL: this.nativeOnline
        ? `${this.publicURL}#token=${this.token}`
        : null,
      region: this.region,
      input:
        this.phoneOnline && this.now() - this.phoneAt < 400
          ? this.input
          : released(),
      recoverSequence: this.recoverSequence,
    };
  }
  phone(auth, data) {
    if (!this.equal(auth, this.token))
      throw new RelayError(401, "Scan the current QR code on the Mac");
    if (
      !data ||
      typeof data.clientID !== "string" ||
      data.clientID.length < 8 ||
      data.clientID.length > 80 ||
      !Number.isSafeInteger(data.sequence) ||
      data.sequence < 0 ||
      !data.viewport ||
      !finite(data.viewport.width, 100, 5000) ||
      !finite(data.viewport.height, 100, 5000) ||
      !data.input ||
      !["left", "right", "jump", "run"].every(
        (k) => typeof data.input[k] === "boolean",
      )
    )
      throw new RelayError(400, "Invalid phone input");
    if (this.phoneOnline && this.clientID !== data.clientID)
      throw new RelayError(409, "Another phone is connected");
    if (this.clientID !== data.clientID) this.phoneSequence = -1;
    if (data.sequence > this.phoneSequence) {
      this.clientID = data.clientID;
      this.phoneAt = this.now();
      this.viewport = data.viewport;
      this.input = data.input;
      this.phoneSequence = data.sequence;
      if (data.recover) this.recoverSequence++;
    }
    return {
      nativeOnline: this.nativeOnline,
      connected: this.phoneOnline,
      snapshot: this.nativeOnline ? this.snapshot : null,
      region: this.region,
      edge: this.layout?.edge ?? "right",
    };
  }
}
