import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// LibreTranslate provider — free & open-source translation.
///
/// Can run self-hosted or use a public instance.
/// No API key required for most public servers.
///
/// Public servers: https://libretranslate.com (rate-limited, key optional)
///                 https://translate.argosopentech.com (no key needed)
///                 https://libretranslate.de
///
/// Self-hosted: https://github.com/LibreTranslate/LibreTranslate
///
/// ```dart
/// // No key needed (public instance):
/// aiProvider: LibreTranslateProvider()
///
/// // With API key (libretranslate.com):
/// aiProvider: LibreTranslateProvider(apiKey: 'your-key')
///
/// // Self-hosted:
/// aiProvider: LibreTranslateProvider(
///   endpoint: 'http://localhost:5000',
/// )
/// ```
class LibreTranslateProvider extends AiProvider {
  final String endpoint;
  final String? apiKey;
  final String sourceLanguage;
  final bool _logging;

  LibreTranslateProvider({
    this.endpoint = 'https://translate.argosopentech.com',
    this.apiKey,
    this.sourceLanguage = 'en',
    bool logging = true,
  }) : _logging = logging; // ignore: prefer_initializing_formals

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    final targetCode = _toIsoCode(targetLanguage);
    _log('Translating "$text" → $targetCode');

    final body = <String, dynamic>{
      'q': text,
      'source': sourceLanguage,
      'target': targetCode,
      'format': 'text',
    };
    if (apiKey != null) body['api_key'] = apiKey!;

    final response = await http.post(
      Uri.parse('$endpoint/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['translatedText'] as String).trim();
  }

  /// LibreTranslate doesn't support batch natively — calls one by one.
  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');
    final result = <String, String>{};
    for (final entry in entries.entries) {
      result[entry.key] = await translate(
        text: entry.value,
        targetLanguage: targetLanguage,
      );
    }
    return result;
  }

  /// Maps a language name or ISO code to a 2-letter LibreTranslate code.
  String _toIsoCode(String language) {
    const nameToCode = {
      'english': 'en', 'hindi': 'hi', 'french': 'fr',
      'german': 'de', 'spanish': 'es', 'portuguese': 'pt',
      'arabic': 'ar', 'chinese': 'zh', 'japanese': 'ja',
      'korean': 'ko', 'russian': 'ru', 'italian': 'it',
      'dutch': 'nl', 'turkish': 'tr', 'polish': 'pl',
      'swedish': 'sv', 'danish': 'da', 'finnish': 'fi',
      'norwegian': 'nb', 'czech': 'cs', 'bengali': 'bn',
      'urdu': 'ur',
    };
    return nameToCode[language.toLowerCase()] ??
        language.toLowerCase().substring(0, 2);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} LibreTranslate error '
        '${response.statusCode}: ${response.body}',
      );
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    if (_logging) print('${LinguaFlowConstants.tag} $message');
  }
}
