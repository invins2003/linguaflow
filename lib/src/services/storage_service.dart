import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaflow/src/core/constants.dart';

/// Persists and retrieves the user's chosen locale across app launches.
class StorageService {
  /// Saves [locale] code to SharedPreferences.
  static Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LinguaFlowConstants.storageKey, locale);
  }

  /// Returns the previously saved locale code, or `null` if none.
  static Future<String?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LinguaFlowConstants.storageKey);
  }

  /// Removes the saved locale (resets to default).
  static Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LinguaFlowConstants.storageKey);
  }
}
