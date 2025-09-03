# ComicSmith — Implementation Plan (`plan.md`)

**Version:** 0.2 MVP scope • Builds on `architecture.md` and the demo scaffolds  
**Primary Targets:** Real Gemini integrations, persistence, image caching, full script parser, exports, settings, QA

---

## 0) Scope & Non‑Goals

### In‑Scope (0.2)
- Real **Gemini Flash 2.5 (text)** client with tool‑calling and system primer.
- Real **Gemini Flash 2.5 Image** client with queued generation + caching by content hash.
- Disk **persistence** (YAML/JSON) + autosave; project open/save flows.
- **Script parser** (full surface) + deterministic formatter; renumber preview and atomic Undo.
- **Exports**: Markdown + PDF (script), optional contact sheet; Bible export (Markdown).
- **Settings UI**: API keys (Keychain), balloon budget, style seed, image concurrency, privacy mode.
- **Continuity**: keep lean rules; batch recompute; per‑panel badges.
- **Testing/Perf**: unit/integration/UI snapshot; perf budget validation.

### Not in 0.2
- Final art/lettering; multi‑user collaboration; advanced continuity exceptions UI; analytics/telemetry.

---

## 1) Milestones & Deliverables

### M0 — Repo hygiene & scaffolds hardening
**Tasks**
1. Promote `ComicSmithCore` to a top‑level package; ensure semantic versioning.
2. Create a macOS **App target** that depends on `ComicSmithCore` (the demo remains as a sample).
3. Add SwiftLint/SwiftFormat; basic CI (build + unit tests).

**Acceptance**
- CI green on main; sample app launches; core package compiles alone.

---

### M1 — Persistence & Project Lifecycle
**Tasks**
1. Define **file schema** (YAML default; JSON fallback): `issue.yaml`, `pages/page_###.yaml`, `bible/*.yaml`.
2. Implement `PersistenceService`:
   - `loadProject(at:)` → `Issue + References`
   - `saveProject(to:)` (atomic writes; temp → replace)
   - `autosave` (debounced on mutation)
3. Wire **Open/Save/Save As** menus; recent documents.
4. Migrate demo state to disk on first save; handle missing/invalid files gracefully.
5. Unit tests: round‑trip encode/decode; corruption recovery.

**Acceptance**
- Create/Open/Save/Autosave work; project folder on disk matches schema; tests pass.

**Dependencies**
- Model stable; no Gemini needed.

---

### M2 — Gemini Flash 2.5 (Text) Integration
**Tasks**
1. Implement `RealGeminiClient` (text):
   - REST/gRPC client per provider SDK.
   - Messages: prepend **STATE_SUMMARY**, **SystemPrimer**, **ToolSchema**; retain last N.
   - Function calling → `ToolRegistry.invoke`.
2. **Error handling**: retries (idempotent), timeouts, network errors → assistant text.
3. Settings: API key storage in **Keychain**; temperature, safety toggles.
4. Telemetry OFF; local logs (debug level).
5. Unit: mock transport; ensure tool call JSON is validated; deterministic packing.

**Acceptance**
- Chat drives tool calls in all modes; errors surface clearly; Keychain persists key.

**Dependencies**
- Tool surface stable; state summary builder available.

---

### M3 — Gemini Flash 2.5 Image + ImageGenQueue
**Tasks**
1. Implement `ImageGenQueue` (prod):
   - Concurrency limit; bounded retry w/ backoff; cancellation on app quit.
   - Compute **content hash** from panel/reference/page; dedupe identical jobs.
   - Write outputs to `assets/` with `{id}-{hash}.png`; maintain “latest” symlink/index.
2. Implement `GeminiImageClient` (image):
   - Prompt templates for **low‑fi** (page) & **medium‑fi** (panel/ref).
   - No dialogue; include style seed + references.
3. UI hooks:
   - Page/Panel/Reference overlays show **Generating…**, then refresh when image lands.
   - Toolbar counter: `Images: n in progress`.
