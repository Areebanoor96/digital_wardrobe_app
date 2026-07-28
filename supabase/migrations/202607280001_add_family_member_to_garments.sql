alter table garments
add column family_member_id uuid references family_members(id);

create index garments_family_member_idx
on garments(family_member_id);
