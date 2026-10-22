# Finwise Design System

A single source of truth for design tokens, typography, spacing, radii, elevation, and component contracts across light and dark modes.

---

## 1. Color System

### 1.1 Palettes (User-Selectable, Royal Indigo Default)
Finwise supports six curated, accessible palettes:
1. **Royal Indigo** (Default): Seed `#4F46E5`, Light Primary `#4F46E5`, Dark Primary `#818CF8`
2. **Finwise Green**: Seed `#059669`, Light Primary `#059669`, Dark Primary `#34D399`
3. **Ocean Blue**: Seed `#2563EB`, Light Primary `#2563EB`, Dark Primary `#60A5FA`
4. **Deep Teal**: Seed `#0D9488`, Light Primary `#0D9488`, Dark Primary `#2DD4BF`
5. **Grape Violet**: Seed `#7C3AED`, Light Primary `#7C3AED`, Dark Primary `#A78BFA`
6. **Amber Gold**: Seed `#D97706`, Light Primary `#B45309`, Dark Primary `#FBBF24`

### 1.2 Category Accents (Semantic, One Per Domain)
- **Growth & Investing**: `#10B981` (Emerald Green)
- **Loans & Debt**: `#6366F1` (Indigo)
- **Goals & Planning**: `#F59E0B` (Amber)
- **Returns & Inflation**: `#8B5CF6` (Purple)
- **Utilities**: `#06B6D4` (Cyan)

### 1.3 Semantic Roles (Light / Dark)
| Role | Light | Dark | Use Case |
|---|---|---|---|
| `primary` | Palette Light | Palette Dark | FAB, Primary buttons, active nav, key numbers |
| `onPrimary` | `#FFFFFF` | Contrasting tone | Text/icon on primary |
| `background` | `#F6F8FA` | `#0B0F14` | Scaffold background |
| `surface` | `#FFFFFF` | `#11161D` | Cards, sheets, dialogs |
| `surfaceVariant` | `#F1F5F9` | `#161C24` | Inputs, nested rows, chip containers |
| `outline` | `#E2E8F0` | `#2A3340` | Card borders, dividers |
| `outlineStrong` | `#CBD5E1` | `#3A4553` | Focused borders |
| `textPrimary` | `#0F172A` | `#F1F5F9` | Headings, primary values |
| `textSecondary` | `#475569` | `#94A3B8` | Descriptions, subtitles |
| `textTertiary` | `#94A3B8` | `#64748B` | Hints, disabled, icons |
| `success` | `#10B981` | `#34D399` | Positive results |
| `warning` | `#F59E0B` | `#FBBF24` | Caution |
| `danger` | `#EF4444` | `#F87171` | Errors, destructive |
| `info` | `#3B82F6` | `#60A5FA` | Neutral info |

---

## 2. Typography Scale

| Token | Size / Height / Weight | Typical Usage |
|---|---|---|
| `displayLarge` | 32 / 40 / w700 | Hero numbers, key calculation outputs |
| `headlineMedium` | 24 / 32 / w700 | Screen titles |
| `titleLarge` | 20 / 28 / w600 | Section headers |
| `titleMedium` | 16 / 24 / w600 | Card titles, list rows |
| `bodyLarge` | 16 / 24 / w400 | Primary body text, input values |
| `bodyMedium` | 14 / 20 / w400 | Descriptions, helper text |
| `labelLarge` | 14 / 20 / w600 | Buttons, chip labels |
| `labelSmall` | 12 / 16 / w500 | Field labels, captions |

Rule of thumb: Only 3 distinct text sizes visible per screen area (Title, Body, Caption).

---

## 3. Spacing Grid (4pt System)

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48`
- `xs` = 4.0
- `sm` = 8.0
- `md` = 12.0
- `lg` = 16.0 (`screen` horizontal padding)
- `xl` = 20.0
- `xxl` = 24.0 (`sectionGap`)
- `xxxl` = 32.0
- `cardGap` = 12.0
- `navClearance` = 88.0 (Bottom scroll clearance for floating nav)

---

## 4. Corner Radii

- `sm` = 8.0
- `md` = 12.0 (Buttons, inputs, icon tiles)
- `lg` = 16.0 (Cards)
- `xl` = 20.0 (Bottom sheets, result cards)
- `pill` = 999.0 (Chips, navigation bar, segmented controls)

---

## 5. Elevation Model

| Level | Light Mode | Dark Mode |
|---|---|---|
| **e0 (Flat)** | Surface + Hairline Outline (`#E2E8F0`) | Surface + Hairline Outline (`#2A3340`) |
| **e1 (Card)** | Surface + Soft shadow (`rgba(15,23,42, 0.06)`, blur 3, offset (0,1)) + Outline | Surface + Subtle border (`#2A3340`), no heavy shadow |
| **e2 (Raised)** | Surface/Primary + Shadow (`rgba(15,23,42, 0.10)`, blur 24, offset (0,8)) | Surface/Primary + Deep shadow (`rgba(0,0,0, 0.45)`, blur 24, offset (0,8)) |

---

## 6. Component Contracts

- **AppBar**: Transparent, headlineMedium title, no shadow, clean back arrow.
- **Card (`AppCard`)**: Radius 16, e1 elevation, 16pt padding, soft shadow in light, clean border in dark.
- **ListRow (`ListRow`)**: Min height 72, leading 40×40 tinted icon tile with radius 12, title titleMedium, subtitle bodyMedium (max 1 line ellipsis), trailing 20px chevron.
- **SectionHeader (`SectionHeader`)**: titleLarge, 24px top / 12px bottom margin.
- **PrimaryButton (`AppButton`)**: Height 52, radius 12, labelLarge, full-width on forms.
- **Segmented Control**: Pill container surfaceVariant, active segment surface + e1, pill radius.
- **Chip Row (`AppChipRow`)**: Horizontal scroll, 8px gaps, 16px side padding, never clips text, chips size to content.
- **Input (`AppTextField`)**: surfaceVariant fill, radius 12, label labelSmall in textSecondary, focus ring 1.5px primary.
- **ResultCard (`ResultCard`)**: Primary container, radius 20, e2, displayLarge value, clean pill tag.
- **BottomNav (`AppBottomNav`)**: Height 60 + safe area, radius pill, e2 elevation; active item has primary icon + label, no oversized colliding blob; content scroll views have clearance padding.
- **EmptyState (`EmptyState`)**: Centered icon 48 in textTertiary, titleMedium line, bodyMedium line.
