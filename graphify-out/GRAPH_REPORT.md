# Graph Report - WYN_iOS  (2026-09-12)

## Corpus Check
- 101 files · ~54,174 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 734 nodes · 1012 edges · 56 communities (43 shown, 13 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 37 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3b895ba4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ProfileView
- NoteDetailView
- Coordinator
- Category
- Foundation
- ShareRootView
- .layout
- wyn.ts
- AuthViewModel
- SharedContent
- CodingKeys
- §4 — Task eseguibili
- WYNTextField
- Font
- .makeFile
- TagEditorSheet
- ScreenshotSheet
- ItalianDate
- Tab
- WYN — What You've Noted
- FeedStore
- WYN iOS — Piano di ricostruzione nativa
- Piano — Salvataggio note da Instagram via tasto Condividi
- CLAUDE.md
- Note
- SwiftUI
- Task 3a Report — AddBar a due righe
- PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)
- Task 0: Baseline screenshot — Report
- Toolkit di verifica (simulatore) — usato da ogni task
- View
- .chip
- SearchView
- SDD ledger — plan: UI_REDESIGN_PLAN.md
- LoginView
- Task 3b Report: NoteCard (badge tipo fonte, miniatura)
- LoginView
- Color
- task-9-brief.md
- Global Constraints (validi per ogni task)
- task-0-brief.md
- task-1-brief.md
- task-2-brief.md
- task-3a-brief.md
- task-3b-brief.md
- task-3c-brief.md
- task-3d-brief.md
- task-4-brief.md
- task-5-brief.md
- task-6-brief.md
- task-7-brief.md
- task-8-brief.md
- Task 3d Report: Feed vuoto (empty-feed onboarding state)
- SearchView
- Tab
- NoteCard

## God Nodes (most connected - your core abstractions)
1. `View` - 42 edges
2. `SwiftUI` - 27 edges
3. `Note` - 26 edges
4. `Category` - 24 edges
5. `FeedStore` - 19 edges
6. `CodingKeys` - 16 edges
7. `NoteDetailView` - 14 edges
8. `§4 — Task eseguibili` - 14 edges
9. `Coordinator` - 13 edges
10. `Foundation` - 12 edges

## Surprising Connections (you probably didn't know these)
- `RootTabView` --calls--> `FeedStore`  [INFERRED]
  WYN/App/RootTabView.swift → WYN/Features/Feed/FeedStore.swift
- `AuthContainerView` --references--> `View`  [EXTRACTED]
  WYN/Features/Auth/AuthContainerView.swift → WYN/DesignSystem/Font+WYN.swift
- `FeedView` --calls--> `FeedFilter`  [INFERRED]
  WYN/Features/Feed/FeedView.swift → WYN/Features/Feed/FilterChips.swift
- `FeedView` --calls--> `ProcessingService`  [INFERRED]
  WYN/Features/Feed/FeedView.swift → WYN/Services/ProcessingService.swift
- `NoteCard` --calls--> `NotesService`  [INFERRED]
  WYN/Features/Feed/NoteCard.swift → WYN/Services/NotesService.swift

## Import Cycles
- None detected.

## Communities (56 total, 13 thin omitted)

### Community 0 - "ProfileView"
Cohesion: 0.27
Nodes (7): ProfileView, StatTile, Bool, Int, String, URL, Void

### Community 1 - "NoteDetailView"
Cohesion: 0.22
Nodes (8): Build, Commit, Concerns, Files changed, Implemented, Self-review, Smoke test, Task 4 Report — Dettaglio nota

### Community 2 - "Coordinator"
Cohesion: 0.08
Nodes (25): NSObject, PhotosUI, PHPickerResult, PHPickerViewController, PHPickerViewControllerDelegate, SafariServices, SFSafariViewController, UIActivityViewController (+17 more)

### Community 3 - "Category"
Cohesion: 0.08
Nodes (29): Codable, Equatable, Hashable, Identifiable, Sendable, NoteDetailView, Any, String (+21 more)

