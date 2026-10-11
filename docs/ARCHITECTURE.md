# Architecture

> **Source of truth**: this document describes the architecture as implemented in Release 1.0.

---

## 1. Layer map

```
lib/
  main.dart                  App entry point — injects SharedPreferences and ScenarioRepository
  app/
    app.dart                 MaterialApp with ProviderScope, theme wiring
    providers.dart           All Riverpod providers; AppSettings notifier; Fmt provider
    theme/
      tokens.dart            AppPalette, Sp, Rd, AppType — design token classes
      theme.dart             buildTheme() — produces ThemeData from tokens
  core/
    format.dart              Fmt (number / money / percent / axis / schedule cell)
                             CurrencyInfo list, NumberStyle list
    validation.dart          validateInputs() — parses raw text, enforces ranges,
                             never silently replaces invalid values with zero
  domain/
    models/
      calc.dart              FieldDef, CalculatorDef, CalcInputs, CalcResult,
                             ResultRow, ChartSpec, Series, Schedule, Scenario
    calculations/
      finance.dart           Pure-Dart financial engine — no Flutter imports
    calculators/
      catalog.dart           14 declarative CalculatorDef instances; catalog list;
                             calcById(), searchCatalog()
  data/
    storage.dart             ScenarioRepository (sqflite), fully offline
    backup.dart              BackupService — export/parse with AES-256-GCM + PBKDF2
  features/
    shell/
      shell.dart             Shell — IndexedStack with FloatingNavBar overlay (Stack + Positioned)
    home/
      home_page.dart         Search, favourites, recents, categories, popular
    catalog/
      catalog_page.dart      Full calculator list with category chip filter
      category_page.dart     Single-category view
    calculator/
      calculator_screen.dart Generic input screen; renders any CalculatorDef
    saved/
      saved_page.dart        Scenario list; rename / duplicate / delete with undo
      compare_page.dart      Side-by-side diff of two same-calculator scenarios
    settings/
      settings_page.dart     Theme, currency, number format, backup, privacy, reset
  shared/
    widgets/
      common.dart            AppCard, CalcTile, EmptyState, SearchField,
                             IconBadge, SectionTitle; pickOne, askText, confirm, toast
      floating_nav.dart      FloatingNavBar — pill-shaped bottom nav
      result_view.dart       ResultView — Summary / Chart / Schedule / Notes tabs
test/
  finance_test.dart          Formula, validation, backup tests
```

---

## 2. Dependency rules

| Layer | May import |
|---|---|
| `domain/` | `dart:` packages only. No Flutter, no data, no features. |
| `core/` | `domain/models/`. `intl`. No Flutter widgets. |
| `data/` | `domain/`. `sqflite`, `cryptography`, `dart:convert`. No Flutter widgets. |
| `shared/widgets/` | `domain/`, `core/`, `app/theme/`. Flutter. |
| `features/` | All of the above. |
| `app/` | All of the above. |

The `domain/` layer is a **pure Dart** library. The `flutter_test` dependency is in
`dev_dependencies` only. Running `dart test` against `domain/` and `core/` requires no Flutter SDK.

---

## 3. Calculator model

Every calculator is a **declarative `CalculatorDef`** — a plain Dart constant that describes:

| Field | Purpose |
|---|---|
| `id` | Stable identifier stored in `Scenario.calcId` |
| `code` | PRD code (C01–C14) |
| `name`, `summary`, `explains` | Display strings |
| `category` | `CalcCategory` enum value |
| `aliases` | Extra terms for search matching |
| `formula` | List of formula strings shown in Notes tab |
| `fields` | Ordered list of `FieldDef` (inputs) |
| `compute` | `CalcResult Function(CalcInputs)` — the formula |

A single generic screen (`CalculatorScreen`) renders **any** calculator. Adding a new
calculator requires only a new `CalculatorDef` in `catalog.dart` — no new screen.

### FieldDef visibility

Fields with `showWhenField` / `showWhenValue` are shown only when another choice field
matches the given value. Choices are resolved first in `validateInputs()` so that
visibility rules can be applied correctly.

### CalcResult contract

`compute` either returns a `CalcResult` or throws `CalcException(message)`.
It must **never** throw an untyped exception for a user-input error.

| Property | Notes |
|---|---|
| `primary` | Always present |
| `rows` | May be empty |
| `chart` | Optional |
| `schedule` | Optional |
| `assumptions` | May be empty; displayed in the Notes tab |

---

## 4. State management

Riverpod is the single state solution. `StatefulWidget` is used only for ephemeral
local UI state (text controllers, dirty-field tracking, selection mode in SavedPage).
No local widget state crosses widget boundaries.

| Provider | Type | Holds |
|---|---|---|
| `prefsProvider` | `Provider<SharedPreferences>` | Injected at startup via override |
| `repoProvider` | `Provider<ScenarioRepository>` | Injected at startup via override |
| `settingsProvider` | `NotifierProvider<SettingsNotifier, AppSettings>` | Theme mode, currency code, locale, favourites list, recents list |
| `fmtProvider` | `Provider<Fmt>` | Derived from `settingsProvider`; rebuilds on currency/locale change |
| `scenariosProvider` | `AsyncNotifierProvider<…, List<Scenario>>` | SQLite rows; reloads after every mutation |

`fmtProvider` is a **derived** provider — widgets that display numbers watch it and
automatically reformat when the user changes currency or number style in Settings.

---

## 5. Data model

### Scenario (SQLite table: `scenarios`)

