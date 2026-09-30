-- Adds the sizing and style-preference fields the Edit Profile screen owns.
--
-- `family_members` is the single source of truth for sizing and style across
-- the whole household, including the account holder's own `self` row. The
-- growth/outgrowth engines already read `height_cm`, `weight_kg`, `shoe_size`
-- and `current_size` from this table, so no changes were needed there.
--
-- `current_size` is intentionally left in place: the outgrowth engine ranks
-- garments against it, and the app keeps it in sync with `tops_size` on save.

alter table public.family_members
  add column if not exists pronouns text,
  add column if not exists gender text,
  add column if not exists shoe_unit text not null default 'EU',
  add column if not exists tops_size text,
  add column if not exists bottoms_size text,
  add column if not exists style_aesthetics text[] not null default '{}',
  add column if not exists color_preferences text[] not null default '{}';

comment on column public.family_members.shoe_unit is
  'Sizing system shoe_size belongs to: EU, US or UK.';

comment on column public.family_members.tops_size is
  'Apparel size for tops. Child age sizes (e.g. 2-3Y) and adult letters (XS-XXL) are both valid.';

comment on column public.family_members.bottoms_size is
  'Apparel size for bottoms. Child age sizes or numeric waist sizes (e.g. 32) are both valid.';

comment on column public.family_members.style_aesthetics is
  'Style aesthetics this member gravitates towards (e.g. Casual, Minimal).';

comment on column public.family_members.color_preferences is
  'Preferred colour shades for this member (e.g. Navy).';
