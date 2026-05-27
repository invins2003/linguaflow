import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads JSON translation files from the app's asset bundle.
class FileLoader {
  /// Reads `{assetPath}{locale}.json` and returns the parsed key-value map.
  ///
  /// Returns an empty map if the file is missing or malformed.
  static Future<Map<String, dynamic>> load(
    String assetPath,
    String locale,
  ) async {
    final fullPath = '$assetPath$locale.json';
    try {
      final raw = await rootBundle.loadString(fullPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (_) {
      // Asset not found or malformed JSON — silently return empty map.
      return {};
    }
  }
}