### Community 4 - "Foundation"
Cohesion: 0.11
Nodes (14): AuthLocalStorage, Foundation, Supabase, ItalianDate, String, Date, String, String (+6 more)

### Community 5 - "ShareRootView"
Cohesion: 0.13
Nodes (16): Decodable, UserNotifications, NoteIdResponse, ProcessingFailure, ProcessingService, Data, String, SupabaseClient (+8 more)

### Community 6 - ".layout"
Cohesion: 0.16
Nodes (15): CGRect, CGSize, Layout, ProposedViewSize, Subviews, FlowLayout, Row, RowItem (+7 more)

### Community 7 - "wyn.ts"
Cohesion: 0.22
Nodes (17): AnalysisResult, analyzeArticle(), analyzeScreenshot(), AnthropicContentBlock, callAnthropic(), CATEGORIES, CORS_HEADERS, ERR (+9 more)

### Community 8 - "AuthViewModel"
Cohesion: 0.08
Nodes (21): App, ColorScheme, Error, LocalizedError, Scene, User, Mode, dark (+13 more)

### Community 9 - "SharedContent"
Cohesion: 0.10
Nodes (17): UIKit, UIViewController, UniformTypeIdentifiers, Haptics, ScreenshotSheet, Bool, String, UIImage (+9 more)

### Community 10 - "CodingKeys"
Cohesion: 0.06
Nodes (38): CaseIterable, CodingKey, String, CategoriesView, CategoryTile, Int, Void, FeedFilter (+30 more)

### Community 11 - "§4 — Task eseguibili"
Cohesion: 0.05
Nodes (42): §0 — Stato, 1.1 Design system (`WYN/DesignSystem/`, `WYN/Resources/`), 1.2 Shell app, 1.3 Auth (non nel mockup → invariata, eredita solo i nuovi token), 1.4 Feed, 1.5 Dettaglio nota (`Features/Detail/`), 1.6 Cerca (`Features/Search/SearchView.swift`), 1.7 Categorie (`Features/Categories/CategoriesView.swift`) (+34 more)

### Community 12 - "WYNTextField"
Cohesion: 0.18
Nodes (12): ButtonStyle, TextInputAutocapitalization, UIKeyboardType, UITextContentType, CategoryBadge, HighlightField, PrimaryButtonStyle, SourceTypeBadge (+4 more)

### Community 13 - "Font"
Cohesion: 0.29
Nodes (5): ViewModifier, Font, MonoLabel, CGFloat, Content

### Community 14 - ".makeFile"
Cohesion: 0.27
Nodes (6): Format, json, markdown, NoteExporter, String, URL

### Community 15 - "TagEditorSheet"
Cohesion: 0.33
Nodes (5): FlowTags, String, Void, TagEditorSheet, TagNormalizer

### Community 16 - "ScreenshotSheet"
Cohesion: 0.11
Nodes (17): Build, Build, Commit, Commit, Concerns, Concerns, Files changed, Files changed (+9 more)

### Community 17 - "ItalianDate"
Cohesion: 0.17
Nodes (11): 1. Export JSON/Markdown: sheet di condivisione vuota (da investigare, non del redesign), 2. Normalizzazione tag: nessun bug (falso allarme iniziale), Build, File screenshot generati (tasks/ui-screens/, non versionati), Potenziali problemi/bug trovati, Riepilogo, Step 1 — Regressione visiva, Step 2 — Regressione funzionale (account demo) (+3 more)

### Community 18 - "Tab"
Cohesion: 0.25
Nodes (7): Build command and filtered output, Commit, Concerns, Files changed, Self-review findings, Task 2 Report: Componenti condivisi, What was implemented

### Community 19 - "WYN — What You've Noted"
Cohesion: 0.05
Nodes (38): 10. Limitazioni note e stato, 11. Checklist minima per replicare da zero, 1. Cos'è WYN, 2. Stack attuale (versione web / PWA), 3. Modello dati, 4. Autenticazione, 5.1 Feed (`/feed`) — home, 5.2 Dettaglio nota (`/nota/[id]`) (+30 more)

