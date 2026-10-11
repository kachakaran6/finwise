# Finwise — Product Requirements Document

Version 1.0 · Platform: Flutter, Android first · Data: local-first · Rules: country-neutral

> **Related documents**: [ARCHITECTURE.md](ARCHITECTURE.md) · [DESIGN_TOKENS.md](DESIGN_TOKENS.md) · [PHASES.md](PHASES.md) · [CONTRIBUTING.md](CONTRIBUTING.md) · [FORMULAS.md](FORMULAS.md)

---

## 1. Summary

A privacy-first Android app for personal-finance and investment calculations that works with no account, no network and no live market data. It provides a tested library of calculators, explains every result, shows schedules and charts, and saves scenarios locally with optional encrypted backup.

**Principles**

1. **Offline by default.** Every calculation, chart and saved item works in airplane mode.
2. **Privacy by design.** No account, telemetry, ads, analytics SDK, cloud sync or INTERNET permission.
3. **Mathematical correctness.** One tested calculation engine. No formulas inside widgets.
4. **Explainability.** Inputs, assumptions, formulas and breakdowns are always visible.
5. **Useful without setup.** Open the app and calculate.
6. **Progressive scope.** Strong core first; advanced modules in later releases.

---

## 2. Problem

People need quick answers: what will recurring investments grow to, how much to invest monthly for a target, how much a loan costs, what an annualised return is, what inflation does to a cost, how two scenarios compare. Existing tools often need internet, collect data, cover one calculation, or hide assumptions.

---

## 3. Goals and non-goals

**Goals**: Flutter Android app; shared calculation library; fully offline; save / rename / duplicate / update / delete scenarios; optional encrypted backup and validated restore; summaries, charts and schedules; currency symbol display without conversion; formulas testable independent of the UI; modular path to advanced calculators.

**Non-goals (v1)**: live prices, brokerage or bank connections, investment advice, tax or statutory rules, jurisdiction-specific schemes, accounts or cloud sync, ads, guaranteed predictions, online currency conversion.

---

## 4. Users and jobs

Individuals planning investments and goals; borrowers comparing loans; students learning time value of money; privacy-conscious users.

- Enter amount, rate and duration, see the outcome and how it was calculated.
- Change one assumption and compare with the previous scenario.
- Keep everything available offline.
- Back up data, protect it, and restore it safely.

---

## 5. Scope by release

| Release | Contents |
|---|---|
| **1.0 (this build)** | C01–C14 core calculators, local scenarios, comparison, charts, schedules, theme, currency display, encrypted backup/restore, accessibility, formula tests |
| 1.1 | Better comparison view, schedule export, input presets, extra validation, performance work |
| 2 | SWP/withdrawal, loan prepayment, affordability, TVM solver, fee impact, savings rate / emergency fund / runway, net worth |
| 3 | XIRR, portfolio transactions and returns, rebalancing, drawdown, return-series statistics, retirement / FIRE scenarios |

Country-specific modules are out of scope and must be separately scoped, versioned and opt-in.

See [PHASES.md](PHASES.md) for detailed task-level tracking per phase.

---

## 6. Functional requirements

**FR-01 Discovery.** Home shows favourites, recents and categories. Search matches name, alias, category and code. Each calculator has a short summary and a "what this calculates" note. No account needed.

**FR-02 Input handling.** Labelled numeric fields with units. Validation of required values, ranges, zero denominators and unsupported durations. Inputs persist while switching result tabs. Reset to defaults. Explicit selectors for compounding, contribution frequency, timing, rate convention. Invalid values are never silently replaced with zero.

**FR-03 Results.** Primary result prominent. Show principal/contributions, estimated growth, total, duration and assumptions. Language is "estimated" / "projected", never "guaranteed". Summary, chart, schedule and notes tabs. Display rounded to currency precision while keeping internal precision.

**FR-04 Comparison.** Compare two saved scenarios of the same calculator. Highlight differing inputs and result deltas. C14 compares two live scenarios. Never compare incompatible units.

**FR-05 Saved scenarios.** Store title, calculator, inputs, result snapshot, timestamps, schema version. Create, view, rename, duplicate, edit, delete. Delete offers undo.

**FR-06 Backup and restore.** Versioned backup file. Optional AES-256-GCM encryption with a PBKDF2-HMAC-SHA256 key derived from a user passphrase. Passphrase never stored. Restore validates format, version, schema, sizes and types before writing, previews record count, and offers merge or replace. Files are never uploaded. Users are told a lost passphrase makes an encrypted backup unrecoverable.

**FR-07 Offline guarantee.** No analytics, ads, remote fonts or images, crash upload or cloud SDKs. Fonts are bundled. The main Android manifest declares no INTERNET permission. Verify on fresh install and after force-stop.

**FR-08 Accessibility.** System text scaling, screen reader labels, 48 dp touch targets, visible focus, no colour-only meaning, light/dark theme, restrained motion.

---

## 7. Calculator inventory (Release 1)

