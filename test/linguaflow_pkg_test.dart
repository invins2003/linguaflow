import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaflow/src/core/translation_store.dart';
import 'package:linguaflow/src/core/cache_manager.dart';
import 'package:linguaflow/src/models/locale_config.dart';
import 'package:linguaflow/src/services/ai/ai_provider_factory.dart';
import 'package:linguaflow/src/services/ai/openai_provider.dart';
import 'package:linguaflow/src/services/ai/gemini_provider.dart';
import 'package:linguaflow/src/services/ai/claude_provider.dart';
import 'package:linguaflow/src/services/ai/deepl_provider.dart';
import 'package:linguaflow/src/services/ai/libretranslate_provider.dart';
import 'package:linguaflow/src/services/ai/nvidia_provider.dart';

void main() {
  // ── TranslationStore ───────────────────────────────────────────────────────

  group('TranslationStore', () {
    late TranslationStore store;

    setUp(() => store = TranslationStore(logging: false));

    test('returns null for unknown locale', () {
      expect(store.get('en', 'hello'), isNull);
    });

    test('returns null for unknown key after locale is loaded', () {
      store.load('en', {'hello': 'Hello'});
      expect(store.get('en', 'missing_key'), isNull);
    });

    test('returns translation after load()', () {
      store.load('en', {'hello': 'Hello', 'welcome': 'Welcome'});
      expect(store.get('en', 'hello'), 'Hello');
      expect(store.get('en', 'welcome'), 'Welcome');
    });

    test('has() returns false before load', () {
      expect(store.has('en', 'hello'), isFalse);
    });

    test('has() returns true after load', () {
      store.load('en', {'hello': 'Hello'});
      expect(store.has('en', 'hello'), isTrue);
    });

    test('put() inserts a single entry', () {
      store.put('hi', 'hello', 'नमस्ते');
      expect(store.get('hi', 'hello'), 'नमस्ते');
    });

    test('put() overwrites an existing entry', () {
      store.load('en', {'hello': 'Hello'});
      store.put('en', 'hello', 'Hi there');
      expect(store.get('en', 'hello'), 'Hi there');
    });

    test('loadedLocales lists all loaded codes', () {
      store.load('en', {'a': '1'});
      store.load('hi', {'a': '2'});
      expect(store.loadedLocales, containsAll(['en', 'hi']));
    });

    test('load() coerces non-string values to String', () {
      store.load('en', {'count': 42, 'flag': true});
      expect(store.get('en', 'count'), '42');
      expect(store.get('en', 'flag'), 'true');
    });

    test('multiple locales are independent', () {
      store.load('en', {'hello': 'Hello'});
      store.load('hi', {'hello': 'नमस्ते'});
      expect(store.get('en', 'hello'), 'Hello');
      expect(store.get('hi', 'hello'), 'नमस्ते');
    });
  });

  // ── LocaleConfig ───────────────────────────────────────────────────────────

  group('LocaleConfig', () {
    test('defaults are applied correctly', () {
      const config = LocaleConfig(supportedLocales: ['en', 'hi']);
      expect(config.fallbackLocale, 'en');
      expect(config.assetPath, 'assets/lang/');
      expect(config.enableLogging, isTrue);
    });

    test('custom values are stored', () {
      const config = LocaleConfig(
        fallbackLocale: 'fr',
        supportedLocales: ['fr', 'de'],
        assetPath: 'assets/i18n/',
        enableLogging: false,
      );
      expect(config.fallbackLocale, 'fr');
      expect(config.supportedLocales, ['fr', 'de']);
      expect(config.assetPath, 'assets/i18n/');
      expect(config.enableLogging, isFalse);
    });
  });

  // ── CacheManager ───────────────────────────────────────────────────────────

  group('CacheManager', () {
    late CacheManager cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = CacheManager();
      await cache.init();
    });

    test('has() returns false for unknown key', () {
      expect(cache.has('en', 'hello'), isFalse);
    });

    test('get() returns null for unknown key', () {
      expect(cache.get('en', 'hello'), isNull);
    });

    test('put() and get() round-trip', () async {
      await cache.put('hi', 'hello', 'नमस्ते');
      expect(cache.get('hi', 'hello'), 'नमस्ते');
    });

    test('has() returns true after put()', () async {
      await cache.put('fr', 'save', 'Enregistrer');
      expect(cache.has('fr', 'save'), isTrue);
    });

    test('different locale+key combos are independent', () async {
      await cache.put('en', 'hello', 'Hello');
      await cache.put('hi', 'hello', 'नमस्ते');
      expect(cache.get('en', 'hello'), 'Hello');
      expect(cache.get('hi', 'hello'), 'नमस्ते');
    });

    test('clearAll() removes only LinguaFlow entries', () async {
      await cache.put('en', 'hello', 'Hello');
      await cache.put('hi', 'hello', 'नमस्ते');
      await cache.clearAll();
      expect(cache.has('en', 'hello'), isFalse);
      expect(cache.has('hi', 'hello'), isFalse);
    });
  });

  // ── AiProviderFactory ──────────────────────────────────────────────────────

  group('AiProviderFactory.create()', () {
    test('creates OpenAiProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.openai,
        apiKey: 'sk-test',
      );
      expect(p, isA<OpenAiProvider>());
    });

    test('creates GeminiProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.gemini,
        apiKey: 'AIza-test',
      );
      expect(p, isA<GeminiProvider>());
    });

    test('creates ClaudeProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.claude,
        apiKey: 'sk-ant-test',
      );
      expect(p, isA<ClaudeProvider>());
    });

    test('creates DeepLProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.deepl,
        apiKey: 'deepl-key:fx',
      );
      expect(p, isA<DeepLProvider>());
    });

    test('creates LibreTranslateProvider with no key', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.libretranslate,
        apiKey: '',
      );
      expect(p, isA<LibreTranslateProvider>());
    });

    test('creates NvidiaProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.nvidia,
        apiKey: 'nvapi-test',
      );
      expect(p, isA<NvidiaProvider>());
    });

    test('custom model is forwarded to OpenAiProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.openai,
        apiKey: 'sk-test',
        model: 'gpt-4o',
      ) as OpenAiProvider;
      expect(p.model, 'gpt-4o');
    });

    test('custom model is forwarded to GeminiProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.gemini,
        apiKey: 'AIza-test',
        model: 'gemini-1.5-pro',
      ) as GeminiProvider;
      expect(p.model, 'gemini-1.5-pro');
    });

    test('custom model is forwarded to NvidiaProvider', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.nvidia,
        apiKey: 'nvapi-test',
        model: 'nvidia/llama-3.1-nemotron-70b-instruct',
      ) as NvidiaProvider;
      expect(p.model, 'nvidia/llama-3.1-nemotron-70b-instruct');
    });

    test('NvidiaProvider uses default model when none specified', () {
      final p = AiProviderFactory.create(
        type: AiProviderType.nvidia,
        apiKey: 'nvapi-test',
      ) as NvidiaProvider;
      expect(p.model, 'meta/llama-3.3-70b-instruct');
    });
  });

  // ── AiProviderType enum ────────────────────────────────────────────────────

  group('AiProviderType', () {
    test('displayName returns readable strings', () {
      expect(AiProviderType.openai.displayName, 'OpenAI');
      expect(AiProviderType.gemini.displayName, 'Google Gemini');
      expect(AiProviderType.claude.displayName, 'Anthropic Claude');
      expect(AiProviderType.nvidia.displayName, 'NVIDIA NIM');
      expect(AiProviderType.deepl.displayName, 'DeepL');
      expect(AiProviderType.libretranslate.displayName, 'LibreTranslate');
    });

    test('envKeyName returns correct env variable names', () {
      expect(AiProviderType.openai.envKeyName, 'OPENAI_API_KEY');
      expect(AiProviderType.gemini.envKeyName, 'GEMINI_API_KEY');
      expect(AiProviderType.claude.envKeyName, 'ANTHROPIC_API_KEY');
      expect(AiProviderType.nvidia.envKeyName, 'NVIDIA_API_KEY');
      expect(AiProviderType.deepl.envKeyName, 'DEEPL_API_KEY');
      expect(AiProviderType.libretranslate.envKeyName, 'LIBRETRANSLATE_API_KEY');
    });
  });
}
