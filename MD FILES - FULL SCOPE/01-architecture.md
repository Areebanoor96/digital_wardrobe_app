# 01 — Architecture & Tech Stack

Digital Wardrobe App · Flutter + Supabase · Scope v1.0 (July 2026)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     FLUTTER APP (iOS + Android)          │
│                                                          │
│  UI Layer (screens, widgets, design system)              │
│        │                                                 │
│  State Layer (Riverpod providers)                        │
│        │                                                 │
│  Repository Layer (garments, outfits, alerts, family…)   │
│        │                          │                      │
│  Local cache (drift/SQLite,       │  Rule Engine (Dart)  │
│  offline mode)                    │  · outfit matching   │
│        │                          │  · color harmony     │
│        ▼                          │  · duplicate check   │
└────────┼──────────────────────────┼──────────────────────┘
         │ supabase_flutter SDK (HTTPS + realtime)
         ▼
┌─────────────────────────────────────────────────────────┐
│                        SUPABASE (free tier)              │
│                                                          │
│  Auth          email / Google / Apple sign-in            │
│  Postgres DB   all tables + Row Level Security           │
│  Storage       garment photos (compressed client-side)   │
│  Edge Functions (Deno/TS)                                 │
│    · send-push (FCM)                                     │
│    · daily-alerts (called by pg_cron)                    │
│    · ootd-suggestion (weather + calendar)                │
│  pg_cron       scheduled jobs (unused/growth/laundry…)   │
└─────────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
  OpenWeatherMap API       Firebase FCM (push only)
  (free, 1000 calls/day)   (free, unlimited)
```

Key principle: **no custom server**. Flutter talks directly to Supabase. All heavy but simple logic (matching, scoring, filtering) runs **on-device in Dart** — instant, free, works offline. Only things that must run without the app open (scheduled alerts, push) live in Edge Functions + pg_cron.

---

## 2. Why each piece

| Concern | Choice | Reason |
|---|---|---|
| Mobile app | Flutter 3.x | Single codebase iOS+Android, requested |
| Database | Supabase Postgres | Free 500MB, relational fits our schema, RLS security |
| Auth | Supabase Auth | Email + Google + Apple built in, free 50K MAU |
| Photos | Supabase Storage | 1GB free ≈ 6–8K compressed photos; DB stores URLs only |
| Push | Firebase FCM | Free, standard; triggered from Edge Function |
| Scheduled jobs | pg_cron (Supabase) | Free cron inside Postgres, calls Edge Functions |
| Weather | OpenWeatherMap free | 1,000 calls/day; cache 1 result/user/day |
| Calendar | device calendar (`device_calendar` pkg) | No Google API setup needed; reads local calendar with permission |
| Outfit matching | Dart rule engine on-device | Zero cost, offline, instant. AI later (v3+) |
| Local cache / offline | drift (SQLite) + cached_network_image | Offline mode = feature #15 in notes |
| Barcode scan | `mobile_scanner` pkg | On-device, free |
| Voice search | `speech_to_text` pkg | On-device speech recognition, free |

---

## 3. Flutter project structure (feature-first)

```
lib/
├── main.dart
├── app.dart                     # MaterialApp, router, theme
├── core/
│   ├── theme/                   # design system (see 05-design-system.md)
│   ├── router/                  # go_router config
│   ├── constants/               # enums, sizes, strings
│   ├── utils/                   # formatters, color utils, validators
│   └── services/
│       ├── supabase_service.dart
│       ├── image_service.dart   # compress + upload pipeline
│       ├── weather_service.dart
│       ├── notification_service.dart  # FCM token, local notifs
│       └── speech_service.dart
├── features/
│   ├── auth/            # login, signup, onboarding
│   ├── wardrobe/        # grid, search, filters, item detail
│   ├── garment_form/    # add/edit item, barcode, duplicate check
│   ├── outfits/         # OOTD, saved outfits, builder, mood filter
│   ├── matching/        # rule engine (pure Dart, unit-tested)
│   ├── calendar_alerts/ # calendar view, alert feed
│   ├── packing/         # trip packing generator
│   ├── analytics/       # cost-per-wear, charts, eco-score, resale
│   ├── laundry/
│   ├── family/          # members, growth, hand-me-down
│   ├── lend_borrow/
│   ├── wishlist/
│   ├── sharing/         # sharing circle, voting (v3)
│   └── profile/         # settings, subscription
└── data/
    ├── models/          # Garment, Outfit, Member… (freezed)
    ├── repositories/    # one per feature, Supabase + drift
    └── local/           # drift database, sync logic
