# WYN iOS — Piano di ricostruzione nativa

App WYN ("What You've Noted") ricostruita da zero come app **nativa iOS** (SwiftUI), fedele alla PWA esistente. Spec vincolante: `features.md`. Prompt: `prompt_wyn_ios.md`.

## Stato di partenza (verificato via Supabase MCP — Fase 1.1 ✅)
- Progetto: **AImFeffo's Project** (`odplsmpadzhyhkdoqrne`), regione eu-west-1, Postgres 17.
- Tabella `public.notes`: 13 colonne come §3, enum `source_type = article|screenshot`, RLS attiva, FK a `auth.users`. 0 righe.
- 4 policy RLS (SELECT/INSERT/UPDATE/DELETE), tutte `auth.uid() = user_id`. Nomi in italiano.
- Bucket Storage `screenshots`: esiste, **privato**.
- Edge Functions: nessuna (da creare 2).
- ⇒ **Nessuna modifica al DB necessaria.** Solo Edge Functions + app iOS.

## Decisioni confermate dall'utente
- Deploy: io installo la Supabase CLI e faccio il deploy; l'utente imposta i 3 secret dal dashboard.
- Bundle id: **`com.feffo.wyn`** → App Group `group.com.feffo.wyn`.
- Modello AI: `claude-sonnet-4-6` come da spec (centralizzato in una costante; flaggato che l'ID potrebbe essere obsoleto).

## Vincoli critici (dal prompt)
- NESSUNA chiave segreta nel bundle iOS (solo URL + anon key).
- Scope lock: solo ciò che è in features.md/prompt. Niente over-engineering.
- Stop-and-ask prima di: deploy/secrets, modifiche distruttive DB, nuove dipendenze, azioni che richiedono credenziali mancanti.
- UI e messaggi di errore in italiano con i testi esatti di features.md.
- Parsing JSON di Claude IDENTICO a §6.3.
- iOS 26 minimo, solo portrait, MVVM leggera, unica dipendenza SPM `supabase-swift`.

---

## Fase 1 — Backend (Edge Functions)
- [x] 1.1 Ispezione Supabase (tabella, policy, bucket, functions). **Nulla da creare sul DB.**
- [x] 1.2 `supabase/functions/process-link/index.ts` (Jina → Claude → insert service-role)
- [x] 1.3 `supabase/functions/process-screenshot/index.ts` (Claude Vision → upload → insert)
- [x] 1.4 Gestione errori con messaggi italiani riusabili (+ modulo condiviso `_shared/wyn.ts`)
- [x] 1.5 CLI installata (2.109.1), login+link OK, secret OK, **deploy fatto**, **test curl reali OK** (link+screenshot+errori). Note di test ripulite. (Resta un utente auth di test `wyn-test-*@example.com`, innocuo — cancellabile dal dashboard.)

## Fase 2 — Progetto Xcode e fondamenta ✅
- [x] 2.1 Progetto "WYN" (xcodegen, bundle `com.feffo.wyn`, **iOS 26**, portrait)
- [x] 2.2 `supabase-swift` via SPM + SupabaseManager condiviso (URL+anon key pubbliche)
- [x] 2.3 Design system: Asset Catalog 8 token §7 (light/dark) + 7 colori categoria; 3 font Newsreader/Geist/Geist Mono; estensioni Font/Color
- [x] 2.4 Modello `Note` Codable (§3), enum `SourceType`, enum `Category` (nome+colore+icona)
- [x] 2.5 Auth: Login + Registrazione (email/password min 6, messaggi §4), redirect via authStateChanges, logout
- [x] 2.6 **Verifica OK**: build verde 0 warning; login reale end-to-end (feffo-demo@wyn.app); sessione persistita (relaunch resta loggato); dark mode fedele §7

**Nota conflitto risolto:** il prompt dice sia "iOS 26" (architettura_vincolata) sia "iOS 17" (Fase 2.1). Ho scelto **iOS 26** perché è nella sezione "decisioni già prese, non rimetterle in discussione" ed è più specifica; il simulatore usato è iPhone 17 Pro / iOS 26.5.
**Nota debug:** hook `#if DEBUG` con launch arg `-uitest-login` per auto-login in verifica (mai in release).

## Fase 3 — Schermate core ✅
- [x] 3.1 TabView 4 tab (Feed, Cerca, Categorie, Profilo)
- [x] 3.2 Feed (§5.1): masthead, AddBar, chips combinabili, NoteCard, stati elab/errore/vuoto, banner categoria
- [x] 3.3 Dettaglio nota (§5.2): header, punti/tag, apri originale (SafariVC), modifica tag (sheet+normalizzazione), elimina (conferma), condividi (share sheet), immagine screenshot via signed URL
- [x] 3.4 Cerca (§5.3): autofocus, debounce 400ms, filtro client-side su title/source_name/tags/summary_points, contatore
- [x] 3.5 Categorie (§5.4): griglia 2 col, conteggi reali, solo categorie con note, tap → feed filtrato
- [x] 3.6 Profilo (§5.5): header, toggle tema, statistiche reali, export JSON/MD via share sheet, info, logout
- [x] 3.7 **Verifica OK**: build verde 0 warning; navigate tutte le schermate con 4 note reali (Tech/Salute/Finanza/Cucina + screenshot); dark mode fedele §7; immagine screenshot da bucket OK; CTA articolo OK

**Note:** `Category` compila senza collisioni (il warning SourceKit "OpaquePointer" era solo rumore di analisi isolata). Aggiunto `Hashable` a `Note` per navigationDestination. Hook debug `#if DEBUG`: `-uitest-tab`, `-uitest-open`.
**Dati demo:** account `feffo-demo@wyn.app` popolato con 4 note reali via Edge Functions. Le 11 note reali sono di `feffo@feffo.it` (password non disponibile — non resettata).

## Fase 4 — Pipeline di cattura nell'app ✅
- [x] 4.1 AddBar link → process-link via functions.invoke, card in elaborazione (shimmer), ricarica/ErrorCard
- [x] 4.2 Screenshot: bottom sheet Libreria (PHPicker) + Scatta foto (fotocamera nativa, NSCameraUsageDescription IT), compressione on-device 1568px q0.85 (ImageCompressor)
- [x] 4.3 Campo hint opzionale (max 150 char) in entrambi i flussi (HintField)
- [x] 4.4 **Verifica OK**: link reale dall'app (Bauhaus→nota Design completa, card elaborazione vista); screenshot dall'app (compressione+Vision→nota Tech "WWDC 2026"); hint influenza i punti in entrambi. Errori server mappati in italiano.

**Note:** sheet screenshot con hint + 2 opzioni; "Scatta foto" attiva (sul simulatore la fotocamera è unavailable → opzione mostrata disabilitata, da testare su device fisico). Hook debug: `-uitest-savelink`, `-uitest-shotsheet`, `-uitest-saveshot`. Demo account: 6 note (4 articoli + 2 screenshot).

## Fase 5 — Share Extension ✅
- [x] 5.1 Target Share Extension (activation rules: web URL max 1 + immagine max 1); .appex embedded verificato
- [x] 5.2 App Group condiviso (scelta rispetto a Keychain per simulatore senza Team ID): sessione persistita in `AppGroupStorage` dentro group.com.feffo.wyn → estensione riusa la sessione. **Verificato**: file `sb-wyn.session.json` presente nel container condiviso dopo login.
- [x] 5.3 UI minimale (ShareRootView) coerente col design system + anteprima + hint + "Salva in WYN" → ProcessingService (stesso codice già verificato in Fase 4)
- [x] 5.4 Notifica locale al completamento (permesso al primo uso in notifySaved)
- [~] 5.5 **Build entrambi i target OK**. Share da Safari: il tap sullo share sheet NON è automatizzabile via MCP (nessun tap tool) → **test manuale su device/simulatore** documentato in Fase 6.3.

**Note:** storage sessione migrato da Keychain ad AppGroupStorage; login+persistenza dell'app riverificati OK con il nuovo storage. Rimossi gli hook debug one-off (savelink/saveshot/shotsheet/open/tab) e DebugImage.swift; resta solo `-uitest-login`.

## Fase 6 — Rifinitura e checklist di parità ✅
- [x] 6.1 Safe area (ignoresSafeArea+padding), tap target ≥44px (AddBar camera 44×44), Dynamic Type (font relativi), Reduce Motion (shimmer disattivato), haptic success al salvataggio
- [x] 6.2 Checklist di parità (sotto)
- [x] 6.3 Elenco retest iPhone fisico (sotto)

### Checklist di parità (Fase 6.2)
- [x] Login, registrazione, logout, sessione persistente — verificato (login reale, relaunch, storage App Group)
- [x] Feed: masthead, AddBar, chips combinabili, card, stati elaborazione/errore/vuoto — verificato con screenshot
- [x] Link → nota completa (titolo, 3–5 punti, categoria valida, tag, read_time, source_name) — Bauhaus/Swift/ecc.
- [x] Screenshot da libreria E da fotocamera → nota con immagine — libreria+processing verificati; **fotocamera: solo device fisico**
- [x] Hint che influenza i punti chiave — verificato (link + screenshot)
- [x] Dettaglio: azioni tag/elimina, apri originale, condividi — implementati e resi; tag/delete via RLS
- [x] Cerca con debounce e match su tutti i campi — implementato (debounce 400ms, 4 campi); **UI results: test manuale (autofocus+typing)**
- [x] Categorie con conteggi corretti → feed filtrato — verificato con screenshot
- [x] Profilo: statistiche reali, export JSON/Markdown via share sheet, toggle tema — statistiche+toggle verificati
- [~] Share Extension da Safari (link) e da Foto (immagine) — build+embed+session OK; **tap share sheet: device fisico**
- [x] Dark mode fedele ai token §7, tipografia Newsreader/Geist/Geist Mono — verificato light+dark
- [x] Nessuna chiave segreta nel bundle — **verificato** (grep sorgenti + strings sui binari: solo anon key)

### Da ritestare su iPhone fisico (Fase 6.3)
1. **Share Extension**: condividi un link da Safari e un'immagine da Foto → sheet "Salva in WYN" → nota creata + notifica locale.
2. **Fotocamera** ("Scatta foto"): scatto reale → compressione → nota (sul simulatore la fotocamera non esiste).
3. **Galleria** (PHPicker): selezione immagine reale end-to-end (sul simulatore serve tap manuale).
4. **Notifiche**: primo salvataggio dall'extension → richiesta permesso → notifica "Nota salvata".
5. **Cerca**: digitazione con autofocus e debounce, verificare i risultati live.
6. **Haptic**: feedback al salvataggio (non percepibile su simulatore).

Istruzioni: apri Xcode → seleziona il target WYN e un iPhone collegato → imposta il tuo Team di firma (Signing & Capabilities) su entrambi i target WYN e ShareExtension (serve un Apple ID/Team per firmare App Group + extension) → Run.

---

## Review

**Stato finale: app WYN nativa iOS completa e funzionante su simulatore.**

### Cosa è stato costruito
- **Backend**: 2 Supabase Edge Functions (`process-link`, `process-screenshot`) deployate e testate end-to-end (curl + dall'app). Parsing JSON §6.3, messaggi errore IT, insert service-role, upload bucket, Claude Vision prima dell'upload. Chiavi segrete solo come Function secrets.
- **App iOS** (SwiftUI, iOS 26, portrait, MVVM leggera, unica dip. supabase-swift):
  - Auth email/password, sessione persistita (App Group storage), messaggi IT §4.
  - Design system §7: 8 token colore light/dark (Asset Catalog), 7 colori categoria, 3 font (Newsreader/Geist/Geist Mono).
  - 4 tab + dettaglio: Feed (masthead, AddBar, chips combinabili, card, stati), Dettaglio (articolo+screenshot, tag/elimina/condividi/apri originale), Cerca (debounce 400ms, 4 campi), Categorie (conteggi, filtro), Profilo (statistiche reali, export JSON/MD, toggle tema).
  - Pipeline cattura: link + screenshot con compressione on-device (1568px/0.85), hint opzionale, card elaborazione/errore, haptic.
  - Share Extension (URL+immagini), sessione condivisa via App Group, notifica locale.

### Verifiche superate (su simulatore, con dati reali)
Build verde 0 warning (entrambi i target) · login+persistenza · feed con note reali · dettaglio articolo e screenshot (immagine da signed URL) · link e screenshot creati end-to-end dall'app · hint influenza i punti · categorie/statistiche corrette · dark mode fedele · **nessun secret nel bundle** (grep+strings).

### Punti aperti (test manuale su iPhone fisico — vedi Fase 6.3)
Share Extension (tap share sheet), fotocamera, PHPicker interattivo, notifiche, cerca con typing, haptic. Firma: impostare Team Apple su target WYN + ShareExtension.

### Decisioni/note
- iOS 26 (non 17): risolto conflitto interno al prompt a favore di `architettura_vincolata`.
- Session sharing via App Group invece di Keychain access group (funziona su simulatore senza Team ID) — confermato dall'utente.
- `Category` non rinominato: compila senza collisioni (warning SourceKit "OpaquePointer" era rumore).
- Modello AI `claude-sonnet-4-6` come da spec (centralizzato in `_shared/wyn.ts`); flaggato come possibile ID obsoleto ma funziona.
- Cruft residuo (rimuovibile dal dashboard): 2 utenti `wyn-test-*@example.com` (0 note) + eventuale utente di test iniziale.

## Redesign UI (mockup Claude Design) ✅
Piano ed esecuzione: `UI_REDESIGN_PLAN.md` (Task 0–9, 11 commit su `new_features`). Fuori scope: §5 del piano. Screenshot before/after in `tasks/ui-screens/` (non versionati).
