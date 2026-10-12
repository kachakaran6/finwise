# Release Notes — Finwise

## Version 1.0.1

### Highlights
- **Refined Neutral Palette**: Replaced template green-tinted theme with a calm, professional ink-and-paper palette in light mode and true graphite in dark mode. Single banknote green primary color, no gold/brass accents.
- **Unified AppHeader**: Consistent, safe-area-aware global header across all screens with dynamic 1px bottom scroll divider and 48dp touch targets.
- **Cleaner Copy & Polish**: Removed redundant helper lines, disclaimers, and subtitle text. Fixed pluralization grammar across catalog and home.
- **Predictive & Tab Back Navigation**: Full Android predictive back navigation support (`enableOnBackInvokedCallback`). Sub-tabs back to Home, Home exits app, unsaved changes prompt discard confirmation, and search/selection modes cancel on back.
- **Redesigned Floating Nav Bar**: Slimmer 60dp floating navigation bar with animated pill tab expansion, haptic feedback, accessibility semantics, and automatic keyboard avoidance.
- **Native Google Play Integration**: In-app flexible & immediate update support and in-app review requests triggered at positive milestones (3rd save), using 100% native Play UI while strictly maintaining zero INTERNET permission.
- **Deployment & Release Docs**: Added `docs/PLAY_RELEASE.md` with guidelines on keystore signing, version code bumps, and internal testing flows.
