-- Country / location selection (Setup Wizard) → automatic Analytics currency.
--
-- Adds a single nullable ISO 3166-1 alpha-2 country code to `profiles`. The
-- country is chosen during the Setup Wizard and is the source of the user's
-- default Analytics currency, derived from the centralized
-- CountryCurrencyService mapping.
--
-- The column is nullable so existing users (who onboarded before this field
-- existed) remain unaffected. When the code is NULL the app falls back to the
-- default country (Pakistan / PKR), which matches the application's existing
-- PKR garment-price convention, so no backfill is required and no existing
-- profile data is touched.

alter table public.profiles
add column if not exists country_code text;