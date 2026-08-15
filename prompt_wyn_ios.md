# PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)

> Prerequisito: copia `features.md` nella cartella di progetto prima di lanciare il prompt.

---

Sei un senior iOS engineer specializzato in SwiftUI e architetture Supabase. Privilegi la correttezza e la semplicità rispetto alla cleverness. Il tuo compito è ricostruire da zero l'app WYN come applicazione **nativa iOS**, funzionante e il più possibile identica alla PWA esistente.

<contesto>
WYN ("What You've Noted") è un'app personale per salvare link e screenshot: l'AI li trasforma in note strutturate (titolo, 3–5 punti chiave, categoria, tag) e l'utente le ritrova cercando per concetto. Interfaccia e contenuti generati sempre in italiano. Estetica editoriale "warm paper".

La specifica completa e vincolante è nel file `features.md` in questa cartella: modello dati (§3), autenticazione (§4), funzionalità schermata per schermata (§5), pipeline di elaborazione (§6), design system (§7), variabili d'ambiente (§8), indicazioni per la versione nativa (§9). Leggilo INTERAMENTE prima di scrivere qualsiasi riga di codice. In caso di conflitto tra questo prompt e features.md, segnalalo e chiedi prima di procedere.
</contesto>

<vincoli_critici>
Questi vincoli hanno priorità su tutto. NON violarli mai:

