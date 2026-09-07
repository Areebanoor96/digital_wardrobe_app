-- Wardrobe category expansion (responsive catalog categories).
--
-- Adds four plannable categories to the `garment_category` enum so the
-- Wardrobe catalog's category row and the Add Listing form stay in sync with
-- what the database can persist. Purely additive: existing values keep their
-- meaning and storage order is irrelevant to the app (the client maps by
-- name), so no existing rows or behaviour change.
--
-- Note: PostgreSQL appends new enum values after the existing declarations;
-- the app never relies on enum position, only on value names.

alter type public.garment_category
add value if not exists 'activewear';

alter type public.garment_category
add value if not exists 'sleepwear';

alter type public.garment_category
add value if not exists 'watches';

alter type public.garment_category
add value if not exists 'other';