import 'package:flutter/material.dart';
import 'package:linguaflow/linguaflow.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  LinguaFlow — Example App
///
///  SETUP:
///  Run once to configure your AI provider interactively:
///
///    dart run linguaflow:setup
///
///  This saves .linguaflow_config.json which is read at startup below.
///
///  Or pass the key at build time:
///    flutter run --dart-define=OPENAI_API_KEY=sk-...
///    flutter run --dart-define=GEMINI_API_KEY=AIza...
///    flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///    flutter run --dart-define=DEEPL_API_KEY=your-key:fx
///
///  Demonstrates:
///   • Runtime language switching (EN / HI / FR)
///   • .tr() extension method
///   • Persisted locale across app restarts
///   • AI fallback for missing keys
/// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Try loading AI provider from .linguaflow_config.json (after `dart run linguaflow:setup`)
  // 2. Fall back to --dart-define env vars
  // 3. Fall back to null (no AI translation — uses fallback locale instead)
  final aiProvider =
      await AiProviderFactory.fromConfig() ?? AiProviderFactory.fromEnv();

  runApp(
    LinguaFlowProvider(
      config: const LocaleConfig(
        fallbackLocale: 'en',
        supportedLocales: ['en', 'hi', 'fr'],
        assetPath: 'assets/lang/',
        enableLogging: true,
      ),
      aiProvider: aiProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = LinguaFlow.of(context);
    return MaterialApp(
      title: 'LinguaFlow Demo',
      locale: manager.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ── Home Page ─────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _languages = [
    ('English', 'en', '🇬🇧'),
    ('हिन्दी', 'hi', '🇮🇳'),
    ('Français', 'fr', '🇫🇷'),
  ];

  @override
  Widget build(BuildContext context) {
    final manager = LinguaFlow.of(context);
    final currentCode = manager.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr(context)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome card ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand, size: 36, color: Colors.amber),
                    const SizedBox(width: 16),
                    Text(
                      'welcome'.tr(context),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Language selector ─────────────────────────────────────────
            Text(
              'select_language'.tr(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _languages.map((lang) {
                final (label, code, flag) = lang;
                final isActive = code == currentCode;
                return ChoiceChip(
                  label: Text('$flag  $label'),
                  selected: isActive,
                  onSelected: (_) => manager.setLocale(code),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Current locale info ───────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('current_language'.tr(context)),
              trailing: Chip(
                label: Text(
                  currentCode.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            Text(
              'hello'.tr(context),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),

            // ── Missing-key AI demo ───────────────────────────────────────
            Text(
              'missing_key_demo'.tr(context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: Text('translate_missing'.tr(context)),
              onPressed: () => _showAiDemo(context),
            ),

            const Spacer(),

            // ── Bottom action row ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('cancel'.tr(context)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {},
                  child: Text('save'.tr(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAiDemo(BuildContext context) {
    final manager = LinguaFlow.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Missing-Key Translation'),
        content: FutureBuilder<String>(
          future: manager.translate('dynamic_ai_key'),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Text(
                'AI provider not configured.\n\n'
                'Run: dart run linguaflow:setup\n'
                'Or pass --dart-define=OPENAI_API_KEY=sk-... at build time.',
                style: TextStyle(color: Colors.red.shade600),
              );
            }
            return Text(
              '"dynamic_ai_key" →\n"${snap.data}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
