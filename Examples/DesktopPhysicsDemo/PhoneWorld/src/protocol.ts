export type Input = {
  left: boolean;
  right: boolean;
  jump: boolean;
  run: boolean;
};
export type Action = keyof Input;
export type Viewport = { width: number; height: number };
export type Player = {
  id: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  width: number;
  height: number;
  facing: "left" | "right";
  animation: string;
  asset: string | null;
  spriteWidth?: number;
  spriteHeight?: number;
  spriteOffsetY?: number;
};
export type PhoneState = {
  nativeOnline: boolean;
  connected: boolean;
  snapshot: {
    width: number;
    height: number;
    player: Player | null;
    platforms?: { x: number; y: number; width: number }[];
  } | null;
  region: { x: number; y: number; width: number; height: number } | null;
  edge: "left" | "right" | "bottom" | "top";
};

export const releasedInput = (): Input => ({
  left: false,
  right: false,
  jump: false,
  run: false,
});

export function parsePhoneState(value: unknown): PhoneState {
  if (!value || typeof value !== "object")
    throw new Error("Invalid world response");
  const state = value as PhoneState;
  const finite = (n: unknown) => typeof n === "number" && Number.isFinite(n);
  if (
    typeof state.nativeOnline !== "boolean" ||
    typeof state.connected !== "boolean" ||
    (state.snapshot !== null &&
      (!state.snapshot ||
        !finite(state.snapshot.width) ||
        !finite(state.snapshot.height))) ||
    !["left", "right", "bottom", "top"].includes(state.edge)
  )
    throw new Error("Invalid world response");
  if (
    state.region &&
    (![
      state.region.x,
      state.region.y,
      state.region.width,
      state.region.height,
    ].every(finite) ||
      state.region.width <= 0 ||
      state.region.height <= 0)
  )
    throw new Error("Invalid phone region");
  const p = state.snapshot?.player;
  if (
    p &&
    (typeof p.id !== "string" ||
      ![p.x, p.y, p.vx, p.vy, p.width, p.height].every(finite) ||
      p.width <= 0 ||
      p.height <= 0 ||
      !["left", "right"].includes(p.facing) ||
      (p.asset !== null &&
        (typeof p.asset !== "string" ||
          !/^[a-zA-Z0-9_-]+\.png$/.test(p.asset))))
  )
    throw new Error("Invalid character state");
  return state;
}
