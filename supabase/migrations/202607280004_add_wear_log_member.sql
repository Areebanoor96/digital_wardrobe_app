alter table public.wear_log
add column if not exists member_id uuid
references public.family_members(id)
on delete set null;

create index if not exists wear_log_member_id_idx
on public.wear_log(member_id);

update public.wear_log as wear
set member_id = garment.member_id
from public.garments as garment
where wear.garment_id = garment.id
  and wear.member_id is null
  and garment.member_id is not null;

