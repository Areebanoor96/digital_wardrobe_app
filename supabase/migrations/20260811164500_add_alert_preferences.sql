alter table public.profiles
add column if not exists unused_alerts_enabled boolean not null default true,
add column if not exists laundry_alerts_enabled boolean not null default true,
add column if not exists ootd_alerts_enabled boolean not null default true;