// Edge Function: process-screenshot
// Immagine JPEG (base64, già compressa dal device) → Claude Vision (analisi)
// → upload su bucket screenshots → insert nota.
// L'analisi avviene PRIMA dell'upload per non lasciare file orfani se l'AI fallisce.

import {
  analyzeScreenshot,
  CORS_HEADERS,
  embedNoteOrNull,
  ERR,
  errorResponse,
  insertNote,
  jsonResponse,
  serviceClient,
  verifyUser,
} from "../_shared/wyn.ts";

const MAX_HINT = 150;
const MAX_BYTES = 20 * 1024 * 1024; // 20 MB

// Decodifica base64 in bytes (per l'upload e per il controllo dimensione).
function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // 1. Verifica utente.
  const userId = await verifyUser(req);
  if (!userId) return errorResponse(ERR.unauthorized, 401);

  // 2. Body: image (base64) + hint opzionale.
  let body: { image?: unknown; hint?: unknown };
  try {
    body = await req.json();
  } catch {
    return errorResponse(ERR.invalidBody, 400);
  }

  // Accetta sia base64 puro sia data URL.
  let imageB64 = typeof body.image === "string" ? body.image : "";
  const comma = imageB64.indexOf(",");
  if (imageB64.startsWith("data:") && comma !== -1) {
    imageB64 = imageB64.slice(comma + 1);
  }
  if (!imageB64) return errorResponse(ERR.invalidBody, 400);

  // 3. Valida dimensione.
  let bytes: Uint8Array;
  try {
    bytes = base64ToBytes(imageB64);
  } catch {
    return errorResponse(ERR.invalidBody, 400);
  }
  if (bytes.byteLength > MAX_BYTES) {
    return errorResponse(ERR.imageTooLarge, 413);
  }

  const hint = typeof body.hint === "string"
    ? body.hint.trim().slice(0, MAX_HINT)
    : undefined;

  try {
    // 4. Analisi con Claude Vision PRIMA dell'upload.
    const analysis = await analyzeScreenshot(imageB64, hint);

    // 4b. Embedding per la ricerca semantica (best effort).
    const embedding = await embedNoteOrNull(analysis.title, analysis.summary_points);

    // 5. Upload su bucket screenshots: <user_id>/<uuid>.jpg
    const db = serviceClient();
    const path = `${userId}/${crypto.randomUUID()}.jpg`;
    const { error: uploadError } = await db.storage
      .from("screenshots")
      .upload(path, bytes, { contentType: "image/jpeg", upsert: false });
    if (uploadError) {
      return errorResponse(ERR.saveFailed, 500);
    }

    // 6. Insert nota.
    const id = await insertNote(db, {
      user_id: userId,
      source_type: "screenshot",
      image_paths: [path],
      title: analysis.title,
      summary_points: analysis.summary_points,
      category: analysis.category,
      tags: analysis.tags,
      embedding,
    });

    return jsonResponse({ id });
  } catch (e) {
    const message = e instanceof Error ? e.message : ERR.processing;
    return errorResponse(message, 500);
  }
});
