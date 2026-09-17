// Edge Function: search-notes
// { query } → backfill pigro delle note senza embedding → embedding Jina della
// query (task retrieval.query) → match_notes con il client utente (RLS)
// → { matches: [{ id, similarity }] }. Solo gli id: l'app ha già le note.

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  CORS_HEADERS,
  embedText,
  embedTexts,
  ERR,
  errorResponse,
  jsonResponse,
  noteEmbeddingText,
  userClient,
  verifyUser,
} from "../_shared/wyn.ts";

const MAX_QUERY = 200;
const MATCH_COUNT = 10;
const MIN_SIMILARITY = 0.4; // tarata sulle note demo il 2026-09-15
// Un utente con più di 50 note senza embedding le completa nel corso di più ricerche.
const BACKFILL_LIMIT = 50;

// Embedda le note dell'utente che non hanno ancora un embedding (precedenti alla
// feature, o con embedding fallito alla creazione). Una sola chiamata batch a Jina.
// Gira sotto RLS: il client utente può aggiornare solo le proprie note.
async function backfillMissingEmbeddings(db: SupabaseClient): Promise<void> {
  const { data: missing, error } = await db
    .from("notes")
    .select("id,title,summary_points")
    .is("embedding", null)
    .limit(BACKFILL_LIMIT);
  if (error || !missing || missing.length === 0) return;

  // Titolo e punti chiave entrambi vuoti → testo vuoto: Jina rifiuta l'input vuoto (422),
  // quindi va scartato prima di chiamare embedTexts per non far fallire tutto il batch.
  const targets = missing
    .map((n) => ({ id: n.id, text: noteEmbeddingText(n.title, n.summary_points) }))
    .filter((t) => t.text.length > 0);
  if (targets.length === 0) return;

  const vectors = await embedTexts(targets.map((t) => t.text), "document");
  await Promise.all(
    targets.map((t, i) =>
      db.from("notes").update({ embedding: vectors[i] }).eq("id", t.id)
    ),
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // 1. Verifica utente.
  const userId = await verifyUser(req);
  if (!userId) return errorResponse(ERR.unauthorized, 401);

  // 2. Body.
  let body: { query?: unknown };
  try {
    body = await req.json();
  } catch {
    return errorResponse(ERR.invalidBody, 400);
  }
  const query = typeof body.query === "string"
    ? body.query.trim().slice(0, MAX_QUERY)
    : "";
  if (!query) return errorResponse(ERR.invalidBody, 400);

  const db = userClient(req);

  // 3. Backfill pigro: non deve mai bloccare la ricerca.
  try {
    await backfillMissingEmbeddings(db);
  } catch (e) {
    console.error("backfill embedding:", e);
  }

  try {
    // 4. Embedding della query.
    const embedding = await embedText(query, "query");

    // 5. Similarità sotto RLS (client con il JWT dell'utente).
    const { data, error } = await db.rpc("match_notes", {
      query_embedding: embedding,
      match_count: MATCH_COUNT,
      min_similarity: MIN_SIMILARITY,
    });
    if (error) {
      console.error("match_notes:", error.message);
      return errorResponse(ERR.searchFailed, 500);
    }
    return jsonResponse({ matches: data ?? [] });
  } catch (e) {
    console.error("search-notes:", e);
    return errorResponse(ERR.searchFailed, 500);
  }
});
