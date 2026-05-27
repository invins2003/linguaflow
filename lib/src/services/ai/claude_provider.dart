import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// Anthropic Claude translation provider.
///
/// Get an API key at https://console.anthropic.com
///
/// ```dart
/// aiProvider: ClaudeProvider(apiKey: 'sk-ant-...')
/// ```
class ClaudeProvider extends AiProvider {
  final String apiKey;
  final String model;
  final bool _logging;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _anthropicVersion = '2023-06-01';

  /// Default model: claude-haiku-4-5-20251001 (fastest + cheapest Claude).
  ClaudeProvider({
    required this.apiKey,
    this.model = 'claude-haiku-4-5-20251001',
    bool logging = true,
  }) : _logging = logging; // ignore: prefer_initializing_formals

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _anthropicVersion,
      };

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    _log('Translating "$text" → $targetLanguage');

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'system': 'You are a professional translator. '
            'Return ONLY the translated text with no explanation.',
        'messages': [
          {
            'role': 'user',
            'content': 'Translate the following text to $targetLanguage:\n\n'
                '"$text"',
          },
        ],
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['content'][0]['text'] as String).trim();
  }

  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode({
        'model': model,
        'max_tokens': 4096,
        'system': 'You are a professional translator. '
            'You receive a JSON object and translate all values to '
            '$targetLanguage. '
            'Keep all keys exactly unchanged. '
            'Return ONLY valid JSON — no markdown, no explanation.',
        'messages': [
          {
            'role': 'user',
            'content': jsonEncode(entries),
          },
        ],
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (data['content'][0]['text'] as String).trim();
    final cleaned =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} Claude error ${response.statusCode}: '
        '${response.body}',
      );
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    if (_logging) print('${LinguaFlowConstants.tag} $message');
  }
}
