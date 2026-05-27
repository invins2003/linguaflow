import 'package:flutter/material.dart';
import 'package:linguaflow/linguaflow.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final aiProvider =
      await AiProviderFactory.fromConfig() ??
      await AiProviderFactory.fromFlutterAssets() ??
      AiProviderFactory.fromEnv() ??
      LibreTranslateProvider();

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

// ── App shell — never rebuilds on locale change ───────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaFlow Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ── Home page ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  static const _languages = [
    ('English', 'en', '🇬🇧'),
    ('हिन्दी', 'hi', '🇮🇳'),
    ('Français', 'fr', '🇫🇷'),
  ];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1.0; // start fully visible
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  /// Fade out → switch locale → fade in.
  Future<void> _switchLocale(String code) async {
    final manager = LinguaFlow.of(context);
    if (manager.locale.languageCode == code) return;

    await _fade.reverse();                   // fade out (220ms)
    if (!mounted) return;
    await manager.setLocale(code);           // swap translations
    if (!mounted) return;
    await _fade.forward();                   // fade in (220ms)
  }

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds only the content — not MaterialApp
    return Consumer<LocaleManager>(
      builder: (context, manager, _) {
        final code = manager.locale.languageCode;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'app_title'.tr(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            elevation: 0,
          ),
          body: FadeTransition(
            opacity: _opacity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome card ────────────────────────────────────────
                  _WelcomeCard(manager: manager),
                  const SizedBox(height: 28),

                  // ── Language chips ──────────────────────────────────────
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
                      final (label, langCode, flag) = lang;
                      final isActive = langCode == code;
                      return AnimatedScale(
                        scale: isActive ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: ChoiceChip(
                          label: Text('$flag  $label'),
                          selected: isActive,
                          onSelected: (_) => _switchLocale(langCode),
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Current locale badge ────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: Text('current_language'.tr(context)),
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Chip(
                        key: ValueKey(code),
                        label: Text(
                          code.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  // ── Big greeting ────────────────────────────────────────
                  Text(
                    'hello'.tr(context),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'welcome'.tr(context),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // ── AI missing-key demo ─────────────────────────────────
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'missing_key_demo'.tr(context),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.auto_fix_high),
                            label: Text('translate_missing'.tr(context)),
                            onPressed: () => _showAiDemo(context, manager),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Action buttons ──────────────────────────────────────
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
          ),
        );
      },
    );
  }

  void _showAiDemo(BuildContext context, LocaleManager manager) {
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
                'AI provider error:\n${snap.error}',
                style: TextStyle(color: Colors.red.shade600),
              );
            }
            return Text(
              '"dynamic_ai_key" →\n\n"${snap.data}"',
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

// ── Welcome card ──────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final LocaleManager manager;
  const _WelcomeCard({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('👋', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'welcome'.tr(context),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    manager.locale.languageCode.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
