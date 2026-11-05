import { useCallback, useEffect, useRef, useState } from "react";
import type { PointerEvent as ReactPointerEvent } from "react";
import type { Action, Viewport } from "./protocol.ts";
import { releasedInput } from "./protocol.ts";
import { usePhoneConnection } from "./usePhoneConnection.ts";
import { WorldView } from "./WorldView.tsx";

const controls: { action: Action; label: string; symbol: string }[] = [
  { action: "left", label: "Left", symbol: "←" },
  { action: "right", label: "Right", symbol: "→" },
  { action: "jump", label: "Jump", symbol: "↑" },
  { action: "run", label: "Run", symbol: "⇧" },
];

const actionForKey = (code: string): Action | null => {
  if (code.startsWith("button-")) {
    const action = code.slice(7);
    if (controls.some((control) => control.action === action))
      return action as Action;
  }
  if (code === "ArrowLeft" || code === "KeyA") return "left";
  if (code === "ArrowRight" || code === "KeyD") return "right";
  if (["ArrowUp", "KeyW", "Space"].includes(code)) return "jump";
  if (["ShiftLeft", "ShiftRight"].includes(code)) return "run";
  return null;
};

export function App() {
  const [viewport, setViewport] = useState<Viewport>({ width: 0, height: 0 });
  const [input, setInput] = useState(releasedInput);
  const pointers = useRef(new Map<number, Action>());
  const keys = useRef(new Set<string>());
  const pulses = useRef(new Map<Action, ReturnType<typeof setTimeout>>());
  const enabled = useRef(false);
  const refreshInput = useCallback(() => {
    const next = releasedInput();
    for (const action of pointers.current.values()) next[action] = true;
    for (const key of keys.current) {
      const action = actionForKey(key);
      if (action) next[action] = true;
    }
    setInput((previous) =>
      controls.every(({ action }) => previous[action] === next[action])
        ? previous
        : next,
    );
  }, []);
  const clearInput = useCallback(() => {
    pointers.current.clear();
    keys.current.clear();
    for (const timer of pulses.current.values()) clearTimeout(timer);
    pulses.current.clear();
    setInput((previous) =>
      controls.every(({ action }) => !previous[action])
        ? previous
        : releasedInput(),
    );
  }, []);
  const { connection, world, phone, returnToMac, reconnect } =
    usePhoneConnection(viewport, input, clearInput);
  const ready = connection === "online" && !!world?.region;

  useEffect(() => {
    enabled.current = ready;
  }, [ready]);
  useEffect(() => {
    const down = (event: KeyboardEvent) => {
      if (
        !enabled.current ||
        event.metaKey ||
        event.ctrlKey ||
        event.altKey ||
        !document.hasFocus()
      )
        return;
      if (
        event.target instanceof HTMLElement &&
        (event.target.isContentEditable ||
          ["INPUT", "TEXTAREA", "SELECT"].includes(event.target.tagName))
      )
        return;
      if (!actionForKey(event.code)) return;
      event.preventDefault();
      keys.current.add(event.code);
      refreshInput();
    };
    const up = (event: KeyboardEvent) => {
      if (!keys.current.has(event.code)) return;
      event.preventDefault();
      keys.current.delete(event.code);
      refreshInput();
    };
    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    return () => {
      window.removeEventListener("keydown", down);
      window.removeEventListener("keyup", up);
    };
  }, [refreshInput]);

  const pointerDown = (
    action: Action,
    event: ReactPointerEvent<HTMLButtonElement>,
  ) => {
    if (!ready || (event.pointerType === "mouse" && event.button !== 0)) return;
    event.preventDefault();
    pointers.current.set(event.pointerId, action);
    try {
      event.currentTarget.setPointerCapture(event.pointerId);
    } catch {
      /* Synthetic pointers may have no OS capture. */
    }
    refreshInput();
  };
  const pointerUp = (event: ReactPointerEvent<HTMLButtonElement>) => {
    if (!pointers.current.has(event.pointerId)) return;
    event.preventDefault();
    pointers.current.delete(event.pointerId);
    refreshInput();
  };

  const status = {
    online: ready ? "Connected" : "Needs placement",
    connecting: "Waiting for Mac…",
    offline: "Reconnecting…",
    invalid: "Pairing needed",
    occupied: "Session is full",
    paused: "Paused",
    removed: "Removed from session",
  }[connection];
  const player = world?.snapshot?.player;
  const region = world?.region;
  const inPhone = !!(
    ready &&
    player &&
    region &&
    player.x + player.width / 2 > region.x &&
    player.x - player.width / 2 < region.x + region.width &&
    player.y + player.height / 2 > region.y &&
    player.y - player.height / 2 < region.y + region.height
  );
  let message = "";
  if (connection === "invalid")
    message = "Scan a new QR code in Desktop Physics Demo on your Mac.";
  else if (connection === "removed")
    message = "This phone was removed. Scan the QR code to join again.";
  else if (connection === "occupied")
    message = "Remove a screen or reset the session on the Mac, then retry.";
  else if (connection === "offline")
    message = "Keep this phone and your Mac connected to Tailscale.";
  else if (connection === "connecting")
    message = "Open Desktop Physics Demo and connect a phone screen.";
  else if (connection === "online" && !region)
    message = "Connect this screen in the Mac layout.";
  else if (ready && !player) message = "Spawn a player on your Mac.";
  else if (ready && !inPhone)
    message =
      player &&
      world?.snapshot &&
      player.x >= 0 &&
      player.x <= world.snapshot.width &&
      player.y >= 0 &&
      player.y <= world.snapshot.height
        ? "Character is on the Mac"
        : "Character is on another screen";

  return (
    <main className="app" data-connection={connection}>
      <header className="header">
        <h1>{phone?.label ?? "Phone world"}</h1>
        <p className="connection" role="status">
          <span className="status-dot" aria-hidden="true" />
          {status}
          {ready && world?.region?.rotation === 90 && " · Rotated view"}
        </p>
      </header>
      <WorldView world={world} message={message} onResize={setViewport} />
      <footer className="controls">
        <div className="movement" role="group" aria-label="Character controls">
          {controls.map(({ action, label, symbol }) => (
            <button
              key={action}
              className={`move move-${action}`}
              disabled={!ready}
              aria-label={label}
              aria-pressed={input[action]}
              data-pressed={input[action]}
              onPointerDown={(event) => pointerDown(action, event)}
              onPointerUp={pointerUp}
              onPointerCancel={pointerUp}
              onLostPointerCapture={pointerUp}
              onKeyDown={(event) => {
                if (event.code !== "Space" && event.code !== "Enter") return;
                event.preventDefault();
                event.stopPropagation();
                keys.current.add(`button-${action}`);
                refreshInput();
              }}
              onKeyUp={(event) => {
                if (event.code !== "Space" && event.code !== "Enter") return;
                event.preventDefault();
                event.stopPropagation();
                keys.current.delete(`button-${action}`);
                refreshInput();
              }}
              onBlur={() => {
                keys.current.delete(`button-${action}`);
                refreshInput();
              }}
              onContextMenu={(event) => event.preventDefault()}
              onClick={(event) => {
                // Assistive technology can activate a button without pointer/key events.
                if (event.detail !== 0 || !ready) return;
                const code = `button-${action}`;
                clearTimeout(pulses.current.get(action));
                keys.current.add(code);
                refreshInput();
                pulses.current.set(
                  action,
                  setTimeout(() => {
                    keys.current.delete(code);
                    pulses.current.delete(action);
                    refreshInput();
                  }, 150),
                );
              }}
            >
              <span className="control-symbol" aria-hidden="true">
                {symbol}
              </span>
              <span>{label}</span>
            </button>
          ))}
        </div>
        <div className="recovery">
          {connection === "occupied" || connection === "offline" ? (
            <button className="text-button" onClick={reconnect}>
              Retry connection
            </button>
          ) : (
            <button
              className="text-button"
              disabled={!inPhone}
              onClick={returnToMac}
            >
              Return to Mac
            </button>
          )}
        </div>
      </footer>
    </main>
  );
}
