// Modulo condiviso tra le Edge Functions di WYN (process-link, process-screenshot).
// Contiene: modello AI, CORS, verifica utente, chiamate a Claude, parsing robusto
// della risposta JSON (§6.3), messaggi di errore in italiano e insert della nota.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Modello AI usato sia per articoli sia per Vision (come la PWA).
export const CLAUDE_MODEL = "claude-sonnet-4-6";

// Embedding per la ricerca semantica (Jina AI: stessa chiave del Reader).
export const JINA_EMBEDDING_MODEL = "jina-embeddings-v5-text-small";
export const EMBEDDING_DIM = 512;

// Le 7 categorie fisse ammesse.
export const CATEGORIES = [
  "Tech",
  "Salute",
  "Business",
  "Cucina",
  "Design",
  "Finanza",
  "Altro",
] as const;

// Messaggi di errore riusabili dall'app (in italiano).
export const ERR = {
  unauthorized: "Sessione non valida. Effettua di nuovo l'accesso.",
  invalidBody: "Richiesta non valida.",
  invalidUrl: "Inserisci un link valido (http o https).",
  unreachable: "Link non raggiungibile",
  tooShort: "Il contenuto è troppo corto",
  processing: "Non siamo riusciti a elaborare questo contenuto",
  imageTooLarge: "L'immagine è troppo grande (max 20 MB).",
  saveFailed: "Non siamo riusciti a salvare la nota.",
  searchFailed: "Non siamo riusciti a cercare per significato.",
} as const;

export const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

export function errorResponse(message: string, status: number): Response {
  return jsonResponse({ error: message }, status);
}

// Client con service-role (bypassa RLS). Usato per insert e upload lato server
// dopo aver verificato l'utente.
export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

// Client con il JWT dell'utente (header Authorization): tutte le query passano dalla RLS.
export function userClient(req: Request): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
}

// Verifica l'utente dal JWT nell'header Authorization. Ritorna l'id utente o null.
export async function verifyUser(req: Request): Promise<string | null> {
  if (!req.headers.get("Authorization")) return null;
  const { data, error } = await userClient(req).auth.getUser();
  if (error || !data.user) return null;
  return data.user.id;
}

// Risultato dell'analisi AI.
export interface AnalysisResult {
  title: string;
  summary_points: string[];
  category: string;
  tags: string[];
  read_time_label?: string;
}

// Parsing robusto della risposta di Claude (§6.3):
// JSON.parse diretto → fallback estrazione primo blocco {...} con regex →
// validazione presenza di title e summary_points → errore se mancanti.
export function parseClaudeJson(raw: string): AnalysisResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    const match = raw.match(/\{[\s\S]*\}/);
    if (!match) throw new Error(ERR.processing);
    parsed = JSON.parse(match[0]);
  }

  const obj = parsed as Record<string, unknown>;
  if (
    typeof obj.title !== "string" ||
    !Array.isArray(obj.summary_points)
  ) {
    throw new Error(ERR.processing);
  }

  const category = typeof obj.category === "string" &&
      (CATEGORIES as readonly string[]).includes(obj.category)
    ? obj.category
    : "Altro";

  return {
    title: obj.title,
    summary_points: (obj.summary_points as unknown[]).map(String),
    category,
    tags: Array.isArray(obj.tags) ? (obj.tags as unknown[]).map(String) : [],
    read_time_label: typeof obj.read_time_label === "string"
      ? obj.read_time_label
      : undefined,
  };
}

// System prompt condiviso: impone output SOLO JSON, in italiano, categorie fisse.
function systemPrompt(includeReadTime: boolean): string {
  const readTimeLine = includeReadTime
    ? `- "read_time_label": stima del tempo di lettura, es. "4 min".\n`
    : "";
  return `Sei un assistente che analizza contenuti e produce note strutturate in ITALIANO.
Rispondi ESCLUSIVAMENTE con un oggetto JSON valido, senza testo prima o dopo, senza markdown.
Lo schema è:
- "title": titolo conciso in italiano, max ~80 caratteri.
- "summary_points": array di 3-5 frasi complete in italiano, ognuna max ~120 caratteri, che catturano i concetti chiave.
- "category": ESATTAMENTE una tra: ${CATEGORIES.join(", ")}.
- "tags": array di 3-5 tag brevi, in minuscolo, in italiano.
${readTimeLine}Anche se il contenuto è in un'altra lingua, la nota deve essere in italiano.`;
}

function hintLine(hint?: string): string {
  if (!hint) return "";
  return `\n\nL'utente vuole evidenziare questo aspetto: "${hint}". Almeno uno dei punti chiave deve riguardarlo.`;
}

