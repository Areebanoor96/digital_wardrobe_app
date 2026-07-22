# 04 — Screens & User Flows

Navigation: 5-tab bottom bar — **Wardrobe · Outfits · Calendar · Analytics · Profile** — plus modals/sheets. Router: go_router. Phase tags mark when each screen ships.

```
Splash → (no session) Onboarding → Auth → Setup wizard → Main tabs
       → (session)   Main tabs
```

---

## 0. Onboarding & Auth (P1)

**Splash:** logo animation, session check.

**Onboarding (3 swipe pages, skippable):** 1) "Your closet, digitized" 2) "Never wonder what to wear" 3) "Track, save, sustain". Illustrations + dots + Get Started.

**Auth:** big buttons — Continue with Google / Apple / Email. Email opens sign-in↔sign-up toggle form (name, email, password, forgot-password). Errors inline.

**Setup wizard (first login, 3 steps, all skippable):**
1. City for weather (auto-detect button via geolocation)
2. Add family members (name, relation, birth date; children get height field)
3. Notification permission + toggles preview

---

## 1. WARDROBE (home tab) (P1)

- **Top bar:** greeting + avatar (→ Profile), bell with unread badge (→ Alert feed)
- **Search bar:** placeholder "Search your closet…", mic icon (voice search, P2), barcode icon (P2)
- **Filter chips row (horizontal scroll):** All · Tops · Bottoms · Dresses · Shoes · Outerwear · Accessories, then a "Filters" chip opening a bottom sheet (color swatches, season, occasion, brand, size, mood, member)
- **Member switcher (if family >1):** small avatar row — Me / Zara / Kabir / All
- **Grid:** 2-column cards (photo, name, color dot, wear count badge). Staggered layout. Pull-to-refresh. Infinite scroll.
- **Card long-press / swipe:** quick actions — Worn Today ✓ · Laundry basket 🧺 · Edit · Archive
- **FAB "+":** sheet → Take Photo / Choose from Gallery / Scan Barcode (P2)
- **Empty state:** friendly illustration "Add your first item" + arrow to FAB

States: loading (shimmer grid), empty, offline banner (subtle), error retry.

## 1a. Item Detail (P1)

Hero photo carousel (swipe, pinch-zoom) → sticky header on scroll. Chips: category, size, brand, seasons, occasions, moods. Stats row: **Wear count · Cost per wear · Last worn**. Wear history timeline (mini calendar dots). Laundry status pill (tap to cycle clean→dirty→washing). Buttons: **Wear Today** (primary) · **Build Outfit** (opens Outfit Builder with this as hero). Overflow menu: Edit · Lend (P2) · Add to hand-me-down (P3) · Resale estimate (P3) · Archive.

## 1b. Add / Edit Item (P1)

