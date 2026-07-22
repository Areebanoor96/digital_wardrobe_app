# Digital Wardrobe App — Project Scope

Flutter mobile app (iOS + Android) with Supabase as the complete backend (database, auth, photo storage, scheduled jobs). Merged from Product Spec PDF v2.0 + notebook feature notes. 33 features across 3 phases.

## Documents

| File | Contents |
|---|---|
| [01-architecture.md](01-architecture.md) | System architecture, tech stack, Flutter project structure, packages, photo pipeline, offline strategy, cron jobs, security |
| [02-database-schema.md](02-database-schema.md) | Complete Postgres SQL: enums, 13 tables, triggers, views, indexes, Row Level Security — ready to run as Supabase migrations |
| [03-features-and-logic.md](03-features-and-logic.md) | All 33 features phased (MVP/v2/v3) + algorithms: outfit matching score, OOTD, growth prediction, duplicate detection, packing, resale, eco-score |
| [04-screens-and-flows.md](04-screens-and-flows.md) | Every screen: layout, components, actions, states, and end-to-end user flows |
| [05-design-system.md](05-design-system.md) | "Airy Closet" design language: colors, typography, components, motion, simplicity rules |
| [06-roadmap.md](06-roadmap.md) | Phased build plan, monetization tiers, free-tier cost budget, risks, success metrics |

## Decisions locked

- **Backend:** Supabase-only (no custom server) — Flutter talks directly to Supabase; Edge Functions + pg_cron for push/scheduled logic
- **Photos:** compressed on-device (~150KB), stored in Supabase Storage, only URLs in DB
- **Matching:** rule-based on-device Dart engine now; AI (chat stylist) as Premium+ in Phase 3
- **Offline:** cache-first with drift (SQLite), queued writes
- **State/nav:** Riverpod + go_router · **Design:** light, modern, Material 3, Plus Jakarta Sans

## Next steps

1. Create Supabase project → run migrations from doc 02
2. `flutter create` + scaffold per doc 01 structure
3. Build Phase 0 (auth + onboarding), then Phase 1 step by step per doc 06
