alter table public.garments
add column if not exists fit text,
add column if not exists pattern text,
add column if not exists fabric_weight text,
add column if not exists sleeve_length text;
