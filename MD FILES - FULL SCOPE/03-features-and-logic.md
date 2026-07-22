# 03 — Feature Master List & Core Logic

All features from the PDF spec v2.0 **+** the notebook notes, merged, de-duplicated, and phased. 33 features total.

---

## 1. Phased feature list

### Phase 1 — MVP (launchable)

| # | Feature | Source | Notes |
|---|---|---|---|
| 1 | Auth + onboarding (email/Google/Apple) | spec | Supabase Auth |
| 2 | Family profiles (me/kids/partner) | spec | needed early for kids alerts |
| 3 | Add item: photo + details (brand, color, size, price, date, occasion, season, mood, fabric) | notes ①, spec #1 | camera/gallery, compression |
| 4 | Wardrobe grid + search + filters (category, color, season, brand, size, occasion) | notes ②, spec #2 | full-text + chips |
| 5 | Item detail view (wear history, CPW, actions) | spec | |
| 6 | Outfit matching (rule-based) + save outfits | notes ③, spec #3 | on-device engine, §3 below |
| 7 | Wear logging ("Worn Today") | spec | trigger updates counts |
| 8 | Wear-frequency alerts ("not worn in 6 months") | notes ④, spec #4 | pg_cron + push |
| 9 | Kids growth alerts (size prediction) | notes ⑤, spec #5 | §5 below |
| 10 | Outfit of the Day (weather + calendar + season + occasion) | notes ⑥, spec #6 | §4 below |
| 11 | Cost-per-wear tracker | notes, spec #7 | price ÷ wear_count |
| 12 | Offline mode (cache-first) | notes ⑮ | drift + queued writes |

### Phase 2 — v2 (premium tier)

| # | Feature | Source | Notes |
|---|---|---|---|
| 13 | Laundry tracker (clean/dirty/washing + reminders) | notes, spec #8 | swipe action + status |
| 14 | Expense tracker (monthly spend, by category/brand) | notes | extends analytics |
| 15 | Packing list generator (trips) | notes, spec #10 | §7 below |
| 16 | Lend/Borrow tracker + return reminders | notes, spec #11 | |
| 17 | Duplicate/similarity detector | notes ①(p2), spec #12 | §6 below |
| 18 | Mood filter (professional/casual/bold/party/cozy) | notes ②(p2), spec #13 | filters matching engine |
| 19 | Wishlist (future buys) | notes ⑪ | |
| 20 | Sale alert on wishlist items | notes ⑫ | manual price update v2; scraping later |
| 21 | Barcode scanner (quick add) | notes ⑭ | prefills brand/name if found |
| 22 | Voice search ("show my black shirts") | notes ⑩ | §8 below |
| 23 | "Shop your closet" weekly challenges | spec #9 | gamification |
| 24 | Vacation planner (multi-day outfit plan) | notes | extends packing |

### Phase 3 — v3 (premium+)

| # | Feature | Source | Notes |
|---|---|---|---|
| 25 | Shared family wardrobe (partner co-manages) | notes ⑬ | RLS shared access |
| 26 | Sharing circle + outfit voting | spec #18, notes ⑧ | invite links |
| 27 | Hand-me-down planner | notes ⑥(p2), spec #16 | |
| 28 | Resale value estimator | notes ⑤(p2), spec #15 | heuristic §9 |
| 29 | Wardrobe expiry timeline (fade/wear-out) | notes ⑦(p2), spec #17 | condition_score |
| 30 | Eco-score / sustainability | notes ⑨(p2), spec #19 | §10 below |
| 31 | Color palette generator (from wardrobe) | notes | fun analytics |
| 32 | Virtual try-on (avatar/bitmoji-style mannequin) | notes ③(p2), spec #14 | measurement-based mannequin first |
| 33 | AI chat stylist | notes ⑯ | LLM API, premium+ only |

**Cut/deferred:** in-app ads (hurts UX at launch), TensorFlow style AI (revisit after real usage data).

---

## 2. Search logic

- Server: Postgres full-text (GIN) over name+brand+color, plus filter params (category, color, season, size, occasion, mood, member).
- On-device (offline + instant-as-you-type): drift cache filtered in Dart; prefix matching on tokens covers the "prefix tree → Blu → Blue/Black" idea.
- Filter chips are AND-combined; each chip category is OR within itself (e.g. color: blue OR black).
- Voice search feeds the same pipeline (§8).

---

## 3. Outfit matching engine (rule-based, on-device Dart)

Input: hero garment + optional occasion + mood + season. Output: ranked outfit combos (top+bottom+shoe [+outer/accessory]).

**Score (0–100) = 40·color + 25·occasion + 15·season + 10·mood + 10·freshness**

1. **Color harmony (40)** — convert hex to HSL:
   - Neutral pairing (black/white/grey/navy/beige with anything): 1.0
   - Monochrome (same hue ±15°, different lightness): 0.9
   - Analogous (hue ±30°): 0.85
   - Complementary (hue 180°±20°): 0.8
   - Triadic (120°±15°): 0.7
   - Clash (else): 0.3
