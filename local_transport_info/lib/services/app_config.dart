/// App-wide runtime flags read from `--dart-define`.
class AppConfig {
  static const bool isAdmin = bool.fromEnvironment(
    'IS_ADMIN',
    defaultValue: false,
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  /// Default estimated fare rate per km when no official fare exists.
  static const double fallbackRatePerKm = 2.45;
}
