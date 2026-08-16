create or replace function public.wear_outfit(
  p_outfit_id uuid,
  p_member_id uuid,
  p_worn_date date default current_date,
  p_event_name text default null,
  p_notes text default null,
  p_laundry_status_after public.laundry_status default null
)
returns void
language plpgsql
security invoker
set search_path = public
as $function$
declare
  v_user_id uuid;
  v_garment_ids uuid[];
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select garment_ids
  into v_garment_ids
  from public.outfits
  where id = p_outfit_id
    and member_id = p_member_id
    and user_id = v_user_id;

  if not found then
    raise exception 'Outfit not found for this profile';
  end if;

  if v_garment_ids is null or cardinality(v_garment_ids) = 0 then
    raise exception 'Outfit contains no garments';
  end if;

  insert into public.wear_log (
    user_id,
    member_id,
    garment_id,
    outfit_id,
    worn_date,
    event_name,
    notes,
    laundry_status_after
  )
  select
    v_user_id,
    p_member_id,
    garment_id,
    p_outfit_id,
    p_worn_date,
    nullif(trim(p_event_name), ''),
    nullif(trim(p_notes), ''),
    p_laundry_status_after
  from unnest(v_garment_ids) as garment_id;

  update public.outfits
  set times_worn = coalesce(times_worn, 0) + 1
  where id = p_outfit_id
    and member_id = p_member_id
    and user_id = v_user_id;
end;
$function$;