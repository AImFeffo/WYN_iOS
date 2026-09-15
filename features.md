# WYN — What You've Noted

Documento di riferimento completo per replicare interamente l'applicazione. Descrive cosa fa l'app, tutte le funzionalità, il modello dati, i flussi, il design e i servizi esterni necessari — sia per l'attuale versione web (PWA) sia per una futura versione **nativa iOS**.

---

## 1. Cos'è WYN

WYN ("What You've Noted") è un'app **mobile-first** per salvare contenuti trovati online e ritrovarli quando servono. L'idea centrale:

> **Salvi un link o uno screenshot → l'AI lo trasforma in una nota strutturata (titolo, punti chiave, categoria, tag) → tu la ritrovi cercando per concetto, non per titolo.**

Non è un "read-it-later" classico: non archivia la pagina intera, ma **estrae il senso** del contenuto in 3–5 punti chiave, lo categorizza automaticamente e lo tagga, così la libreria personale resta leggera e navigabile.

Tono e identità visiva: stile **editoriale "warm paper"** (palette beige/carta, tipografia serif per i titoli, monospace per le etichette), non un'app "tech" generica.

Lingua dell'interfaccia e dei contenuti generati: **italiano** (l'AI risponde sempre in italiano anche su contenuti in altre lingue).

---

## 2. Stack attuale (versione web / PWA)

| Livello | Tecnologia |
|---|---|
| Framework | **Next.js 16** (App Router, React 19, TypeScript) |
| Styling | **Tailwind CSS v4** (via `@tailwindcss/postcss`) + variabili CSS custom |
| Tema chiaro/scuro | **next-themes** (`attribute="class"`, `defaultTheme="system"`) |
| Backend / DB / Auth / Storage | **Supabase** (Postgres + Auth + Storage) |
| AI (analisi contenuti) | **Anthropic Claude** (`@anthropic-ai/sdk`), modello `claude-sonnet-4-6` |
| Estrazione testo da URL / embeddings | **Jina AI**: Reader (`https://r.jina.ai/`) per il testo, Embeddings (`jina-embeddings-v5-text-small`, 512d) per la ricerca semantica |
| Elaborazione immagini | **sharp** (resize/compressione lato server) |
| Analytics performance | **@vercel/speed-insights** |
| Font | Google Fonts: **Newsreader** (titoli), **Geist** (testo), **Geist Mono** (etichette) |
| Hosting | **Vercel** (live su `wyn-lilac-two.vercel.app`) |

### Struttura cartelle rilevante
```
app/
  (auth)/login, (auth)/register    → schermate autenticazione
  (main)/feed, cerca, categorie, profilo + layout.tsx (bottom nav)
  aggiungi/                        → pagina "aggiungi nota" (raggiungibile via URL, non più nella nav)
  nota/[id]/                       → dettaglio nota
  api/
    process-link/                  → pipeline URL → nota
    process-screenshot/            → pipeline screenshot → nota
    search/                        → ricerca note
    notes/[id]/                    → PATCH (tag) e DELETE nota
    export/                        → export JSON / Markdown
  layout.tsx, globals.css, page.tsx (redirect → /feed)
lib/
  supabase/{client,server,service}.ts
  claude.ts, jina.ts, notes.ts, types.ts, mock-data.ts
components/ ui/, notes/, aggiungi/, profilo/, layout/
proxy.ts                           → middleware di protezione route
public/manifest.json               → manifest PWA
```

---

## 3. Modello dati

### Tabella Supabase `notes`

