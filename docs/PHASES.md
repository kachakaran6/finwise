# Delivery Phases

---

## Phase 0 — Foundations ✅ Done

**Goal**: repository skeleton, tooling, bundled assets, design system.

- [x] Repository layout matching `lib/` architecture (`app`, `core`, `domain`, `data`, `features`, `shared`)
- [x] `analysis_options.yaml` with `flutter_lints`
- [x] IBM Plex Sans and IBM Plex Mono bundled in `assets/fonts/`
- [x] Launcher icon (adaptive, treasury-green background)
- [x] Design tokens — `AppPalette` (light + dark), `Sp`, `Rd`, `AppType` in `lib/app/theme/tokens.dart`
- [x] `buildTheme()` in `lib/app/theme/theme.dart` wiring Material 3 components to tokens
- [x] `pubspec.yaml` with all Release 1 dependencies pinned

---

## Phase 1 — Core calculators ✅ Done (Release 1.0)

**Goal**: all 14 PRD calculators working on a single generic screen.

- [x] Pure-Dart financial engine (`lib/domain/calculations/finance.dart`)
  - `compoundValue`, `simpleInterest`, `annuityFv`, `goalContribution`, `presentValue`
  - `cagr`, `emi`, `amortize`, `project`, `Projection`, `chartFrom`, `yearlySchedule`
- [x] Domain models (`lib/domain/models/calc.dart`)
  - `FieldDef`, `CalculatorDef`, `CalcInputs`, `CalcResult`, `ResultRow`
  - `ChartSpec`, `Series`, `Schedule`, `Scenario`, `CalcException`
- [x] Calculator catalog (`lib/domain/calculators/catalog.dart`) — C01–C14
- [x] `validateInputs()` — never zeroes invalid fields (FR-02)
- [x] `CalculatorScreen` — generic screen rendering any `CalculatorDef`
  - Input card with number fields, choice pickers, visibility rules
  - Live result via `ResultView` (Summary / Chart / Schedule / Notes tabs)
  - Save / Update saved scenario
  - Favourite toggle, reset to defaults
- [x] `ResultView` — Summary rows, `fl_chart` line chart, schedule table, formula notes
- [x] Shell + `FloatingNavBar` (Home / Calculators / Saved / Settings)
- [x] `HomePage` — search, favourites, recents chips, category grid, popular list
- [x] `CatalogPage` — full list with category filter chips
- [x] `CategoryPage` — single-category calculator list

---

## Phase 2 — Persistence and comparison ✅ Done (Release 1.0)

**Goal**: scenarios survive app restart; side-by-side comparison.

- [x] `ScenarioRepository` (SQLite via `sqflite`) — `upsert`, `upsertAll`, `delete`, `clear`, `all()`
- [x] Riverpod providers — `scenariosProvider`, `settingsProvider`, `fmtProvider`
- [x] `SavedPage` — list ordered by `updated_at DESC`; rename, duplicate, delete with undo snackbar
- [x] Compare mode — select 2 from same calculator; `ComparePage` shows differing inputs and result deltas
- [x] Favourites (toggled in `CalculatorScreen`; listed on `HomePage`)
- [x] Recents (pushed on screen open; shown as horizontal chips on `HomePage`)

---

## Phase 3 — Backup and privacy ✅ Done (Release 1.0)

**Goal**: encrypted backup/restore; verified offline guarantee.

- [x] `BackupService.export()` — plain JSON or AES-256-GCM encrypted with PBKDF2-HMAC-SHA256 (150 000 iterations, 16-byte random salt)
- [x] `BackupService.parse()` — validates size, JSON structure, version, record count, per-field types, `calcId` allow-list before writing anything
- [x] Restore preview: shows record count and skipped count; offers Merge or Replace
- [x] PBKDF2 key derivation and encryption run in a background `Isolate`
- [x] Export via `share_plus` (writes to temp dir, uses OS share sheet — no upload)
- [x] Restore via `file_picker` (reads bytes directly — no server involved)
- [x] Settings page: theme, currency symbol (display only), number format, export, restore, privacy statement, delete all data
- [x] Passphrase never stored; user warned that loss makes encrypted backup unrecoverable

---

## Phase 4 — Quality (Release 1.1) 🔜 Planned

**Goal**: accessibility pass, widget tests, schedule export, presets, performance.

- [ ] Accessibility audit with TalkBack (Android) at 200% text scale
  - Verify all `IconButton` tooltips
  - Verify screen reader focus order on `CalculatorScreen`
  - Verify `AppBar` back button label
- [ ] Widget tests for `CalculatorScreen` — field interaction, save flow
- [ ] Widget tests for shell navigation — tab switching, back behaviour
- [ ] Schedule export as CSV (`share_plus`)
- [ ] Input presets: save named sets of default inputs per calculator
- [ ] Live comparison (C14-style) for any two unsaved scenarios
- [ ] Improved comparison view — visual delta bars
- [ ] Additional input validation: mixed-sign check for loan fields
- [ ] Performance profiling of long amortization schedules (≥ 600 rows)

---

## Phase 5 — Expanded finance (Release 2) 📋 Backlog

**Goal**: withdrawal planning, loan tools, financial health calculators.

- [ ] C15 Systematic Withdrawal Plan (SWP) — periodic withdrawals from a corpus
- [ ] C16 Loan prepayment — extra payment impact on tenure and interest saved
- [ ] C17 Loan affordability — maximum loan given EMI budget
- [ ] C18 TVM solver — solve for any one of PV / FV / rate / n / payment
- [ ] C19 Fee impact — effect of annual expense ratio on long-term returns
- [ ] C20 Savings rate — income and expense inputs → savings rate %
- [ ] C21 Emergency fund — runway given monthly expenses and fund size
- [ ] C22 Net worth — assets minus liabilities snapshot

---

## Phase 6 — Advanced analytics (Release 3) 📋 Backlog

**Goal**: XIRR, portfolio-level metrics, retirement planning.

- [ ] C23 XIRR — internal rate of return for irregular cash flows (bracketed solver)
- [ ] C24 Portfolio transactions — cost basis, realised gain/loss, holding period
- [ ] C25 Allocation — target vs actual weight, rebalancing amounts
- [ ] C26 Drawdown — max drawdown, recovery time
- [ ] C27 Return-series statistics — arithmetic / geometric mean, standard deviation, Sharpe
- [ ] C28 Retirement / FIRE — corpus needed, drawdown rate, years to target

---

## Permanent out-of-scope

Country-specific modules (e.g. PPF, EPF, NPS, FD with TDS, ELSS, GST) are **out of scope** for
the main app. They must be scoped, versioned, and opt-in as separate modules, and must not
affect the core calculators or the offline guarantee.

---

## Release checklist

Run before every release build:

1. `./setup.sh` completes and `flutter test` passes.
2. `flutter analyze` is clean (zero issues, zero hints).
3. Airplane-mode run on a fresh install — all screens and calculators work.
4. Force-stop and relaunch — scenarios are present; settings are preserved.
5. Release manifest has no INTERNET permission:
   ```bash
   grep -r INTERNET android/app/src/main/AndroidManifest.xml
   # Must return nothing
   ```
6. Light and dark themes — result cards, charts, and error states look correct.
7. Text scale 200% — no layout overflow.
8. Sign and build:
   ```bash
   flutter build appbundle --release
   ```
