# 02 — Database Schema (Supabase Postgres)

Run these migrations in order via Supabase CLI. `auth.users` is managed by Supabase Auth; we extend it with `profiles`.

---

## 1. Enums

```sql
create type garment_category as enum ('top','bottom','dress','outerwear','shoe','accessory','jewelry','bag');
create type occasion_type    as enum ('casual','formal','sport','party','work','sleep','ethnic');
create type season_type      as enum ('summer','winter','spring','autumn','all');
create type mood_type        as enum ('professional','casual','bold','cozy','party','minimal');
create type relationship_type as enum ('self','child','partner','other');
create type laundry_status   as enum ('clean','dirty','washing','ironing');
create type alert_type       as enum ('unused','growth','laundry','lend_return','hand_me_down','expiry','sale','ootd');
create type handover_target  as enum ('sibling','cousin','donation','resale');
create type subscription_tier as enum ('free','premium','premium_plus');
```

---

## 2. Core tables

```sql
-- extends auth.users
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  avatar_url text,
  location_city text,
  lat float, lng float,                          -- for weather
  subscription_tier subscription_tier default 'free',
  wear_threshold_days int default 180,
  growth_alert_months int default 3,
  notif_prefs jsonb default '{"unused":true,"growth":true,"laundry":true,"lend":true,"ootd":true,"sale":true}',
  fcm_token text,
  created_at timestamptz default now()
);

create table family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  relationship relationship_type default 'self',
  birth_date date,
  height_cm float, weight_kg float,
  current_size text,                              -- e.g. "6T", "M"
  avatar_url text,
  created_at timestamptz default now()
);

create table garments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  member_id uuid references family_members(id) on delete set null,
  name text not null,
  category garment_category not null,
  subcategory text,
  color_hex text,                                 -- "#1A2B3C"
  color_name text,                                -- "Navy"
  secondary_colors text[],
  size text,
  brand text,
  price numeric(10,2),
  currency text default 'PKR',
  purchase_date date,
  occasions occasion_type[] default '{casual}',
  seasons season_type[] default '{all}',
  mood_tags mood_type[] default '{}',
  fabric text,
  wash_instructions text,
  barcode text,                                   -- from scanner
  photo_urls text[] default '{}',                 -- [full, thumb, extra…]
  image_hash text,                                -- perceptual hash for duplicate detection
  wear_count int default 0,
  last_worn_date date,
  laundry_status laundry_status default 'clean',
  dirty_since timestamptz,
  condition_score int default 100 check (condition_score between 0 and 100), -- expiry/fade
  eco_score int check (eco_score between 0 and 100),
  resale_estimate numeric(10,2),
  is_archived boolean default false,              -- sold/donated/discarded
  archived_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text,
  garment_ids uuid[] not null,                    -- 2–6 items
  mood mood_type,
  occasion occasion_type,
  season season_type,
  is_favorite boolean default false,
  times_worn int default 0,
  cover_photo_url text,
  created_at timestamptz default now()
);

create table wear_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  garment_id uuid not null references garments(id) on delete cascade,
  outfit_id uuid references outfits(id) on delete set null,
  worn_date date not null default current_date,
  weather_temp float, weather_cond text,          -- snapshot for learning later
  created_at timestamptz default now()
);
```

---

## 3. Feature tables

```sql
create table alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  type alert_type not null,
  garment_id uuid references garments(id) on delete cascade,
  member_id uuid references family_members(id) on delete cascade,
  title text not null,
  body text,
  is_read boolean default false,
  is_dismissed boolean default false,
  created_at timestamptz default now()
);

create table lend_borrow_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  garment_id uuid not null references garments(id) on delete cascade,
  direction text not null check (direction in ('lent','borrowed')),
  person_name text not null,
  date_out date default current_date,
  expected_return_date date,
  returned boolean default false,
  returned_date date
);

create table hand_me_down_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  garment_id uuid not null references garments(id) on delete cascade,
  from_member_id uuid references family_members(id),
  to_member_id uuid references family_members(id),
  target handover_target default 'sibling',
  target_season season_type,
  estimated_date date,
  done boolean default false
);

create table wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  category garment_category,
  brand text, color_name text,
  target_price numeric(10,2),
  current_price numeric(10,2),
  product_url text, photo_url text,
  sale_alert boolean default true,
  purchased boolean default false,
  created_at timestamptz default now()
);

create table packing_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  trip_name text not null,
  destination text,
  start_date date, end_date date,
  outfit_ids uuid[] default '{}',
  extra_items jsonb default '[]',                 -- [{"name":"Charger","packed":false}]
  packed_garments jsonb default '{}',             -- {garment_id: true}
  created_at timestamptz default now()
);

-- v3: sharing circle
create table sharing_circles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  invite_code text unique not null,
  invite_expires_at timestamptz,
  created_at timestamptz default now()
);

create table circle_members (
  circle_id uuid references sharing_circles(id) on delete cascade,
  member_user_id uuid references profiles(id) on delete cascade,
  can_vote boolean default true,
  joined_at timestamptz default now(),
  primary key (circle_id, member_user_id)
);

create table outfit_votes (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid not null references outfits(id) on delete cascade,
  voter_id uuid not null references profiles(id) on delete cascade,
  vote int not null check (vote in (-1, 1)),
  comment text,
  created_at timestamptz default now(),
  unique (outfit_id, voter_id)
);
```

