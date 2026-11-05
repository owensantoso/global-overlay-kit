import { testPreflight } from "../scripts/test-preflight.mjs";
import assert from "node:assert/strict";
import { once } from "node:events";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { createServer } from "./server.mjs";

const preflight = (action) =>
  testPreflight(action, "desktop-phone-world-http-test-loopback");

test("HTTP companion serves the private phone projection and bounds pairing input", async (t) => {
  const fixture = await mkdtemp(join(tmpdir(), "phone-world-http-"));
  const staticRoot = join(fixture, "dist");
  await mkdir(staticRoot);
  const index = "<!doctype html><title>Phone world test fixture</title>";
  await writeFile(join(staticRoot, "index.html"), index);
  await writeFile(join(staticRoot, "app.js"), "export const fixture = true;\n");
  await writeFile(join(fixture, "outside.txt"), "outside-static-root");

  const secret = "test-native-only-capability-000000000000";
  const config = {
    nativeSecret: secret,
    publicURL: "https://phone-world.test/phone-world/",
    staticRoot,
    port: 0,
  };
  const { server } = createServer(config);
  preflight("network");
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  assert.ok(address && typeof address === "object");
  config.port = address.port;
  const base = `http://127.0.0.1:${address.port}`;
  const url = (path) => `${base}/phone-world/${path}`;
  const snapshot = {
    width: 1200,
    height: 800,
    player: {
      id: "http-test-one-player",
      x: 1190,
      y: 40,
      vx: 120,
      vy: 0,
      width: 48,
      height: 72,
      facing: "right",
      animation: "walk",
      asset: null,
    },
    platforms: [],
  };
  let nativeSequence = 0;
  let token;
  const released = { left: false, right: false, jump: false, run: false };
  const nativeBody = () => ({
    instanceID: "http-test-native",
    sequence: ++nativeSequence,
    enabled: true,
    snapshot,
    layout: { edge: "right", alignment: 0, scale: 0.4 },
  });
  const post = (path, capability, body, headers = {}) =>
    fetch(url(path), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${capability}`,
        ...headers,
      },
      body: JSON.stringify(body),
    });

  try {
    await t.test(
      "static identity, MIME, security headers and slash redirect",
      async () => {
        const redirect = await fetch(`${base}/phone-world`, {
          redirect: "manual",
        });
        assert.equal(redirect.status, 308);
        assert.equal(redirect.headers.get("location"), "/phone-world/");
        const page = await fetch(url(""));
        assert.equal(page.status, 200);
        assert.match(page.headers.get("content-type"), /^text\/html/);
        assert.equal(await page.text(), index);
        assert.match(
          page.headers.get("content-security-policy"),
          /frame-ancestors 'none'/,
        );
        assert.match(
          page.headers.get("content-security-policy"),
          /connect-src 'self'/,
        );
        assert.equal(page.headers.get("x-content-type-options"), "nosniff");
        assert.equal(page.headers.get("referrer-policy"), "no-referrer");
        assert.equal(page.headers.get("cache-control"), "no-store");
        assert.match(page.headers.get("permissions-policy"), /camera=\(\)/);
        const script = await fetch(url("app.js"));
        assert.equal(script.status, 200);
        assert.equal(script.headers.get("content-type"), "text/javascript");
        assert.match(await script.text(), /fixture = true/);
        const head = await fetch(url("app.js"), { method: "HEAD" });
        assert.equal(head.status, 200);
        assert.equal(await head.text(), "");
      },
    );

    await t.test(
      "unauthorized native status and phone calls expose no snapshot",
      async () => {
        for (const headers of [{}, { Authorization: "Bearer wrong" }]) {
          const response = await fetch(url("api/native-status"), { headers });
          assert.equal(response.status, 401);
          const body = await response.json();
          assert.equal(body.snapshot, undefined);
          assert.equal(body.joinURL, undefined);
        }
        const phone = await post("api/phone", "wrong", {});
        assert.equal(phone.status, 401);
        const native = await post("api/native", "wrong", nativeBody());
        assert.equal(native.status, 401);
      },
    );

    await t.test(
      "native pairing and phone input preserve the authoritative entity",
      async () => {
        const joined = await post("api/native", secret, nativeBody(), {
          Origin: "https://phone-world.test",
        });
        assert.equal(joined.status, 200);
        const nativeReply = await joined.json();
        token = new URLSearchParams(
          new URL(nativeReply.joinURL).hash.slice(1),
        ).get("token");
        assert.match(token, /^[a-f0-9]{48}$/);
        assert.equal(nativeReply.connected, false);

        const phone = await post("api/phone", token, {
          clientID: "http-test-phone",
          sequence: 1,
          viewport: { width: 390, height: 650 },
          input: { ...released, right: true, jump: true },
        });
        assert.equal(phone.status, 200);
        const phoneReply = await phone.json();
        assert.equal(phoneReply.connected, true);
        assert.equal(phoneReply.snapshot.player.id, snapshot.player.id);
        assert.equal(phoneReply.region.x, snapshot.width);
        assert.equal(phoneReply.region.y, 0);

        const status = await fetch(url("api/native-status"), {
          headers: { Authorization: `Bearer ${secret}` },
        });
        assert.equal(status.status, 200);
        const current = await status.json();
        assert.equal(current.snapshot.player.id, snapshot.player.id);
        assert.equal(current.input.right, true);
        assert.equal(current.input.jump, true);
        const health = await fetch(url("health"));
        assert.deepEqual(await health.json(), {
          service: "desktop-phone-world",
          nativeOnline: true,
          phoneOnline: true,
        });
      },
    );

    await t.test(
      "cross-origin, malformed and oversized requests are rejected",
      async () => {
        const origin = await post("api/native", secret, nativeBody(), {
          Origin: "https://unrelated.test",
        });
        assert.equal(origin.status, 403);
        const malformed = await fetch(url("api/phone"), {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: "{",
        });
        assert.equal(malformed.status, 400);
        const contentType = await fetch(url("api/phone"), {
          method: "POST",
          headers: { "Content-Type": "text/plain" },
          body: "{}",
        });
        assert.equal(contentType.status, 415);
        const oversized = await post("api/phone", token, {
          padding: "x".repeat(16001),
        });
        assert.equal(oversized.status, 413);
        const method = await fetch(url("api/phone"));
        assert.equal(method.status, 405);
      },
    );

    await t.test(
      "encoded traversal cannot read outside the static root",
      async () => {
        const response = await fetch(url("%2e%2e%2foutside.txt"));
        assert.equal(response.status, 403);
        assert.doesNotMatch(await response.text(), /outside-static-root/);
        const missing = await fetch(url("missing.js"));
        assert.equal(missing.status, 404);
      },
    );
  } finally {
    // This handle owns only the disposable loopback server created above.
    preflight("process-control");
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    await rm(fixture, { recursive: true, force: true });
  }
});