| Campo | Tipo | Note |
|---|---|---|
| `id` | uuid (PK) | generato dal DB |
| `user_id` | uuid | FK all'utente autenticato |
| `source_type` | enum `article` \| `screenshot` | origine del contenuto |
| `url` | text, nullable | presente solo per `article` |
| `image_paths` | text[] , nullable | path nello Storage, solo per `screenshot` |
| `title` | text | titolo generato dall'AI (max ~80 caratteri) |
| `summary_points` | text[] | 3–5 punti chiave (frasi complete, max ~120 char l'una) |
| `category` | text | una delle 7 categorie (vedi sotto) |
| `tags` | text[] | 3–5 tag brevi, minuscolo, in italiano |
| `source_name` | text, nullable | es. hostname del sito (`lennysnewsletter.com`) |
| `thumbnail_url` | text, nullable | previsto ma non popolato attualmente |
| `read_time_label` | text, nullable | es. "4 min", solo per articoli |
| `created_at` | timestamptz | ordinamento feed (desc) |
| `embedding` | vector(512), nullable | titolo + punti chiave, calcolato alla creazione (best effort: null se Jina fallisce) |

### Categorie (fisse, 7)
`Tech · Salute · Business · Cucina · Design · Finanza · Altro`

Ogni categoria ha un **colore** associato (usato per icona/accenti UI). Se una nota ha una categoria non riconosciuta, fallback grigio `#8C8478`.

| Categoria | Colore |
|---|---|
| Tech | `#2C5266` |
| Salute | `#5E7E6B` |
| Business | `#B0884A` |
| Cucina | `#AE5F3D` |
| Design | `#6E5E84` |
| Finanza | `#3B5A52` |
| Altro | `#8C8478` |

### Row Level Security (RLS)
Sulla tabella `notes` sono attive **4 policy** (SELECT / INSERT / UPDATE / DELETE), tutte con condizione `user_id = auth.uid()`: ogni utente vede e modifica solo le proprie note.

> ⚠️ **Eccezione INSERT:** le API di elaborazione (`process-link`, `process-screenshot`) inseriscono usando la **service-role key** (client `service.ts`), che bypassa RLS. Questo perché l'insert avviene lato server dopo aver già verificato l'utente. Fondamentale in una riscrittura: l'insert deve comunque impostare `user_id` all'utente autenticato verificato server-side.

### Storage Supabase
- Bucket **`screenshots`**.
- Path file: `${user_id}/${uuid}.jpg` (sempre JPEG dopo la compressione).
- Upload effettuato con service-role key.

---

## 4. Autenticazione

- **Email + password** tramite Supabase Auth.
- Login: `signInWithPassword({ email, password })` → redirect a `/feed`.
- Registrazione: `signUp({ email, password })` → messaggio di successo → redirect a `/feed` dopo 1,5 s. Password minima 6 caratteri.
- Logout: `signOut()`.
- **Conferma email disattivata** (scelta da sviluppo; per produzione reale andrebbe riattivata).
- Gestione errori con messaggi in italiano ("Email o password non corretti", "Questa email è già registrata", ecc.).

### Protezione route (middleware `proxy.ts`)
- Route **protette**: `/feed`, `/cerca`, `/categorie`, `/aggiungi`, `/nota`, `/profilo`. Se non loggato → redirect a `/login`.
- Route **auth** (`/login`, `/register`): se già loggato → redirect a `/feed`.
- Il middleware rinfresca i cookie di sessione Supabase a ogni richiesta (pattern SSR ufficiale con `getAll`/`setAll`).

---

## 5. Funzionalità (dettaglio per schermata)

### 5.1 Feed (`/feed`) — home
- **Masthead** editoriale: logo "WYN" a sinistra, data corrente in italiano a destra (es. "Martedì 8 Luglio").
- **AddBar** in cima al feed (barra di aggiunta): un input "Incolla un link…".
  - Se c'è testo → bottone **SALVA** → chiama `POST /api/process-link`.
  - Se vuoto → bottone **fotocamera** → apre un **BottomSheet** "Carica screenshot" con due opzioni:
    - **"Scegli da Libreria"** (attivo) → file picker immagini (JPEG/PNG/WebP) → bottone **Elabora** → `POST /api/process-screenshot`.
    - **"Scatta foto"** (**disabilitato** attualmente, da collegare in futuro).
  - L'immagine viene **compressa lato client** (canvas, lato massimo 1568px, JPEG q. 0,85) prima dell'upload.
- **Card "in elaborazione"**: mentre l'AI lavora, in cima al feed appare una card con spinner + shimmer e l'etichetta del contenuto in lavorazione. In caso di errore, una **ErrorCard** con "Non siamo riusciti a elaborare questo contenuto" + bottone Chiudi.
- **Filtri (chips)**: riga scrollabile orizzontale con `Tutti / Articoli / Screenshot` + una chip per ogni categoria presente. I filtri sono combinabili (tipo + categoria). Ordinamento fisso: dal più recente.
- **Lista note**: `NoteCard` per ogni nota. Stato vuoto: "Nessuna nota ancora / Incolla un link o carica uno screenshot qui sopra".
- Filtro per categoria anche via URL: `/feed?categoria=Tech` (mostra banner "← Tutte le note").

### 5.2 Dettaglio nota (`/nota/[id]`)
- Top bar: link "← Feed", bottone **Condividi** (icona presente ma **azione non ancora implementata**), menu **NoteActions** (modifica tag / elimina).
- Header: icona categoria colorata + titolo (serif) + categoria + tempo relativo ("2 ore fa").
- Corpo (`NotaTabs`): **vista unica** con i punti chiave e i tag (in una versione precedente c'era un tab switcher Riassunto/Punti, ora rimosso).
- Per gli **articoli** con URL: CTA fissa in basso **"Apri articolo originale"** (apre l'URL in nuova scheda).
- 404 se la nota non esiste o non appartiene all'utente.

### 5.3 Cerca (`/cerca`)
- Input con autofocus, placeholder "Cerca per concetto, non per titolo…".
- **Debounce 400 ms** → `GET /api/search?q=…`.
- Ricerca **case-insensitive** su: `title`, `source_name`, `tags`, `summary_points` (match "contiene").
  - Nota: la ricerca è **client-side sul set di note dell'utente** (recupera tutte le note e filtra in memoria). Non è ricerca full-text DB né semantica.
- Risultati come lista compatta (`ResultCard`); stato "N risultati", loading e stato vuoto dedicati.
- **App iOS — ricerca ibrida**: allo stesso filtro testuale client-side si affianca una ricerca semantica. Con almeno 3 caratteri (dopo il debounce) l'app chiama la Edge Function `search-notes`, che genera l'embedding della query con Jina (`jina-embeddings-v5-text-small`, 512d, `task: retrieval.query`) e la confronta via pgvector (`match_notes`, similarità coseno, soglia 0.40, top 10) con gli embedding delle note (`task: retrieval.passage` su titolo + punti chiave). La lista mostra prima i match testuali (invariati, evidenziati), poi le note trovate per significato con etichetta «Corrisponde per significato». Stati: «Corrispondenza testuale» (idle), «cerco per significato…» (loading), «Testo e significato» (fatto), «Solo corrispondenza testuale» (fallback su errore di rete/server, nessun blocco); «Nessun risultato» solo se entrambi gli esiti sono vuoti.

### 5.4 Categorie (`/categorie`)
- Griglia 2 colonne con una card per categoria: icona colorata + nome + conteggio note.
- Mostra solo le categorie con almeno una nota (fallback: tutte, se nessuna ha note).
- Tap su categoria → `/feed?categoria=<nome>`.
- Conteggi calcolati con `getCategoryCounts` (raggruppa le note dell'utente per categoria).

### 5.5 Profilo (`/profilo`)
- Header utente: avatar con iniziale, nome (parte prima della `@` dell'email), email.
- **Impostazioni**: toggle **Tema scuro** (stile iOS switch).
- **Statistiche** (reali): note totali, n° articoli, n° screenshot, categoria più usata.
- **Dati → Esporta note**: bottoni per scaricare tutte le note (`GET /api/export?format=json|markdown`).
- **Integrazione iPhone**: istruzioni testuali per "Aggiungi a schermata Home" da Safari (installazione PWA).
- **Supporto**: link mailto per inviare feedback.
- **Informazioni**: versione app ("1.0.0"), "Membro da" (data creazione account), link privacy policy.
- **Logout**.

### 5.6 Navigazione
- **Bottom nav** a **4 slot** (Feed, Cerca, Categorie, Profilo). Non c'è più il pulsante "+" centrale: l'aggiunta avviene dall'AddBar nel feed.
- Esiste ancora una pagina `/aggiungi` (con `LinkForm` e `ScreenshotForm`, che supportano anche un **hint** "Cosa vuoi evidenziare?"), raggiungibile via URL ma **non linkata** dalla nav.

---

## 6. Pipeline di elaborazione (il cuore dell'app)

### 6.1 Da link → nota (`POST /api/process-link`)
1. Verifica utente autenticato (401 se assente).
2. Legge `url` e `hint` (opzionale, max 150 char) dal body JSON.
3. Valida che sia un URL `http`/`https`.
4. **Estrae il testo** con **Jina AI Reader**: `GET https://r.jina.ai/<url>` con header `Authorization: Bearer <JINA_API_KEY>`. Testo troncato a 15.000 caratteri; `sourceName` = hostname senza `www.`. Errore se il contenuto è < 100 caratteri.
5. **Analizza con Claude** (`analyzeArticle`): system prompt che impone un output **solo JSON** con `title`, `summary_points` (3–5), `category` (una delle 7), `tags` (3–5), `read_time_label`. Se presente, l'hint forza almeno un punto chiave su quell'aspetto.
6. **Embedding best effort**: calcola l'embedding (Jina, titolo + punti chiave) da includere nell'insert; se Jina fallisce la nota viene salvata comunque con `embedding = null`.
7. **Salva** la nota su Supabase con service-role key (`source_type: "article"`).
8. Ritorna `{ id }`. Il client fa `router.refresh()` per aggiornare il feed.

### 6.2 Da screenshot → nota (`POST /api/process-screenshot`)
1. Verifica utente autenticato.
2. Legge `multipart/form-data`: campo `image` + `hint` opzionale.
3. Valida tipo (`image/jpeg|png|webp`) e dimensione (max 20 MB).
4. **Resize con sharp** (lato max 1568px, `fit: inside`, no enlargement) → JPEG q. 85.
5. **Analizza con Claude Vision** (`analyzeScreenshot`): immagine in base64 + prompt che chiede lo stesso JSON degli articoli **senza** `read_time_label`. (L'analisi avviene **prima** dell'upload, per evitare file orfani se Claude fallisce.)
6. **Embedding best effort**: calcola l'embedding (Jina, titolo + punti chiave); se Jina fallisce la nota viene salvata comunque con `embedding = null`.
7. **Upload** su Storage bucket `screenshots` (path `user_id/uuid.jpg`).
8. **Salva** la nota (`source_type: "screenshot"`, `image_paths: [path]`).
9. Ritorna `{ id }`.

### 6.3 Robustezza del parsing AI
Claude a volte "avvolge" il JSON in testo/markdown: il codice tenta `JSON.parse` diretto e, se fallisce, estrae il primo blocco `{...}` con regex. Valida che `title` e `summary_points` esistano, altrimenti solleva errore. **Da replicare identico** in una versione nativa.

### 6.4 Altre API
- `GET /api/search?q=` → `{ notes }` (vedi §5.3).
- `PATCH /api/notes/[id]` con `{ tags: string[] }` → normalizza (trim, minuscolo, ≤40 char, non vuoti) e aggiorna. Rispetta RLS (usa client utente, non service-role).
- `DELETE /api/notes/[id]` → elimina la nota (solo se dell'utente).
- `GET /api/export?format=json|markdown` → download di tutte le note dell'utente.
- **App iOS** — `POST search-notes { query } → { matches: [{ id, similarity }] }` (Edge Function): query troncata a 200 caratteri, esegue `match_notes` (pgvector, soglia 0.40, top 10) con il JWT dell'utente (RLS). Prima della ricerca esegue un **backfill pigro**: le note dell'utente senza embedding (max 50 per chiamata) vengono embeddate in batch e aggiornate; un fallimento del backfill viene loggato e non blocca la ricerca.

---

## 7. Design system

### Palette (variabili CSS, con dark mode)
| Token | Light | Dark | Uso |
|---|---|---|---|
| `--bg` | `#F6F3EA` | `#191712` | sfondo pagina |
| `--surface` | `#FBF9F2` | `#211E18` | card / superfici |
| `--ink` | `#1B1916` | `#F1ECE0` | testo primario |
| `--ink-2` | `#6E6557` | `#A69E8D` | testo secondario |
| `--ink-3` | `#A8A192` | `#6E675A` | testo terziario / meta |
| `--hairline` | rgba(27,25,22,.12) | rgba(241,236,224,.14) | bordi sottili |
| `--hairline-strong` | rgba(27,25,22,.26) | rgba(241,236,224,.30) | bordi marcati |
| `--danger` | `#9E3B2E` | `#D98A78` | errori |

### Tipografia
- **Titoli**: Newsreader (serif), classe `.font-heading`, tracking negativo.
- **Testo**: Geist (sans).
- **Etichette / meta / byline**: Geist Mono, classe `.font-mono`, spesso maiuscolo con letter-spacing.

### Dettagli iOS-friendly (importanti per una PWA installata)
- Safe-area: utility `.pb-safe`, `.pt-safe`, `.pt-page` (usano `env(safe-area-inset-*)`).
- Toggle stile iOS custom (`.ios-toggle`).
- Viewport bloccato (`maximumScale: 1`, `userScalable: false`), `-webkit-tap-highlight-color: transparent`, scrollbar nascoste.
- Animazioni `wyn-spin` (spinner) e `wyn-shimmer` (skeleton), disattivate con `prefers-reduced-motion`.

### PWA (`manifest.json`)
- `display: standalone`, `start_url: /feed`, orientamento `portrait`, lingua `it`.
- Icone 192/512 (`purpose: "any maskable"`) + `apple-touch-icon`.
- ⚠️ Dichiara un **`share_target`** (`action: /share`) **ma la route `/share` non esiste** nel codice: la condivisione di sistema verso l'app **non è implementata**. In una riscrittura è una feature da progettare (vedi §9).

---

## 8. Variabili d'ambiente

Necessarie per far girare l'app (nomi da `.env.local`):

| Variabile | Scopo |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | URL progetto Supabase (pubblica) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | chiave anon Supabase (pubblica) |
| `SUPABASE_SERVICE_ROLE_KEY` | chiave service-role (**segreta**, solo server: insert/upload che bypassano RLS) |
| `ANTHROPIC_API_KEY` | chiave API Claude |
| `JINA_API_KEY` | chiave API Jina, usata sia per il Reader (estrazione testo) sia per gli Embeddings (ricerca semantica) |

> Le chiavi `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `JINA_API_KEY` **non devono mai finire sul client**. In una versione nativa iOS questo è critico (vedi §9): non vanno incluse nell'app, ma tenute su un backend.

---

## 9. Come ricreare l'app **nativa per iOS**

Questa sezione elenca cosa serve per riscrivere WYN come **app iOS nativa** (SwiftUI) mantenendo le stesse funzionalità.

### 9.1 Servizi esterni necessari (gli stessi di oggi)
| Servizio | A cosa serve | Ha SDK / accesso nativo? |
|---|---|---|
| **Supabase** | DB Postgres, Auth email/password, Storage screenshot, RLS | Sì — **`supabase-swift`** (SDK ufficiale Swift): auth, database, storage. |
| **Anthropic Claude** | Analisi articoli e screenshot (vision) → JSON strutturato | API REST. **Non chiamarla dall'app** (esporrebbe la chiave). |
| **Jina AI Reader** | Estrazione testo pulito da un URL | API REST (`r.jina.ai`). Anch'essa da chiamare da backend. |
| **Elaborazione immagini** | Resize/compressione screenshot | Nativo iOS (`UIImage`/`ImageIO`), non serve `sharp`. La compressione può avvenire sul device prima dell'upload. |

### 9.2 Il punto chiave: serve comunque un backend
Le chiavi Claude, Jina e service-role di Supabase **non possono stare nell'app** (un'app iOS è decompilabile). Due strade:

1. **Supabase Edge Functions** (consigliata, resta tutto in Supabase): riscrivi `process-link` e `process-screenshot` come Edge Functions (Deno/TypeScript). L'app iOS chiama le function autenticandosi col token Supabase dell'utente; la function verifica l'utente, chiama Jina + Claude con le chiavi segrete (Function secrets), poi inserisce la nota. È il porting più diretto delle attuali API route Next.js.
2. **Un backend proprio** (Vercel/altro) che espone gli stessi endpoint. Va bene se vuoi riusare quasi tal quale il codice `lib/claude.ts`, `lib/jina.ts` e le route attuali.

In entrambi i casi l'app iOS parla **solo** con Supabase (auth, lettura note, storage) e con i tuoi endpoint di elaborazione. Nessuna chiave segreta nel bundle.

### 9.3 Cosa fa direttamente l'app iOS
- **Auth**: `supabase-swift` → `signIn`/`signUp`/`signOut` email-password; sessione persistita in modo sicuro.
- **Feed / dettaglio / categorie / ricerca**: query dirette alla tabella `notes` via SDK (RLS garantisce l'isolamento per utente). La ricerca è ibrida: filtro testuale client-side (come oggi) più ricerca semantica via Edge Function `search-notes` (pgvector, vedi §5.3/§6.4).
- **Aggiunta screenshot**: compressione con API native, upload su Storage, chiamata all'endpoint di elaborazione.
- **Export**: generazione JSON/Markdown lato client e condivisione con il share sheet iOS.

### 9.4 Funzionalità nativa che oggi manca (e conviene aggiungere)
- **Share Extension iOS**: è il vero valore nativo. Consente di condividere un link o uno screenshot **da qualsiasi app** (Safari, Foto, ecc.) direttamente in WYN. Sostituisce sia l'AddBar sia il `share_target` PWA mai implementato. Richiede un target Share Extension nel progetto Xcode che invii l'URL/immagine al backend di elaborazione.
- **Notifica/feedback** al termine dell'elaborazione asincrona (l'analisi AI richiede secondi): utile una **elaborazione in background con notifica locale** quando la nota è pronta.
- **"Scatta foto"**: banale da abilitare in nativo (fotocamera + `PHPicker`), mentre nella PWA era disabilitato.

### 9.5 Configurazione Supabase da replicare
- Tabella `notes` con lo schema di §3.
- Enum/valori `source_type` = `article` | `screenshot`.
- **RLS attiva** + 4 policy (`user_id = auth.uid()`).
- Bucket Storage **`screenshots`** (privato) con path `user_id/uuid.jpg`.
- **Redirect/URL** e (per produzione) **conferma email** riattivata.
- Le operazioni che oggi usano la service-role key vanno spostate dentro le Edge Functions (dove la chiave vive come secret).

---

## 10. Limitazioni note e stato

- **Ricerca**: web, solo testuale in-memory (title, source_name, tags, summary_points). App iOS: ibrida testo + semantica (pgvector, vedi §5.3); la qualità dei risultati semantici dipende dall'embedding — es. sulle note demo «come risparmiare» non recupera la nota sull'interesse composto (similarità 0.25, sotto soglia).
- **Condivisione**: bottone "Condividi" nel dettaglio e `share_target` PWA **non implementati**.
- **"Scatta foto"**: disabilitato nella PWA.
- **Elaborazione sincrona**: l'utente attende il completamento AI (nessun job in background lato server).
- **`thumbnail_url`**: campo previsto ma non popolato.
- **Prompt/output solo in italiano.**

### Idee v2 (non implementate)
Elaborazione asincrona con polling/realtime, swipe-to-delete nel feed, onboarding iniziale, dominio personalizzato.

---

## 11. Checklist minima per replicare da zero

1. Progetto Supabase: tabella `notes` (§3), RLS + 4 policy, bucket `screenshots`, Auth email/password.
2. Chiavi: Supabase (url, anon, service-role), Anthropic, Jina (§8).
3. Backend con 2 endpoint autenticati: `process-link` (Jina → Claude → insert) e `process-screenshot` (resize → Claude Vision → upload → insert), più `search`, `notes/[id]` (PATCH/DELETE), `export`. Parsing JSON robusto di Claude (§6.3).
4. UI: 4 schermate (Feed, Cerca, Categorie, Profilo) + Dettaglio nota + Auth; design "warm paper" con dark mode (§7); 7 categorie con colori.
5. (iOS nativo) `supabase-swift`, Share Extension, compressione immagini nativa, endpoint di elaborazione come Edge Functions.
