import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linguaflow/src/core/locale_manager.dart';
import 'package:linguaflow/src/core/translation_store.dart';
import 'package:linguaflow/src/core/cache_manager.dart';
import 'package:linguaflow/src/models/locale_config.dart';
import 'package:linguaflow/src/services/ai/ai_provider.dart';

/// Wraps your app to provide LinguaFlow localization capabilities.
///
/// Place at the root of your widget tree:
///
/// ```dart
/// LinguaFlowProvider(
///   config: LocaleConfig(
///     fallbackLocale: 'en',
///     supportedLocales: ['en', 'hi', 'fr'],
///   ),
///   child: MyApp(),
/// )
/// ```
class LinguaFlowProvider extends StatefulWidget {
  final LocaleConfig config;
  final Widget child;

  /// Optionally supply an AI provider to enable missing-key translation.
  final AiProvider? aiProvider;

  /// Optional loading widget shown while translations are being initialized.
  final Widget? loadingWidget;

  const LinguaFlowProvider({
    super.key,
    required this.config,
    required this.child,
    this.aiProvider,
    this.loadingWidget,
  });

  @override
  State<LinguaFlowProvider> createState() => _LinguaFlowProviderState();
}

class _LinguaFlowProviderState extends State<LinguaFlowProvider> {
  late final LocaleManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = LocaleManager(
      config: widget.config,
      store: TranslationStore(logging: widget.config.enableLogging),
      cache: CacheManager(),
      aiProvider: widget.aiProvider,
    );
    _manager.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleManager>.value(
      value: _manager,
      child: Consumer<LocaleManager>(
        builder: (context, manager, _) {
          if (!manager.isInitialized) {
            return widget.loadingWidget ??
                const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
          }
          return widget.child;
        },
      ),
    );
  }
}

/// Convenience accessor — call anywhere inside the widget tree.
///
/// ```dart
/// LinguaFlow.of(context).setLocale('hi');
/// ```
class LinguaFlow {
  LinguaFlow._();

  static LocaleManager of(BuildContext context) =>
      Provider.of<LocaleManager>(context, listen: false);
}