---

## 4. Triggers & functions

```sql
-- wear logging: increment count + set last_worn + mark dirty
create or replace function fn_after_wear() returns trigger as $$
begin
  update garments set
    wear_count = wear_count + 1,
    last_worn_date = new.worn_date,
    laundry_status = 'dirty',
    dirty_since = now(),
    condition_score = greatest(condition_score - 1, 0)  -- gradual wear-out for expiry timeline
  where id = new.garment_id;
  return new;
end; $$ language plpgsql security definer;

create trigger trg_after_wear after insert on wear_log
for each row execute function fn_after_wear();

-- auto profile on signup
create or replace function fn_new_user() returns trigger as $$
begin
  insert into profiles (id, full_name) values (new.id, new.raw_user_meta_data->>'full_name');
  insert into family_members (user_id, name, relationship)
    values (new.id, coalesce(new.raw_user_meta_data->>'full_name','Me'), 'self');
  return new;
end; $$ language plpgsql security definer;

create trigger trg_new_user after insert on auth.users
for each row execute function fn_new_user();

-- updated_at
create or replace function fn_touch() returns trigger as $$
begin new.updated_at = now(); return new; end; $$ language plpgsql;
create trigger trg_garments_touch before update on garments
for each row execute function fn_touch();
```

---

## 5. Views (analytics)

```sql
create view v_cost_per_wear as
select g.id, g.user_id, g.name, g.price, g.wear_count,
       case when g.wear_count = 0 then g.price
            else round(g.price / g.wear_count, 2) end as cost_per_wear
from garments g where g.is_archived = false and g.price is not null;

create view v_wardrobe_stats as
select user_id,
       count(*) as total_items,
       sum(price) as total_value,
       round(avg(case when wear_count=0 then price else price/wear_count end),2) as avg_cpw,
       round(avg(eco_score)) as avg_eco_score
from garments where is_archived = false
group by user_id;
```

---

## 6. Indexes

```sql
create index idx_garments_user on garments(user_id) where is_archived = false;
create index idx_garments_search on garments using gin (to_tsvector('simple', name || ' ' || coalesce(brand,'') || ' ' || coalesce(color_name,'')));
create index idx_garments_category on garments(user_id, category);
create index idx_wear_log_garment on wear_log(garment_id, worn_date desc);
create index idx_wear_log_user_date on wear_log(user_id, worn_date desc);
create index idx_alerts_user on alerts(user_id, is_dismissed, created_at desc);
```

The GIN index powers search (the "prefix tree" idea from the notes — Postgres full-text + `ilike` prefix matching does this server-side; on-device search over the drift cache handles offline).

---

## 7. Row Level Security

```sql
-- pattern applied to every user-owned table:
alter table garments enable row level security;
create policy "own rows" on garments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- repeat for: profiles(id), family_members, outfits, wear_log, alerts,
-- lend_borrow_log, hand_me_down_plans, wishlist_items, packing_lists, sharing_circles(owner_id)

-- circle members can view shared outfits (v3):
create policy "circle can view outfits" on outfits for select using (
  exists (
    select 1 from circle_members cm
    join sharing_circles sc on sc.id = cm.circle_id
    where cm.member_user_id = auth.uid() and sc.owner_id = outfits.user_id
  )
);
create policy "circle can vote" on outfit_votes
  for insert with check (auth.uid() = voter_id);
```

Storage policy: bucket `garments`, path convention `{user_id}/…`:

```sql
create policy "own photos" on storage.objects for all
using (bucket_id = 'garments' and (storage.foldername(name))[1] = auth.uid()::text);
```

---

## 8. Size budget (free tier 500MB)

| Data | Row size est. | 5,000 garments |
|---|---|---|
| garments | ~1KB | 5MB |
| wear_log (3 yrs daily) | ~150B | ~2MB |
| everything else | — | <5MB |

DB usage is trivial; **photos (Storage 1GB) are the real limit** — hence client-side compression.
