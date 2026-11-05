import { randomBytes, randomUUID, timingSafeEqual } from "node:crypto";

const released = () => ({ left: false, right: false, jump: false, run: false });
const finite = (n, min, max) =>
  typeof n === "number" && Number.isFinite(n) && n >= min && n <= max;
const identifier = (value) =>
  typeof value === "string" && value.length > 0 && value.length <= 80;
const geometry = (rect) =>
  rect &&
  finite(rect.x, -100000, 100000) &&
  finite(rect.y, -100000, 100000) &&
  finite(rect.width, 1, 10000) &&
  finite(rect.height, 1, 10000);

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
    this.snapshot = null;
    this.nativeID = null;
    this.nativeSequence = -1;
    this.recoverSequence = 0;
    this.rotate();
  }
  rotate() {
    this.token = randomBytes(24).toString("hex");
    this.phones = new Map();
    this.blockedClients = new Set();
    this.nextLabel = 1;
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
  live(phone) {
    return this.nativeOnline && this.now() - phone.at < 750;
  }
  get phoneOnline() {
    return [...this.phones.values()].some((phone) => this.live(phone));
  }

  validateSnapshot(snapshot) {
    if (
      !snapshot ||
      !finite(snapshot.width, 100, 10000) ||
      !finite(snapshot.height, 100, 10000) ||
      !Array.isArray(snapshot.screens) ||
      snapshot.screens.length > 8 ||
      !Array.isArray(snapshot.seams) ||
      snapshot.seams.length > 64
    )
      throw new RelayError(400, "Invalid world layout");
    const ids = new Set(["mac"]);
    for (const screen of snapshot.screens) {
      if (
        !identifier(screen.id) ||
        ids.has(screen.id) ||
        !geometry(screen) ||
        ![0, 90].includes(screen.rotation ?? 0)
      )
        throw new RelayError(400, "Invalid world screen");
      ids.add(screen.id);
    }
    for (const seam of snapshot.seams) {
      if (
        !ids.has(seam.from) ||
        !ids.has(seam.to) ||
        seam.from === seam.to ||
        !["x1", "y1", "x2", "y2"].every((key) =>
          finite(seam[key], -100000, 100000),
        ) ||
        !(
          (seam.x1 === seam.x2 && seam.y1 !== seam.y2) ||
          (seam.y1 === seam.y2 && seam.x1 !== seam.x2)
        )
      )
        throw new RelayError(400, "Invalid world seam");
    }
    const player = snapshot.player;
    if (
      player !== null &&
      (!player ||
        !identifier(player.id) ||
        !["left", "right"].includes(player.facing) ||
        !["x", "y", "vx", "vy"].every((key) =>
          finite(player[key], -100000, 100000),
        ) ||
        !finite(player.width, 1, 2048) ||
        !finite(player.height, 1, 2048))
    )
      throw new RelayError(400, "Invalid player");
  }

  native(auth, data) {
    if (!this.equal(auth, this.secret))
      throw new RelayError(401, "Native authorization required");
    if (
      !data ||
      !identifier(data.instanceID) ||
      !Number.isSafeInteger(data.sequence) ||
      data.sequence < 0 ||
      typeof data.enabled !== "boolean" ||
      (data.rotate !== undefined && typeof data.rotate !== "boolean") ||
      (data.removeIDs !== undefined &&
        (!Array.isArray(data.removeIDs) ||
          data.removeIDs.length > 8 ||
          !data.removeIDs.every(identifier) ||
          new Set(data.removeIDs).size !== data.removeIDs.length))
    )
      throw new RelayError(400, "Invalid native instance");
    if (this.nativeOnline && this.nativeID !== data.instanceID)
      throw new RelayError(409, "Another native world is connected");
    if (
      this.nativeID === data.instanceID &&
      data.sequence <= this.nativeSequence
    )
      return this.nativeReply();
    if (data.enabled) this.validateSnapshot(data.snapshot);
    const reset =
      this.nativeID !== data.instanceID || data.rotate || !data.enabled;
    if (reset) this.rotate();
    for (const id of data.removeIDs ?? []) {
      for (const [clientID, phone] of this.phones) {
        if (phone.id === id) {
          this.phones.delete(clientID);
          this.blockedClients.add(clientID);
        }
      }
    }
    this.nativeID = data.instanceID;
    this.nativeSequence = data.sequence;
    this.nativeAt = data.enabled ? this.now() : -Infinity;
    this.snapshot = data.enabled ? structuredClone(data.snapshot) : null;
    return this.nativeReply();
  }

  regionFor(phone) {
    if (!this.live(phone)) return null;
    const rect = this.snapshot?.screens.find(
      (screen) => screen.id === phone.id,
    );
    return rect
      ? {
          x: rect.x,
          y: rect.y,
          width: rect.width,
          height: rect.height,
          rotation: rect.rotation ?? 0,
        }
      : null;
  }
  nativeReply() {
    const input = released();
    for (const phone of this.phones.values()) {
      if (!this.regionFor(phone) || this.now() - phone.at >= 400) continue;
      for (const key of Object.keys(input)) input[key] ||= phone.input[key];
    }
    return {
      connected: this.phoneOnline,
      nativeOnline: this.nativeOnline,
      joinURL: this.nativeOnline
        ? `${this.publicURL}#token=${this.token}`
        : null,
      input,
      recoverSequence: this.recoverSequence,
      phones: [...this.phones.values()].map((phone) => ({
        id: phone.id,
        label: phone.label,
        connected: this.live(phone),
        viewport: { ...phone.viewport },
      })),
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
        (key) => typeof data.input[key] === "boolean",
      ) ||
      (data.recover !== undefined && typeof data.recover !== "boolean")
    )
      throw new RelayError(400, "Invalid phone input");
    if (this.blockedClients.has(data.clientID))
      throw new RelayError(410, "Phone removed from this session");
    let phone = this.phones.get(data.clientID);
    if (!phone) {
      if (this.phones.size >= 8)
        throw new RelayError(
          409,
          "Eight phone screens are already paired. Reset the session on the Mac to pair different screens.",
        );
      phone = {
        id: randomUUID(),
        label: `Phone ${this.nextLabel++}`,
        at: -Infinity,
        sequence: -1,
        viewport: { ...data.viewport },
        input: released(),
      };
      this.phones.set(data.clientID, phone);
    }
    if (data.sequence > phone.sequence) {
      phone.at = this.now();
      phone.sequence = data.sequence;
      phone.viewport = { ...data.viewport };
      phone.input = { ...data.input };
      if (data.recover && this.regionFor(phone)) this.recoverSequence++;
    }
    const labels = new Map(
      [...this.phones.values()].map((item) => [item.id, item.label]),
    );
    const region = this.regionFor(phone);
    const seams = region
      ? this.snapshot.seams
          .filter((seam) => seam.from === phone.id || seam.to === phone.id)
          .map((seam) => {
            const neighborID = seam.from === phone.id ? seam.to : seam.from;
            return {
              x1: seam.x1,
              y1: seam.y1,
              x2: seam.x2,
              y2: seam.y2,
              neighborID,
              label:
                neighborID === "mac"
                  ? "To Mac"
                  : `To ${labels.get(neighborID) ?? "phone"}`,
            };
          })
          .filter(
            (seam) =>
              seam.neighborID === "mac" ||
              [...this.phones.values()].some(
                (item) => item.id === seam.neighborID && this.regionFor(item),
              ),
          )
      : [];
    return {
      nativeOnline: this.nativeOnline,
      connected: this.live(phone),
      phone: { id: phone.id, label: phone.label },
      snapshot: this.nativeOnline ? structuredClone(this.snapshot) : null,
      region,
      seams,
    };
  }
}
