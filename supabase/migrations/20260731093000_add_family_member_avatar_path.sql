alter table public.family_members
add column if not exists avatar_path text;

alter table public.family_members
drop column if exists avatar_url;