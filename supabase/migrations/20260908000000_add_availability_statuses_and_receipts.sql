-- Add three new availability statuses (sent for laundry, damaged, sent to
-- tailor) and a receipt attachment path for garment purchase receipts.

alter table public.garments
drop constraint if exists garments_availability_status_check;

alter table public.garments
add constraint garments_availability_status_check
check (
  availability_status is null
  or availability_status in (
    'available',
    'lent',
    'borrowed',
    'in_storage',
    'donated',
    'lost',
    'sent_for_laundry',
    'damaged',
    'sent_to_tailor'
  )
);

alter table public.garments
add column if not exists receipt_path text;