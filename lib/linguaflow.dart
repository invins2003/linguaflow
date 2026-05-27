/// LinguaFlow — AI-powered localization for Flutter apps.
///
/// ## Quick start
///
/// ```dart
/// // 1. Wrap your app
/// LinguaFlowProvider(
///   config: LocaleConfig(
///     fallbackLocale: 'en',
///     supportedLocales: ['en', 'hi', 'fr'],
///   ),
///   aiProvider: OpenAiProvider(apiKey: 'sk-...'),
///   child: MyApp(),
/// )
///
/// // 2. Translate strings
/// Text('welcome'.tr(context))
///
/// // 3. Switch locale
/// LinguaFlow.of(context).setLocale('hi');
/// ```
library;

// Core
export 'src/core/locale_manager.dart';
export 'src/core/translation_store.dart';
export 'src/core/cache_manager.dart';
export 'src/core/constants.dart';

// Models
export 'src/models/locale_config.dart';

// Services
export 'src/services/file_loader.dart';
export 'src/services/storage_service.dart';
export 'src/services/ai/ai_provider.dart';
export 'src/services/ai/ai_provider_factory.dart';
export 'src/services/ai/openai_provider.dart';
export 'src/services/ai/gemini_provider.dart';
export 'src/services/ai/claude_provider.dart';
export 'src/services/ai/deepl_provider.dart';
export 'src/services/ai/libretranslate_provider.dart';
export 'src/services/ai/nvidia_provider.dart';

// Extensions
export 'src/extensions/string_extension.dart';

// Widgets
export 'src/widgets/linguaflow_provider.dart';