```

Each `features/x/` folder contains `screens/`, `widgets/`, `providers/`.

---

## 4. Key packages

| Package | Purpose |
|---|---|
| supabase_flutter | DB, auth, storage, realtime |
| flutter_riverpod | state management |
| go_router | navigation, deep links |
| freezed + json_serializable | immutable models |
| drift | local SQLite for offline cache |
| flutter_image_compress | photo compression before upload |
| image_picker | camera/gallery |
| cached_network_image | photo caching/offline display |
| fl_chart | analytics charts |
| firebase_messaging + flutter_local_notifications | push |
| mobile_scanner | barcode scanning |
| speech_to_text | voice search |
| device_calendar | OOTD calendar context |
| geolocator | city for weather |
| table_calendar | calendar screen |
| shimmer | loading skeletons |

---

## 5. Photo pipeline

1. Capture/pick image → crop to square (optional)
2. Compress on-device: max 1080px, JPEG quality 75 → ~100–200KB
3. Also generate 300px thumbnail (~20KB) for grid
4. Upload both to Storage bucket `garments/{user_id}/{garment_id}/{full|thumb}.jpg`
5. Save public URLs (bucket is private; use signed URLs via RLS-protected policy) in `garments.photo_urls`
6. Grid uses thumbnails; detail view uses full image; all cached locally

Budget: 1GB free ÷ ~150KB avg = **~6,500 photos** before upgrade needed.

---

## 6. Offline strategy (feature: offline mode)

- drift mirrors core tables (garments, outfits, wear_log, members)
- Reads always hit local cache first → render instantly → refresh from Supabase in background
- Writes while offline are queued in a local `pending_ops` table → replayed on reconnect (last-write-wins)
- Photos: cached_network_image keeps viewed images; new photos queue for upload
- Rule engine is pure Dart → matching, search, filters fully work offline

---

## 7. Server-side logic (Edge Functions + pg_cron)

| Job | Schedule (pg_cron) | Logic |
|---|---|---|
| unused-wear-alert | daily 08:00 | garments where `last_worn_date < now() - wear_threshold` → insert alert row + push |
| growth-alert | weekly Sun 09:00 | kids: compare garment size vs predicted size at +N months → alert + push |
| laundry-reminder | daily 09:00 | `is_dirty` for >3 days → push |
| lend-return | daily 10:00 | `expected_return_date = today` → push |
| hand-me-down | monthly 1st 08:00 | items tagged for sibling where target season ≈ next month → push |
| ootd-push | daily 07:00 | Edge Function: fetch weather → pick outfit → push "Outfit of the Day" |
| sale-alert (v2) | daily | wishlist items: check price API/manual flag → push |

Alerts are written to an `alerts` table (feed in app) **and** sent via FCM. All toggleable per type in settings.

---

## 8. Security model

- RLS on every table: `user_id = auth.uid()` (details in 02-database-schema.md)
- Storage policies: users read/write only `garments/{their_uid}/**`
- Sharing circle (v3): membership table grants read-only access to shared outfits via RLS policy
- API keys (weather) live in Edge Functions env, never in the app binary

---

## 9. Environments

- **dev**: separate Supabase project + `.env` via `--dart-define`
- **prod**: second Supabase project (both free)
- Migrations: SQL files in `/supabase/migrations`, applied with Supabase CLI (`supabase db push`)
