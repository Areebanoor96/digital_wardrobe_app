# Digital Wardrobe

Phase 0 provides the Flutter application foundation: Material 3 theme, Riverpod, go_router, onboarding, Supabase email/OAuth entry points, setup wizard, database migration, private garment storage policy, and continuous integration.

## MVP scope

The current Phase 1 MVP adds a Wardrobe dashboard, garment photo upload to private Supabase Storage, garment create/read/update/delete, local search and category filters, a manual outfit builder with saved outfits, and a basic editable profile with logout. Weather, notifications, analytics, offline support, family management, alerts, calendar integrations, and automated recommendations are intentionally out of scope.

## Supabase setup

1. Create separate Supabase projects for development and production.
2. Install and log in to the [Supabase CLI](https://supabase.com/docs/guides/cli), link the development project, then run `supabase db push`. This applies [the initial migration](supabase/migrations/20260720000000_initial_schema.sql), including the `garments` private storage bucket and RLS policies.
3. In Supabase Authentication, enable Email, Google, and Apple as appropriate. Set the OAuth redirect URL to `io.supabase.digitalwardrobe://login-callback/` and configure the matching Android/iOS deep-link settings before testing social login.
4. Get the project URL and **anon** key from Supabase Dashboard → Settings → API. Never use or place the service-role key in this app.

Credentials are deliberately not stored in the repository. Launch with your real values:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Use the equivalent values from your production project for a production build. `.env.example` is only a reminder of required names; the application reads compile-time `--dart-define` values.

## Verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Without credentials, the app still opens and displays a configuration notice after onboarding; this prevents accidental use of invented credentials.
