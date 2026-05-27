import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaflow/src/core/constants.dart';

/// Persists AI-generated translations across app sessions using SharedPreferences.
///
/// Cache key format: `linguaflow_cache_{locale}_{translationKey}`
class CacheManager {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Builds the cache key from locale + translation key.
  String _key(String locale, String translationKey) =>
      '${LinguaFlowConstants.cachePrefix}${locale}_$translationKey';

  /// Returns a cached translation, or `null` if not found.
  String? get(String locale, String translationKey) {
    return _prefs?.getString(_key(locale, translationKey));
  }

  /// Stores a translation in the cache.
  Future<void> put(String locale, String translationKey, String value) async {
    await _prefs?.setString(_key(locale, translationKey), value);
  }

  /// Returns `true` if this locale+key combo is cached.
  bool has(String locale, String translationKey) =>
      _prefs?.containsKey(_key(locale, translationKey)) ?? false;

  /// Clears all LinguaFlow cache entries.
  Future<void> clearAll() async {
    final keys = _prefs?.getKeys() ?? {};
    for (final k in keys) {
      if (k.startsWith(LinguaFlowConstants.cachePrefix)) {
        await _prefs?.remove(k);
      }
    }
  }
}
