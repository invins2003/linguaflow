import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// DeepL translation provider — specialized for high-quality translations.
///
/// Free tier: https://www.deepl.com/en/pro#developer (500k chars/month free)
/// Get your key at https://www.deepl.com/account/summary
///
/// Free API keys end with `:fx` and use `api-free.deepl.com`.
/// Paid keys use `api.deepl.com`.
///
/// ```dart
/// aiProvider: DeepLProvider(apiKey: 'your-key:fx')  // free tier
/// aiProvider: DeepLProvider(apiKey: 'your-key')      // paid tier
/// ```
class DeepLProvider extends AiProvider {
  final String apiKey;
  final bool _logging;

  DeepLProvider({
    required this.apiKey,
    bool logging = true,
  }) : _logging = logging; // ignore: prefer_initializing_formals

  /// DeepL free tier uses api-free.deepl.com, paid uses api.deepl.com.
  String get _baseUrl => apiKey.endsWith(':fx')
      ? 'https://api-free.deepl.com/v2'
      : 'https://api.deepl.com/v2';

  Map<String, String> get _headers => {
        'Authorization': 'DeepL-Auth-Key $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    _log('Translating "$text" → $targetLanguage');

    final response = await http.post(
      Uri.parse('$_baseUrl/translate'),
      headers: _headers,
      body: jsonEncode({
        'text': [text],
        'target_lang': _toDeepLCode(targetLanguage),
        'source_lang': 'EN',
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['translations'][0]['text'] as String).trim();
  }

  /// DeepL supports up to 50 texts per request — use that for batch.
  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');

    final keys = entries.keys.toList();
    final texts = entries.values.toList();

    final response = await http.post(
      Uri.parse('$_baseUrl/translate'),
      headers: _headers,
      body: jsonEncode({
        'text': texts,
        'target_lang': _toDeepLCode(targetLanguage),
        'source_lang': 'EN',
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final translations = data['translations'] as List<dynamic>;

    return {
      for (var i = 0; i < keys.length; i++)
        keys[i]: (translations[i]['text'] as String).trim(),
    };
  }

  /// Maps a language name (e.g. 'Hindi') or ISO code (e.g. 'hi')
  /// to DeepL's expected target language code (e.g. 'HI').
  String _toDeepLCode(String language) {
    const nameToCode = {
      'english': 'EN-US', 'hindi': 'HI', 'french': 'FR',
      'german': 'DE', 'spanish': 'ES', 'portuguese': 'PT-PT',
      'arabic': 'AR', 'chinese': 'ZH-HANS', 'japanese': 'JA',
      'korean': 'KO', 'russian': 'RU', 'italian': 'IT',
      'dutch': 'NL', 'turkish': 'TR', 'polish': 'PL',
      'swedish': 'SV', 'danish': 'DA', 'finnish': 'FI',
      'norwegian': 'NB', 'czech': 'CS', 'romanian': 'RO',
      'hungarian': 'HU', 'greek': 'EL', 'bulgarian': 'BG',
    };

    // Accept both full language names (from LocaleManager) and ISO codes.
    final lower = language.toLowerCase();
    if (nameToCode.containsKey(lower)) return nameToCode[lower]!;

    // Fall back to uppercase ISO code (e.g. 'hi' → 'HI').
    return language.toUpperCase();
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} DeepL error ${response.statusCode}: '
        '${response.body}',
      );
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    if (_logging) print('${LinguaFlowConstants.tag} $message');
  }
}
