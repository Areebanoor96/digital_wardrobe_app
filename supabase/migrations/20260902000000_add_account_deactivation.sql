-- Account management: temporary deactivation.
--
-- Adds a single nullable status column to `profiles`. When set, the account is
-- temporarily deactivated (data preserved, sign out applied, reactivation
-- allowed later). NULL (the default) means the account is active.
--
-- No data is deleted here; reactivation simply clears the flag. The status is
-- authoritative: it is read from the server on every app entry point (sign in,
-- session restore, router redirect) and the account-management Edge Functions
-- (service role) are the only path that mutates it.

alter table public.profiles
add column if not exists deactivated_at timestamptz;
