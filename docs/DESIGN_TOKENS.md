# Design Tokens

Source of truth in code: `lib/app/theme/tokens.dart`.

---

## Colour — Light theme

| Token | Hex | WCAG on bg | Use |
|---|---|---|---|
| `bg` | `#F4F6F2` | — | Screen / scaffold background |
| `surface` | `#FFFFFF` | — | Cards, input fills |
| `surfaceAlt` | `#EBEFE9` | — | Segmented button track, table headers |
| `outline` | `#D8DFD8` | — | Card borders, dividers, input borders |
| `ink` | `#101A14` | 15.5 : 1 on surface | Primary text |
| `inkMuted` | `#55655B` | 5.8 : 1 on surface | Secondary text, placeholder labels |
| `inkSubtle` | `#7E8C83` | 3.6 : 1 on surface | Hints, axis labels, icons |
| `primary` | `#0F5C3A` | 5.3 : 1 on surface | CTAs, focused borders, result card bg, links |
| `onPrimary` | `#FFFFFF` | 5.3 : 1 on primary | Text / icons on primary-coloured surfaces |
| `primarySoft` | `#DDEBE2` | — | Icon badge bg, info panels, compare hint card |
| `accent` | `#9A7219` | — | Chart comparison line, brass highlights |
| `onAccent` | `#FFFFFF` | — | Text on accent-coloured surfaces |
| `gain` | `#12703F` | — | Positive delta in Compare, gain labels |
| `loss` | `#B3261E` | — | Error text, negative delta, validation errors |
| `navBg` | `#12281D` | — | Floating navigation bar background |

## Colour — Dark theme

| Token | Hex |
|---|---|
| `bg` | `#0B120F` |
| `surface` | `#111A16` |
| `surfaceAlt` | `#17231D` |
| `outline` | `#25352D` |
| `ink` | `#EAF0EC` |
| `inkMuted` | `#9DB0A5` |
| `inkSubtle` | `#6E8176` |
| `primary` | `#4CB782` |
| `onPrimary` | `#06180F` |
| `primarySoft` | `#16302A` |
| `accent` | `#D2A64A` |
| `onAccent` | `#1C1403` |
| `gain` | `#4CB782` |
| `loss` | `#E07A6F` |
| `navBg` | `#1A2A22` |

> **Accessibility rule**: Gains and losses are **never** communicated by colour alone.
> Positive values carry a `+` sign; negative values carry a `−` sign and a label.
> Error states show error text below the field in addition to the red border.

---

## Typography

All text uses IBM Plex Sans. Numeric values use IBM Plex Mono (tabular figures).
Both families are bundled in `assets/fonts/` (SIL Open Font License).

| Role | Dart constant | Font | Size | Weight | Height | Use |
|---|---|---|---|---|---|---|
| Display | `displayLarge` | IBM Plex Sans | 36 | 600 | 1.15 | Not used in R1 |
| Headline | `headlineMedium` | IBM Plex Sans | 26 | 600 | 1.20 | Page titles (Home, Saved, Settings) |
| Title L | `titleLarge` | IBM Plex Sans | 20 | 600 | 1.25 | AppBar titles |
| Title M | `titleMedium` | IBM Plex Sans | 16 | 600 | 1.30 | Section headers |
| Title S | `titleSmall` | IBM Plex Sans | 14 | 600 | 1.30 | Calculator names in tiles, scenario titles |
| Body L | `bodyLarge` | IBM Plex Sans | 16 | 400 | 1.45 | Choice picker items, dialog body |
| Body M | `bodyMedium` | IBM Plex Sans | 14 | 400 | 1.45 | Calculator `explains` text, info panels |
| Body S | `bodySmall` | IBM Plex Sans | 12.5 | 400 | 1.40 | Subtitles, dates, helper text (`inkMuted`) |
| Label L | `labelLarge` | IBM Plex Sans | 14 | 600 | — | Button text, comparison column headers |
| Label M | `labelMedium` | IBM Plex Sans | 12.5 | 500 | — | Offline badge, floating label text |
| Label S | `labelSmall` | IBM Plex Sans | 11 | 500 | — | Chart delta labels, table footnotes |
| **Figures** | `AppType.figure(color, size, w)` | **IBM Plex Mono** | 12.5–34 | 500–600 | — | All money / number values in result cards, tiles, compare |

### Figure usage

```dart
// Result card primary value
AppType.figure(p.onPrimary, size: 34, w: FontWeight.w600)

// Row value in summary
AppType.figure(p.ink, size: 15, w: FontWeight.w500)

// Schedule cell
AppType.figure(p.ink, size: 12.5)

// Scenario tile primary value
AppType.figure(p.primary, size: 15, w: FontWeight.w600)
```

---

## Spacing

All spacing uses multiples of 4. Constants live in `Sp`.

| Constant | Value (dp) | Typical use |
|---|---|---|
| `Sp.xs` | 4 | Gap between icon and text in badges; compact padding |
| `Sp.sm` | 8 | Between cards in a list; vertical gap inside rows |
| `Sp.md` | 12 | Between icon and text in tiles; checkbox margin |
| `Sp.lg` | 16 | Card padding; between fields; section vertical gaps |
| `Sp.xl` | 20 | Page horizontal margin (`Sp.page`); between major sections |
| `Sp.xxl` | 24 | Section title top padding |
| `Sp.xxxl` | 32 | Empty-state padding; bottom padding in scroll views |
| `Sp.page` | 20 | Left/right margin for all scroll views |
| `Sp.navClearance` | 108 | Bottom padding to clear the floating nav bar |

---

## Corner radii

