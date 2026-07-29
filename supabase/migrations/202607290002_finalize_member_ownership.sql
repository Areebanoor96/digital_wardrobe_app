alter table public.garments
alter column member_id set not null;

alter table public.outfits
alter column member_id set not null;

alter table public.wear_log
alter column member_id set not null;