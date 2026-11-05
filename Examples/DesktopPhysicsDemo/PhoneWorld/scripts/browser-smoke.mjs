import { testPreflight as preflight } from "./test-preflight.mjs";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve, extname } from "node:path";
import { chromium } from "playwright";

// Test-only authority exercises the delivered browser bundle. It is never shipped.
const root = fileURLToPath(new URL("../", import.meta.url));
const token = "a".repeat(64);
const requests = [];
let nativeOnline = true;
let responseStatus = 200;
let responseDelay = 0;
let playerX = 1590;

preflight("network", "phone-world-browser-smoke-loopback");
const server = createServer(async (req, res) => {
  try {
    if (req.url === "/phone-world/api/phone") {
      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      const body = JSON.parse(Buffer.concat(chunks).toString());
      requests.push(body);
      const regionHeight = (400 * body.viewport.height) / body.viewport.width;
      assert.equal(req.headers.authorization, `Bearer ${token}`);
      if (responseDelay)
        await new Promise((resolve) => setTimeout(resolve, responseDelay));
      res.writeHead(responseStatus, { "content-type": "application/json" });
      res.end(
        JSON.stringify({
          nativeOnline,
          connected: true,
          snapshot: nativeOnline
            ? {
                width: 1512,
                height: 982,
                player: {
                  id: "same-native-player",
                  x: playerX,
                  y: Math.max(70, regionHeight / 2),
                  vx: 0,
                  vy: 0,
                  width: 34,
                  height: 86,
                  facing: "right",
                  animation: "idle",
                  asset: "fighter_Idle_0001.png",
                  spriteWidth: 270,
                  spriteHeight: 270,
                  spriteOffsetY: 22,
                },
                platforms: [{ x: 1512, y: 30, width: 400 }],
              }
            : null,
          region: { x: 1512, y: 0, width: 400, height: regionHeight },
          edge: "right",
        }),
      );
      return;
    }
    const pathname = new URL(req.url, "http://test").pathname;
    let path;
    if (pathname.startsWith("/phone-world/characters/")) {
      path = resolve(root, "dist/characters", pathname.split("/").at(-1));
    } else {
      const relative = pathname.replace(/^\/phone-world\//, "") || "index.html";
      path = resolve(root, "dist", relative);
      if (!path.startsWith(resolve(root, "dist") + "/"))
        throw new Error("Invalid test path");
    }
    const mime =
      {
        ".html": "text/html",
        ".js": "text/javascript",
        ".css": "text/css",
        ".png": "image/png",
      }[extname(path)] || "application/octet-stream";
    res.writeHead(200, { "content-type": mime });
    res.end(await readFile(path));
  } catch {
    if (!res.headersSent) res.writeHead(404);
    res.end();
  }
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const port = server.address().port;
const origin = `http://127.0.0.1:${port}`;
preflight("process-control", "phone-world-browser-smoke-launch");
const browser = await chromium.launch({ channel: "chrome", headless: true });
const errors = [];
const expectedNetworkNotes = [];
const external = [];
let checks = 0;
const check = (condition, message) => {
  assert.ok(condition, message);
  checks++;
};
const wait = async (predicate) => {
  const end = Date.now() + 4000;
  while (!predicate()) {
    if (Date.now() > end)
      throw new Error("Timed out waiting for browser input");
    await new Promise((resolve) => setTimeout(resolve, 30));
  }
};
const last = () => requests.at(-1);
try {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    hasTouch: true,
  });
  const page = await context.newPage();
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() !== "error") return;
    if (
      message.location().url.endsWith("/phone-world/api/phone") &&
      /status of (401|409)/.test(message.text())
    ) {
      expectedNetworkNotes.push(message.text());
    } else errors.push(message.text());
  });
  page.on("request", (request) => {
    if (!request.url().startsWith(origin)) external.push(request.url());
  });
  await page.goto(`${origin}/phone-world/#token=${token}`);
  await page.locator('main[data-connection="online"]').waitFor();
  check(
    (await page.getByRole("heading", { name: "Phone world" }).count()) === 1,
    "React entry renders one heading",
  );
  check(!new URL(page.url()).hash, "pairing capability removed from address");
  await wait(() => requests.length >= 4);
  check(
    requests.every(
      (request, index) =>
        index === 0 || request.sequence > requests[index - 1].sequence,
    ),
    "requests have increasing sequence",
  );
  check(
    last().viewport.width === 390 &&
      last().viewport.height > 400 &&
      last().viewport.height < 844,
    "only measured canvas dimensions sent",
  );
  const left = page.getByRole("button", { name: "Left", exact: true });
  const jump = page.getByRole("button", { name: "Jump", exact: true });
  await left.dispatchEvent("pointerdown", {
    pointerId: 11,
    pointerType: "touch",
    button: 0,
  });
  await jump.dispatchEvent("pointerdown", {
    pointerId: 12,
    pointerType: "touch",
    button: 0,
  });
  await wait(() => last()?.input.left && last()?.input.jump);
  check(true, "two fingers independently hold move and jump");
  await left.dispatchEvent("pointercancel", {
    pointerId: 11,
    pointerType: "touch",
  });
  await wait(() => !last()?.input.left && last()?.input.jump);
  check(true, "cancel releases only its own pointer");
  await jump.dispatchEvent("lostpointercapture", {
    pointerId: 12,
    pointerType: "touch",
  });
  await wait(() =>
    Object.values(last()?.input || {}).every((value) => value === false),
  );
  check(true, "lost capture releases jump");
  await left.focus();
  await page.keyboard.down("Enter");
  await wait(() => last()?.input.left);
  await page.keyboard.up("Enter");
  await wait(() => !last()?.input.left);
  check(true, "focused native button works with keyboard");
  await page.locator("h1").click();
  await page.keyboard.down("ArrowRight");
  await wait(() => last()?.input.right);
  await page.evaluate(() => window.dispatchEvent(new Event("blur")));
  await wait(() => !last()?.input.right);
  await page.keyboard.up("ArrowRight");
  check(true, "blur releases keyboard movement");
  await left.dispatchEvent("pointerdown", {
    pointerId: 20,
    pointerType: "touch",
    button: 0,
  });
  await wait(() => last()?.input.left);
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", {
      configurable: true,
      value: true,
    });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await wait(() => !last()?.input.left);
  await page.locator('main[data-connection="paused"]').waitFor();
  check(
    await left.isDisabled(),
    "simulated hidden tab releases input and pauses polling",
  );
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", {
      configurable: true,
      value: false,
    });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await page.locator('main[data-connection="online"]').waitFor();
  responseDelay = 1200;
  await page.locator('main[data-connection="offline"]').waitFor();
  check(
    await left.isDisabled(),
    "request deadline clears stale controls within one second",
  );
  responseDelay = 0;
  await page.locator('main[data-connection="online"]').waitFor();
  await page.getByRole("button", { name: "Return to Mac" }).click();
  await wait(() => requests.some((request) => request.recover));
  check(true, "recovery requests native return with released input");
  playerX = 900;
  await page.getByText("Character is on the Mac", { exact: true }).waitFor();
  check(
    await page.getByRole("button", { name: "Return to Mac" }).isDisabled(),
    "Mac-only position explained and recovery disabled",
  );
  playerX = 1590;
  await page
    .getByText("Character is on the Mac", { exact: true })
    .waitFor({ state: "hidden" });
  await page.setViewportSize({ width: 844, height: 390 });
  await wait(
    () => last()?.viewport.width === 844 && last()?.viewport.height < 300,
  );
  check(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
    "landscape controls fit without horizontal overflow",
  );
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.waitForTimeout(150);
  await mkdir(resolve(root, "evidence"), { recursive: true });
  await page.screenshot({ path: resolve(root, "evidence/phone-portrait.png") });
  await page.setViewportSize({ width: 844, height: 390 });
  await page.waitForTimeout(150);
  await page.screenshot({
    path: resolve(root, "evidence/phone-landscape.png"),
  });
  nativeOnline = false;
  await page.locator('main[data-connection="connecting"]').waitFor();
  check(
    await left.isDisabled(),
    "stale native disables controls and removes character state",
  );
  nativeOnline = true;
  await page.locator('main[data-connection="online"]').waitFor();
  responseStatus = 409;
  await page.getByText("Another phone is connected", { exact: true }).waitFor();
  check(
    await page.getByRole("button", { name: "Retry connection" }).isVisible(),
    "occupied pairing is recoverable",
  );
  responseStatus = 200;
  await page.getByRole("button", { name: "Retry connection" }).click();
  await page.locator('main[data-connection="online"]').waitFor();
  responseStatus = 401;
  await page.locator('main[data-connection="invalid"]').waitFor();
  check(
    await page
      .getByText("Scan a new QR code in Desktop Physics Demo on your Mac.")
      .isVisible(),
    "revoked capability gives specific recovery",
  );
  check(errors.length === 0, `no console errors: ${errors.join(", ")}`);
  check(external.length === 0, "no external runtime requests");
  await context.close();
  const fresh = await browser.newContext({
    viewport: { width: 390, height: 844 },
  });
  const empty = await fresh.newPage();
  await empty.goto(`${origin}/phone-world/`);
  check(
    await empty.getByRole("button", { name: "Left", exact: true }).isDisabled(),
    "unpaired page keeps controls disabled",
  );
  await fresh.close();
  await writeFile(
    resolve(root, "evidence/browser-receipt.json"),
    JSON.stringify(
      {
        checks,
        consoleErrors: errors,
        expectedNetworkNotes,
        externalRequests: external,
        authority:
          "test-only HTTP fixture; no physical phone or native simulation exercised",
        browser: await browser.version(),
      },
      null,
      2,
    ) + "\n",
  );
  process.stdout.write(`Phone browser smoke passed ${checks} checks.\n`);
} finally {
  preflight("process-control", "phone-world-browser-smoke-owned-browser-close");
  await browser.close();
  await new Promise((resolve) => server.close(resolve));
}
