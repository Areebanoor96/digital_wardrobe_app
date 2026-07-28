alter table public.outfits
add column if not exists member_id uuid
references public.family_members(id)
on delete set null;

create index if not exists outfits_member_id_idx
on public.outfits(member_id);

update public.outfits as outfit
set member_id = resolved.member_id
from (
  select
    existing_outfit.id,
    (array_agg(distinct garment.member_id))[1] as member_id
  from public.outfits as existing_outfit
  cross join lateral unnest(existing_outfit.garment_ids) as garment_id
  join public.garments as garment
    on garment.id = garment_id
  group by existing_outfit.id
  having count(distinct garment.member_id) = 1
     and bool_and(garment.member_id is not null)
) as resolved
where outfit.id = resolved.id
  and outfit.member_id is null;