4. Settings: max parallel jobs; queue visibility toggle (dev only).
5. Unit: hash stability; queue dedupe; error surfaces.

**Acceptance**
- Regenerate thumbnails/roughs produces files and visible progress; dialogue‑only changes do not enqueue.

**Dependencies**
- Persistence ready for assets; references linkages present.

---

### M4 — Script Parser + Formatter (Full Surface)
**Tasks**
1. Grammar support:
   - `Page N (K Panels)`
   - `Panel i: Description…`
   - `Dialogue (Name): …`, `Thought (Name): …`, `Caption: …`, `SFX: …`
2. Parser produces **mutation plan** (insert pages/panels; edit; renumber).
3. **Renumber preview** sheet: side‑by‑side old vs new; confirm/Cancel.
4. **Atomic Undo**: group all mutations from a single apply.
5. Formatter: deterministic, id‑stable output; round‑trip without loss.
6. Unit tests: fixtures for inserts, deletes, balloon reorders; idempotence under format/parse.

**Acceptance**
- Editing Script updates model precisely; renumber preview works; Undo restores previous state exactly.

**Dependencies**
- ModelController ops complete; UI hook in ScriptView.

---

### M5 — Content Modes Polish
**Tasks**
1. **Issue Mode**: board view w/ grid thumbnails; drag reorder (ghost preview).
2. **Page Mode**: drag reorder panels; chips + ⚠ remain; layout preset switcher.
3. **Panel Mode**: balloon reorder (drag); tail handles (stub); right‑click menu parity.
4. **References**: All + Detail as shipped; add “introduced page” validator and usage links.
5. Mode transitions respect **no panel editing** in Page Mode.

**Acceptance**
- Drag interactions are smooth; warnings and chips consistent; context menus stable.

**Dependencies**
- Images available (M3) for thumbnails; parser (M4) independent.

---

### M6 — Exports
**Tasks**
1. **Markdown**: script export; optional **contact sheet** (thumb gallery).
2. **PDF**: script export using **PDFKit** (page headers, clean line breaks); contact sheet PDF.
3. **Bible**: Characters/Locations/Props summary (Markdown; basic PDF optional).
4. Export settings: include page titles; include warnings (optional footnotes).
5. Integration tests: exported files open; regression snapshot tests on text.

**Acceptance**
- Exports write to `/exports`; results match fixtures; PDFs open in Preview.

**Dependencies**
- Formatter complete; image cache for contact sheet.

---

### M7 — Settings & Privacy
**Tasks**
1. Settings window:
   - API keys (Keychain)
   - Balloon budget (global default)
   - Style seed
   - Image concurrency
   - Offline/Privacy mode (disables network; hides “Generating…”).
2. Per‑project overrides: balloon budget, style seed.
3. Validation and inline help.

**Acceptance**
- Settings persist; offline mode blocks calls gracefully; UI reflects states.

**Dependencies**
- Gemini clients (M2, M3).

---

### M8 — Continuity (Lean) & Sweep
**Tasks**
1. Keep demo rules; factor into `ContinuityService`:
   - Appears before introduction
   - Dead/destroyed contradictions
   - Cracked vs “intact” lexical check
2. Background **sweep** at intervals or on demand; cache per panel.
3. UI: badges + list under panel (first two lines + “… N more”).
4. Unit tests: target each rule; false positive minimization.

**Acceptance**
- Sweep runs fast on 300 panels; badges accurate; toggling ref “introduced page” updates warnings.

**Dependencies**
- References and model stable.

---

### M9 — Testing, Perf, CI
**Tasks**
1. Unit tests: parser, continuity, hash, persistence.
2. Integration: chat tool calls mutate model; undo groups; exports.
3. UI snapshot: Issue/Page/Panel views with fixtures.
4. Perf harness: synthetic issue (50 pages, 300 panels) — measure render & parse times.
5. CI: run tests on PR; artifact exports for manual QA.

