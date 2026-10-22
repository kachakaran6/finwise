# UI/UX Refactor Progress

Track refactoring progress against the acceptance rubric across light and dark modes.

| Screen / Area | Light | Dark | Notes |
|---|---|---|---|
| **Theme & Tokens Layer** (`lib/theme/`) | PASS | PASS | Complete token layer with 6 palettes (Royal Indigo default), typography, spacing, elevation |
| **Shared Widgets Library** (`lib/widgets/`) | PASS | PASS | AppCard, ListRow (minHeight 72), AppChipRow, AppButton, AppTextField, SectionHeader, EmptyState |
| **Navigation Shell & Bottom Nav** | PASS | PASS | Pill active indicator, no oversized green blob, nav clearance padding across all screens |
| **Home Page** (`home_page.dart`) | PASS | PASS | Clean 2-col category grid, 12px gap, Popular section safe nav clearance |
| **Calculators Catalog** (`catalog_page.dart`) | PASS | PASS | Non-clipping chip scroll, full "All" chip, search bar tokenised, ListRow contract |
| **Category Page** (`category_page.dart`) | PASS | PASS | Removed redundant hero card header, domain accent badges, graceful empty state |
| **Calculator Screen & Result** (`calculator_screen.dart`, `result_view.dart`) | PASS | PASS | Consistent input radius 12, neutral labels, e2 ResultCard with displayLarge, pill notes/tabs |
| **Saved & Compare Screens** (`saved_page.dart`, `compare_sheet.dart`) | PASS | PASS | Domain category accents, 40×40 icon tiles, e1 cards, safe bottom clearance |
| **Settings Page** (`settings_page.dart`) | PASS | PASS | Appearance theme colour picker (6 swatches), unified semantic icons, no clipped privacy text |
| **Our Apps & Ecosystem** (`our_apps_page.dart`) | PASS | PASS | Purged raw color literals, tokenised badge, button and card styles |

---

## Rubric Verification Summary

### Consistency
- [x] **No raw `Color(0x...)` / raw dimensions outside `lib/theme/`**: Zero occurrences verified across `lib/`.
- [x] **Card radius and elevation**: Every card uses radius 16 (`AppRadius.lg`) and e1 elevation.
- [x] **Elevation hierarchy**: Identical ordering in light and dark (light = soft shadow $\le 10\%$, dark = surface + border).
- [x] **Semantic domain accents**: Growth (Green `#10B981`), Loans (Indigo `#6366F1`), Goals (Amber `#F59E0B`), Returns (Purple `#8B5CF6`), Utilities (Cyan `#06B6D4`).
- [x] **4pt Spacing grid**: Screen padding = 16, card gap = 12, section gap = 24.

### Typography
- [x] **Type scale**: Strict scale applied via `AppTypography` (`displayLarge`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelSmall`). Max 3 sizes visible per screen.
- [x] **Line-heights**: Specified height ratios matching tokens; no clipped text.

### Layout & Safety
- [x] **Bottom nav clearance**: Bottom padding (`AppSpacing.navClearance` = 88) applied on all scrollable views; no content hidden behind nav bar.
- [x] **Chip row**: Horizontal scroll with 8px gaps and edge padding; full "All" label rendering; no edge clipping.
- [x] **List rows**: Conforms to `ListRow` contract (min height 72, 40×40 icon tile with radius 12, titleMedium, 1-line ellipsis subtitle, 20px chevron).

### Colour & Contrast
- [x] **WCAG AA Compliance**: High contrast pairs on dark surfaces (`#0B0F14`, `#11161D`) and light surfaces (`#FFFFFF`, `#F6F8FA`).
- [x] **Primary & Semantic Contrast**: Checked across all 6 palettes (`royal_indigo`, `finwise_green`, `ocean_blue`, `deep_teal`, `grape_violet`, `amber_gold`).

### Behaviour & Quality Gates
- [x] **No logic changes**: Calculator math, formulas, storage, routing targets, and 100% offline privacy unchanged.
- [x] **`dart analyze`**: 0 issues found.
- [x] **`flutter test`**: 29/29 tests passed.
