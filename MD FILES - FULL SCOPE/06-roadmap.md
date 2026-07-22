# 06 — Roadmap, Monetization & Budget

---

## 1. Build phases

### Phase 0 — Foundation
Supabase projects (dev+prod) · migrations from 02 · storage bucket + policies · Flutter scaffold (router, theme, Riverpod, models) · auth screens + Google/Apple sign-in · onboarding + setup wizard · CI (GitHub Actions: analyze, test, build).

### Phase 1 — MVP → **beta launch**
1. Add item (photo pipeline, compression, form, color suggestion) · wardrobe grid
2. Search + filters · item detail · wear logging · drift offline cache
3. Matching engine (pure Dart + unit tests) · outfit builder · saved outfits
4. Alerts infra (pg_cron + Edge Functions + FCM) · unused alerts · growth alerts · family/height tracking
5. OOTD (weather + device calendar) · daily push
6. Cost-per-wear + basic analytics · polish, empty states, beta to 20–50 testers (TestFlight/Play internal)

### Phase 2 — v2 → **public launch + Premium**
1. Laundry tracker · expense tracker
2. Packing generator + vacation planner · lend/borrow
3. Duplicate detector (attributes; pHash if time) · mood filter
4. Wishlist + sale alerts (manual price) · barcode scanner
5. Voice search · weekly challenges · dark theme
6. Paywall + in-app purchases (RevenueCat) · store listing polish · **public release**

### Phase 3 — v3 → **Premium+**
1. Shared family wardrobe · sharing circle + voting
2. Hand-me-down planner · resale estimator
3. Eco-score · expiry timeline · color palette generator
4. AI chat stylist (Edge Function + LLM) · mannequin try-on v1 (measurement silhouette)
5. Perf pass, accessibility audit, v3 release

Every phase ends with a working, testable build. Cut list if behind: try-on → later; voice search → later; challenges → later.

---

## 2. Monetization (from spec, adjusted)

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | All Phase 1 (MVP) features, up to ~200 items |
| Premium | $4.99/mo or $19.99 lifetime | Phase 2 features, unlimited items |
| Premium+ | $9.99/mo | Everything + AI stylist, sharing circle, priority backup |

Add-ons later: resale affiliate links, sponsored sustainable brands. **No ads at launch.** IAP via RevenueCat (free tier) to manage both stores.

---

## 3. Running cost budget (launch → ~5K users)

| Service | Free tier | Expected use | Cost |
|---|---|---|---|
| Supabase | 500MB DB, 1GB storage, 50K MAU, 500K edge calls | comfortably within | $0 |
| Firebase FCM | unlimited push | — | $0 |
| OpenWeatherMap | 1,000 calls/day | 1 cached call/user/day; batch cities in Edge Function | $0 |
| RevenueCat | free to $2.5K MRR | — | $0 |
| Google Play | one-time $25 | — | $25 |
| Apple Developer | $99/yr | — | $99/yr |
| LLM API (P3 only) | — | rate-limited, Premium+ only | ~$0.01–0.03/chat, priced into tier |

First real upgrade trigger: **photo storage >1GB** (~6.5K photos) → Supabase Pro $25/mo — by then Premium revenue should cover it.

---

## 4. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Manual item entry is tedious → churn | barcode scan, color auto-suggest, 3 required fields only, batch-add mode later |
| Matching feels dumb | tuned rule weights + easy swap UI; collect "kept vs swapped" data to tune, AI later |
| Free tier limits hit | compression, thumbnails, image cleanup on archive; monitor dashboard |
| Growth prediction inaccurate | conservative lead time, present as "likely", easy dismiss |
| Scope creep (33 features!) | phases are strict; nothing from P2 starts before beta ships |
| Store rejection (photos of kids' data) | privacy policy, data deletion in-app, no public sharing of child data |

---

## 5. Success metrics (beta)

Activation: ≥10 items added in first week · Retention: D30 ≥ 25% · Engagement: ≥3 wear logs/week · OOTD acceptance ("Wear This") ≥ 30% · Premium conversion after public launch ≥ 3%.
