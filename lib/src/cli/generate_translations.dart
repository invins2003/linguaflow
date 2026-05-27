import 'dart:convert';
import 'dart:io';
import 'package:linguaflow/src/services/ai/openai_provider.dart';

/// CLI entry point — run with:
///
/// ```bash
/// dart run linguaflow:generate \
///   --key=sk-... \
///   --source=assets/lang/en.json \
///   --targets=hi,fr,de
/// ```
Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);

  final rawKey = parsed['key'];
  final sourcePath = parsed['source'] ?? 'assets/lang/en.json';
  final targets =
      (parsed['targets'] ?? '').split(',').where((t) => t.isNotEmpty).toList();
  final model = parsed['model'] ?? 'gpt-4.1-mini';

  if (rawKey == null || rawKey.isEmpty) {
    _exit('Error: --key=<openai-api-key> is required.');
  }
  if (targets.isEmpty) {
    _exit('Error: --targets=hi,fr,de is required.');
  }
  final apiKey = rawKey;

  // Read source JSON.
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    _exit('Error: source file not found: $sourcePath');
  }

  final raw = sourceFile.readAsStringSync();
  final Map<String, dynamic> source;
  try {
    source = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    _exit('Error: $sourcePath is not valid JSON.');
  }

  final entries = source.map((k, v) => MapEntry(k, v.toString()));
  final provider = OpenAiProvider(apiKey: apiKey, model: model);
  final outDir = File(sourcePath).parent;

  stdout.writeln('[LinguaFlow] Loaded ${entries.length} keys from $sourcePath');

  for (final target in targets) {
    stdout.writeln('[LinguaFlow] Translating → $target...');
    try {
      final translated = await provider.translateBatch(
        entries: entries,
        targetLanguage: _languageName(target),
      );

      final outPath = '${outDir.path}/$target.json';
      File(outPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(translated),
      );
      stdout.writeln('[LinguaFlow] ✓ Saved $outPath');
    } catch (e) {
      stderr.writeln('[LinguaFlow] ✗ Failed for $target: $e');
    }
  }

  stdout.writeln('[LinguaFlow] Done.');
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length >= 2) {
        result[parts[0]] = parts.sublist(1).join('=');
      }
    }
  }
  return result;
}

String _languageName(String code) {
  const names = {
    'en': 'English', 'hi': 'Hindi', 'fr': 'French',
    'de': 'German', 'es': 'Spanish', 'pt': 'Portuguese',
    'ar': 'Arabic', 'zh': 'Chinese', 'ja': 'Japanese',
    'ko': 'Korean', 'ru': 'Russian', 'it': 'Italian',
    'nl': 'Dutch', 'tr': 'Turkish', 'pl': 'Polish',
  };
  return names[code] ?? code;
}

Never _exit(String message) {
  stderr.writeln(message);
  exit(1);
}