### Community 20 - "FeedStore"
Cohesion: 0.33
Nodes (5): ErrorCard, ProcessingCard, Int, String, Void

### Community 21 - "WYN iOS — Piano di ricostruzione nativa"
Cohesion: 0.11
Nodes (18): Checklist di parità (Fase 6.2), Cosa è stato costruito, Da ritestare su iPhone fisico (Fase 6.3), Decisioni confermate dall'utente, Decisioni/note, Fase 1 — Backend (Edge Functions), Fase 2 — Progetto Xcode e fondamenta ✅, Fase 3 — Schermate core ✅ (+10 more)

### Community 22 - "Piano — Salvataggio note da Instagram via tasto Condividi"
Cohesion: 0.12
Nodes (16): 0. Premessa: cosa esiste già (verificato nel codice), 1. Decisioni prese (confermate dall'utente), 2. Architettura della soluzione, 3. Fasi di implementazione, 4. Riepilogo file toccati, 5. Cosa questo piano NON fa (e perché), 6. Rischi, 7. Prossimo passo (+8 more)

### Community 23 - "CLAUDE.md"
Cohesion: 0.13
Nodes (13): 1. Think Before Coding, 2. Simplicity First, 3. Surgical Changes, 4. Goal-Driven Execution, 5.1 Plan Mode, 5.2 Subagent Strategy, 5.3 Self-Improvement Loop, 5.4 Verification Before Done (+5 more)

### Community 24 - "Note"
Cohesion: 0.14
Nodes (8): SwiftUI, AuthContainerView, AuthScaffold, Content, String, RegisterView, Bool, String

### Community 25 - "SwiftUI"
Cohesion: 0.40
Nodes (4): AddBar, Bool, String, Void

### Community 26 - "Task 3a Report — AddBar a due righe"
Cohesion: 0.22
Nodes (8): Build, Commit, Concerns, Files changed, Self-review findings, Smoke test (step by step), Task 3a Report — AddBar a due righe, What was implemented

### Community 27 - "PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)"
Cohesion: 0.25
Nodes (7): Fase 1 — Backend (Edge Functions), Fase 2 — Progetto Xcode e fondamenta, Fase 3 — Schermate core, Fase 4 — Pipeline di cattura nell'app, Fase 5 — Share Extension, Fase 6 — Rifinitura e checklist di parità, PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)

### Community 28 - "Task 0: Baseline screenshot — Report"
Cohesion: 0.25
Nodes (7): Build result, Navigation notes (coordinates/commands that worked, in the 402×874-pt accessibility coordinate space; screenshots are 1206×2622 px, i.e. 3x scale), Per-screen description (verified by reading the PNGs), Problems encountered, Screenshots captured (14/14), Task 0: Baseline screenshot — Report, Verification

### Community 29 - "Toolkit di verifica (simulatore) — usato da ogni task"
Cohesion: 0.22
Nodes (8): Automazione UI (tap, testo, swipe): binario `axe`, Build (0 warning attesi), Coordinate note (dal Task 0, spazio punti 402×874; gli screenshot sono 1206×2622 px = 3x), Inserire un URL (dal Task 3a): `axe type` storpia `://` in `ç--`, Installa e avvia con auto-login demo, Regole, Tema e screenshot, Toolkit di verifica (simulatore) — usato da ogni task

### Community 30 - "View"
Cohesion: 0.22
Nodes (8): Build, Commit, Concerns, Files changed, Self-review findings, Smoke test, Task 3c Report: Card in arrivo ed errore (processing card + error card), What was implemented

### Community 31 - ".chip"
Cohesion: 0.12
Nodes (15): Build (comando esatto dal toolkit), Build ShareExtension (stesso comando, scheme `ShareExtension`), Build WYN (comando esatto dal toolkit), Colorset count, Commit, Concern (per decisione del controller), Cosa ho cambiato, Cosa ho implementato (+7 more)

### Community 32 - "SearchView"
Cohesion: 0.22
Nodes (8): Build, Commit, Concerns, Files changed, Self-review, Smoke test (simulator iPhone 17 Pro / iOS 26.5, demo account), Task 5: Cerca — Report, What was implemented

### Community 33 - "SDD ledger — plan: UI_REDESIGN_PLAN.md"
Cohesion: 0.40
Nodes (4): Avanzamento, Preflight — rulings di setup, Preflight — scansione conflitti (fatta prima del Task 1), SDD ledger — plan: UI_REDESIGN_PLAN.md

### Community 34 - "LoginView"
Cohesion: 0.20
Nodes (9): Build, Commit, Concerns, Files changed, Grep result, Self-review findings, Smoke test — step by step, Task 8 Report: Sheet screenshot (+1 more)

### Community 36 - "Task 3b Report: NoteCard (badge tipo fonte, miniatura)"
Cohesion: 0.17
Nodes (11): 1. Feed — screenshot light/dark, 2. Tap card → dettaglio → back, 3. Pull-to-refresh, Comando di build + output filtrato, Commit, Concerns, Cosa è stato implementato, File modificati (+3 more)

### Community 37 - "LoginView"
Cohesion: 0.40
Nodes (3): LoginView, Bool, String

### Community 38 - "Color"
Cohesion: 0.21
Nodes (7): Configuration, LaunchView, RootView, Color, View, CGFloat, String

### Community 39 - "task-9-brief.md"
Cohesion: 0.50
Nodes (3): §5 — Fuori scope (follow-up separati, cambiano funzionalità), Self-review (fatto il 2026-09-12), Task 9: Verifica finale e chiusura

### Community 53 - "Task 3d Report: Feed vuoto (empty-feed onboarding state)"
Cohesion: 0.18
Nodes (10): Build, Commit, Concerns, Files changed, Integration with existing structure, Self-review, Smoke test (step by step), Status: DONE (+2 more)

### Community 56 - "SearchView"
Cohesion: 0.16
Nodes (14): AttributedString, highlighted(), ResultCard, SearchMatch, keyPoint, source, tag, title (+6 more)

### Community 57 - "Tab"
Cohesion: 0.33
Nodes (6): RootTabView, Tab, categories, feed, profile, search

### Community 59 - "NoteCard"
Cohesion: 0.50
Nodes (4): NoteCard, String, URL, TagRow

## Knowledge Gaps
- **292 isolated node(s):** `feed`, `search`, `categories`, `profile`, `system` (+287 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftUI` connect `Note` to `ProfileView`, `Coordinator`, `Category`, `LoginView`, `Color`, `.layout`, `AuthViewModel`, `SharedContent`, `CodingKeys`, `ShareRootView`, `WYNTextField`, `Font`, `TagEditorSheet`, `FeedStore`, `SearchView`, `Tab`, `NoteCard`, `SwiftUI`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Why does `View` connect `Color` to `ProfileView`, `Category`, `LoginView`, `ShareRootView`, `SharedContent`, `CodingKeys`, `WYNTextField`, `Font`, `TagEditorSheet`, `FeedStore`, `Note`, `Tab`, `SearchView`, `NoteCard`, `SwiftUI`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `AuthViewModel`, `Category`, `ShareRootView`, `.makeFile`?**
  _High betweenness centrality (0.049) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `FeedStore` (e.g. with `RootTabView` and `NotesService`) actually correct?**
  _`FeedStore` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `feed`, `search`, `categories` to the rest of the system?**
  _292 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Coordinator` be split into smaller, more focused modules?**
  _Cohesion score 0.08170731707317073 - nodes in this community are weakly interconnected._
- **Should `Category` be split into smaller, more focused modules?**
  _Cohesion score 0.07541478129713423 - nodes in this community are weakly interconnected._