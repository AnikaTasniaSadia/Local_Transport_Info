/// App-wide runtime flags read from `--dart-define`.
class AppConfig {
  static const bool isAdmin = bool.fromEnvironment(
    'IS_ADMIN',
    defaultValue: false,
  );

  /// Default estimated fare rate per km when no official fare exists.
  static const double fallbackRatePerKm = 2.45;
}
