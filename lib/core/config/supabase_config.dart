class SupabaseConfig {
  const SupabaseConfig._();

  // Testing/dev credentials are embedded as defaults so the app always
  // connects without needing --dart-define flags. Passing --dart-define
  // (e.g. for production) still overrides these values.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ungfjljsnuzrsuuykpkb.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVuZ2ZqbGpzbnV6cnN1dXlrcGtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1MzgzMTEsImV4cCI6MjEwMDExNDMxMX0.vzmmC9Y228b2YY8-HixpvZxOXvII3RvvNXqLDzkGmDk',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
