-- Production garment management cleanup.
-- Keeps legacy garment fields/enums for backward compatibility while adding
-- canonical status, stitching, ironing, locations, lending notes, and sizes.

alter type public.season_type add value if not exists 'rainy';

alter table public.garments
add column if not exists availability_status text,
add column if not exists stitching_status text,
add column if not exists ironing_status text,
add column if not exists location_id uuid;

alter table public.garments
drop constraint if exists garments_availability_status_check;

alter table public.garments
add constraint garments_availability_status_check
check (
  availability_status is null
  or availability_status in (
    'available',
    'lent',
    'borrowed',
    'in_storage',
    'donated',
    'lost'
  )
);

alter table public.garments
drop constraint if exists garments_stitching_status_check;

alter table public.garments
add constraint garments_stitching_status_check
check (
  stitching_status is null
  or stitching_status in ('stitched', 'unstitched')
);

alter table public.garments
drop constraint if exists garments_ironing_status_check;

alter table public.garments
add constraint garments_ironing_status_check
check (
  ironing_status is null
  or ironing_status in ('ironed', 'needs_ironing')
);

update public.garments
set availability_status = 'available'
where availability_status is null;

alter table public.garments
alter column availability_status set default 'available';

alter table public.garments
alter column availability_status set not null;

alter table public.lend_borrow_log
add column if not exists notes text;

create table if not exists public.garment_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references public.profiles(id)
    on delete cascade,
  member_id uuid not null
    references public.family_members(id)
    on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint garment_locations_name_not_blank check (length(trim(name)) > 0)
);

create unique index if not exists garment_locations_member_name_unique
on public.garment_locations (member_id, lower(trim(name)));

create index if not exists garment_locations_user_member_idx
on public.garment_locations (user_id, member_id);

alter table public.garment_locations enable row level security;

drop policy if exists "own garment locations" on public.garment_locations;
create policy "own garment locations"
on public.garment_locations
for all
using (
  auth.uid() = garment_locations.user_id
  and exists (
    select 1
    from public.family_members fm
    where fm.id = garment_locations.member_id
      and fm.user_id = auth.uid()
  )
)
with check (
  auth.uid() = garment_locations.user_id
  and exists (
    select 1
    from public.family_members fm
    where fm.id = garment_locations.member_id
      and fm.user_id = auth.uid()
  )
);

alter table public.garments
drop constraint if exists garments_location_id_fkey;

alter table public.garments
add constraint garments_location_id_fkey
foreign key (location_id)
references public.garment_locations(id)
on delete set null;

create index if not exists garments_location_id_idx
on public.garments(location_id);

create index if not exists garments_availability_status_idx
on public.garments(user_id, member_id, availability_status)
where is_archived = false;

create table if not exists public.garment_sizes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references public.profiles(id)
    on delete cascade,
  garment_id uuid not null
    references public.garments(id)
    on delete cascade,
  size text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint garment_sizes_size_not_blank check (length(trim(size)) > 0)
);

create unique index if not exists garment_sizes_garment_size_unique
on public.garment_sizes (garment_id, lower(trim(size)));

create index if not exists garment_sizes_user_garment_idx
on public.garment_sizes(user_id, garment_id, sort_order);

alter table public.garment_sizes enable row level security;

drop policy if exists "own garment sizes" on public.garment_sizes;
create policy "own garment sizes"
on public.garment_sizes
for all
using (
  auth.uid() = garment_sizes.user_id
  and exists (
    select 1
    from public.garments g
    where g.id = garment_sizes.garment_id
      and g.user_id = auth.uid()
  )
)
with check (
  auth.uid() = garment_sizes.user_id
  and exists (
    select 1
    from public.garments g
    where g.id = garment_sizes.garment_id
      and g.user_id = auth.uid()
  )
);

insert into public.garment_sizes (user_id, garment_id, size, sort_order)
select g.user_id, g.id, trim(g.size), 0
from public.garments g
where g.size is not null
  and length(trim(g.size)) > 0
  and not exists (
    select 1
    from public.garment_sizes gs
    where gs.garment_id = g.id
      and lower(trim(gs.size)) = lower(trim(g.size))
  );

drop trigger if exists trg_garment_locations_touch on public.garment_locations;
create trigger trg_garment_locations_touch
before update on public.garment_locations
for each row
execute function public.fn_touch();