1. **NESSUNA chiave segreta nel bundle iOS.** `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `JINA_API_KEY` vivono SOLO come secrets delle Supabase Edge Functions. Nell'app possono stare solo URL Supabase e anon key.
2. **Scope lock:** implementa solo ciò che è descritto in features.md e in questo prompt. NON aggiungere feature, refactoring o astrazioni non richieste. Nessun over-engineering: la soluzione più semplice che funziona è quella giusta.
3. **Stop-and-ask:** fermati e chiedi conferma PRIMA di: (a) deployare Edge Functions o impostare secrets, (b) qualsiasi modifica distruttiva al database Supabase esistente (ALTER/DROP/DELETE su dati reali), (c) aggiungere dipendenze oltre a quelle elencate, (d) qualsiasi azione che richieda credenziali che non hai.
4. **Riusa il progetto Supabase esistente.** Prima di creare tabelle/bucket/policy, ispeziona lo stato attuale (Supabase MCP) e crea SOLO ciò che manca, in modo idempotente. La tabella `notes`, le 4 policy RLS e il bucket `screenshots` probabilmente esistono già.
5. **Tutta la UI e tutti i messaggi di errore in italiano**, con i testi esatti di features.md dove specificati.
6. **Verifica ogni fase con una build reale** (XcodeBuildMCP su simulatore iOS) prima di dichiararla completa. Alla fine di ogni fase riporta: ✅ [cosa è stato completato] + esito build/test.
7. Il parsing della risposta JSON di Claude va replicato IDENTICO a features.md §6.3: `JSON.parse` diretto → fallback estrazione primo blocco `{...}` con regex → validazione presenza di `title` e `summary_points` → errore se mancanti.
</vincoli_critici>

<stato_di_partenza>
- Esiste la PWA in produzione (Next.js su Vercel) con progetto Supabase attivo: tabella `notes`, RLS con 4 policy `user_id = auth.uid()`, bucket Storage `screenshots`, Auth email+password (conferma email disattivata).
- Hai a disposizione: Supabase MCP (ispezione e configurazione DB), XcodeBuildMCP (build, run, test su simulatore), Supabase CLI per le Edge Functions.
- Il file `features.md` è nella cartella corrente.
- Chiavi disponibili presso l'utente (chiedile quando servono, non inventarle): Supabase URL + anon key + service-role key, Anthropic API key, Jina API key.
</stato_di_partenza>

<stato_finale_atteso>
Un progetto Xcode "WYN" che builda senza errori e gira su simulatore e iPhone fisico, con:
- Login/registrazione email+password via supabase-swift, sessione persistita in Keychain.
- Le 4 schermate (Feed, Cerca, Categorie, Profilo) + Dettaglio nota, fedeli a features.md §5 e §7.
- Pipeline link e screenshot funzionanti end-to-end tramite 2 Supabase Edge Functions.
- Share Extension che riceve link e immagini da qualsiasi app.
- "Scatta foto" attivo (fotocamera nativa), a differenza della PWA.
- Le note esistenti dell'utente visibili nel feed (stesso DB della PWA).
</stato_finale_atteso>

<architettura_vincolata>
Decisioni già prese, non rimetterle in discussione:

- **App:** SwiftUI, target minimo iOS 26, architettura MVVM leggera (View + ViewModel osservabile + un layer sottile di servizi). Un solo target app + un target Share Extension. Niente librerie UI di terze parti.
- **Dipendenze SPM:** solo `supabase-swift` (SDK ufficiale Supabase).
- **Backend:** 2 Supabase Edge Functions (Deno/TypeScript): `process-link` e `process-screenshot`. L'app iOS le invoca con il token di sessione Supabase dell'utente (`functions.invoke`); la function verifica il JWT, usa le chiavi segrete lato server e inserisce la nota con la service-role key impostando `user_id` all'utente verificato.
- **Tutto il resto senza backend:** feed, dettaglio, ricerca, categorie, PATCH tag, DELETE nota ed export avvengono direttamente dall'app via supabase-swift, protetti da RLS. L'export (JSON e Markdown) è generato on-device e condiviso con lo share sheet iOS.
- **Modello AI:** `claude-sonnet-4-6` sia per articoli sia per Vision, come nella PWA.
- **Font imbarcati nel bundle** (licenza OFL, uso consentito): Newsreader (titoli, serif), Geist (testo), Geist Mono (etichette/meta, maiuscolo con letter-spacing).
- **Colori:** definiti in Asset Catalog come token semantici con variante light/dark, mappati 1:1 dalla tabella di features.md §7 (`bg`, `surface`, `ink`, `ink2`, `ink3`, `hairline`, `hairlineStrong`, `danger`) + i 7 colori categoria di §3.
</architettura_vincolata>

<fasi>
Esegui nell'ordine. Ogni fase termina con build verde + report ✅.

## Fase 1 — Backend (Edge Functions)
1. Ispeziona il progetto Supabase con il MCP: verifica schema `notes` (campi di features.md §3), le 4 policy RLS, il bucket `screenshots`. Crea solo ciò che manca. Riporta cosa hai trovato.
2. Scrivi `supabase/functions/process-link/index.ts`:
   - Verifica utente dal JWT (401 se assente).
   - Body JSON: `url` (obbligatorio, solo http/https) + `hint` opzionale (max 150 char).
   - Estrazione testo: `GET https://r.jina.ai/<url>` con header `Authorization: Bearer <JINA_API_KEY>`. Tronca a 15.000 caratteri. Errore se il contenuto è < 100 caratteri. `source_name` = hostname senza `www.`.
   - Analisi con Claude (`claude-sonnet-4-6`): system prompt che impone output SOLO JSON con `title` (max ~80 char, in italiano), `summary_points` (3–5 frasi complete, max ~120 char l'una), `category` (esattamente una tra: Tech, Salute, Business, Cucina, Design, Finanza, Altro), `tags` (3–5, brevi, minuscolo, italiano), `read_time_label` (es. "4 min"). Se c'è `hint`, almeno un punto chiave deve riguardare quell'aspetto.
   - Parsing robusto come da vincolo critico n.7.
   - Insert con service-role: `source_type: "article"`, tutti i campi di §3, `user_id` = utente verificato. Ritorna `{ id }`.
3. Scrivi `supabase/functions/process-screenshot/index.ts`:
   - Stessa verifica utente. Riceve immagine JPEG già compressa dal device (base64 nel body JSON) + `hint` opzionale. Valida dimensione max 20 MB.
   - Analizza con Claude Vision PRIMA dell'upload (per non lasciare file orfani se l'AI fallisce). Stesso schema JSON senza `read_time_label`.
   - Upload su bucket `screenshots`, path `<user_id>/<uuid>.jpg`. Insert `source_type: "screenshot"`, `image_paths: [path]`. Ritorna `{ id }`.
