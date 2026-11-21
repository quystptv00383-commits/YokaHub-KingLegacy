// YokaHub Private Boss API — Cloudflare Worker Template
// Requires a Cloudflare KV binding named `BOSS_KV`
// Optional Secret Env Var: `YOKA_API_KEY` (khớp với ô API Secret Key trong Tab 1 YokaHub)

const TTL_SECONDS = 90;
const KV_INDEX_KEY = "yoka_boss_index_v1";

function jsonResp(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-store",
    },
  });
}

function checkAuth(request, env) {
  if (!env.YOKA_API_KEY || env.YOKA_API_KEY.trim() === "") return true;
  const provided = request.headers.get("x-yoka-key") || "";
  return provided === env.YOKA_API_KEY.trim();
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, x-yoka-key",
        },
      });
    }

    if (!env.BOSS_KV) {
      return jsonResp({ error: "Missing KV binding BOSS_KV", entries: [] }, 500);
    }

    if (!checkAuth(request, env)) {
      return jsonResp({ error: "Unauthorized", entries: [] }, 401);
    }

    const url = new URL(request.url);
    const now = Math.floor(Date.now() / 1000);

    // GET /api/bosses -> Trả danh sách Boss còn sống để YokaHub hop thẳng JobId
    if (request.method === "GET" && (url.pathname === "/api/bosses" || url.pathname === "/")) {
      const rawMap = (await env.BOSS_KV.get(KV_INDEX_KEY, "json")) || {};
      const aliveEntries = [];
      let dirty = false;

      for (const [k, entry] of Object.entries(rawMap)) {
        if (!entry || typeof entry !== "object" || now - (entry.updatedAt || 0) > TTL_SECONDS) {
          delete rawMap[k];
          dirty = true;
        } else {
          aliveEntries.push(entry);
        }
      }

      if (dirty) {
        await env.BOSS_KV.put(KV_INDEX_KEY, JSON.stringify(rawMap));
      }

      return jsonResp({
        ok: true,
        updatedAt: now,
        count: aliveEntries.length,
        entries: aliveEntries,
      });
    }

    // POST /api/report -> Nhận báo cáo Boss sống từ client / bot quét YokaHub
    if (request.method === "POST" && url.pathname === "/api/report") {
      let body;
      try {
        body = await request.json();
      } catch {
        return jsonResp({ error: "Invalid JSON" }, 400);
      }

      const placeId = Number(body.placeId);
      const jobId = String(body.jobId || body.serverRef || "").trim();
      const eventName = String(body.eventName || "").trim();
      if (!placeId || !jobId || !eventName) {
        return jsonResp({ error: "Missing placeId, jobId or eventName" }, 400);
      }

      const key = `${placeId}:${jobId}:${eventName.toLowerCase()}`;
      const rawMap = (await env.BOSS_KV.get(KV_INDEX_KEY, "json")) || {};

      // Dọn dẹp entry quá hạn
      for (const [k, entry] of Object.entries(rawMap)) {
        if (!entry || now - (entry.updatedAt || 0) > TTL_SECONDS) {
          delete rawMap[k];
        }
      }

      rawMap[key] = {
        placeId,
        jobId,
        serverRef: jobId,
        eventName,
        source: String(body.source || "yoka_private"),
        alive: body.alive !== false,
        health: body.health || { current: 100, max: 100, percent: 100 },
        players: body.players || { current: 1, max: 12 },
        updatedAt: now,
      };

      await env.BOSS_KV.put(KV_INDEX_KEY, JSON.stringify(rawMap));
      return jsonResp({ ok: true, key, count: Object.keys(rawMap).length });
    }

    return jsonResp({ error: "Not found" }, 404);
  },
};
