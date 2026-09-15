# Graph Report - WYN_iOS  (2026-09-15)

## Corpus Check
- 91 files · ~49,825 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 681 nodes · 1001 edges · 51 communities (44 shown, 7 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 39 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `62aea86e`
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
- NoteDetailView
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
8. `SearchView` - 14 edges
9. `§4 — Task eseguibili` - 14 edges
10. `Coordinator` - 13 edges

## Surprising Connections (you probably didn't know these)
- `RootTabView` --calls--> `FeedStore`  [INFERRED]
  WYN/App/RootTabView.swift → WYN/Features/Feed/FeedStore.swift
- `AuthContainerView` --references--> `View`  [EXTRACTED]
  WYN/Features/Auth/AuthContainerView.swift → WYN/DesignSystem/Font+WYN.swift
- `NoteDetailView` --calls--> `NotesService`  [INFERRED]
  WYN/Features/Detail/NoteDetailView.swift → WYN/Services/NotesService.swift
- `FeedStore` --calls--> `NotesService`  [INFERRED]
  WYN/Features/Feed/FeedStore.swift → WYN/Services/NotesService.swift
- `FeedView` --calls--> `FeedFilter`  [INFERRED]
  WYN/Features/Feed/FeedView.swift → WYN/Features/Feed/FilterChips.swift

## Import Cycles
- None detected.

## Communities (51 total, 7 thin omitted)

### Community 0 - "ProfileView"
Cohesion: 0.23
Nodes (10): LaunchView, RootView, View, ProfileView, StatTile, Bool, Int, String (+2 more)

### Community 1 - "NoteDetailView"
Cohesion: 0.13
Nodes (14): §0 — Decisioni di design (approvate), §1 — Stato di partenza (verificato il 2026-09-15), §2 — File toccati, §3 — Rischi e note per chi esegue, Comandi di verifica riusati dai task, Global Constraints (validi per ogni task), Task 1: Migrazione DB — colonna `embedding` e funzione `match_notes`, Task 2: Helper embedding in `_shared/wyn.ts` + calcolo alla creazione nota (+6 more)

### Community 2 - "Coordinator"
Cohesion: 0.09
Nodes (24): NSObject, PhotosUI, PHPickerResult, PHPickerViewController, PHPickerViewControllerDelegate, SFSafariViewController, UIActivityViewController, UIImagePickerController (+16 more)

### Community 3 - "Category"
Cohesion: 0.22
Nodes (11): Equatable, Identifiable, FeedStore, ProcessingError, ProcessingItem, String, UUID, FeedView (+3 more)

### Community 4 - "Foundation"
Cohesion: 0.13
Nodes (14): AuthLocalStorage, Decodable, Double, Foundation, Supabase, String, AppGroupStorage, Data (+6 more)

### Community 5 - "ShareRootView"
Cohesion: 0.13
Nodes (16): UserNotifications, NoteIdResponse, ProcessingFailure, ProcessingService, Data, String, SupabaseClient, UIImage (+8 more)

### Community 6 - ".layout"
Cohesion: 0.16
Nodes (15): CGRect, CGSize, Layout, ProposedViewSize, Subviews, FlowLayout, Row, RowItem (+7 more)

### Community 7 - "wyn.ts"
Cohesion: 0.18
Nodes (23): backfillMissingEmbeddings(), AnalysisResult, analyzeArticle(), analyzeScreenshot(), AnthropicContentBlock, callAnthropic(), CATEGORIES, CORS_HEADERS (+15 more)

### Community 8 - "AuthViewModel"
Cohesion: 0.08
Nodes (21): App, ColorScheme, Error, LocalizedError, Scene, User, Mode, dark (+13 more)

### Community 9 - "SharedContent"
Cohesion: 0.19
Nodes (10): UIViewController, UniformTypeIdentifiers, SharedContent, image, link, ShareViewController, Any, String (+2 more)

### Community 10 - "CodingKeys"
Cohesion: 0.13
Nodes (15): CodingKey, CodingKeys, category, createdAt, id, imagePaths, readTimeLabel, sourceName (+7 more)

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
Cohesion: 0.18
Nodes (5): NotesService, String, SupabaseClient, URL, UUID

### Community 17 - "ItalianDate"
Cohesion: 0.14
Nodes (13): Caso anomalo: «come risparmiare», Commit, Deploy e conferma finale (MIN_SIMILARITY = 0.4), Falsi positivi interni alle query rilevanti (a soglia 0.40), I due numeri chiave, Mappa id → titolo (note demo), Note operative, Procedura seguita (+5 more)

### Community 18 - "Tab"
Cohesion: 0.19
Nodes (9): FeedFilter, FilterChips, Kind, all, article, screenshot, Bool, String (+1 more)

### Community 19 - "WYN — What You've Noted"
Cohesion: 0.05
Nodes (38): 10. Limitazioni note e stato, 11. Checklist minima per replicare da zero, 1. Cos'è WYN, 2. Stack attuale (versione web / PWA), 3. Modello dati, 4. Autenticazione, 5.1 Feed (`/feed`) — home, 5.2 Dettaglio nota (`/nota/[id]`) (+30 more)

### Community 20 - "FeedStore"
Cohesion: 0.17
Nodes (8): Configuration, Color, ErrorCard, ProcessingCard, CGFloat, Int, String, Void

### Community 21 - "WYN iOS — Piano di ricostruzione nativa"
Cohesion: 0.08
Nodes (24): Checklist di parità (Fase 6.2), Cosa è stato costruito, Cosa è stato costruito, Da ritestare su iPhone fisico (Fase 6.3), Decisioni confermate dall'utente, Decisioni/note, Decisioni prese, Fase 1 — Backend (Edge Functions) (+16 more)

### Community 22 - "Piano — Salvataggio note da Instagram via tasto Condividi"
Cohesion: 0.12
Nodes (16): 0. Premessa: cosa esiste già (verificato nel codice), 1. Decisioni prese (confermate dall'utente), 2. Architettura della soluzione, 3. Fasi di implementazione, 4. Riepilogo file toccati, 5. Cosa questo piano NON fa (e perché), 6. Rischi, 7. Prossimo passo (+8 more)

### Community 23 - "CLAUDE.md"
Cohesion: 0.13
Nodes (13): 1. Think Before Coding, 2. Simplicity First, 3. Surgical Changes, 4. Goal-Driven Execution, 5.1 Plan Mode, 5.2 Subagent Strategy, 5.3 Self-Improvement Loop, 5.4 Verification Before Done (+5 more)

### Community 24 - "Note"
Cohesion: 0.13
Nodes (8): SwiftUI, AuthContainerView, LoginView, Bool, String, RegisterView, Bool, String

### Community 25 - "SwiftUI"
Cohesion: 0.40
Nodes (4): AddBar, Bool, String, Void

### Community 26 - "Task 3a Report — AddBar a due righe"
Cohesion: 0.17
Nodes (11): Commit, Concerns, Cosa è stato implementato, `deno check`, Deploy, File modificati/creati, Installazione deno, Self-review (+3 more)

### Community 27 - "PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)"
Cohesion: 0.25
Nodes (7): Fase 1 — Backend (Edge Functions), Fase 2 — Progetto Xcode e fondamenta, Fase 3 — Schermate core, Fase 4 — Pipeline di cattura nell'app, Fase 5 — Share Extension, Fase 6 — Rifinitura e checklist di parità, PROMPT — WYN nativo iOS (per Opus 4.8 in Claude Code)

### Community 28 - "Task 0: Baseline screenshot — Report"
Cohesion: 0.25
Nodes (10): Codable, Hashable, Sendable, String, Note, SourceType, article, screenshot (+2 more)

### Community 29 - "Toolkit di verifica (simulatore) — usato da ogni task"
Cohesion: 0.18
Nodes (10): Backfill verification, Concerns, curl verification (verbatim), `deno check` output, Deploy output, Files changed, graphify, Self-review findings (+2 more)

### Community 30 - "View"
Cohesion: 0.22
Nodes (9): CaseIterable, Category, altro, business, cucina, design, finanza, salute (+1 more)

### Community 31 - ".chip"
Cohesion: 0.22
Nodes (8): Chiamate MCP effettuate e risultati, Commit, Cosa ho implementato, File modificati, Ispezione pre-migrazione, Preoccupazioni, Self-review, Task 1 Report: Migrazione DB — colonna `embedding` e funzione `match_notes`

### Community 32 - "SearchView"
Cohesion: 0.22
Nodes (8): Build (Step 3), Concerns, Files changed, Self-review, Smoke test (Step 4), Status: DONE, Task 5 Report — NotesService.semanticMatches e colonne esplicite, What was implemented

### Community 33 - "SDD ledger — plan: UI_REDESIGN_PLAN.md"
Cohesion: 0.25
Nodes (7): Build (Step 8), Concerns, Files changed, Self-review, Smoke test (Step 9, with controller's substitutions), Task 6 Report — iOS SearchView ibrida, stati, copy, What was implemented

### Community 34 - "LoginView"
Cohesion: 0.39
Nodes (4): ItalianDate, String, Date, String

### Community 35 - "NoteDetailView"
Cohesion: 0.29
Nodes (4): NoteDetailView, Any, String, URL

### Community 36 - "Task 3b Report: NoteCard (badge tipo fonte, miniatura)"
Cohesion: 0.29
Nodes (3): SafariServices, UIKit, Haptics

### Community 37 - "LoginView"
Cohesion: 0.48
Nodes (5): ScreenshotSheet, Bool, String, UIImage, Void

### Community 38 - "Color"
Cohesion: 0.50
Nodes (4): CategoriesView, CategoryTile, Int, Void

### Community 39 - "task-9-brief.md"
Cohesion: 0.50
Nodes (3): Preflight scan (2026-09-15), SDD ledger — plan: SEMANTIC_SEARCH_PLAN.md, Task log

### Community 40 - "Global Constraints (validi per ogni task)"
Cohesion: 0.50
Nodes (3): AuthScaffold, Content, String

### Community 56 - "SearchView"
Cohesion: 0.11
Nodes (21): AttributedString, highlighted(), ResultCard, SearchMatch, keyPoint, semantic, source, tag (+13 more)

### Community 57 - "Tab"
Cohesion: 0.33
Nodes (6): RootTabView, Tab, categories, feed, profile, search

### Community 59 - "NoteCard"
Cohesion: 0.50
Nodes (4): NoteCard, String, URL, TagRow

## Knowledge Gaps
- **247 isolated node(s):** `feed`, `search`, `categories`, `profile`, `system` (+242 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `ProfileView` to `NoteDetailView`, `Category`, `LoginView`, `Color`, `ShareRootView`, `Global Constraints (validi per ogni task)`, `WYNTextField`, `Font`, `TagEditorSheet`, `Tab`, `FeedStore`, `Note`, `Tab`, `SearchView`, `NoteCard`, `SwiftUI`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `Note` to `ProfileView`, `Coordinator`, `ShareRootView`, `.layout`, `AuthViewModel`, `SharedContent`, `WYNTextField`, `Font`, `TagEditorSheet`, `Tab`, `FeedStore`, `SwiftUI`, `NoteDetailView`, `Task 3b Report: NoteCard (badge tipo fonte, miniatura)`, `Color`, `Global Constraints (validi per ogni task)`, `SearchView`, `Tab`, `NoteCard`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `LoginView`, `Category`, `ShareRootView`, `AuthViewModel`, `.makeFile`, `Task 0: Baseline screenshot — Report`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `FeedStore` (e.g. with `RootTabView` and `NotesService`) actually correct?**
  _`FeedStore` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `feed`, `search`, `categories` to the rest of the system?**
  _247 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `NoteDetailView` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `Coordinator` be split into smaller, more focused modules?**
  _Cohesion score 0.08636977058029689 - nodes in this community are weakly interconnected._