/// Abstract interface for AI translation backends.
///
/// Implement this to plug in any translation provider
/// (OpenAI, Gemini, Claude, DeepL, etc.).
abstract class AiProvider {
  /// Translates [text] into [targetLanguage] (e.g. 'Hindi', 'French').
  ///
  /// Returns the translated string, or throws on failure.
  Future<String> translate({
    required String text,
    required String targetLanguage,
  });

  /// Translates an entire map of key→value pairs to [targetLanguage].
  ///
  /// Default implementation calls [translate] per entry; providers
  /// can override for a single batch API call.
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    final result = <String, String>{};
    for (final entry in entries.entries) {
      result[entry.key] = await translate(
        text: entry.value,
        targetLanguage: targetLanguage,
      );
    }
    return result;
  }
}
