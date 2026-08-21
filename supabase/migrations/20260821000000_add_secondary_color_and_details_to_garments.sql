-- Adds optional secondary garment color and free-form details to garments.
-- All columns are nullable so existing rows and queries stay backward
-- compatible: legacy garments simply read as NULL for these fields.
alter table public.garments add column if not exists secondary_color_name text;
alter table public.garments add column if not exists secondary_color_hex text;
alter table public.garments add column if not exists details text;
