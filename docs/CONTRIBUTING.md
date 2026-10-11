# Contributing

> This guide covers how to add features, run tests, and prepare a release build.

---

## Quick start

```bash
./setup.sh          # installs dependencies, runs tests
flutter run         # launch on a connected Android device or emulator
flutter test        # run all unit tests
flutter analyze     # static analysis (must be clean)
```

`setup.sh` requires Flutter ≥ 3.19 and Android SDK ≥ 34.

---

## Project conventions

### Dart style

- Follow `flutter_lints` (configured in `analysis_options.yaml`).
- No `// ignore:` comments without an explanation.
- All public symbols in `domain/` and `core/` must have a doc comment.
- Format with `dart format .` before committing.

### Domain layer rules (enforced by convention)

- **No Flutter imports** in `lib/domain/` or `lib/core/`.
- **No side effects** in `compute` functions — they are pure functions of `CalcInputs`.
- **Throw `CalcException`** for any user-input error. Never throw an untyped exception.
- **No `double.nan` or `double.infinity`** returned in a `ResultRow.value`;
  return `ResultRow('label', double.nan)` only if you explicitly check with `!v.isFinite`
  in `Fmt.value()`.

### Naming

| Thing | Convention |
|---|---|
| Calculator ID | lowercase, no spaces (e.g. `stepup`, `absret`) |
| Field ID | camelCase within the calculator (e.g. `contrib`, `annualRate`) |
| Provider | `fooProvider` / `FooNotifier` |
| Test group | matches the PRD code or feature name |

---

## Adding a calculator

See [ARCHITECTURE.md § 10](ARCHITECTURE.md#10-adding-a-new-calculator) for the full checklist.

Short version:

1. Write a pure-Dart `_myCalc(CalcInputs x) → CalcResult` function.
2. Add a `CalculatorDef` to the `catalog` list in `catalog.dart`.
3. Add an icon in `iconForCalc()` in `shared/widgets/common.dart`.
4. Write unit tests.

---

## Tests

All tests live in `test/finance_test.dart`.

### What to test for every new calculator

- [ ] Default inputs produce a finite, positive primary result.
- [ ] Zero-rate edge case: formula degenerates gracefully (no division by zero).
- [ ] Negative or out-of-range inputs throw `CalcException`.
- [ ] Closed-form result matches period-by-period simulation to within `1e-6`
      (where a simulation is feasible).
- [ ] Validation: `validateInputs` marks required empty fields as errors, not zeros.

Verify formulas against the derivations in [FORMULAS.md](FORMULAS.md) before writing tests.

### Running a specific test

```bash
flutter test test/finance_test.dart --name "C07 CAGR"
```

### Test coverage

The test suite covers:

| Area | Coverage |
|---|---|
| C01–C11 core formulas | Unit tested |
| C03 closed-form vs simulation | Checked for both `begin` and `end` timing |
| C04 step-up at 0% equals SIP | Round-trip check |
| C05 goal contribution round-trip | Verified against C03 |
| C11 amortization | Closing balance = 0; principal sum = loan amount |
| Validation | Invalid inputs produce errors, not zeros |
| Backup plain round trip | Export → parse → title check |
| Backup encrypted round trip | Correct passphrase succeeds; wrong fails |
| Backup malformed records | Skipped gracefully |

---

## Design system

See [DESIGN_TOKENS.md](DESIGN_TOKENS.md) for colours, typography, spacing, radii,
and component specifications.

The canonical source of truth for tokens in code is `lib/app/theme/tokens.dart`
(`AppPalette`, `Sp`, `Rd`, `AppType`). Do not introduce ad-hoc colour values or
font sizes in widgets.

### Using the palette

```dart
final p = context.pal; // AppPalette extension on BuildContext

Text('value', style: AppType.figure(p.primary, size: 20));
Container(color: p.primarySoft, child: ...);
```

### Cards

All content cards use `AppCard`. Do not use raw `Card` or `Container` with a shadow.

```dart
AppCard(
  onTap: () => ...,    // optional; omit for non-interactive cards
  color: p.surfaceAlt, // optional; defaults to p.surface
  child: ...,
)
```

---

## Release checklist

1. `./setup.sh` completes without errors and all tests pass.
2. `flutter analyze` reports no issues.
3. Airplane-mode run on a **fresh install** — all calculators and navigation work.
4. Force-stop and relaunch — saved scenarios are present.
5. Text scale 200% — no overflow or clipped labels.
6. TalkBack / accessibility — all interactive elements have labels.
7. Light and dark themes — check contrast on result cards and chart labels.
8. Release manifest: `grep INTERNET android/app/src/main/AndroidManifest.xml` returns nothing.
9. Sign and build:
   ```bash
   flutter build appbundle --release
   ```

---

## Dependency decisions

| Package | Why | Alternative considered |
|---|---|---|
| `flutter_riverpod` | Compile-safe providers, no `BuildContext` required in business logic | `provider`, `bloc` |
| `sqflite` | Mature local SQLite; no network, no cloud | `drift`, `isar` |
| `shared_preferences` | Settings are a small key-value store, no schema needed | SQLite table |
| `fl_chart` | Line charts, no network requests, no ads | `charts_flutter` (deprecated) |
| `phosphor_flutter` | Consistent icon set, dual weight (regular/fill) | `material_icons` |
| `cryptography` | Pure Dart AES-GCM + PBKDF2, no native bridge required | `pointycastle` |
| `share_plus` | Cross-platform share sheet for backup files | `flutter_share` |
| `file_picker` | File selection without cloud storage permission | `image_picker` |
| `intl` | Locale-aware number formatting | `money2` |