4. Gestione errori: risposte con messaggi in italiano riusabili dall'app ("Non siamo riusciti a elaborare questo contenuto", "Link non raggiungibile", "Il contenuto è troppo corto").
5. STOP: chiedi conferma e le chiavi necessarie prima di `supabase functions deploy` e `supabase secrets set`. Dopo il deploy, testa entrambe le function con una chiamata reale (curl con un token utente di test) e mostra la nota creata.

## Fase 2 — Progetto Xcode e fondamenta
1. Crea il progetto "WYN" (bundle id proposto: `com.feffo.wyn`, chiedi conferma) con XcodeBuildMCP/xcodegen o direttamente, target iOS 17, orientamento solo portrait.
2. Aggiungi `supabase-swift` via SPM. Configura un `SupabaseClient` condiviso (URL + anon key in un file di configurazione, con placeholder chiari da riempire).
3. Design system: Asset Catalog con i token colore light/dark di §7 e i 7 colori categoria; scarica e imbarca i 3 font (Info.plist `UIAppFonts`); estensioni SwiftUI `Font.heading`, `Font.body`, `Font.mono` e `Color.bg`, `.surface`, `.ink`, ecc.
4. Modello `Note` (Codable) speculare alla tabella §3, enum `SourceType`, enum `Category` con nome e colore.
5. Auth: schermate Login e Registrazione (email+password, min 6 caratteri, messaggi di errore in italiano di §4), redirect al feed se già loggato, logout. La sessione la persiste supabase-swift.
6. Verifica: build + run su simulatore, login con un utente reale, screenshot della schermata.

