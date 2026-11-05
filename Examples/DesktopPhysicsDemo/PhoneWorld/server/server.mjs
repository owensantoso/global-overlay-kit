import http from "node:http";
import { readFile } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { PhoneRelay, RelayError } from "./relay.mjs";

export function createServer(config) {
  const relay = new PhoneRelay({
    secret: config.nativeSecret,
    publicURL: config.publicURL,
  });
  const root = resolve(
    config.staticRoot ?? fileURLToPath(new URL("../dist/", import.meta.url)),
  );
  const mime = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript",
    ".css": "text/css",
    ".png": "image/png",
    ".json": "application/json",
    ".svg": "image/svg+xml",
  };
  const server = http.createServer(async (req, res) => {
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Referrer-Policy", "no-referrer");
    res.setHeader("Cache-Control", "no-store");
    res.setHeader(
      "Content-Security-Policy",
      "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
    );
    res.setHeader(
      "Permissions-Policy",
      "camera=(), microphone=(), geolocation=()",
    );
    const send = (status, data) => {
      res.writeHead(status, { "Content-Type": "application/json" });
      res.end(JSON.stringify(data));
    };
    try {
      const path = new URL(req.url, "http://localhost").pathname;
      if (path === "/phone-world/health" && req.method === "GET")
        return send(200, {
          service: "desktop-phone-world",
          nativeOnline: relay.nativeOnline,
          phoneOnline: relay.phoneOnline,
        });
      if (path === "/phone-world/api/native-status" && req.method === "GET") {
        const auth = String(req.headers.authorization ?? "").replace(
          /^Bearer /,
          "",
        );
        if (!relay.equal(auth, config.nativeSecret))
          return send(401, { error: "Native authorization required" });
        return send(200, {
          ...relay.nativeReply(),
          snapshot: relay.nativeOnline ? relay.snapshot : null,
        });
      }
      if (path.startsWith("/phone-world/api/")) {
        if (req.method !== "POST") return send(405, { error: "POST required" });
        // No cross-origin browser reads or writes, even from another tailnet application.
        if (
          req.headers.origin &&
          req.headers.origin !== new URL(config.publicURL).origin &&
          req.headers.origin !== `http://127.0.0.1:${config.port}`
        )
          return send(403, { error: "Origin rejected" });
        if (!String(req.headers["content-type"]).startsWith("application/json"))
          return send(415, { error: "JSON required" });
        let body = "";
        for await (const part of req) {
          body += part;
          if (Buffer.byteLength(body) > 65536)
            throw new RelayError(413, "Request too large");
        }
        let data;
        try {
          data = JSON.parse(body);
        } catch {
          throw new RelayError(400, "Invalid JSON");
        }
        const auth = String(req.headers.authorization ?? "").replace(
          /^Bearer /,
          "",
        );
        if (path === "/phone-world/api/native")
          return send(200, relay.native(auth, data));
        if (path === "/phone-world/api/phone")
          return send(200, relay.phone(auth, data));
        return send(404, { error: "Unknown action" });
      }
      if (req.method !== "GET" && req.method !== "HEAD")
        return send(405, { error: "GET required" });
      if (path === "/phone-world") {
        res.writeHead(308, { Location: "/phone-world/" });
        return res.end();
      }
      if (!path.startsWith("/phone-world/"))
        return send(404, { error: "Not found" });
      const relative =
        decodeURIComponent(path.slice("/phone-world/".length)) || "index.html";
      const file = resolve(root, relative);
      if (!file.startsWith(root + sep))
        return send(403, { error: "Invalid path" });
      let bytes;
      try {
        bytes = await readFile(file);
      } catch {
        return send(404, { error: "Not found" });
      }
      res.writeHead(200, {
        "Content-Type": mime[extname(file)] ?? "application/octet-stream",
      });
      res.end(req.method === "HEAD" ? undefined : bytes);
    } catch (error) {
      send(error instanceof RelayError ? error.status : 400, {
        error: error instanceof RelayError ? error.message : "Invalid request",
      });
    }
  });
  return { server, relay };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const config = JSON.parse(await readFile(process.argv[2], "utf8"));
  const { server } = createServer(config);
  server.listen(config.port, "127.0.0.1", () =>
    console.log(
      `Desktop Phone World listening on loopback port ${config.port}`,
    ),
  );
}
