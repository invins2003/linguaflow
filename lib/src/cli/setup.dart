import 'dart:convert';
import 'dart:io';
import 'package:linguaflow/src/services/ai/ai_provider_factory.dart';

/// Interactive setup wizard — run once per project:
///
/// ```bash
/// dart run linguaflow:setup
/// ```
///
/// Guides the developer through:
///   1. Choosing an AI provider
///   2. Entering their API key
///   3. (Optional) customising the model
///   4. Saving to .linguaflow_config.json
///
/// After setup the app reads the key automatically:
/// ```dart
/// aiProvider: await AiProviderFactory.fromConfig()
/// ```
Future<void> main(List<String> args) async {
  _banner();

  // ── Step 1: Choose provider ─────────────────────────────────────────────
  _section('Step 1 — Choose your AI provider');

  final providers = [
    (AiProviderType.openai,        'OpenAI         ', 'GPT-4.1-mini            ', 'Best quality   · https://platform.openai.com/api-keys'),
    (AiProviderType.gemini,        'Google Gemini  ', 'Gemini 2.0 Flash        ', 'Fast & cheap   · https://aistudio.google.com/app/apikey'),
    (AiProviderType.claude,        'Anthropic Claude','Haiku 4.5               ', 'Balanced       · https://console.anthropic.com'),
    (AiProviderType.nvidia,        'NVIDIA NIM     ', 'LLaMA 3.3 70B Instruct  ', 'High quality   · https://build.nvidia.com (free credits)'),
    (AiProviderType.deepl,         'DeepL          ', '—                       ', 'Translation-focused · https://www.deepl.com/account/summary'),
    (AiProviderType.libretranslate,'LibreTranslate ', '—                       ', 'Free & open-source (no key required for public servers)'),
  ];

  for (var i = 0; i < providers.length; i++) {
    final (_, name, model, note) = providers[i];
    stdout.writeln('  [${i + 1}]  $name  default: $model  $note');
  }

  stdout.writeln();
  final choice = _prompt('Enter choice [1–${providers.length}]', required: true);
  final idx = (int.tryParse(choice) ?? 0) - 1;

  if (idx < 0 || idx >= providers.length) {
    _exitError('Invalid choice. Run the setup again.');
  }

  final (selectedType, selectedName, defaultModel, _) = providers[idx];
  stdout.writeln('\n  ✓  Selected: $selectedName\n');

  // ── Step 2: Enter API key ───────────────────────────────────────────────
  _section('Step 2 — Enter your API key');

  String apiKey = '';

  if (selectedType == AiProviderType.libretranslate) {
    stdout.writeln('  LibreTranslate does not require an API key for most public servers.');
    stdout.writeln('  (Leave blank to use without a key)\n');
    apiKey = _prompt('API key (optional, press Enter to skip)', required: false);
  } else {
    final keyName = selectedType.envKeyName;
    stdout.writeln('  You can also set this as an environment variable:');
    stdout.writeln('  export $keyName=your-key\n');
    apiKey = _prompt('API key', required: true, obscure: true);
  }

  // ── Step 3: Custom model (optional) ────────────────────────────────────
  String? model;

  if (selectedType != AiProviderType.deepl &&
      selectedType != AiProviderType.libretranslate) {
    _section('Step 3 — Model (optional)');
    stdout.writeln('  Default: ${defaultModel.trim()}');
    stdout.writeln('  Press Enter to keep the default.\n');
    final modelInput = _prompt('Model name (optional)', required: false);
    if (modelInput.isNotEmpty) model = modelInput;
  }

  // ── Step 4: LibreTranslate endpoint (optional) ─────────────────────────
  String? endpoint;

  if (selectedType == AiProviderType.libretranslate) {
    _section('Step 3 — Server endpoint (optional)');
    stdout.writeln('  Default: https://translate.argosopentech.com');
    stdout.writeln('  Change this if you are self-hosting LibreTranslate.\n');
    final ep = _prompt('Endpoint (optional)', required: false);
    if (ep.isNotEmpty) endpoint = ep;
  }

  // ── Step 5: Save config ─────────────────────────────────────────────────
  _section('Saving configuration');

  final config = <String, dynamic>{
    'provider': selectedType.name,
    'apiKey': apiKey,
    'model': ?model,
    'endpoint': ?endpoint,
  };

  const configPath = '.linguaflow_config.json';
  File(configPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(config),
  );

  stdout.writeln('  ✓  Saved to $configPath\n');

  // ── Gitignore warning ───────────────────────────────────────────────────
  _addToGitignore(configPath);

  // ── Usage hint ──────────────────────────────────────────────────────────
  _section('You\'re ready! Use in your app:');
  stdout.writeln('''  // main.dart
  LinguaFlowProvider(
    config: LocaleConfig(
      fallbackLocale: 'en',
      supportedLocales: ['en', 'hi', 'fr'],
    ),
    aiProvider: await AiProviderFactory.fromConfig(),
    child: MyApp(),
  )
''');

  stdout.writeln('  Alternatively, pass the key via --dart-define at build time:');
  stdout.writeln('  flutter run --dart-define=${selectedType.envKeyName}=your-key\n');

  _divider();
  stdout.writeln('  🎉  LinguaFlow setup complete!\n');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _banner() {
  stdout.writeln('');
  _divider();
  stdout.writeln('   🌐  LinguaFlow — AI Provider Setup');
  _divider();
  stdout.writeln('');
}

void _section(String title) {
  stdout.writeln('  ── $title');
  stdout.writeln('');
}

void _divider() {
  stdout.writeln('  ${'─' * 54}');
}

/// Prompts for input. If [obscure] is true, the typed chars are hidden (★).
/// NOTE: Full terminal echo-off requires platform-specific code; this
///       shows a note instead of silently echoing the key.
String _prompt(String label, {bool required = false, bool obscure = false}) {
  if (obscure) {
    stdout.writeln('  (Your key will be visible as you type — '
        'clear your terminal after setup if needed)');
  }
  stdout.write('  $label: ');
  final value = stdin.readLineSync()?.trim() ?? '';
  if (required && value.isEmpty) {
    _exitError('$label is required.');
  }
  return value;
}

/// Appends [configPath] to .gitignore if it exists, to avoid accidental commits.
void _addToGitignore(String configPath) {
  final gitignore = File('.gitignore');
  if (!gitignore.existsSync()) {
    stdout.writeln('  ⚠  No .gitignore found — make sure to add '
        '$configPath manually to avoid committing your API key!\n');
    return;
  }

  final contents = gitignore.readAsStringSync();
  if (contents.contains(configPath)) {
    stdout.writeln('  ✓  $configPath is already in .gitignore\n');
    return;
  }

  gitignore.writeAsStringSync('$contents\n# LinguaFlow\n$configPath\n');
  stdout.writeln('  ✓  Added $configPath to .gitignore\n');
}

Never _exitError(String message) {
  stderr.writeln('\n  ✗  $message');
  exit(1);
}
