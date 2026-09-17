# WYN iOS — Piano ricerca per significato (semantica)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La schermata Cerca trova le note anche per significato («come risparmiare» → nota su TER e commissioni), non solo per parola esatta o tag, senza cambiare il resto dell'app.

**Architecture:** Ricerca ibrida. Il filtro testuale client-side resta identico; in parallelo l'app chiama una nuova Edge Function `search-notes` che calcola l'embedding della query (Jina AI, `jina-embeddings-v5-text-small`, 512 dimensioni, stessa chiave già usata per il Reader) e interroga Postgres con `pgvector` tramite la funzione SQL `match_notes` (eseguita con i permessi dell'utente, quindi sotto RLS). L'embedding di ogni nota viene calcolato alla creazione dentro `process-link` / `process-screenshot` e salvato nella nuova colonna `notes.embedding`. La lista risultati mostra prima i match testuali (card invariate), poi quelli per significato con etichetta «Corrisponde per significato».

**Tech Stack:** Supabase (Postgres 17 + `vector` 0.8.0 già installato, Edge Functions Deno, supabase-js 2), Jina AI Embeddings REST (`https://api.jina.ai/v1/embeddings`, stessa `JINA_API_KEY` del Reader), SwiftUI + supabase-swift (`client.functions.invoke`). Nessuna nuova dipendenza SPM.

**Spec:** design approvato in chat il 2026-09-15 (riassunto in §0). Spec funzionale di riferimento: `features.md` §5.3 (da aggiornare nel Task 7).

---

## §0 — Decisioni di design (approvate)

- **Dove:** backend Supabase (pgvector + embedding). Scartati: solo on-device (NLEmbedding) e Claude a ogni ricerca.
- **Provider embedding:** Jina AI, modello `jina-embeddings-v5-text-small` (multilingue, 119+ lingue incluso l'italiano, Matryoshka), `dimensions: 512`, `task` `retrieval.passage` per le note e `retrieval.query` per la ricerca. Scelto al posto di Voyage (consigliato da Anthropic, che non offre embedding propri) perché la chiave `JINA_API_KEY` è **già nei secret** delle Edge Functions per il Reader: una sola API a pagamento. Risposta in formato OpenAI-compatibile (`data[].embedding`).
- **Testo embeddato:** solo `title` + `summary_points`. I **tag restano fuori**: già coperti dalla ricerca testuale e modificabili dal client, così non serve ricalcolare l'embedding quando cambiano.
- **Creazione nota:** l'embedding è *best effort*. Se Jina fallisce la nota viene salvata con `embedding = null` e non compare nei risultati semantici. Mai bloccare il salvataggio.
- **Risultati:** lista unica ibrida. Prima i match testuali (ordine e card attuali), poi le note per significato non già presenti, in ordine di somiglianza. Top 10, soglia minima di similarità iniziale 0.4 (da tarare nel Task 6).
- **Fallback:** se `search-notes` fallisce o manca la rete, la lista mostra solo i risultati testuali e l'etichetta a destra dice «Solo corrispondenza testuale». Nessun errore bloccante.
- **Backfill:** *pigro*, dentro `search-notes`. Prima di cercare, le note dell'utente senza embedding (precedenti alla feature, o con embedding fallito alla creazione) vengono embeddate in un'unica chiamata batch a Jina e aggiornate sotto RLS. Copre tutti gli utenti (27 note di 4 utenti al 2026-09-15) senza service-role key né chiavi locali. Il Task 4 originale (script locale) è **sostituito** da questo (ruling del 2026-09-15).
- **Indice vettoriale:** nessuno per ora (poche centinaia di note per utente al massimo). Da aggiungere HNSW solo se la latenza di `match_notes` supera i 100 ms.

---

## Global Constraints (validi per ogni task)

- **Nessuna chiave segreta nel bundle iOS.** `JINA_API_KEY` (già presente) vive solo nei secret delle Edge Functions; **nessun secret nuovo**. Nessuna chiave locale: anche il backfill gira nelle Edge Functions.
- **Deploy e migrazione** li esegue chi implementa (norma già stabilita nel progetto: la CLI Supabase è loggata, i secret li gestisce l'utente). Migrazione additiva e reversibile.
- **Comportamenti invariati** (`features.md` §5): debounce 400 ms + autofocus, filtro testuale su title / sourceName / tags / summaryPoints con la stessa precedenza, navigazione al dettaglio, tutto il resto dell'app. Share Extension, `ProcessingService`, `FeedStore`, `Note`, `AuthViewModel` **non si toccano**.
- **Testi UI in italiano**, riportati verbatim nei task.
- **Nessuna nuova dipendenza SPM.** Unica dipendenza: `supabase-swift`.
- **Nessun test target iOS nel progetto** (verificato): la verifica iOS è build verde 0 warning + screenshot + smoke test sul simulatore. Lato Deno si aggiunge un test unitario con `deno test` per gli helper puri.
- **Un commit per task**, messaggio `db: …` / `functions: …` / `ui: cerca — …` / `docs: …`. Ogni commit termina con:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01VfBvnkjLi9auakf6Da1CZf
  ```
- Dopo ogni task che tocca codice: `graphify update .`

### Comandi di verifica riusati dai task

```bash
# Build iOS (0 warning attesi)
xcodebuild -project WYN.xcodeproj -scheme WYN -derivedDataPath build/DerivedData \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 \
  | grep -E "warning:|error:|BUILD (SUCCEEDED|FAILED)"

# Avvio con auto-login demo (hook #if DEBUG già presente in WYNApp.swift)
xcrun simctl launch booted com.feffo.wyn -uitest-login

# Screenshot
xcrun simctl io booted screenshot tasks/ui-screens/<nome>.png
```

Tap e digitazione sul simulatore: binario `axe` bundlato in XcodeBuildMCP (`~/.npm/_npx/99336612077b7094/node_modules/xcodebuildmcp/bundled/axe`, comandi `describe-ui`, `tap -x -y`, `type`). Coordinate in punti, 402×874 su iPhone 17 Pro.

Token dell'account demo per le chiamate `curl` alle Edge Functions (password: quella dell'account demo `feffo-demo@wyn.app`, nota in memoria di sessione `wyn-sim-ui-automation`, mai scriverla nel repo):

```bash
export SB_URL="https://odplsmpadzhyhkdoqrne.supabase.co"
export ANON="$(grep -o 'eyJ[^"]*' WYN/Services/SupabaseConfig.swift | head -1)"
export TOKEN="$(curl -s "$SB_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "content-type: application/json" \
  -d '{"email":"feffo-demo@wyn.app","password":"<password demo>"}' | jq -r .access_token)"
```

---

## §1 — Stato di partenza (verificato il 2026-09-15)

- Progetto Supabase `odplsmpadzhyhkdoqrne`: tabella `public.notes` (13 colonne, RLS attiva, 7 righe), estensione `vector` 0.8.0 **già installata** nello schema `extensions`. Nessuna cartella `supabase/migrations`, nessuno script.
- Edge Functions deployate: `process-link`, `process-screenshot` (v1). Entrambe con `verify_jwt = false` in `supabase/config.toml` (la verifica la fa `verifyUser`).
- `WYN/Features/Search/SearchView.swift`: filtro client-side su `store.notes`, `SearchMatch` (title/source/tag/keyPoint), `ResultCard(note:term:)`, empty state con testo «La ricerca confronta il testo, non il significato».
- `WYN/Services/NotesService.swift`: `fetchNotes()` e `fetchNote(id:)` usano `.select()` (= tutte le colonne).
- `supabase/functions/_shared/wyn.ts`: `verifyUser`, `serviceClient`, `analyzeArticle`, `analyzeScreenshot`, `insertNote(db, NoteInsert)`, `ERR`.

---

## §2 — File toccati

| File | Azione | Responsabilità |
|---|---|---|
| `supabase/migrations/20260915120000_notes_embedding.sql` | crea | colonna `embedding`, funzione `match_notes` |
| `supabase/functions/_shared/wyn.ts` | modifica | `embedTexts` / `embedText` (Jina), `noteEmbeddingText`, `embedNoteOrNull`, `userClient`, `ERR.searchFailed`, `NoteInsert.embedding` |
| `supabase/functions/_shared/wyn_test.ts` | crea | test `deno test` di `noteEmbeddingText` |
| `supabase/functions/process-link/index.ts` | modifica | calcola l'embedding prima dell'insert |
| `supabase/functions/process-screenshot/index.ts` | modifica | idem |
| `supabase/functions/search-notes/index.ts` | crea | backfill pigro → query → embedding → `match_notes` → `{ matches }` |
| `supabase/config.toml` | modifica | `[functions.search-notes] verify_jwt = false` |
| `WYN/Services/NotesService.swift` | modifica | colonne esplicite (senza `embedding`), `semanticMatches(query:)` |
| `WYN/Features/Search/SearchView.swift` | modifica | ricerca ibrida, stati, copy, `SearchMatch.semantic`, `ResultCard(match:)` |
| `features.md`, `tasks/todo.md` | modifica | documentazione |

---

### Task 1: Migrazione DB — colonna `embedding` e funzione `match_notes`

**Files:**
- Create: `supabase/migrations/20260915120000_notes_embedding.sql`

**Interfaces:**
- Produces: colonna `public.notes.embedding extensions.vector(512)` nullable; funzione `public.match_notes(query_embedding vector(512), match_count int default 10, min_similarity float default 0.4) returns table (id uuid, similarity float)`, `security invoker`, filtra `user_id = auth.uid()` e `embedding is not null`.

- [ ] **Step 1: Scrivere la migrazione**

```sql
-- Ricerca semantica: embedding per nota + funzione di similarità (coseno).
-- L'estensione vector è già installata nello schema extensions.
create extension if not exists vector with schema extensions;

alter table public.notes
  add column if not exists embedding extensions.vector(512);

-- Note dell'utente corrente ordinate per similarità coseno decrescente.
-- security invoker: gira con i permessi del chiamante, quindi sotto RLS.
create or replace function public.match_notes(
  query_embedding extensions.vector(512),
  match_count int default 10,
  min_similarity float default 0.4
)
returns table (id uuid, similarity float)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  select n.id,
         1 - (n.embedding <=> query_embedding) as similarity
  from public.notes n
  where n.user_id = auth.uid()
    and n.embedding is not null
    and 1 - (n.embedding <=> query_embedding) >= min_similarity
  order by n.embedding <=> query_embedding
  limit match_count;
$$;
```

- [ ] **Step 2: STOP — chiedere conferma all'utente prima di applicarla al progetto remoto**

- [ ] **Step 3: Applicare la migrazione**

Con il Supabase MCP: `apply_migration` (project `odplsmpadzhyhkdoqrne`, name `notes_embedding`, query = contenuto del file). Equivalente CLI (chiede la password del DB): `supabase db push`.

- [ ] **Step 4: Verificare**

Con `execute_sql`:
```sql
select column_name, udt_name from information_schema.columns
 where table_name = 'notes' and column_name = 'embedding';
select proname, prosecdef from pg_proc where proname = 'match_notes';
```
Atteso: una riga `embedding | vector`; `match_notes | false` (false = security invoker).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260915120000_notes_embedding.sql
git commit -m "db: colonna notes.embedding (vector 512) e funzione match_notes"
```

---

### Task 2: Helper embedding in `_shared/wyn.ts` + calcolo alla creazione nota

**Files:**
- Modify: `supabase/functions/_shared/wyn.ts`
- Create: `supabase/functions/_shared/wyn_test.ts`
- Modify: `supabase/functions/process-link/index.ts` (blocco «5. Analisi con Claude» / «6. Insert»)
- Modify: `supabase/functions/process-screenshot/index.ts` (blocco «4. Analisi» / «6. Insert nota»)

**Interfaces:**
- Produces (in `wyn.ts`):
  - `export const JINA_EMBEDDING_MODEL = "jina-embeddings-v5-text-small"`, `export const EMBEDDING_DIM = 512`
  - `export function noteEmbeddingText(title: string, summaryPoints: string[]): string`
  - `export async function embedTexts(texts: string[], kind: "document" | "query"): Promise<number[][]>` (una chiamata batch; lancia `Error` se Jina fallisce o restituisce un numero diverso di vettori)
  - `export async function embedText(text: string, kind: "document" | "query"): Promise<number[]>` (wrapper su `embedTexts` per un singolo testo)
  - `export async function embedNoteOrNull(title: string, summaryPoints: string[]): Promise<number[] | null>`
  - `export function userClient(req: Request): SupabaseClient` (client con il JWT dell'utente, usato anche da `verifyUser`)
  - `ERR.searchFailed = "Non siamo riusciti a cercare per significato."`
  - `NoteInsert.embedding?: number[] | null`

- [ ] **Step 1: Scrivere il test fallente**

`supabase/functions/_shared/wyn_test.ts`:
```ts
import { assertEquals } from "jsr:@std/assert@1";
import { noteEmbeddingText } from "./wyn.ts";

Deno.test("noteEmbeddingText concatena titolo e punti chiave, scarta i vuoti", () => {
  assertEquals(
    noteEmbeddingText(" Titolo ", ["primo", "  ", "secondo "]),
    "Titolo\nprimo\nsecondo",
  );
});

Deno.test("noteEmbeddingText con soli punti chiave", () => {
  assertEquals(noteEmbeddingText("", ["a"]), "a");
});
```

- [ ] **Step 2: Eseguirlo e vederlo fallire**

```bash
which deno || brew install deno
deno test supabase/functions/_shared/wyn_test.ts
```
Atteso: FAIL, `noteEmbeddingText` non esportata.

- [ ] **Step 3: Aggiungere gli helper a `wyn.ts`**

Dopo `CLAUDE_MODEL`:
```ts
// Embedding per la ricerca semantica (Jina AI: stessa chiave del Reader).
export const JINA_EMBEDDING_MODEL = "jina-embeddings-v5-text-small";
export const EMBEDDING_DIM = 512;
```

In `ERR` aggiungere:
```ts
  searchFailed: "Non siamo riusciti a cercare per significato.",
```

Sostituire `verifyUser` con `userClient` + `verifyUser`:
```ts
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
```

Prima di `NoteInsert`:
```ts
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
```

In `NoteInsert` aggiungere:
```ts
  embedding?: number[] | null;
```

- [ ] **Step 4: Eseguire il test**

```bash
deno test supabase/functions/_shared/wyn_test.ts
```
Atteso: 2 passed.

- [ ] **Step 5: Calcolare l'embedding in `process-link`**

Importare `embedNoteOrNull` e, tra il punto 5 e il punto 6:
```ts
    // 5. Analisi con Claude.
    const analysis = await analyzeArticle(text, hint);

    // 5b. Embedding per la ricerca semantica (best effort).
    const embedding = await embedNoteOrNull(analysis.title, analysis.summary_points);

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
      embedding,
    });
```

- [ ] **Step 6: Lo stesso in `process-screenshot`**

Importare `embedNoteOrNull`; dopo `const analysis = await analyzeScreenshot(imageB64, hint);` e prima dell'upload:
```ts
    // 4b. Embedding per la ricerca semantica (best effort).
    const embedding = await embedNoteOrNull(analysis.title, analysis.summary_points);
```
e nell'insert aggiungere `embedding,` dopo `tags: analysis.tags,`.

- [ ] **Step 7: Type-check**

```bash
deno check supabase/functions/process-link/index.ts supabase/functions/process-screenshot/index.ts
```
Atteso: nessun errore.

- [ ] **Step 8: STOP — chiedere conferma del deploy**

Nessun secret nuovo: `JINA_API_KEY` è già impostata per `process-link` (verificare con `supabase secrets list`). Con la conferma dell'utente:
```bash
supabase functions deploy process-link
supabase functions deploy process-screenshot
```

- [ ] **Step 9: Smoke test — creare una nota e verificare l'embedding**

```bash
curl -s "$SB_URL/functions/v1/process-link" \
  -H "Authorization: Bearer $TOKEN" -H "apikey: $ANON" -H "content-type: application/json" \
  -d '{"url":"https://www.lennysnewsletter.com/p/how-to-price-your-product"}'
```
Atteso: `{"id":"…"}`. Poi con `execute_sql`:
```sql
select id, title, embedding is not null as has_embedding from public.notes
 order by created_at desc limit 1;
```
Atteso: `has_embedding = true`.

- [ ] **Step 10: Commit**

```bash
git add supabase/functions/_shared/wyn.ts supabase/functions/_shared/wyn_test.ts \
        supabase/functions/process-link/index.ts supabase/functions/process-screenshot/index.ts
git commit -m "functions: embedding Jina alla creazione della nota (best effort)"
```

---

### Task 3: Edge Function `search-notes`

**Files:**
- Create: `supabase/functions/search-notes/index.ts`
- Modify: `supabase/config.toml`

**Interfaces:**
- Consumes: `embedText`, `embedTexts`, `noteEmbeddingText`, `userClient`, `verifyUser`, `ERR`, `CORS_HEADERS`, `jsonResponse`, `errorResponse` da `wyn.ts`; funzione SQL `match_notes` (Task 1).
- Produces: `POST /functions/v1/search-notes` con body `{ "query": string }` → `200 { "matches": [{ "id": uuid, "similarity": number }] }` ordinati per similarità decrescente; `400 { error }` se query vuota; `401` senza sessione; `500 { error: ERR.searchFailed }` se Jina o il DB falliscono. **Effetto collaterale:** prima della ricerca embedda (batch, max 50 per chiamata) le note dell'utente con `embedding is null` e le aggiorna; un fallimento del backfill viene loggato e non blocca la ricerca.

- [ ] **Step 1: Scrivere la funzione**

```ts
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
const MIN_SIMILARITY = 0.4; // da tarare sulle note reali (Task 6)
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

  const vectors = await embedTexts(
    missing.map((n) => noteEmbeddingText(n.title, n.summary_points)),
    "document",
  );
  await Promise.all(
    missing.map((n, i) =>
      db.from("notes").update({ embedding: vectors[i] }).eq("id", n.id)
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
```

- [ ] **Step 2: Registrarla in `supabase/config.toml`**

```toml
[functions.search-notes]
verify_jwt = false
```

- [ ] **Step 3: Type-check**

```bash
deno check supabase/functions/search-notes/index.ts
```

- [ ] **Step 4: STOP — conferma dell'utente, poi deploy**

```bash
supabase functions deploy search-notes
```

- [ ] **Step 5: Verificare con curl**

```bash
# query semantica: deve trovare la nota creata nel Task 2 (pricing) senza contenere la parola
curl -s "$SB_URL/functions/v1/search-notes" \
  -H "Authorization: Bearer $TOKEN" -H "apikey: $ANON" -H "content-type: application/json" \
  -d '{"query":"quanto far pagare un prodotto"}'
# query vuota → 400
curl -s -o /dev/null -w "%{http_code}\n" "$SB_URL/functions/v1/search-notes" \
  -H "Authorization: Bearer $TOKEN" -H "apikey: $ANON" -H "content-type: application/json" \
  -d '{"query":"   "}'
# senza token → 401
curl -s -o /dev/null -w "%{http_code}\n" "$SB_URL/functions/v1/search-notes" \
  -H "apikey: $ANON" -H "content-type: application/json" -d '{"query":"test"}'
```
Atteso: `{"matches":[{"id":"…","similarity":0.…}]}` con l'id della nota sul pricing in cima; `400`; `401`.

Backfill pigro: dopo la prima chiamata, con `execute_sql`:
```sql
select count(*) filter (where embedding is null) as senza, count(*) as totale
  from public.notes where user_id = (select id from auth.users where email = 'feffo-demo@wyn.app');
```
Atteso: `senza = 0`. Le note degli altri utenti si completano alla loro prima ricerca.

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/search-notes/index.ts supabase/config.toml
git commit -m "functions: search-notes (embedding query + match_notes sotto RLS)"
```

---

### Task 4: Backfill delle note esistenti — SOSTITUITO

**Decisione (2026-09-15):** le 27 note esistenti appartengono a 4 utenti; uno script locale avrebbe richiesto service-role key e chiave Jina fuori dai secret. Il backfill è ora *pigro* dentro `search-notes` (Task 3, `backfillMissingEmbeddings`): ogni utente completa le proprie note alla prima ricerca, sotto RLS, senza chiavi locali. Nessun file da creare, nessun passo da eseguire.

- [x] Nessuna azione (assorbito dal Task 3).

---

### Task 5: iOS — `NotesService.semanticMatches` e colonne esplicite

**Files:**
- Modify: `WYN/Services/NotesService.swift`

**Interfaces:**
- Produces: `func semanticMatches(query: String) async throws -> [UUID]` (id ordinati per similarità decrescente; lancia in caso di errore rete/server). `fetchNotes()` e `fetchNote(id:)` non scaricano più `embedding`.

- [ ] **Step 1: Escludere `embedding` dalle select**

`.select()` seleziona `*`, che ora includerebbe 512 float per nota. Aggiungere in `NotesService`:
```swift
    /// Colonne della nota. `embedding` è esclusa: 512 float per nota inutili al client.
    private static let columns =
        "id,user_id,source_type,url,image_paths,title,summary_points,category,tags,source_name,thumbnail_url,read_time_label,created_at"
```
e sostituire `.select()` con `.select(Self.columns)` in `fetchNotes()` e `fetchNote(id:)`.

- [ ] **Step 2: Aggiungere `semanticMatches`**

Dopo `fetchNote(id:)`:
```swift
    /// Id delle note simili per significato alla query, ordinati per somiglianza.
    /// Chiama la Edge Function `search-notes` (RLS: solo note dell'utente).
    func semanticMatches(query: String) async throws -> [UUID] {
        let response: SemanticSearchResponse = try await client.functions.invoke(
            "search-notes",
            options: FunctionInvokeOptions(body: ["query": query])
        )
        return response.matches.map(\.id)
    }
```
In fondo al file:
```swift
private struct SemanticSearchResponse: Decodable {
    struct Match: Decodable {
        let id: UUID
        let similarity: Double
    }
    let matches: [Match]
}
```

- [ ] **Step 3: Build**

Comando build in «Comandi di verifica». Atteso: `BUILD SUCCEEDED`, 0 warning. `NotesService.swift` è compilato anche dal target ShareExtension (vedi `project.yml`): la build dell'app compila entrambi.

- [ ] **Step 4: Smoke test feed**

Avviare con `-uitest-login`: il feed carica le note come prima (le colonne esplicite non hanno rotto il decoding).

- [ ] **Step 5: Commit**

```bash
git add WYN/Services/NotesService.swift
git commit -m "ui: cerca — NotesService.semanticMatches, select senza embedding"
```

---

### Task 6: iOS — SearchView ibrida, stati, copy, taratura soglia

**Files:**
- Modify: `WYN/Features/Search/SearchView.swift`
- Modify (solo se la soglia cambia): `supabase/functions/search-notes/index.ts` (`MIN_SIMILARITY`)

**Interfaces:**
- Consumes: `NotesService.semanticMatches(query:)` (Task 5).
- Produces: `SearchMatch.semantic`; `ResultCard(note:term:match:)` (il match viene passato dalla view, non più calcolato dentro la card).

- [ ] **Step 1: Stato e servizio**

Sotto `@State private var selectedNote: Note?` aggiungere:
```swift
    /// Ricerca per significato (Edge Function search-notes), in parallelo al filtro testuale.
    @State private var semanticIDs: [UUID] = []
    @State private var semanticState: SemanticState = .idle
    @State private var semanticTask: Task<Void, Never>?
    private let service = NotesService()

    private enum SemanticState { case idle, loading, done, failed }
    /// Sotto questa lunghezza la ricerca semantica non parte (evita chiamate per 1-2 lettere).
    private static let minSemanticLength = 3
```

- [ ] **Step 2: Risultati ibridi**

Rinominare l'attuale `results` in `textResults` (corpo invariato) e aggiungere:
```swift
    /// Note trovate per significato e non già presenti nei risultati testuali.
    private var semanticResults: [Note] {
        let textIDs = Set(textResults.map(\.id))
        return semanticIDs.compactMap { id in
            textIDs.contains(id) ? nil : store.notes.first { $0.id == id }
        }
    }

    /// Prima i match testuali (ordine attuale), poi quelli per significato.
    private var results: [Note] { textResults + semanticResults }
```

- [ ] **Step 3: Avvio/cancellazione della chiamata semantica**

Dopo l'`.onChange(of: query)` esistente:
```swift
        .onChange(of: debounced) { _, newValue in
            runSemanticSearch(for: newValue.trimmed)
        }
```
e come metodo privato:
```swift
    private func runSemanticSearch(for term: String) {
        semanticTask?.cancel()
        semanticIDs = []
        guard term.count >= Self.minSemanticLength else {
            semanticState = .idle
            return
        }
        semanticState = .loading
        semanticTask = Task {
            do {
                let ids = try await service.semanticMatches(query: term)
                guard !Task.isCancelled else { return }
                semanticIDs = ids
                semanticState = .done
            } catch {
                guard !Task.isCancelled else { return }
                semanticState = .failed
            }
        }
    }
```
Il bottone «x» del campo azzera `debounced`, quindi passa da qui e resetta tutto.

- [ ] **Step 4: Placeholder**

`TextField("Cerca una parola nelle note…", …)` → `TextField("Cerca per concetto, non per titolo…", …)`.

- [ ] **Step 5: `resultsContent`**

```swift
    @ViewBuilder
    private var resultsContent: some View {
        if debounced.trimmed.isEmpty {
            emptyPrompt
        } else if results.isEmpty {
            if semanticState == .loading { semanticLoading } else { noResults }
        } else {
            let textIDs = Set(textResults.map(\.id))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(results.count) risultati")
                            .monoLabel(size: 11)
                            .foregroundStyle(Color.ink3)
                        Spacer()
                        Text(modeLabel)
                            .monoLabel(size: 9)
                            .foregroundStyle(Color.ink3)
                    }
                    .padding(.horizontal, 20)
                    ForEach(results) { note in
                        Button { selectedNote = note } label: {
                            ResultCard(
                                note: note,
                                term: term,
                                match: textIDs.contains(note.id)
                                    ? SearchMatch.find(in: note, term: term)
                                    : .semantic
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// Etichetta a destra del conteggio: dice cosa sta confrontando la ricerca.
    private var modeLabel: String {
        switch semanticState {
        case .idle:    return "Corrispondenza testuale"
        case .loading: return "cerco per significato…"
        case .done:    return "Testo e significato"
        case .failed:  return "Solo corrispondenza testuale"
        }
    }

    private var semanticLoading: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Cerco per significato…")
                .monoLabel(size: 11)
                .foregroundStyle(Color.ink3)
            Spacer()
        }
    }
```

- [ ] **Step 6: Empty state (copy)**

Nel `emptyPrompt` sostituire i due testi:
- titolo: `"Cerca per concetto, non solo per parola"`
- corpo: `"Scrivi una parola che compare nella nota, oppure descrivi quello che ricordi. Cercare «come risparmiare» trova anche una nota che parla di «TER» e «commissioni»."`

e le righe dei campi:
```swift
                    comparedField("Titolo", "testo e significato")
                    comparedField("Punti chiave", "testo e significato")
                    comparedField("Tag", "testo esatto")
                    comparedField("Nome della fonte", "testo esatto")
```
con la firma `private func comparedField(_ name: String, _ mode: String) -> some View` e `Text(mode)` al posto di `Text("testo esatto")`.

- [ ] **Step 7: `SearchMatch.semantic` e `ResultCard(match:)`**

In `SearchMatch`:
```swift
    case title, source, tag(String), keyPoint(String), semantic
```
e in `label`:
```swift
        case .semantic: return "Corrisponde per significato"
```
`SearchMatch.find` resta invariato (usato solo per i match testuali).

In `ResultCard`: sostituire `private var match: SearchMatch { SearchMatch.find(in: note, term: term) }` con `let match: SearchMatch`, e nello `switch match` aggiungere:
```swift
            case .semantic:
                if let point = note.summaryPoints.first {
                    Text("«\(point)»")
                        .font(.body(13.5))
                        .foregroundStyle(Color.ink)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
```

- [ ] **Step 8: Build**

Atteso: `BUILD SUCCEEDED`, 0 warning.

- [ ] **Step 9: Smoke test e screenshot (account demo)**

Avviare con `-uitest-login`, tab Cerca, digitare con `axe type`:
1. `come risparmiare` → compaiono risultati; la nota Finanza (se non contiene la parola) ha etichetta «Corrisponde per significato» dopo gli eventuali match testuali; etichetta a destra «Testo e significato». Screenshot `tasks/ui-screens/cerca-ibrida-light.png` (+ `-dark` con `xcrun simctl ui booted appearance dark`).
2. Parola esatta presente in un titolo → quella nota è prima, con «Trovato nel titolo» ed evidenziazione come prima.
3. `xk` (2 lettere) → nessuna chiamata semantica, etichetta «Corrispondenza testuale».
4. Rete spenta (`xcrun simctl status_bar` non basta: disattivare il Wi-Fi del Mac) + query con match testuale → lista con «Solo corrispondenza testuale». Screenshot `tasks/ui-screens/cerca-solo-testo.png`.
5. `zzzz qqqq` → «Nessun risultato» solo dopo la fine della chiamata.
6. Tap su un risultato semantico → apre il dettaglio.
7. Schermata vuota (nessuna query): screenshot `tasks/ui-screens/cerca-vuota-light.png`.

- [ ] **Step 10: Tarare la soglia**

Con `curl` (Task 3, Step 5) provare 3 query pertinenti e 3 non pertinenti sulle note demo e annotare le `similarity`. Se una query non pertinente supera 0.4 o una pertinente resta sotto, cambiare `MIN_SIMILARITY` in `search-notes/index.ts`, ridistribuire (con conferma) e ripetere. Riportare i valori scelti nella review di `tasks/todo.md`.

- [ ] **Step 11: Commit**

```bash
git add WYN/Features/Search/SearchView.swift supabase/functions/search-notes/index.ts
git commit -m "ui: cerca — risultati ibridi testo + significato, stati e copy"
```

---

### Task 7: Documentazione e chiusura

**Files:**
- Modify: `features.md` (§3, §5.3, §6.1, §6.2, §6.4, §9.3, §10, «Idee v2»)
- Modify: `tasks/todo.md` (sezione review)
- Run: `graphify update .`

- [ ] **Step 1: `features.md`**

- §5.3: placeholder «Cerca per concetto, non per titolo…»; descrivere la ricerca ibrida (filtro testuale client-side invariato + `search-notes` con embedding Jina `jina-embeddings-v5-text-small` 512d e `match_notes` pgvector; top 10, soglia scelta nel Task 6; fallback «Solo corrispondenza testuale»).
- §6.4: aggiungere `POST search-notes { query } → { matches: [{ id, similarity }] }` (con backfill pigro delle note senza embedding).
- §6.1 / §6.2: aggiungere il passo «embedding best effort (null se Jina fallisce)».
- §3: nuova colonna `embedding | vector(512), nullable | titolo + punti chiave, calcolato alla creazione`.
- §2 / §8: Jina AI usato anche per gli embedding (stessa `JINA_API_KEY`), nessuna chiave nuova.
- §10: rimuovere «Nessuna ricerca semantica/vettoriale»; in «Idee v2» togliere «Ricerca semantica (pgvector + embeddings)».

- [ ] **Step 2: `tasks/todo.md`**

Aggiungere in fondo una sezione «Ricerca semantica — review (2026-09-…)» con: task completati, soglia scelta e similarità osservate, note deployate, eventuali note senza embedding.

- [ ] **Step 3: Graph e commit**

```bash
graphify update .
git add features.md tasks/todo.md graphify-out
git commit -m "docs: ricerca semantica — features.md e review"
```

---

## §3 — Rischi e note per chi esegue

- **Ordine obbligato:** Task 1 → 2 → 3 lato backend (Task 4 assorbito dal 3); Task 5 → 6 lato iOS possono partire solo dopo il Task 3 deployato (altrimenti la UI mostra sempre «Solo corrispondenza testuale»).
- **Risposte in ritardo:** `runSemanticSearch` cancella il task precedente a ogni nuovo termine e ignora i risultati se cancellato. Non usare i risultati di una query vecchia.
- **`select("*")` e la colonna vettoriale:** il Task 5 va fatto anche se non si volesse la UI, altrimenti ogni caricamento del feed scarica gli embedding.
- **Share Extension:** nessuna modifica. Le note create da lì passano dalle stesse Edge Functions e ricevono l'embedding.
- **Costi:** una chiamata Jina Embeddings per nota creata e una per ricerca (dopo il debounce, minimo 3 caratteri), sullo stesso piano/chiave del Reader. Trascurabili a questi volumi (free tier: 100 richieste/min, 100K token/min).
- **Se `deno` non è installato** localmente: `brew install deno` (serve solo per `deno test` / `deno check` / backfill; il deploy usa la Supabase CLI).
