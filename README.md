# Finwise

Fully offline, privacy-first personal finance and investment calculator app for Android. No account, no network, no analytics.

## Quick start

```bash
./setup.sh          # creates android/, installs packages, icons, runs tests
flutter run         # debug on a device or emulator
flutter build apk --release
```

Requires Flutter 3.27 or newer (Dart 3.3+).

`setup.sh` runs `flutter create` for the Android platform, so the first run needs the
Flutter SDK and pub.dev access once to download packages. After that the app itself
never touches the network.

## What is included

- 14 calculators (C01–C14): compound, simple, SIP, step-up, goal contribution, goal lump
  sum, CAGR, absolute return, inflation, EMI, amortization, savings goal, percentage,
  comparison.
- Charts, schedules, formula notes and assumptions for each result.
- Saved scenarios (SQLite), compare two scenarios, favourites, recents.
- Encrypted backup (AES-256-GCM + PBKDF2) and validated restore.
- Light and dark theme, currency symbol and number format settings.
- Floating bottom navigation.

## Libraries

`flutter_riverpod` · `sqflite` · `shared_preferences` · `path_provider` · `intl` ·
`fl_chart` · `phosphor_flutter` · `cryptography` · `share_plus` · `file_picker`

## Documents

| File | Contents |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Product requirements, goals, screen map, acceptance criteria |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layer map, data models, state management, design decisions |
| [`docs/PHASES.md`](docs/PHASES.md) | Delivery phases with task-level checklists |
| [`docs/DESIGN_TOKENS.md`](docs/DESIGN_TOKENS.md) | Colour, typography, spacing, component specs |
| [`docs/FORMULAS.md`](docs/FORMULAS.md) | Mathematical derivations for all 14 calculators |
| [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) | Dev setup, conventions, how to add a calculator, release checklist |

## Offline verification

1. Install a release build, enable airplane mode, use every tab.
2. Force-stop and relaunch; saved scenarios remain.
3. `grep INTERNET android/app/src/main/AndroidManifest.xml` returns nothing.
   (The debug manifest adds INTERNET only for hot-reload; it is absent from release.)

---

Results are estimates from the numbers entered. They are not financial advice.