**Acceptance**
- All tests pass; perf within target (see architecture.md §7).

**Dependencies**
- All features landed; scaffolds created in M0.

---

### M10 — Packaging, Signing, Distribution
**Tasks**
1. Create macOS **App project** (bundle) with App Sandbox.
2. Code sign + Notarize (Developer ID); export `.dmg` or `.pkg`.
3. First‑run experience: create project, add API keys, sample series.
4. Crash logs via Apple default; analytics OFF.

**Acceptance**
- Signed app installs, launches, opens/saves, exports; security prompts OK.

**Dependencies**
- Settings & Keychain done; persistence done.

---

## 2) Detailed Task Breakdown (Engineering Tickets)

Below, each item lists **owner**, **deps**, **acceptance**.

### PERS‑01: Persistence types & adapters
- **Owner:** Core
- **Deps:** Model
- **Tasks:** Define Codable structs for page/ref YAML; implement YAML/JSON adapters; data migration hooks.
- **Acceptance:** Round‑trip fixtures pass.

### PERS‑02: Autosave & atomic writes
- **Owner:** Core
- **Deps:** PERS‑01
- **Tasks:** Debounced autosave; write to temp; replace original; backup retention (N=3).
- **Acceptance:** No data loss on crash simulation.

### GEM‑01: RealGeminiClient (text)
- **Owner:** Platform
- **Deps:** CHAT‑01
- **Tasks:** Implement generate(messages:tools:); retries; error surfacing.
- **Acceptance:** Tool calls execute end‑to‑end in Issue/Page/Panel/Refs.

### CHAT‑01: Message packer
- **Owner:** Core
- **Deps:** Model, SystemPrimer
- **Tasks:** Build `STATE_SUMMARY` (compact); include focused page/panel; include allowed ops by mode.
- **Acceptance:** Summary < 2KB; correct IDs and counts.

### IMG‑01: ImageGenQueue
- **Owner:** Platform
- **Deps:** Cache key spec
- **Tasks:** Concurrent jobs; disk writes; completion publish; dedupe; error handling.
- **Acceptance:** Thumbnails/roughs write to `assets/`; overlays update.

### IMG‑02: GeminiImageClient
- **Owner:** Platform
- **Deps:** IMG‑01
- **Tasks:** Implement prompts; transport; map responses to files.
- **Acceptance:** Valid images generated with deterministic naming.

### SCR‑01: Script formatter
- **Owner:** Core
- **Deps:** Model
- **Tasks:** Deterministic text projection; IDs preserved; lines wrapped.
- **Acceptance:** Matches fixtures; stable across runs.

### SCR‑02: Script parser (delta plan)
- **Owner:** Core
- **Deps:** SCR‑01
- **Tasks:** Tokenizer; mutation plan; renumber preview; atomic apply.
- **Acceptance:** All grammar features supported; Undo exact.

### UI‑ISS‑01: Issue board w/ grid
- **Owner:** UI
- **Deps:** IMG‑01
- **Tasks:** Grid layout; drag reorder; page context menu.
- **Acceptance:** Smooth drag; thumbnails refresh; keyboard support optional.

### UI‑PAGE‑01: Panels board polish
- **Owner:** UI
- **Deps:** IMG‑01
- **Tasks:** Drag reorder with ghost; layout preset switcher; regenerate button.
- **Acceptance:** No panel editing exposed in Page Mode.

### UI‑PAN‑01: Panel view polish
- **Owner:** UI
- **Deps:** SCR‑02
- **Tasks:** Balloon reorder via drag; tail anchors (stub); right‑click parity.
- **Acceptance:** Balloons reorder correctly; order exported.

### UI‑REF‑01: References polish
- **Owner:** UI
- **Deps:** PERS‑01
- **Tasks:** Search, sort, usage badges; “introduced page” validator; jump links.
- **Acceptance:** Edits persist; usage counts accurate.

