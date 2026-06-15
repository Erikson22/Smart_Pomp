"use strict";

/**
 * Smart Pump – Relay HTTP standalone (Render.com / Fly.io / Railway)
 *
 * Reçoit les requêtes du SIM808 et les retransmet vers Firebase RTDB via REST API.
 * Zéro dépendance externe – uniquement Node.js built-ins.
 *
 * POST /relay   Body: { "path": "/pompe/mesures", "data": { ... } }
 *               → PUT https://FIREBASE_HOST/path.json?auth=SECRET  → 200 OK
 *
 * GET  /relay   ?path=/pompe/commande
 *               → GET https://FIREBASE_HOST/path.json?auth=SECRET  → 200 + JSON
 */

const http  = require("http");
const https = require("https");
const url   = require("url");

const FIREBASE_HOST   = process.env.FIREBASE_HOST   || "smartpumpmonitor-default-rtdb.europe-west1.firebasedatabase.app";
const FIREBASE_SECRET = process.env.FIREBASE_SECRET || "";
const PORT            = parseInt(process.env.PORT)  || 8080;

// ── Utilitaire : lire le body JSON d'une requête ─────────────────────────────
function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", chunk => { raw += chunk; });
    req.on("end",  () => {
      try { resolve(JSON.parse(raw)); }
      catch (e) { resolve({}); }
    });
    req.on("error", reject);
  });
}

// ── Utilitaire : requête HTTPS vers Firebase REST API ────────────────────────
function firebaseReq(method, fbPath, body) {
  return new Promise((resolve, reject) => {
    if (!fbPath.endsWith(".json")) fbPath += ".json";
    const authSuffix = FIREBASE_SECRET ? `?auth=${FIREBASE_SECRET}` : "";
    const payload    = body !== null ? JSON.stringify(body) : null;

    const opts = {
      hostname : FIREBASE_HOST,
      port     : 443,
      path     : fbPath + authSuffix,
      method,
      headers  : { "Content-Type": "application/json" }
    };
    if (payload) opts.headers["Content-Length"] = Buffer.byteLength(payload);

    const req = https.request(opts, res => {
      let data = "";
      res.on("data", c => { data += c; });
      res.on("end",  () => resolve({ status: res.statusCode, body: data }));
    });
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

// ── Serveur HTTP ─────────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const parsed = url.parse(req.url, true);

  // CORS (accès Flutter web si besoin)
  res.setHeader("Access-Control-Allow-Origin",  "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  try {
    // ── Health check ───────────────────────────────────────────────────────
    if (req.method === "GET" && parsed.pathname === "/") {
      res.writeHead(200, { "Content-Type": "text/plain" });
      return res.end("Smart Pump Relay OK");
    }

    // ── POST /relay  →  écriture Firebase ─────────────────────────────────
    if (req.method === "POST" && parsed.pathname === "/relay") {
      const { path, data } = await readBody(req);

      if (!path || data === undefined) {
        res.writeHead(400);
        return res.end(JSON.stringify({ error: "'path' et 'data' requis" }));
      }

      console.log(`[relay] PUT ${path}`);
      const result = await firebaseReq("PUT", path, data);

      if (result.status === 200 || result.status === 204) {
        res.writeHead(200);
        return res.end("OK");
      }
      console.error(`[relay] Firebase ${result.status}: ${result.body}`);
      res.writeHead(500);
      return res.end(`Firebase error ${result.status}`);
    }

    // ── GET /relay?path=...  →  lecture Firebase ───────────────────────────
    if (req.method === "GET" && parsed.pathname === "/relay") {
      const fbPath = parsed.query.path;

      if (!fbPath) {
        res.writeHead(400);
        return res.end(JSON.stringify({ error: "Query param 'path' requis" }));
      }

      console.log(`[relay] GET ${fbPath}`);
      const result = await firebaseReq("GET", fbPath, null);

      res.writeHead(200, { "Content-Type": "application/json" });
      return res.end(result.body);
    }

    // ── 404 ────────────────────────────────────────────────────────────────
    res.writeHead(404);
    res.end("Not found");

  } catch (err) {
    console.error("[relay] Erreur:", err.message);
    res.writeHead(500);
    res.end(JSON.stringify({ error: err.message }));
  }
});

server.listen(PORT, () => {
  console.log(`[relay] En écoute sur port ${PORT}`);
  console.log(`[relay] Firebase host: ${FIREBASE_HOST}`);
  console.log(`[relay] Auth: ${FIREBASE_SECRET ? "Database Secret configuré" : "⚠️  FIREBASE_SECRET vide"}`);
});
