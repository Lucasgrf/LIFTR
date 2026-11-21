/// Runtime Supabase configuration injected via `--dart-define`.
///
/// Pass `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// when running with cloud sync enabled. When omitted, the app runs purely
/// against its local Drift SQLite database (offline-first mode).
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