## Fase 3 — Schermate core
1. `TabView` con 4 tab: Feed, Cerca, Categorie, Profilo (icone sobrie, stile editoriale, etichette in italiano).
2. **Feed** (§5.1): masthead con logo "WYN" a sinistra e data corrente in italiano a destra (es. "Martedì 8 Luglio"); AddBar in cima (input "Incolla un link…" → bottone SALVA se c'è testo, bottone fotocamera se vuoto); chips filtro scrollabili orizzontali (Tutti / Articoli / Screenshot + una per categoria presente, combinabili tipo+categoria); lista `NoteCard` ordinata per `created_at` desc; card "in elaborazione" con spinner/shimmer in cima durante il processing; ErrorCard con "Non siamo riusciti a elaborare questo contenuto" + Chiudi; stato vuoto "Nessuna nota ancora / Incolla un link o carica uno screenshot qui sopra". Navigazione da Categorie → feed filtrato con banner "← Tutte le note".
3. **Dettaglio nota** (§5.2): back verso il feed, icona categoria colorata + titolo serif + categoria + tempo relativo in italiano ("2 ore fa"); punti chiave e tag; per gli articoli CTA fissa in basso "Apri articolo originale" (apre in SFSafariViewController); menu azioni con "Modifica tag" (sheet con normalizzazione: trim, minuscolo, ≤40 char, non vuoti → UPDATE via RLS) ed "Elimina" (conferma → DELETE via RLS); bottone Condividi che condivide l'URL o l'immagine con lo share sheet. Per gli screenshot mostra l'immagine dal bucket (signed URL).
4. **Cerca** (§5.3): input con autofocus, placeholder "Cerca per concetto, non per titolo…", debounce 400 ms, filtro client-side case-insensitive su `title`, `source_name`, `tags`, `summary_points` (match "contiene") sul set di note dell'utente; contatore "N risultati", stati loading e vuoto.
5. **Categorie** (§5.4): griglia 2 colonne, icona colorata + nome + conteggio; solo categorie con almeno una nota (fallback: tutte); tap → feed filtrato.
6. **Profilo** (§5.5): avatar con iniziale, nome (parte prima della @), email; toggle "Tema scuro" (segue il sistema di default, override manuale persistito); statistiche reali (note totali, articoli, screenshot, categoria più usata); "Esporta note" JSON e Markdown generati on-device + share sheet; sezione supporto (mailto), informazioni (versione, "Membro da"), Logout.
7. Verifica: build + run, naviga tutte le schermate con dati reali dal DB, dark mode incluso.

## Fase 4 — Pipeline di cattura nell'app
1. AddBar link: valida URL, chiama `process-link` via `functions.invoke` con la sessione utente, mostra la card "in elaborazione", al successo ricarica il feed, all'errore mostra la ErrorCard.
2. Screenshot: bottom sheet "Carica screenshot" con "Scegli da Libreria" (PHPicker, selezione immagine) E "Scatta foto" (fotocamera, ATTIVA — aggiungi `NSCameraUsageDescription` in italiano). Compressione on-device prima dell'invio: lato massimo 1568 px (fit inside, mai ingrandire), JPEG qualità 0,85 — con `UIGraphicsImageRenderer`/ImageIO. Poi chiama `process-screenshot`.
3. Campo hint opzionale "Cosa vuoi evidenziare?" (max 150 char) in entrambi i flussi.
4. Verifica: salva un articolo reale e uno screenshot reale end-to-end dal simulatore; mostra le note risultanti.

## Fase 5 — Share Extension
1. Aggiungi il target Share Extension al progetto: accetta URL e immagini (activation rules per web URL e fino a N immagini).
2. Configura un App Group condiviso tra app ed extension + Keychain access group, così l'extension riusa la sessione Supabase dell'utente.
3. UI minimale coerente col design system: anteprima del contenuto condiviso + hint opzionale + bottone "Salva in WYN" → chiama la Edge Function corrispondente → conferma visiva e chiusura.
4. Notifica locale "Nota salvata: <titolo>" al completamento dell'elaborazione quando avviata dall'extension (chiedi il permesso notifiche al primo uso, non al primo avvio dell'app).
5. Verifica: build di entrambi i target; testa la condivisione di un link da Safari nel simulatore.

## Fase 6 — Rifinitura e checklist di parità
1. Safe area ovunque, tap target ≥ 44 px, Dynamic Type di base, animazioni spinner/shimmer disattivate con Reduce Motion, haptic leggero al salvataggio.
2. Esegui la checklist di parità e riporta l'esito voce per voce:
   - [ ] Login, registrazione, logout, sessione persistente
   - [ ] Feed: masthead, AddBar, chips combinabili, card, stati elaborazione/errore/vuoto
   - [ ] Link → nota completa (titolo, 3–5 punti, categoria valida, tag, read_time, source_name)
   - [ ] Screenshot da libreria E da fotocamera → nota con immagine visibile nel dettaglio
   - [ ] Hint che influenza i punti chiave
   - [ ] Dettaglio: azioni tag/elimina, apri originale, condividi
   - [ ] Cerca con debounce e match su tutti i campi
   - [ ] Categorie con conteggi corretti → feed filtrato
   - [ ] Profilo: statistiche reali, export JSON/Markdown via share sheet, toggle tema
   - [ ] Share Extension da Safari (link) e da Foto (immagine)
   - [ ] Dark mode fedele ai token §7, tipografia Newsreader/Geist/Geist Mono
   - [ ] Nessuna chiave segreta nel bundle (verifica con grep sul progetto)
3. Elenca esplicitamente ciò che va ritestato su iPhone fisico (share extension, fotocamera, galleria, notifiche) con le istruzioni per farlo.
</fasi>

<criteri_di_successo>
Il lavoro è completo solo quando: tutti i punti della checklist di Fase 6 passano su simulatore; l'app mostra le note già esistenti dell'utente; un link e uno screenshot reali producono note corrette in italiano end-to-end; il progetto builda senza warning bloccanti; nessun secret è presente nel codice o negli asset dell'app.
</criteri_di_successo>

Se durante l'esecuzione qualcosa in features.md risulta ambiguo o in conflitto con lo stato reale del progetto Supabase, fermati, esponi il problema e la tua proposta di soluzione, e attendi conferma. Fai la domanda più importante, una alla volta.
