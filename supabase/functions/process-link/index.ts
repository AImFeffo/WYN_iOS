// Edge Function: process-link
// URL articolo → Jina (estrazione testo) → Claude (analisi) → insert nota.

import {
  analyzeArticle,
  CORS_HEADERS,
  ERR,
  errorResponse,
  insertNote,
  jsonResponse,
  serviceClient,
  verifyUser,
} from "../_shared/wyn.ts";

const MAX_TEXT = 15_000;
const MIN_TEXT = 100;
const MAX_HINT = 150;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // 1. Verifica utente.
  const userId = await verifyUser(req);
  if (!userId) return errorResponse(ERR.unauthorized, 401);

  // 2. Body.
  let body: { url?: unknown; hint?: unknown };
  try {
    body = await req.json();
  } catch {
    return errorResponse(ERR.invalidBody, 400);
  }

  // 3. Valida URL (solo http/https).
  const rawUrl = typeof body.url === "string" ? body.url.trim() : "";
  let parsedUrl: URL;
  try {
    parsedUrl = new URL(rawUrl);
    if (parsedUrl.protocol !== "http:" && parsedUrl.protocol !== "https:") {
      throw new Error();
    }
  } catch {
    return errorResponse(ERR.invalidUrl, 400);
  }

  const hint = typeof body.hint === "string"
    ? body.hint.trim().slice(0, MAX_HINT)
    : undefined;

  try {
    // 4. Estrazione testo con Jina Reader.
    let jinaRes: Response;
    try {
      jinaRes = await fetch(`https://r.jina.ai/${parsedUrl.href}`, {
        headers: {
          Authorization: `Bearer ${Deno.env.get("JINA_API_KEY")}`,
        },
      });
    } catch {
      return errorResponse(ERR.unreachable, 502);
    }
    if (!jinaRes.ok) {
      return errorResponse(ERR.unreachable, 502);
    }

    const text = (await jinaRes.text()).slice(0, MAX_TEXT);
    if (text.trim().length < MIN_TEXT) {
      return errorResponse(ERR.tooShort, 422);
    }

    const sourceName = parsedUrl.hostname.replace(/^www\./, "");

    // 5. Analisi con Claude.
    const analysis = await analyzeArticle(text, hint);

    // 6. Insert con service-role.
    const db = serviceClient();
    const id = await insertNote(db, {
      user_id: userId,
      source_type: "article",
      url: parsedUrl.href,
      title: analysis.title,
      summary_points: analysis.summary_points,
      category: analysis.category,
      tags: analysis.tags,
      source_name: sourceName,
      read_time_label: analysis.read_time_label ?? null,
    });

    return jsonResponse({ id });
  } catch (e) {
    const message = e instanceof Error ? e.message : ERR.processing;
    return errorResponse(message, 500);
  }
});