| ID | Calculator | Core formula |
|---|---|---|
| C01 | Compound interest | A = P(1 + r/m)^(mt) |
| C02 | Simple interest | I = P·r·t |
| C03 | Recurring investment (SIP) | FV = C((1+i)^n − 1)/i, ×(1+i) if beginning-of-period |
| C04 | Step-up recurring investment | Contribution rises by s% at the start of each investment year; year 1 uses the initial amount |
| C05 | Goal contribution | C = FV·i/((1+i)^n − 1), ÷(1+i) if beginning |
| C06 | Goal lump sum (PV) | PV = FV/(1+i)^n |
| C07 | CAGR | (V1/V0)^(1/t) − 1 |
| C08 | Absolute return | (V1 + distributions − costs − V0)/V0 |
| C09 | Inflation / real return | FV = Cost(1+f)^t; real = (1+nominal)/(1+f) − 1 |
| C10 | EMI | P·i(1+i)^n/((1+i)^n − 1) |
| C11 | Amortization schedule | interest = opening·i; principal = payment − interest |
| C12 | Savings goal | Remaining target solved with C05, optional no-growth mode |
| C13 | Percentage | of, change, percentage points, add/remove, find original |
| C14 | Investment comparison | Two scenarios, one horizon, one model |

**Conventions**: rates are annual percentages. Nominal periodic rate = r/k. Effective conversion = (1+r)^(1/k) − 1. The convention in use is always shown. Zero-rate cases have explicit branches. Loan schedules round interest and payment to 2 dp per period, clear residuals under a defined tolerance, and adjust the final payment.

---

## 8. Architecture

```
lib/
  app/        app shell, providers, theme (tokens.dart, theme.dart)
  core/       formatting, validation
  domain/     models, calculations (pure Dart), calculator registry
  data/       SQLite storage, backup service
  features/   shell, home, catalog, calculator, saved, settings
  shared/     widgets (floating nav, result view, cards)
test/         formula, validation and backup tests
```

- Domain layer is pure Dart with no Flutter imports, immutable results and no database or UI dependencies.
- Each calculator is a declarative `CalculatorDef`: fields, validation limits, formula notes, and a `compute` function. One generic screen renders all calculators, so new calculators reuse the validated engine.
- State: Riverpod. Storage: sqflite (scenarios) and shared_preferences (settings). Charts: fl_chart. Icons: Phosphor. Crypto: `cryptography`. Sharing: share_plus. Restore picker: file_picker.
- Heavy crypto runs in a background isolate.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full layer map, dependency rules, data models, and navigation tree.

---

## 9. Data model

`scenarios(id, title, calc_id, inputs JSON, snapshot JSON, schema_version, created_at, updated_at)`.
Backup file `{format, version, createdAt, scenarios[]}`; encrypted form `{format, version, kdf, iterations, cipher, salt, nonce, data, mac}`.

See [ARCHITECTURE.md § 5](ARCHITECTURE.md#5-data-model) for complete JSON schemas.

---

## 10. Screen map

Floating bottom navigation: **Home**, **Calculators**, **Saved**, **Settings**.

- **Home**: offline badge, search, favourites, recents, categories, popular.
- **Calculators**: search and category filter chips.
- **Calculator**: inputs card, result card with Summary / Chart / Schedule / Notes, save.
- **Saved**: list, rename, duplicate, delete with undo, compare mode.
- **Compare**: differing inputs and result deltas.
- **Settings**: theme, currency symbol, number format, export, restore, privacy statement, delete all data.

---

## 11. Design system

See [DESIGN_TOKENS.md](DESIGN_TOKENS.md). Money-themed treasury green and brass on cool neutral surfaces. IBM Plex Sans for text and IBM Plex Mono for figures, bundled locally. Phosphor icons. No emoji.

---

## 12. Security and privacy

No network permission. No third-party telemetry. Local database in app sandbox. Backup encryption: AES-256-GCM, PBKDF2-HMAC-SHA256 with 150,000 iterations and a random 16-byte salt. Restore treats files as untrusted: size limit, record limit, type checks and calculator-id allow-list.

---

## 13. Testing

Unit tests for every formula including zero-rate and invalid inputs, closed-form versus simulation checks, amortization closing to zero, validation behaviour, backup round trip, wrong passphrase and invalid record rejection.

Manual: airplane mode, force-stop relaunch, text scale 200%, TalkBack, dark/light.

See [CONTRIBUTING.md § Tests](CONTRIBUTING.md#tests) for the test matrix.

---

## 14. Acceptance criteria for 1.0

- All C01–C14 calculators compute with defaults and reject invalid input explicitly.
- Saved scenarios survive app restart.
- Encrypted backup restores on a clean install; wrong passphrase fails safely.
- `android.permission.INTERNET` is absent from the release manifest.
- Light and dark themes pass contrast review.

---

## 15. Risks

| Risk | Mitigation |
|---|---|
| Users read projections as promises | Estimate wording on every result and in Notes |
| Floating-point drift in schedules | Per-period rounding, tolerance clamp, final-payment adjustment, tests |
| Pure-Dart PBKDF2 speed | Background isolate; optional native acceleration later |
| Rate convention confusion | Explicit selector with helper text |
| Backup file corruption | GCM authentication tag catches any modification; restore rejects bad files |
