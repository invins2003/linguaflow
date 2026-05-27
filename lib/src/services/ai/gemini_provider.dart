import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// Google Gemini translation provider.
///
/// Uses the Gemini REST API — no extra SDK needed.
///
/// Get a free API key at https://aistudio.google.com/app/apikey
///
/// ```dart
/// aiProvider: GeminiProvider(apiKey: 'AIza...')
/// ```
class GeminiProvider extends AiProvider {
  final String apiKey;
  final String model;
  final bool _logging;

  /// Default model: gemini-2.0-flash (fast + cheap).
  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
    bool logging = true,
  }) : _logging = logging; // ignore: prefer_initializing_formals

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent?key=$apiKey',
      );

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    _log('Translating "$text" → $targetLanguage');

    final response = await http.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Translate the following text to $targetLanguage.\n'
                    'Return ONLY the translated text with no explanation.\n\n'
                    '"$text"',
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.2},
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['candidates'][0]['content']['parts'][0]['text'] as String)
        .trim();
  }

  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');

    final response = await http.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Translate all JSON values to $targetLanguage.\n'
                    'Keep all keys exactly unchanged.\n'
                    'Return ONLY valid JSON — no markdown, no explanation.\n\n'
                    '${jsonEncode(entries)}',
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.2},
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw =
        (data['candidates'][0]['content']['parts'][0]['text'] as String).trim();
    final cleaned =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} Gemini error ${response.statusCode}: '
        '${response.body}',
      );
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    if (_logging) print('${LinguaFlowConstants.tag} $message');
  }
}
