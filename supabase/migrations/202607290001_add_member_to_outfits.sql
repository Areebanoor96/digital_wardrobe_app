alter table public.outfits
add column if not exists member_id uuid
references public.family_members(id)
on delete restrict;

create index if not exists outfits_member_id_idx
on public.outfits(member_id);