- Photo section first: big rounded drop area, up to 3 photos, first = cover; auto-crop square suggestion
- **Smart-fill:** after photo, app pre-suggests dominant color (from image pixels) — user confirms
- Form (grouped, not one long wall):
  - *Basics:* name, category (chip grid), subcategory, color (palette picker + custom), size
  - *Purchase:* brand (autocomplete from user's brands), price, date
  - *Style:* occasions (multi-chips), seasons (multi-chips), moods (multi-chips)
  - *Care:* fabric, wash instructions (icon presets: machine/hand/dry-clean)
  - *Owner:* member selector
- Sticky Save. On save → duplicate check → possible "Similar item found" sheet (photos side by side, Add Anyway / Cancel)
- Edit mode = same screen prefilled

---

## 2. OUTFITS tab (P1)

- **OOTD hero card (top):** gradient card — weather icon + temp + today's calendar event chip → 3 item thumbnails in a row → buttons: **Wear This** · Shuffle ↻. Collapsed version after worn ("Today: ✓ logged").
- **Mood selector row (P2):** 5 mood pills (Professional, Casual, Bold, Cozy, Party) — filters suggestions + builder
- **Saved outfits:** horizontal shelves by occasion ("Work", "Weekend", "Party") — cards show stacked thumbnails + name + ♥. Tap → Outfit Detail (items list, wear all, edit, delete, share P3, votes P3)
- **FAB "Create Outfit"** → Outfit Builder

## 2a. Outfit Builder (P1)

1. Slots displayed as vertical stack: Top · Bottom · Shoes (+ add slot: Outerwear/Accessory). Tap a slot → wardrobe picker (filtered to that category)
2. After hero piece picked → remaining slots auto-fill with best matches, each showing **Match %** ring
3. Swap arrows on each slot cycle through next-best alternatives
4. Bottom bar: total match score + **Save Outfit** (name + occasion + mood sheet)
5. Weekly challenge banner (P2) appears here when active

---

## 3. CALENDAR & ALERTS tab (P1)

Segmented control: **Calendar | Alerts | Trips**

- **Calendar:** month view, dots on worn days. Tap day → bottom sheet: that day's outfit/items, or "log what you wore" (retroactive logging)
- **Alerts feed:** cards with icon + message + garment thumbnail. Types: Unused 6mo · Growth · Laundry · Lend return · Hand-me-down · Sale (P2/P3 as shipped). Swipe to dismiss (undo snackbar). Actions inline (e.g. growth alert → "Plan hand-me-down")
- **Trips (P2):** list of packing lists + "New Trip" → Packing wizard (see 03 §7): dates → outfits → checklist with progress bar → share

---

## 4. ANALYTICS tab (P1 basic, P2/P3 grows)

- **Summary cards (P1):** Total items · Wardrobe value · Avg cost-per-wear · Items never worn
- **Cost-per-wear list (P1):** best value / worst value toggle, sorted rows (thumb, name, price, wears, CPW)
- **Most/least worn chart (P1):** horizontal bars, top 5 each, year filter
- **Expense tracker (P2):** monthly spend line chart + by-category donut + by-brand list
- **Eco-score ring (P3):** wardrobe score + per-item breakdown + tips
- **Expiry timeline (P3):** items sorted by projected retirement
- **Resale list (P3):** thumb + estimate + Sell button (share sheet)
- **Color palette (P3):** auto-generated palette grid of wardrobe colors + "your dominant palette" card

---

## 5. PROFILE tab (P1)

- Header: avatar, name, subscription badge, "Manage plan"
- **Family:** member cards (avatar, age, current size) → member detail: edit info, height log (chart for kids), their garments count. "+ Add member"
- **Lend/Borrow (P2):** two tabs (Lent / Borrowed), rows with person, item, due date, "Mark returned" / "Remind"
- **Wishlist (P2):** grid of wish items, target price vs current, sale-alert toggle, "Bought it" → converts to Add Item prefilled
- **Hand-me-down planner (P3):** items tagged with from→to member, target season, estimated date, done ✓
- **Sharing circle (P3):** invite via code/link (24h expiry), member list, per-member vote toggle
- **Settings:** notification toggles per type · wear threshold slider (3–12 months) · growth lead time (1–6 months) · currency · theme (light default / dark) · offline sync status · export data (CSV) · logout · delete account (double-confirm)

---

## 6. Overlays & misc

- **Voice search sheet (P2):** mic pulse animation, live transcript, parsed filter chips shown before applying
- **Barcode scanner (P2):** camera overlay, on hit prefills Add form
- **AI Stylist chat (P3):** chat UI, suggestion bubbles render item thumbnails from user's closet, quick prompts ("Tonight's dinner", "Rainy day work fit")
- **Paywall sheet:** shown when free user taps P2/P3 feature — feature list per tier, monthly/one-time toggle
- **Global:** offline banner, error toasts, confirmation dialogs for destructive actions, haptics on key actions

---

## 7. Flow examples

**Add item (happy path):** FAB → camera → auto-square crop → compress → form (color pre-suggested) → save → duplicate check passes → grid updates optimistically → upload finishes in background.

**Morning flow:** 07:00 push "Your outfit for today ☀️ 24°" → tap → OOTD card → Shuffle once → Wear This → all 3 items logged, laundry statuses set, calendar dot added.

**Growth alert flow:** Sunday push → Alerts feed → "Jeans too small by Oct" → tap "Plan hand-me-down" → pick Kabir + winter → planner entry + reminder scheduled → alert dismissed.
