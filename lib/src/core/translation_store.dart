import 'package:flutter/foundation.dart';
import 'package:linguaflow/src/core/constants.dart';

/// Holds all loaded translations in memory.
///
/// Structure:
/// ```
/// {
///   'en': { 'hello': 'Hello', 'welcome': 'Welcome' },
///   'hi': { 'hello': 'नमस्ते', 'welcome': 'स्वागत है' },
/// }
/// ```
class TranslationStore {
  final Map<String, Map<String, String>> _translations = {};
  final bool _logging;

  TranslationStore({bool logging = true}) : _logging = logging; // ignore: prefer_initializing_formals — named param differs from field

  /// Load a map of translations for a given locale.
  void load(String locale, Map<String, dynamic> data) {
    _translations[locale] = data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    _log('Loaded ${data.length} keys for locale "$locale".');
  }

  /// Returns the translated string for [key] in [locale].
  /// Returns `null` if either the locale or key is missing.
  String? get(String locale, String key) {
    final localeMap = _translations[locale];
    if (localeMap == null) {
      _log('Locale "$locale" not loaded.');
      return null;
    }
    final value = localeMap[key];
    if (value == null) {
      _log('Missing key: "$key" for locale "$locale".');
    }
    return value;
  }

  /// Returns `true` if a translation exists for [locale] + [key].
  bool has(String locale, String key) =>
      _translations[locale]?.containsKey(key) ?? false;

  /// Inserts or updates a single translation entry (used by AI fallback).
  void put(String locale, String key, String value) {
    _translations.putIfAbsent(locale, () => {})[key] = value;
  }

  /// All loaded locale codes.
  List<String> get loadedLocales => _translations.keys.toList();

  void _log(String message) {
    if (_logging) debugPrint('${LinguaFlowConstants.tag} $message');
  }
}
