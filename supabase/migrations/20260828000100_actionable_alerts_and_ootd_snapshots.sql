alter table public.alerts
add column if not exists target_type text,
add column if not exists target_id uuid,
add column if not exists action_payload jsonb not null default '{}'::jsonb,
add column if not exists read_at timestamptz,
add column if not exists dismissed_at timestamptz;

create table if not exists public.ootd_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_id uuid not null references public.family_members(id) on delete cascade,
  garment_ids uuid[] not null,
  score int not null default 0 check (score between 0 and 100),
  reason text not null,
  reasons jsonb not null default '[]'::jsonb,
  context jsonb not null default '{}'::jsonb,
  weather_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index if not exists alerts_target_idx
on public.alerts (user_id, member_id, target_type, target_id);

create unique index if not exists alerts_active_target_unique_idx
on public.alerts (user_id, member_id, type, target_type, target_id)
where is_dismissed = false
  and target_type is not null
  and target_id is not null;

create index if not exists ootd_recommendations_user_member_created_idx
on public.ootd_recommendations (user_id, member_id, created_at desc);

create index if not exists ootd_recommendations_user_member_expires_idx
on public.ootd_recommendations (user_id, member_id, expires_at);

create index if not exists ootd_recommendations_garment_ids_idx
on public.ootd_recommendations using gin (garment_ids);

alter table public.ootd_recommendations enable row level security;

create policy "own ootd recommendations"
on public.ootd_recommendations
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
