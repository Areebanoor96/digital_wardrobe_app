# 05 — Design System ("Airy Closet")

Goal: **modern, light, simple-feeling despite deep functionality.** Strategy: one primary action per screen, progressive disclosure (sheets instead of new pages), generous whitespace, soft depth.

---

## 1. Color palette (light-first)

| Token | Hex | Use |
|---|---|---|
| `primary` | `#6C5CE7` | soft violet — buttons, active tab, FAB |
| `primaryLight` | `#EDEAFD` | chip fills, selected states, OOTD gradient start |
| `accent` | `#00B894` | success, eco-score, "worn" checks |
| `warn` | `#FDCB6E` | laundry, aging condition |
| `danger` | `#E17055` | alerts, overdue, delete |
| `bg` | `#FAFAFC` | app background (never pure white) |
| `surface` | `#FFFFFF` | cards, sheets |
| `textPrimary` | `#1A1A2E` | headings |
| `textSecondary` | `#6B7280` | labels, meta |
| `border` | `#EEEFF3` | hairlines, dividers |

Mood colors (pills/tags): Professional `#4A69BD` · Casual `#78C6A3` · Bold `#E84393` · Cozy `#E67E22` · Party `#9B59B6`.

Dark theme: same hues on `#121218` bg / `#1E1E28` surface — ship in P2, default stays light.

## 2. Typography

Font: **Plus Jakarta Sans** (Google Fonts) — modern, friendly, great numerals.

| Style | Size/weight | Use |
|---|---|---|
| Display | 28 / 800 | greeting, big numbers |
| H1 | 22 / 700 | screen titles |
| H2 | 17 / 600 | section headers |
| Body | 15 / 400 | default |
| Label | 13 / 500 | chips, meta |
| Caption | 11 / 500, letter-spaced | badges, overlines |

## 3. Shape, space, depth

- Radius: cards 20 · sheets 28 (top) · chips/buttons 999 (pill) · inputs 14 · photos 16
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32; screen padding 20
- Elevation: no harsh shadows — `BoxShadow(black 6%, blur 24, offset 0,8)` on cards; sheets get a grabber handle
- Photos always on `#F4F4F8` placeholder with shimmer

## 4. Signature components

| Component | Design |
|---|---|
| **GarmentCard** | rounded photo, name (1 line), color dot + size, tiny wear-count pill top-right; hero animation into detail |
| **OOTDCard** | violet→lavender gradient, glassy weather chip, 3 overlapping circular item thumbs, big pill CTA "Wear This" |
| **MatchRing** | circular progress around thumbnail showing match % (color: >80 green, >60 amber, else grey) |
| **StatCard** | white card, caption label, Display number, small trend arrow |
| **AlertCard** | left icon in tinted circle (type color), title + body, thumbnail right, swipe-to-dismiss with elastic bounce |
| **ChipFilter** | pill, `primaryLight` fill when active, count badge |
| **FAB** | 60px, primary, subtle pulse on first launch (onboarding hint) |
| **BottomBar** | floating pill bar (inset 16, radius 24), 5 icons, active icon = filled + label, others icon-only |
| **EmptyState** | soft illustration, one sentence, one button — never a blank screen |
| **EcoRing** | thick gradient ring (red→amber→green), animated sweep on load |

## 5. Motion

- Page transitions: fade-through (Material 3), 250ms
- Hero animations: garment photo grid→detail
- Lists: staggered fade+slide-up on first load (40ms interval)
- Wear This: checkmark burst + haptic medium
- Challenge complete: confetti (P2)
- All animations ≤300ms, `Curves.easeOutCubic`, respect reduced-motion setting

## 6. UX rules (how "lots of features" stays simple)

1. Bottom sheets over new screens for filters, quick edits, pickers — user never loses context
2. One FAB per screen with the single most likely action
3. Advanced features live behind the Detail overflow menu, not on the grid
4. Icons + labels always paired in the tab bar (no mystery meat)
5. All alerts arrive in one feed; badges never exceed "9+"
6. Forms grouped in visual sections with smart defaults; only name + category + photo are required
7. Optimistic UI everywhere — save instantly, sync in background
8. Touch targets ≥44px; contrast AA; dynamic type supported

## 7. Theming implementation

Single `AppTheme` (Material 3, `ColorScheme.fromSeed(seedColor: primary)` overridden with tokens above). All tokens as `ThemeExtension` (`AppColors`, `AppSpacing`) — no hardcoded hex in widgets. Google Fonts via `google_fonts` package.
