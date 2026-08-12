alter table public.family_members
add column if not exists height_cm double precision,
add column if not exists weight_kg double precision,
add column if not exists shoe_size text;

create table if not exists public.growth_measurements (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  member_id uuid not null
    references public.family_members(id)
    on delete cascade,

  recorded_at date not null default current_date,

  height_cm double precision,
  weight_kg double precision,
  clothing_size text,
  shoe_size text,

  created_at timestamptz not null default now()
);

alter table public.growth_measurements
add constraint growth_measurements_has_value
check (
  height_cm is not null
  or weight_kg is not null
  or clothing_size is not null
  or shoe_size is not null
);

alter table public.growth_measurements enable row level security;
create policy "Users can view their own growth measurements"
on public.growth_measurements
for select
using (auth.uid() = user_id);

create policy "Users can insert their own growth measurements"
on public.growth_measurements
for insert
with check (auth.uid() = user_id);

create policy "Users can update their own growth measurements"
on public.growth_measurements
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own growth measurements"
on public.growth_measurements
for delete
using (auth.uid() = user_id);

create index if not exists growth_measurements_member_date_idx
on public.growth_measurements (
  member_id,
  recorded_at desc
);