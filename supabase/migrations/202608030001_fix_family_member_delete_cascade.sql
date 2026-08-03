-- Garments belonging to a deleted wardrobe profile
-- should be deleted with that profile.
alter table public.garments
drop constraint if exists garments_member_id_fkey;

alter table public.garments
add constraint garments_member_id_fkey
foreign key (member_id)
references public.family_members(id)
on delete cascade;


-- Outfits belonging to a deleted wardrobe profile
-- should be deleted with that profile.
alter table public.outfits
drop constraint if exists outfits_member_id_fkey;

alter table public.outfits
add constraint outfits_member_id_fkey
foreign key (member_id)
references public.family_members(id)
on delete cascade;


-- Wear history belongs to the wardrobe profile,
-- so it should also be removed.
alter table public.wear_log
drop constraint if exists wear_log_member_id_fkey;

alter table public.wear_log
add constraint wear_log_member_id_fkey
foreign key (member_id)
references public.family_members(id)
on delete cascade;