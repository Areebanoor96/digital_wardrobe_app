alter table public.garments
add column if not exists purchase_store text;

alter table public.wear_log
add column if not exists event_name text;

alter table public.wear_log
add column if not exists notes text;

alter table public.wear_log
add column if not exists laundry_status_after text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'wear_log_laundry_status_after_check'
      and conrelid = 'public.wear_log'::regclass
  ) then
    alter table public.wear_log
    add constraint wear_log_laundry_status_after_check
    check (
      laundry_status_after is null
      or laundry_status_after in (
        'clean',
        'dirty',
        'washing',
        'ironing'
      )
    );
  end if;
end
$$;