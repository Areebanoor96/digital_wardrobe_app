alter table public.profiles
add column if not exists growth_alerts_enabled boolean not null default true;