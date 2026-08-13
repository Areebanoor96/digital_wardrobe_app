-- Complete Wear Logging.
-- 1) Allow a wear entry to choose the resulting laundry status instead of
--    the trigger forcing every garment to 'dirty'.
-- 2) Roll garment statistics back when a wear record is deleted.

-- The original fn_after_wear() unconditionally set laundry_status = 'dirty'.
-- Respect the recorded laundry_status_after choice (null keeps current status).
create or replace function public.fn_after_wear()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.garments
     set wear_count = wear_count + 1,
         last_worn_date = new.worn_date,
         laundry_status = case
           when new.laundry_status_after is null then laundry_status
           else new.laundry_status_after::public.laundry_status
         end,
         dirty_since = case
           when new.laundry_status_after = 'dirty' then now()
           else dirty_since
         end,
         condition_score = greatest(condition_score - 1, 0)
   where id = new.garment_id;

  return new;
end;
$$;

-- Roll garment statistics back when a wear record is deleted so that
-- wear_count and last_worn_date stay in sync with the remaining rows.
create or replace function public.fn_after_wear_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  latest_worn date;
begin
  select max(worn_date)
    into latest_worn
    from public.wear_log
   where garment_id = old.garment_id;

  update public.garments
     set wear_count = greatest(coalesce(wear_count, 0) - 1, 0),
         last_worn_date = latest_worn,
         condition_score = least(condition_score + 1, 100)
   where id = old.garment_id;

  return old;
end;
$$;

drop trigger if exists trg_after_wear_delete on public.wear_log;
create trigger trg_after_wear_delete
after delete on public.wear_log
for each row
execute function public.fn_after_wear_delete();