2. **Occasion (25)** — all items share requested occasion: 1.0; adjacent (work↔formal, casual↔sport): 0.6; mismatch: 0.
3. **Season (15)** — item seasons include current/requested season or 'all'.
4. **Mood (10)** — item mood_tags contain selected mood: 1.0; empty tags: 0.5.
5. **Freshness (10)** — prefers less-recently-worn, clean items: `min(days_since_worn/30, 1)`, ×0 if dirty.

Constraints: exactly one bottom (or dress replaces top+bottom), one pair of shoes, max 1 outerwear, dirty/archived/lent-out items excluded. Return top 3 combos; user can swap any slot (re-ranks alternatives for that slot).

Engine is a pure Dart module with unit tests — later swap/augment with AI without touching UI.

---

## 4. Outfit of the Day (OOTD)

Daily, on app open (and 07:00 push via Edge Function):

1. Weather for user's city (cached 1/day): temp, condition.
2. Temp → season bucket: <10° winter · 10–19° autumn/spring · 20–29° summer · ≥30° summer+light fabrics.
3. Rain/snow → require outerwear, exclude suede/canvas shoes.
4. Device calendar today's events → keyword map: "interview/meeting/presentation" → work/formal · "party/dinner/wedding" → party/formal · "gym/match" → sport · none → casual.
5. Run matching engine with derived occasion+season; exclude items worn in last 7 days.
6. Card shows weather + event + 3-item combo + "Wear This" (logs all pieces) + "Shuffle".

---

## 5. Kids growth alerts

Per child (birth_date, height history, current_size):

- Size ladder per region (e.g. 2T→3T→4T→5→6→6X/7…); each step ≈ known height range.
- Growth rate: if ≥2 height entries, cm/month from last two; else age-based default (0–1y: 2cm/mo, 1–3y: 0.8, 3–10y: 0.5).
- Predicted height at +N months (user setting, default 3) → mapped size. If mapped size > garment size → alert: *"Zara's blue jeans will likely be too small by October."*
- Weekly job (Sun 09:00). Alert actions: dismiss · add to hand-me-down plan · add replacement to wishlist.

---

## 6. Duplicate detector

On save of a new item:

1. **Attribute score:** same category (required) + same subcategory (+0.3) + color ΔE < 20 (+0.4) + same brand (+0.15) + same size (+0.15).
2. **Image score (later in v2):** perceptual hash (pHash via `image` package) stored per garment; Hamming distance < 10 → +boost.
3. Combined ≥ 0.8 → bottom sheet: "Looks like you already own this" with side-by-side photos → **Add Anyway / Cancel**.

---

## 7. Packing list generator

Wizard: destination + dates → nights calculated → optional weather lookup for destination → user picks saved outfits or auto-suggest (1 outfit/day via matching engine, re-wearing bottoms every 2 days) → checklist grouped by category + auto-extras rules (≥1 night: charger, toiletries; beach destination: swimwear; formal event flag: formalwear) → checkboxes, progress bar, share as text (WhatsApp/email).

---

## 8. Voice search

`speech_to_text` → transcript → lightweight Dart parser: extract color words, category words, occasion/season words, brand names (matched against user's own brand list) → same filter pipeline as chips. Example: "show my black shirts" → {color: black, category: top, subcategory: shirt}.

---

## 9. Resale value estimator (heuristic)

`resale = price × category_factor × condition_factor × age_factor × brand_factor`

- category_factor: outerwear 0.45, shoes 0.35, dress 0.35, top/bottom 0.25, accessory 0.2
- condition_factor: condition_score/100
- age_factor: max(1 − 0.15 × years_owned, 0.3)
- brand_factor: premium brand list 1.3 · known 1.0 · unknown 0.7

Shown in analytics with "Sell" deep link (Vinted/Poshmark/local marketplace share sheet). Clearly labeled *estimate*.

---

## 10. Eco-score

Per garment (0–100): fabric base score (linen/hemp 90, organic cotton 80, cotton 65, wool 60, viscose 50, polyester/nylon 35, blends averaged) + longevity bonus (wear_count × 0.5, cap 20) − freshness penalty if barely worn (wear_count < 5 after 6 months: −10). Wardrobe score = weighted average. Ring gauge + tips ("Your 12 unworn polyester items are your biggest eco cost — consider the resale tab").

---

## 11. Expiry timeline

condition_score starts at 100, −1 per wear (trigger), −extra per wash for delicate fabrics (laundry feature logs washes). Bands: 100–70 good · 69–40 aging · <40 "retire soon" → appears in expiry timeline chart (Analytics) sorted by projected retirement date (linear extrapolation of decay rate).

---

## 12. Weekly challenges ("shop your closet")

Template pool, one auto-assigned per week: "Wear your 3 least-worn items", "All-neutral week", "No repeats for 7 days", "Style one item 2 different ways". Progress tracked from wear_log; confetti + streak counter on completion. Pure client logic — no backend needed.

---

## 13. AI chat stylist (v3, premium+)

Chat screen → LLM API (Claude/GPT) via Edge Function (key stays server-side). Context injected: compact JSON of user's wardrobe (names, categories, colors, moods) + weather. Answers "what should I wear to a beach wedding?" with items from *their* closet. Rate-limited per tier. This is the only paid-API feature; everything else stays free to run.
