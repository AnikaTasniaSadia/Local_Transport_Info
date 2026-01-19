/// Reads Supabase credentials from Dart defines.
///
/// Run example:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _nextPublicSupabaseUrl = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_URL',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _nextPublicSupabaseAnonKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  );
  static const String _nextPublicSupabasePublishableKey =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY');

  static String get url =>
      _supabaseUrl.isNotEmpty ? _supabaseUrl : _nextPublicSupabaseUrl;

  /// Supabase client key for client-side usage.
  ///
  /// `supabase_flutter` names this parameter `anonKey`, but newer Supabase
  /// dashboards may label it as a publishable key.
  static String get anonKey {
    if (_supabaseAnonKey.isNotEmpty) return _supabaseAnonKey;
    if (_nextPublicSupabaseAnonKey.isNotEmpty) {
      return _nextPublicSupabaseAnonKey;
    }
    return _nextPublicSupabasePublishableKey;
  }

  static void assertValid() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase credentials. Provide --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=... (or NEXT_PUBLIC_SUPABASE_URL '
        '+ NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY) when running the app.',
      );
    }
  }
}
