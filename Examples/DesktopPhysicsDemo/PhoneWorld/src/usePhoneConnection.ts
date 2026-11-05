import { useCallback, useEffect, useRef, useState } from "react";
import { parsePhoneState, releasedInput } from "./protocol.ts";
import type { Input, PhoneState, Viewport } from "./protocol.ts";

type Connection =
  | "connecting"
  | "online"
  | "offline"
  | "invalid"
  | "occupied"
  | "paused"
  | "removed";

function session() {
  const fragment = new URLSearchParams(location.hash.slice(1)).get("token");
  let token = fragment && /^[a-f0-9]{32,128}$/i.test(fragment) ? fragment : "";
  let clientID = "";
  let removed = false;
  try {
    removed = sessionStorage.getItem("phone-world.removed") === "true";
    if (fragment && token && removed) {
      sessionStorage.removeItem("phone-world.clientID");
      sessionStorage.removeItem("phone-world.removed");
      removed = false;
    }
    if (token) sessionStorage.setItem("phone-world.token", token);
    else token = sessionStorage.getItem("phone-world.token") || "";
    clientID = sessionStorage.getItem("phone-world.clientID") || "";
    if (!clientID) {
      clientID = crypto.randomUUID();
      sessionStorage.setItem("phone-world.clientID", clientID);
    }
  } catch {
    /* A same-page session works when storage is unavailable. */
  }
  if (!clientID) clientID = crypto.randomUUID();
  if (location.hash)
    history.replaceState(null, "", location.pathname + location.search);
  return { token, clientID, removed, sequenceBase: Date.now() * 1000 };
}

export function usePhoneConnection(
  viewport: Viewport,
  input: Input,
  clearInput: () => void,
) {
  useEffect(() => {
    const invitation = () => {
      const token = new URLSearchParams(location.hash.slice(1)).get("token");
      // Camera can reopen the existing tab with a fragment-only navigation.
      if (token && /^[a-f0-9]{32,128}$/i.test(token)) location.reload();
    };
    window.addEventListener("hashchange", invitation);
    return () => window.removeEventListener("hashchange", invitation);
  }, []);
  const [credentials] = useState(session);
  const [connection, setConnection] = useState<Connection>(
    credentials.removed
      ? "removed"
      : credentials.token
        ? "connecting"
        : "invalid",
  );
  const [world, setWorld] = useState<PhoneState | null>(null);
  const [phone, setPhone] = useState<PhoneState["phone"] | null>(null);
  const [retry, setRetry] = useState(0);
  const latest = useRef({ viewport, input });
  const sequence = useRef(credentials.sequenceBase);
  const recovery = useRef(false);
  const sendRelease = useRef<(() => void) | null>(null);
  const hasViewport = viewport.width > 0 && viewport.height > 0;

  useEffect(() => {
    latest.current = { viewport, input };
  }, [viewport, input]);

  const returnToMac = useCallback(() => {
    clearInput();
    recovery.current = true;
  }, [clearInput]);

  const reconnect = useCallback(() => {
    clearInput();
    setRetry((n) => n + 1);
  }, [clearInput]);

  useEffect(() => {
    if (!credentials.token || credentials.removed || !hasViewport) return;
    let disposed = false;
    let paused = document.hidden;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let controller: AbortController | null = null;
    let generation = 0;
    let lastApplied = 0;
    let expired = false;

    const body = (release = false) => ({
      clientID: credentials.clientID,
      sequence: ++sequence.current,
      viewport: latest.current.viewport,
      input: release ? releasedInput() : latest.current.input,
      ...(recovery.current && !release ? { recover: true } : {}),
    });
    const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${credentials.token}`,
    };
    const release = () => {
      latest.current = { ...latest.current, input: releasedInput() };
      clearInput();
      if (expired) return;
      void fetch(`${import.meta.env.BASE_URL}api/phone`, {
        method: "POST",
        headers,
        body: JSON.stringify(body(true)),
        keepalive: true,
      }).catch(() => {
        /* Server heartbeat expiry also releases held controls. */
      });
    };
    sendRelease.current = release;

    const poll = async () => {
      if (disposed || paused || expired) return;
      const mine = ++generation;
      controller = new AbortController();
      const request = body();
      const timeout = setTimeout(() => controller?.abort(), 800);
      let delay = 33;
      try {
        const response = await fetch(`${import.meta.env.BASE_URL}api/phone`, {
          method: "POST",
          headers,
          body: JSON.stringify(request),
          signal: controller.signal,
          cache: "no-store",
        });
        if (disposed || paused || mine !== generation) return;
        if (response.status === 401 || response.status === 410) {
          expired = true;
          if (response.status === 410) {
            try {
              sessionStorage.setItem("phone-world.removed", "true");
            } catch {
              /* Current session still stops. */
            }
          }
          clearInput();
          setWorld(null);
          setConnection(response.status === 410 ? "removed" : "invalid");
          return;
        }
        if (response.status === 409) {
          clearInput();
          setWorld(null);
          setConnection("occupied");
          delay = 1000;
        } else {
          if (!response.ok) throw new Error("Connection unavailable");
          const next = parsePhoneState(await response.json());
          if (
            disposed ||
            paused ||
            mine !== generation ||
            request.sequence <= lastApplied
          )
            return;
          lastApplied = request.sequence;
          if (request.recover) recovery.current = false;
          if (
            !next.nativeOnline ||
            !next.connected ||
            !next.snapshot ||
            !next.region
          ) {
            latest.current.input = releasedInput();
            clearInput();
          }
          setWorld(next);
          setPhone(next.phone);
          setConnection(
            next.nativeOnline && next.connected && next.snapshot
              ? "online"
              : "connecting",
          );
        }
      } catch {
        if (disposed || paused || mine !== generation) return;
        latest.current.input = releasedInput();
        clearInput();
        setWorld(null);
        setConnection("offline");
        delay = 400;
      } finally {
        clearTimeout(timeout);
        controller = null;
        if (!disposed && !paused && !expired && mine === generation)
          timer = setTimeout(() => {
            void poll();
          }, delay);
      }
    };

    const pause = () => {
      paused = true;
      ++generation;
      clearTimeout(timer);
      controller?.abort();
      release();
      setWorld(null);
      setConnection("paused");
    };
    const resume = () => {
      if (document.hidden || disposed || expired || !paused) return;
      paused = false;
      setConnection("connecting");
      void poll();
    };
    const visibility = () => {
      if (document.hidden) pause();
      else resume();
    };
    const blur = () => {
      release();
    };
    document.addEventListener("visibilitychange", visibility);
    window.addEventListener("pagehide", pause);
    window.addEventListener("pageshow", resume);
    window.addEventListener("blur", blur);
    window.addEventListener("focus", resume);
    if (!paused) void poll();

    return () => {
      disposed = true;
      ++generation;
      clearTimeout(timer);
      controller?.abort();
      release();
      sendRelease.current = null;
      document.removeEventListener("visibilitychange", visibility);
      window.removeEventListener("pagehide", pause);
      window.removeEventListener("pageshow", resume);
      window.removeEventListener("blur", blur);
      window.removeEventListener("focus", resume);
    };
    // Viewport changes are read through latest; they must not restart pairing.
  }, [credentials, clearInput, retry, hasViewport]);

  return {
    connection,
    world,
    phone,
    returnToMac,
    reconnect,
    release: () => sendRelease.current?.(),
  };
}