interface AnthropicContentBlock {
  type: string;
  text?: string;
}

async function callAnthropic(
  content: unknown,
  system: string,
): Promise<string> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      system,
      messages: [{ role: "user", content }],
    }),
  });

  if (!res.ok) {
    throw new Error(ERR.processing);
  }
  const data = await res.json();
  const blocks = (data.content ?? []) as AnthropicContentBlock[];
  const text = blocks.find((b) => b.type === "text")?.text;
  if (!text) throw new Error(ERR.processing);
  return text;
}

// Analizza un articolo (testo estratto da Jina).
export async function analyzeArticle(
  text: string,
  hint?: string,
): Promise<AnalysisResult> {
  const system = systemPrompt(true);
  const userText =
    `Analizza il seguente contenuto e produci la nota JSON.${hintLine(hint)}\n\n---\n\n${text}`;
  const raw = await callAnthropic(userText, system);
  return parseClaudeJson(raw);
}

// Analizza uno screenshot (immagine JPEG in base64) con Claude Vision.
export async function analyzeScreenshot(
  base64Jpeg: string,
  hint?: string,
): Promise<AnalysisResult> {
  const system = systemPrompt(false);
  const content = [
    {
      type: "image",
      source: { type: "base64", media_type: "image/jpeg", data: base64Jpeg },
    },
    {
      type: "text",
      text:
        `Analizza questo screenshot e produci la nota JSON.${hintLine(hint)}`,
    },
  ];
  const raw = await callAnthropic(content, system);
  return parseClaudeJson(raw);
}

// Testo embeddato per nota: titolo + punti chiave. I tag restano fuori
// (già coperti dalla ricerca testuale e modificabili dal client).
export function noteEmbeddingText(title: string, summaryPoints: string[]): string {
  return [title, ...summaryPoints]
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .join("\n");
}

// Embedding batch con Jina. kind: "document" per le note (task retrieval.passage),
// "query" per la ricerca (task retrieval.query). Vettori L2-normalizzati (default Jina).
// Ritorna un vettore per testo, nello stesso ordine.
export async function embedTexts(
  texts: string[],
  kind: "document" | "query",
): Promise<number[][]> {
  const res = await fetch("https://api.jina.ai/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("JINA_API_KEY")}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: JINA_EMBEDDING_MODEL,
      input: texts,
      task: kind === "query" ? "retrieval.query" : "retrieval.passage",
      dimensions: EMBEDDING_DIM,
    }),
  });
  if (!res.ok) throw new Error(`jina embeddings: HTTP ${res.status}`);
  const data = await res.json();
  const items = Array.isArray(data?.data) ? data.data : [];
  if (items.length !== texts.length) {
    throw new Error("jina embeddings: risposta non valida");
  }
  // Jina restituisce `index` per ogni elemento: riordina per sicurezza.
  const vectors: number[][] = new Array(texts.length);
  for (const item of items) {
    const v = item?.embedding;
    if (!Array.isArray(v) || v.length !== EMBEDDING_DIM || typeof item.index !== "number") {
      throw new Error("jina embeddings: risposta non valida");
    }
    vectors[item.index] = v as number[];
  }
  return vectors;
}

// Embedding di un singolo testo.
export async function embedText(
  text: string,
  kind: "document" | "query",
): Promise<number[]> {
  return (await embedTexts([text], kind))[0];
}

// Embedding "best effort" di una nota: null se Jina fallisce.
// La nota va salvata comunque; senza embedding non comparirà nei risultati semantici.
export async function embedNoteOrNull(
  title: string,
  summaryPoints: string[],
): Promise<number[] | null> {
  try {
    return await embedText(noteEmbeddingText(title, summaryPoints), "document");
  } catch (e) {
    console.error("embedding fallito:", e);
    return null;
  }
}

// Campi comuni della nota da inserire.
export interface NoteInsert {
  user_id: string;
  source_type: "article" | "screenshot";
  title: string;
  summary_points: string[];
  category: string;
  tags: string[];
  url?: string | null;
  image_paths?: string[] | null;
  source_name?: string | null;
  read_time_label?: string | null;
  embedding?: number[] | null;
}

// Inserisce la nota con la service-role key e ritorna l'id creato.
export async function insertNote(
  db: SupabaseClient,
  note: NoteInsert,
): Promise<string> {
  const { data, error } = await db
    .from("notes")
    .insert(note)
    .select("id")
    .single();
  if (error || !data) {
    throw new Error(ERR.saveFailed);
  }
  return data.id as string;
}
