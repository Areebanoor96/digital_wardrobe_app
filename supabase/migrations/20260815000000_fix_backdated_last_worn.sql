create or replace function public.fn_after_wear()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  update public.garments
  set
    wear_count = wear_count + 1,

    last_worn_date = greatest(
      coalesce(last_worn_date, new.worn_date),
      new.worn_date
    ),

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
$function$;