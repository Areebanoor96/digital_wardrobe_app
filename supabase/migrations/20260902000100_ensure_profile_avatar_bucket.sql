-- Account management: ensure the profile-avatars storage bucket exists with the
-- same per-user folder ownership policy used by the garments bucket.
--
-- The client already writes avatars to this bucket (family_repository), but the
-- bucket + RLS policy were never captured in a migration. Making it explicit
-- guarantees the permanent-deletion Edge Function can enumerate and remove a
-- user's avatar objects from a known bucket.

insert into storage.buckets (id, name, public)
values ('profile_avatars', 'profile_avatars', false)
on conflict (id) do nothing;

drop policy if exists "own profile avatars" on storage.objects;
create policy "own profile avatars"
on storage.objects
for all
using (
  bucket_id = 'profile_avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile_avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