### EXP‑01: Markdown exporter
- **Owner:** Core
- **Deps:** SCR‑01
- **Tasks:** Write script to `/exports`; include options.
- **Acceptance:** Exports match fixtures; opens in editors.

### EXP‑02: PDF exporter
- **Owner:** Core
- **Deps:** EXP‑01
- **Tasks:** PDFKit layout; fonts; headers; page breaks.
- **Acceptance:** PDFs open in Preview; layout consistent.

### CFG‑01: Settings UI
- **Owner:** UI
- **Deps:** Keychain
- **Tasks:** Build panes; bind to `UserDefaults` + Keychain; per‑project overrides.
- **Acceptance:** Settings persisted; toggles reflect state.

### QA‑01: Unit tests
- **Owner:** QA/Core
- **Deps:** All modules
- **Tasks:** Parser, continuity, persistence, hash tests.
- **Acceptance:** 90%+ coverage on core logic.

### QA‑02: Integration & UI snapshots
- **Owner:** QA/UI
- **Deps:** UI modules
- **Tasks:** End‑to‑end tool call flows; snapshot views with fixtures.
- **Acceptance:** Baselines approved; CI stable.

### REL‑01: Packaging & signing
- **Owner:** Platform
- **Deps:** M7
- **Tasks:** App target; signing; notarization; DMG.
- **Acceptance:** Install & run on clean macOS.

---

## 3) Cross‑Cutting Concerns

- **Undo/Redo:** Tool mutations and Script applies grouped; test for nested sequences.
- **Threading:** Model on main; queues off main; `@MainActor` for UI publishes.
- **Error Surface:** Human‑readable assistant messages; no stack traces to user.
- **IDs:** Never synthesized in the assistant; app generates; tools return them.
- **Accessibility:** Labels for chips, warnings, buttons; large text mode tested.

---

## 4) Risk Register & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Model drift between Script and UI | Confusing state | Parser produces mutation plan; atomic apply; formatter round‑trips |
| Image API rate limits | Slow thumbnails | Queue concurrency; caching by content hash; batch regenerate |
| Token bloat in chat | Tool misuse | Compact `STATE_SUMMARY`; limit history; include only focused context |
| Undo bugs | Data loss | Grouped transactions; unit tests for multi‑step sequences |
| Persistence corruption | Project loss | Atomic writes; backups (N=3); schema validation |
| False‑positive continuity | Noise | Keep rules lean; allow disable; future exceptions UI |

---

## 5) Definition of Done (per module)

- **Core**: Unit tests green; public API documented; no force unwraps; thread safe.
- **UI**: Snapshots match baselines; interactions keyboard accessible; no layout jitters.
- **Chat**: Tool calls validated; retries bounded; state summary under size budget.
- **Images**: Files written & referenced; retries surfaced; no crashes on missing files.
- **Exports**: Files open; headers correct; fixtures updated and reviewed.
- **Settings**: Stored securely; toggles have UI feedback; offline mode blocks network.
- **QA**: Test plan executed; perf within targets.

---

## 6) Handoffs & Artifacts

- `user_guide.md` — end‑user documentation (updated post‑0.2)
- `architecture.md` — system design
- `tools_schema.json` — tool surface (kept in sync with ToolRegistry)
- `system_primer.txt` — assistant rules and constraints
- `state_summary_template.yaml` — packing template
- `ComicSmithCore` — Swift package (core)
- `ComicSmithApp` — macOS app target (to be created for packaging)

---

## 7) Execution Order (Recommended)

1. **M1** Persistence → **M2** Chat (text) → **M3** Images → **M4** Script parser → **M5** UI polish → **M6** Exports → **M7** Settings → **M8** Continuity → **M9** Tests/Perf → **M10** Packaging.

Each milestone closes with: code review, tests, short demo video, and doc updates.