Constants live in `Rd`. Use `Rd.r(Rd.md)` to produce a `BorderRadius`.

| Constant | Value (dp) | Use |
|---|---|---|
| `Rd.sm` | 10 | Chips, checkboxes |
| `Rd.md` | 14 | Input fields, buttons, dialogs |
| `Rd.lg` | 20 | Cards (`AppCard`) |
| `Rd.xl` | 28 | Bottom sheet top corners; category icon badge (large) |
| Floating nav | 34 | Floating nav bar pill shape (hardcoded in `floating_nav.dart`) |

---

## Elevation

- **Cards** (`AppCard`): flat — `color` fill + 1 px `outline` border. No shadow.
- **Floating nav bar**: single box shadow with `AppPalette.shadow`.
- **Snack bars**: floating with `navBg` background.
- **Dialogs / bottom sheets**: Material elevation handled by the framework.

---

## Icons

Source: Phosphor Icons (`phosphor_flutter` package).

| State | Weight | Example use |
|---|---|---|
| Inactive / default | `PhosphorIconsRegular.*` | Nav bar inactive tab, toolbar icons |
| Active / selected / on-state | `PhosphorIconsFill.*` | Nav bar active tab, favourite star, offline shield |
| Decorative / in-badge | `PhosphorIconsRegular.*` | Category badges, calculator tiles |

Icon sizes:

| Context | Size (dp) | Touch target |
|---|---|---|
| Navigation bar | 24 | 48 dp (enforced by `NavigationDestination`) |
| Toolbar / AppBar | 22–24 | 48 dp (enforced by `IconButton`) |
| Tile / row | 18–20 | Inherits from `ListTile` or `InkWell` |
| Badge (inside `IconBadge`) | 52% of badge size | N/A (decorative) |

**No emoji are used anywhere in the UI.**

---

## Component specifications

### AppCard

```
Shape:       RoundedRectangleBorder, radius Rd.lg (20 dp)
Fill:        p.surface  (or caller-specified color)
Border:      1 px p.outline
Shadow:      none
Padding:     EdgeInsets.all(Sp.lg)  (default; overridable)
Ink:         InkWell ripple on tap (only when onTap is provided)
```

### Floating navigation bar

```
Background:  p.navBg
Height:      68 dp
Width:       screen width − 2 × Sp.xl (40 dp inset)
Radius:      34 dp (pill)
Shadow:      box shadow, p.shadow
Position:    bottom-aligned, clearance from system bars via SafeArea
Selected:    translucent white highlight behind selected item, icon in p.accent (fill weight)
Inactive:    icon in p.inkSubtle (regular weight)
```

### Result card (Summary tab, primary result)

```
Background:  p.primary
Text colour: p.onPrimary
Value style: IBM Plex Mono, 34 sp, weight 600
Label:       IBM Plex Sans Body M, onPrimary
Disclaimer:  "Estimated" prefix or suffix — never "guaranteed"
Radius:      Rd.lg (inherits from AppCard)
```

### Input field

```
Fill:        p.surface
Border:      1 px p.outline (enabled); 1.6 px p.primary (focused); 1 px p.loss (error)
Radius:      Rd.md (14 dp)
Label:       inkMuted when resting; p.primary when floating
Prefix:      currency symbol (for money fields) — trimmed symbol + space
Suffix:      unit label (e.g. "% per year", "years")
Error text:  p.loss colour, bodySmall
Keyboard:    `numberWithOptions(decimal: true)` for numeric fields;
             negative inputs allowed only when field `min < 0`
```

### Choice field

```
Rendered as: InputDecorator (matching input field visual) with caret-down icon
Tap action:  opens a bottom sheet via pickOne()
```

### Bottom sheet picker (`pickOne`)

```
Background:  p.surface
Top radius:  Rd.xl (28 dp) via BottomSheetTheme
Drag handle: shown
Max height:  75% of screen
Selected:    bold check icon in p.primary
```

### Segmented tabs (Summary / Chart / Schedule / Notes)

```
Track:       p.surfaceAlt
Thumb:       p.surface with p.outline border (selected)
Text:        p.ink; p.onPrimary when selected with primary background
```

### Snack bar / toast

```
Background:  p.navBg
Text:        #EAF0EC (fixed — matches dark ink regardless of theme)
Behaviour:   floating; inset from bottom by 104 dp (above nav bar)
Action:      p.accent colour label
```

---

## Accessibility requirements

- **Touch targets**: minimum 48 × 48 dp for all interactive elements.
- **Text scale**: UI must not clip or overflow at 200% text scale.
- **Screen reader**: every `IconButton` and `Icon` used as a button must have a
  `tooltip` or `semanticLabel`.
- **Colour-only meaning**: never use colour as the only differentiator (see gain/loss rule above).
- **Focus**: visible focus indicator is provided by Material 3 (focus ring) — do not remove it.
- **Motion**: system `disableAnimations` setting is respected by Flutter automatically.
  Heavy animations (if any are added) should respect `MediaQuery.disableAnimations`.

---

## Do and don't

| Do | Don't |
|---|---|
| Use `context.pal` to access palette tokens | Use hard-coded `Color(0xFF…)` in widgets |
| Use `Sp.*` and `Rd.*` constants | Use magic numbers for padding or radius |
| Use `AppType.figure(…)` for numeric values | Use `TextStyle(fontFamily: 'IBMPlexMono')` directly |
| Use `AppCard` for all content cards | Use `Card` or `Container` with custom shadows |
| Throw `CalcException` for user errors | Throw `Exception` or `Error` for user errors |
| Show `+ / −` signs alongside gain/loss colours | Rely on colour alone to convey +/− |
