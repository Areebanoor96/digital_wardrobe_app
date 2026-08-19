alter table public.family_members
add column if not exists foot_length_cm double precision;

alter table public.growth_measurements
add column if not exists foot_length_cm double precision;

alter table public.growth_measurements
drop constraint if exists growth_measurements_has_value;

alter table public.growth_measurements
add constraint growth_measurements_has_value
check (
  height_cm is not null
  or weight_kg is not null
  or clothing_size is not null
  or shoe_size is not null
  or foot_length_cm is not null
);