import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// NVIDIA NIM translation provider.
///
/// Uses NVIDIA's cloud inference API (OpenAI-compatible format).
/// Supports LLaMA, Nemotron, Mistral, and other models hosted on NVIDIA's infra.
///
/// Get a free API key (1 000 credits) at https://build.nvidia.com
///
/// ```dart
/// aiProvider: NvidiaProvider(apiKey: 'nvapi-...')
/// ```
class NvidiaProvider extends AiProvider {
  final String apiKey;
  final String model;
  final bool _logging;

  static const _endpoint =
      'https://integrate.api.nvidia.com/v1/chat/completions';

  /// Default model: meta/llama-3.3-70b-instruct
  /// — strong multilingual translation quality.
  ///
  /// Other good options:
  /// - `nvidia/llama-3.1-nemotron-70b-instruct`
  /// - `meta/llama-3.1-405b-instruct` (highest quality, slower)
  /// - `mistralai/mixtral-8x22b-instruct-v0.1`
  NvidiaProvider({
    required this.apiKey,
    this.model = 'meta/llama-3.3-70b-instruct',
    bool logging = true,
  }) : _logging = logging; // ignore: prefer_initializing_formals

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    _log('Translating "$text" → $targetLanguage');

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional translator. '
                'Return ONLY the translated text with no explanation.',
          },
          {
            'role': 'user',
            'content': 'Translate the following text to $targetLanguage:\n\n'
                '"$text"',
          },
        ],
        'temperature': 0.2,
        'max_tokens': 1024,
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['choices'][0]['message']['content'] as String).trim();
  }

  /// Single API call for an entire JSON map.
  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional translator. '
                'You receive a JSON object and translate all values to '
                '$targetLanguage. '
                'Keep all keys exactly unchanged. '
                'Return ONLY valid JSON — no markdown, no explanation.',
          },
          {
            'role': 'user',
            'content': jsonEncode(entries),
          },
        ],
        'temperature': 0.2,
        'max_tokens': 4096,
      }),
    );

    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw =
        (data['choices'][0]['message']['content'] as String).trim();
    final cleaned =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} NVIDIA NIM error '
        '${response.statusCode}: ${response.body}',
      );
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    if (_logging) print('${LinguaFlowConstants.tag} $message');
  }
}
