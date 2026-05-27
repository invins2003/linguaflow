import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/core/constants.dart';

/// OpenAI-powered translation provider.
///
/// Uses the Chat Completions API with GPT-4.1-mini by default.
///
/// ```dart
/// final provider = OpenAiProvider(apiKey: 'sk-...');
/// ```
class OpenAiProvider extends AiProvider {
  final String apiKey;
  final String model;
  final bool _logging;

  static const _endpoint =
      'https://api.openai.com/v1/chat/completions';

  OpenAiProvider({
    required this.apiKey,
    this.model = 'gpt-4.1-mini',
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
            'content':
                'You are a professional translator. '
                'Translate text accurately. '
                'Return ONLY the translated text with no explanation.',
          },
          {
            'role': 'user',
            'content':
                'Translate the following text to $targetLanguage.\n\n'
                '"$text"',
          },
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} OpenAI error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final translated =
        data['choices'][0]['message']['content'] as String;
    return translated.trim();
  }

  /// Single API call for an entire JSON map — much cheaper than per-key calls.
  @override
  Future<Map<String, String>> translateBatch({
    required Map<String, String> entries,
    required String targetLanguage,
  }) async {
    _log('Batch translating ${entries.length} keys → $targetLanguage');

    final jsonInput = jsonEncode(entries);

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
            'content':
                'You are a professional translator. '
                'You will receive a JSON object with string values. '
                'Translate ALL values to $targetLanguage. '
                'Keep ALL keys exactly unchanged. '
                'Return ONLY valid JSON — no markdown, no explanation.',
          },
          {
            'role': 'user',
            'content': jsonInput,
          },
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        '${LinguaFlowConstants.tag} OpenAI batch error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['choices'][0]['message']['content'] as String;

    // Strip any accidental markdown code fences.
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  void _log(String message) {
    if (_logging) debugPrint('${LinguaFlowConstants.tag} $message');
  }
}
