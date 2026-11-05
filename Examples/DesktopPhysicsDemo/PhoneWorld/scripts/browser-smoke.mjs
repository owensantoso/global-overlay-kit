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
const clients = new Map();
let placed = true;
let mainClientID = null;
let nativeOnline = true;
let responseStatus = 200;
let responseDelay = 0;
let playerX = 1590;
let rotation = 0;
let asymmetric = false;

preflight("network", "phone-world-browser-smoke-loopback");
const server = createServer(async (req, res) => {
  try {
    if (req.url === "/phone-world/api/phone") {
      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      const body = JSON.parse(Buffer.concat(chunks).toString());
      requests.push(body);
      if (!clients.has(body.clientID))
        clients.set(body.clientID, {
          id: `screen-${clients.size + 1}`,
          label: `Phone ${clients.size + 1}`,
          index: clients.size,
        });
      const own = clients.get(body.clientID);
      const regionX = 1512 + own.index * 400;
      const regionWidth =
        rotation === 90
          ? (400 * body.viewport.height) / body.viewport.width
          : 400;
      const regionHeight =
        rotation === 90
          ? 400
          : (400 * body.viewport.height) / body.viewport.width;
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
                  x: asymmetric ? regionX + regionWidth * 0.25 : playerX,
                  y: asymmetric
                    ? regionHeight * 0.3
                    : Math.max(70, regionHeight / 2),
                  vx: 0,
                  vy: 0,
                  width: asymmetric ? 20 : 34,
                  height: asymmetric ? 60 : 86,
                  facing: "right",
                  animation: "idle",
                  asset: asymmetric ? null : "fighter_Idle_0001.png",
                  spriteWidth: asymmetric ? 20 : 270,
                  spriteHeight: asymmetric ? 60 : 270,
                  spriteOffsetY: asymmetric ? 0 : 22,
                },
                platforms: asymmetric
                  ? [
                      {
                        x: regionX + regionWidth * 0.6,
                        y: regionHeight * 0.8,
                        width: regionWidth * 0.25,
                      },
                    ]
                  : [{ x: 1512, y: 30, width: 400 }],
              }
            : null,
          phone: { id: own.id, label: own.label },
          region: placed
            ? {
                x: regionX,
                y: 0,
                width: regionWidth,
                height: regionHeight,
                rotation,
              }
            : null,
          seams: placed
            ? [
                {
                  x1: regionX,
                  y1: 0,
                  x2: regionX,
                  y2: regionHeight,
                  neighborID: own.index === 0 ? "mac" : "screen-1",
                  label: own.index === 0 ? "To Mac" : "To Phone 1",
                },
                ...(own.index === 0
                  ? [
                      {
                        x1: regionX + regionWidth,
                        y1: 0,
                        x2: regionX + regionWidth,
                        y2: regionHeight,
                        neighborID: "screen-2",
                        label: "To Phone 2",
                      },
                    ]
                  : []),
              ]
            : [],
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
const lastFor = (clientID) =>
  requests.findLast((request) => request.clientID === clientID);
const last = () => (mainClientID ? lastFor(mainClientID) : requests.at(-1));
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
      /status of (401|409|410)/.test(message.text())
    ) {
      expectedNetworkNotes.push(message.text());
    } else errors.push(message.text());
  });
  page.on("request", (request) => {
    if (!request.url().startsWith(origin)) external.push(request.url());
  });
  await page.goto(`${origin}/phone-world/#token=${token}`);
  await page.locator('main[data-connection="online"]').waitFor();
  mainClientID = await page.evaluate(() =>
    sessionStorage.getItem("phone-world.clientID"),
  );
  check(
    (await page.getByRole("heading", { name: "Phone 1" }).count()) === 1,
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
  const secondContext = await browser.newContext({
    viewport: { width: 844, height: 390 },
    hasTouch: true,
  });
  const second = await secondContext.newPage();
  second.on("pageerror", (error) => errors.push(error.message));
  await second.goto(`${origin}/phone-world/#token=${token}`);
  await second.getByRole("heading", { name: "Phone 2", exact: true }).waitFor();
  const secondClientID = await second.evaluate(() =>
    sessionStorage.getItem("phone-world.clientID"),
  );
  check(
    secondClientID !== mainClientID,
    "same QR creates separate stable phone identities",
  );
  await wait(
    () =>
      lastFor(secondClientID)?.viewport.width === 844 &&
      last()?.viewport.width === 390,
  );
  check(true, "simultaneous phone viewports remain independent");
  await second
    .getByRole("button", { name: "Right", exact: true })
    .dispatchEvent("pointerdown", {
      pointerId: 31,
      pointerType: "touch",
      button: 0,
    });
  await wait(() => lastFor(secondClientID)?.input.right);
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
  check(
    lastFor(secondClientID)?.input.right,
    "hiding one phone does not release the other phone",
  );
  await second
    .getByRole("button", { name: "Right", exact: true })
    .dispatchEvent("pointercancel", { pointerId: 31, pointerType: "touch" });
  await secondContext.close();
  await page.reload();
  await page.getByRole("heading", { name: "Phone 1", exact: true }).waitFor();
  check(
    (await page.evaluate(() =>
      sessionStorage.getItem("phone-world.clientID"),
    )) === mainClientID,
    "reload keeps stable screen identity",
  );
  placed = false;
  await page
    .getByText("Connect this screen in the Mac layout.", { exact: true })
    .waitFor();
  check(
    await left.isDisabled(),
    "inactive screen explains placement and disables input",
  );
  placed = true;
  await wait(() => last()?.input.left === false);
  await page
    .getByText("Connect this screen in the Mac layout.", { exact: true })
    .waitFor({ state: "hidden" });
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
  await page.setViewportSize({ width: 390, height: 844 });
  asymmetric = true;
  rotation = 90;
  await page.getByText(/Rotated view/).waitFor();
  await page.waitForTimeout(100);
  const rotationPixels = async (turned) =>
    page.locator("canvas").evaluate((canvas, turned) => {
      const context = canvas.getContext("2d");
      const width = canvas.width,
        height = canvas.height;
      const pixels = context.getImageData(0, 0, width, height).data;
      const cx = width * (turned ? 0.3 : 0.25),
        cy = height * (turned ? 0.25 : 0.7);
      let minX = width,
        minY = height,
        maxX = -1,
        maxY = -1;
      const dark = (x, y) => {
        const i = (Math.floor(y) * width + Math.floor(x)) * 4;
        return (
          pixels[i + 3] > 0 &&
          pixels[i] < 60 &&
          pixels[i + 1] < 70 &&
          pixels[i + 2] < 80
        );
      };
      for (
        let y = Math.max(0, Math.floor(cy - height * 0.25));
        y < Math.min(height, cy + height * 0.25);
        y++
      ) {
        for (
          let x = Math.max(0, Math.floor(cx - width * 0.17));
          x < Math.min(width, cx + width * 0.17);
          x++
        ) {
          if (dark(x, y)) {
            minX = Math.min(minX, x);
            maxX = Math.max(maxX, x);
            minY = Math.min(minY, y);
            maxY = Math.max(maxY, y);
          }
        }
      }
      const platform = turned
        ? dark(width * 0.8, height * 0.7)
        : dark(width * 0.7, height * 0.2);
      const sampleX = turned ? width * 0.5 : 1,
        sampleY = turned ? 1 : height * 0.5;
      const i = (Math.floor(sampleY) * width + Math.floor(sampleX)) * 4;
      return {
        box: {
          width: maxX - minX + 1,
          height: maxY - minY + 1,
          cx: (minX + maxX) / 2,
          cy: (minY + maxY) / 2,
        },
        expected: { cx, cy },
        platform,
        seam:
          pixels[i + 3] > 0 &&
          pixels[i] < 30 &&
          pixels[i + 1] > 100 &&
          pixels[i + 2] > 130,
      };
    }, turned);
  let pixels = await rotationPixels(true);
  check(
    Math.abs(pixels.box.cx - pixels.expected.cx) < 3 &&
      Math.abs(pixels.box.cy - pixels.expected.cy) < 3,
    "clockwise quarter-turn places asymmetric character at expected physical coordinates",
  );
  check(
    pixels.box.width / pixels.box.height > 2.6 &&
      pixels.box.width / pixels.box.height < 3.5,
    "rotated character keeps proportions and turns its long axis",
  );
  check(
    pixels.platform && pixels.seam,
    "platform and To Mac seam rotate together with the world",
  );
  check(
    last().viewport.width === 390 && last().viewport.height > 400,
    "rotated projection still reports physical canvas dimensions",
  );
  await left.dispatchEvent("pointerdown", {
    pointerId: 51,
    pointerType: "touch",
    button: 0,
  });
  await wait(() => last()?.input.left && !last()?.input.right);
  await left.dispatchEvent("pointerup", {
    pointerId: 51,
    pointerType: "touch",
  });
  check(true, "unrotated Left control retains world-left meaning");
  await page.screenshot({
    path: resolve(root, "evidence/phone-rotated-portrait.png"),
  });
  await page.setViewportSize({ width: 844, height: 390 });
  await wait(() => last()?.viewport.width === 844);
  await page.waitForTimeout(100);
  pixels = await rotationPixels(true);
  check(
    pixels.box.width / pixels.box.height > 2.6 &&
      pixels.box.width / pixels.box.height < 3.5 &&
      pixels.platform,
    "rotated landscape device preserves world geometry",
  );
  await page.screenshot({
    path: resolve(root, "evidence/phone-rotated-landscape.png"),
  });
  rotation = 0;
  await page.getByText(/Rotated view/).waitFor({ state: "hidden" });
  await page.waitForTimeout(100);
  pixels = await rotationPixels(false);
  check(
    pixels.box.height / pixels.box.width > 2.6 &&
      pixels.box.height / pixels.box.width < 3.5 &&
      pixels.platform &&
      pixels.seam,
    "turning back restores upright character, platform and seams",
  );
  asymmetric = false;
  nativeOnline = false;
  await page.locator('main[data-connection="connecting"]').waitFor();
  check(
    await left.isDisabled(),
    "stale native disables controls and removes character state",
  );
  nativeOnline = true;
  await page.locator('main[data-connection="online"]').waitFor();
  responseStatus = 409;
  await page.getByText("Session is full", { exact: true }).waitFor();
  check(
    await page.getByRole("button", { name: "Retry connection" }).isVisible(),
    "occupied pairing is recoverable",
  );
  responseStatus = 200;
  await page.getByRole("button", { name: "Retry connection" }).click();
  await page.locator('main[data-connection="online"]').waitFor();
  responseStatus = 410;
  await page.locator('main[data-connection="removed"]').waitFor();
  check(
    await page
      .getByText("This phone was removed. Scan the QR code to join again.", {
        exact: true,
      })
      .isVisible(),
    "removed phone shows explicit scan-to-rejoin path",
  );
  const beforeReload = requests.length;
  await page.reload();
  await page.locator('main[data-connection="removed"]').waitFor();
  await page.waitForTimeout(200);
  check(
    requests.length === beforeReload,
    "removed URL does not silently refill a screen slot on reload",
  );
  responseStatus = 200;
  const removedClientID = mainClientID;
  await page.goto(`${origin}/phone-world/#token=${token}`);
  await page.locator('main[data-connection="online"]').waitFor();
  mainClientID = await page.evaluate(() =>
    sessionStorage.getItem("phone-world.clientID"),
  );
  check(
    mainClientID !== removedClientID,
    "explicit QR scan creates a fresh identity after removal",
  );
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
