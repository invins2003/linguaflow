/// Configuration passed to [LinguaFlowProvider] during initialization.
class LocaleConfig {
  /// The default/fallback locale code (e.g. 'en').
  final String fallbackLocale;

  /// All locale codes your app supports (e.g. ['en', 'hi', 'fr']).
  final List<String> supportedLocales;

  /// Path prefix for JSON asset files.
  /// Defaults to 'assets/lang/' → loads 'assets/lang/en.json', etc.
  final String assetPath;

  /// Whether to log debug messages to the console.
  final bool enableLogging;

  /// When true, LinguaFlow reads the device locale on first launch and
  /// switches to it automatically if it is in [supportedLocales].
  final bool autoDetectLocale;

  const LocaleConfig({
    this.fallbackLocale = 'en',
    required this.supportedLocales,
    this.assetPath = 'assets/lang/',
    this.enableLogging = true,
    this.autoDetectLocale = true,
  });
}
