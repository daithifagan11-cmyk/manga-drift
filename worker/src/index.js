const CONTENT_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
};

function getContentType(key) {
  const dotIdx = key.lastIndexOf(".");
  if (dotIdx === -1) return "application/octet-stream";
  const ext = key.slice(dotIdx).toLowerCase();
  return CONTENT_TYPES[ext] || "application/octet-stream";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Redirect /game -> /game/ so relative asset URLs resolve cleanly
    if (url.pathname === "/game") {
      return Response.redirect(`${url.origin}/game/`, 301);
    }

    if (url.pathname.startsWith("/game/")) {
      let key = url.pathname.slice(1); // e.g. "game/index.wasm"
      if (key.endsWith("/")) {
        key += "index.html";
      }

      const object = await env.GAME_BUCKET.get(key);
      if (!object) {
        return new Response("Not Found", { status: 404 });
      }

      const headers = new Headers();
      object.writeHttpMetadata(headers);
      if (!headers.has("Content-Type")) {
        headers.set("Content-Type", getContentType(key));
      }
      headers.set("ETag", object.httpEtag);
      headers.set(
        "Cache-Control",
        key.endsWith(".html") ? "public, max-age=300" : "public, max-age=86400"
      );

      return new Response(object.body, { status: 200, headers });
    }

    // Serve website/index.html and style.css via Workers Static Assets
    return env.ASSETS.fetch(request);
  },
};