```sql
CREATE TABLE scenarios(
  id             TEXT    PRIMARY KEY,
  title          TEXT    NOT NULL,
  calc_id        TEXT    NOT NULL,
  inputs         TEXT    NOT NULL,    -- JSON: Map<String, num|String>
  snapshot       TEXT    NOT NULL,    -- JSON: {primary: {...}, rows: [...]}
  schema_version INTEGER NOT NULL,
  created_at     INTEGER NOT NULL,    -- millisecondsSinceEpoch
  updated_at     INTEGER NOT NULL     -- millisecondsSinceEpoch
);
```

`snapshot` stores only `primary` and `rows` — not chart or schedule data — so the
Saved list can display a result value without re-computing.

### Backup wire format

**Plain file (`format: "ofc-backup"`)**

```json
{
  "format": "ofc-backup",
  "version": 1,
  "createdAt": "2024-01-15T10:30:00Z",
  "scenarios": [
    {
      "id": "abc123",
      "title": "My SIP",
      "calcId": "sip",
      "inputs": { "contribution": 500, "rate": 10, "years": 15, ... },
      "snapshot": { "primary": {...}, "rows": [...] },
      "schemaVersion": 1,
      "createdAt": 1705312200000,
      "updatedAt": 1705312200000
    }
  ]
}
```

**Encrypted file (`format: "ofc-backup-enc"`)**

```json
{
  "format": "ofc-backup-enc",
  "version": 1,
  "kdf": "pbkdf2-hmac-sha256",
  "iterations": 150000,
  "cipher": "aes-256-gcm",
  "salt": "<base64, 16 random bytes>",
  "nonce": "<base64, 12-byte GCM nonce>",
  "data": "<base64 ciphertext of the plain JSON>",
  "mac": "<base64, 16-byte GCM authentication tag>"
}
```

The PBKDF2 key derivation runs in a background `Isolate`. The passphrase is never
stored anywhere. A wrong passphrase is caught by the GCM tag verification failure.

**Restore validation** (before writing any data):

1. File size ≤ 10 MB
2. Valid JSON with known `format` field
3. `version` ≤ current version constant
4. Scenario list ≤ 5 000 records
5. Per-record: `id` is a non-empty String ≤ 64 chars; `calcId` resolves via `calcById()`; all input values are `num` or `String`; timestamps are `int`

---

## 6. Screen navigation

```
AppShell (IndexedStack + FloatingNavBar)
├── 0  HomePage
├── 1  CatalogPage
│         └── CategoryPage (push)
│               └── CalculatorScreen (push)
├── 2  SavedPage
│         ├── CalculatorScreen (push, existing: scenario)
│         └── ComparePage (push)
└── 3  SettingsPage
```

Navigation uses plain `Navigator.push` with `MaterialPageRoute`. There is no named-route
table. The shell uses an `IndexedStack` so tab state (scroll position, search text) is
preserved across tab switches.

---

## 7. Offline guarantee

- `android.permission.INTERNET` is **absent** from the release `AndroidManifest.xml`.
- IBM Plex Sans and IBM Plex Mono are bundled in `assets/fonts/` (SIL Open Font License).
- No third-party analytics, crash-upload, or cloud-sync SDK is included.
- Backup files are written to `getTemporaryDirectory()` and shared via `share_plus`.
  No data leaves the device automatically.
- Verify after each build: `grep -r INTERNET android/app/src/main/AndroidManifest.xml`
  must return nothing.

---

## 8. Formatting pipeline

```
double value
    │
    ▼  Fmt.value(ResultRow)
    │  — reads ResultRow.kind (money / percent / years / number / text)
    │  — dispatches to NumberFormat (intl), locale-aware
    │
    ▼  Widget (Text, AppType.figure)
```

`Fmt` is constructed from `CurrencyInfo` + locale string. Changing currency or locale
in Settings triggers a `settingsProvider` state change, which invalidates `fmtProvider`,
which rebuilds every widget watching it.

`scheduleCell(value, col, firstIsIndex)` formats the index column as an integer and all
other columns with currency decimal places.

`axis(value)` produces compact labels (e.g. `1.2M`, `450K`) for chart y-axes.

---

## 9. Chart rendering

`ChartSpec` (pure Dart) is produced by each `compute` function. `ResultView` maps it
to `fl_chart LineChartData`. Each `Series` in `ChartSpec` maps to one `LineChartBarData`:

| Series `emphasis` | Line style | Colour token |
|---|---|---|
| `true` (default) | Solid, filled gradient | `AppPalette.primary` |
| `false` | Dashed, no fill | `AppPalette.accent` |

Axis labels use `Fmt.axis()`. Touch tooltips show formatted values using `Fmt.value()`.

---

## 10. Adding a new calculator

1. Add a pure-Dart compute function in `catalog.dart` or a separate file.
2. Add a `CalculatorDef` constant to the `catalog` list with a new unique `id` and
   the next PRD `code`.
3. Add an icon mapping in `iconForCalc()` in `common.dart`.
4. Write unit tests in `finance_test.dart` covering zero-rate cases, invalid inputs,
   and a closed-form vs simulation check where applicable.

No new screen, route, or provider is required.

---

## 11. Key design decisions

| Decision | Rationale |
|---|---|
| One generic screen for all calculators | C15+ requires only a new `CalculatorDef`; zero new screens. |
| Snapshot stored alongside scenario inputs | Saved list renders instantly; no re-compute needed. |
| `validateInputs` never replaces invalid input with zero | FR-02: invalid values must remain visible to the user. |
| Final EMI payment is adjusted, not re-computed | Eliminates floating-point residual accumulation across 240+ rows. |
| PBKDF2 key derivation in an isolate | 150 000 iterations would block the UI thread for seconds. |
| No named routes | All navigation is type-safe; avoids string-based route maintenance. |
| `Fmt` as a derived Riverpod provider | Currency/locale changes automatically reflow all displayed values. |
| `CalcException` as the only user-error type | Separates user-input errors from programming errors at the call site. |
