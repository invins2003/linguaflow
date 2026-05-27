import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/services/ai/openai_provider.dart';
import 'package:linguaflow/src/services/ai/gemini_provider.dart';
import 'package:linguaflow/src/services/ai/claude_provider.dart';
import 'package:linguaflow/src/services/ai/deepl_provider.dart';
import 'package:linguaflow/src/services/ai/libretranslate_provider.dart';
import 'package:linguaflow/src/services/ai/nvidia_provider.dart';

/// Supported AI translation providers.
enum AiProviderType { openai, gemini, claude, deepl, libretranslate, nvidia }

extension AiProviderTypeX on AiProviderType {
  String get displayName => switch (this) {
        AiProviderType.openai => 'OpenAI',
        AiProviderType.gemini => 'Google Gemini',
        AiProviderType.claude => 'Anthropic Claude',
        AiProviderType.deepl => 'DeepL',
        AiProviderType.libretranslate => 'LibreTranslate',
        AiProviderType.nvidia => 'NVIDIA NIM',
      };

  String get envKeyName => switch (this) {
        AiProviderType.openai => 'OPENAI_API_KEY',
        AiProviderType.gemini => 'GEMINI_API_KEY',
        AiProviderType.claude => 'ANTHROPIC_API_KEY',
        AiProviderType.deepl => 'DEEPL_API_KEY',
        AiProviderType.libretranslate => 'LIBRETRANSLATE_API_KEY',
        AiProviderType.nvidia => 'NVIDIA_API_KEY',
      };
}

/// Factory for creating [AiProvider] instances from multiple sources.
///
/// ## Usage options (in order of preference):
///
/// ### 1. From saved config (after running `dart run linguaflow:setup`):
/// ```dart
/// aiProvider: await AiProviderFactory.fromConfig()
/// ```
///
/// ### 2. From environment variables / `--dart-define`:
/// ```dart
/// aiProvider: AiProviderFactory.fromEnv()
/// ```
/// Set one of: `OPENAI_API_KEY`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`,
/// `DEEPL_API_KEY`, `LIBRETRANSLATE_API_KEY`, `NVIDIA_API_KEY`
///
/// Or via `--dart-define` at build time:
/// ```
/// flutter run --dart-define=NVIDIA_API_KEY=nvapi-...
/// ```
///
/// ### 3. Explicit creation:
/// ```dart
/// aiProvider: AiProviderFactory.create(
///   type: AiProviderType.nvidia,
///   apiKey: 'nvapi-...',
/// )
/// ```
class AiProviderFactory {
  AiProviderFactory._();

  /// Default config file path (relative to project root).
  static const defaultConfigPath = '.linguaflow_config.json';

  // ── From config file ────────────────────────────────────────────────────

  /// Loads provider config from [configPath] (default: `.linguaflow_config.json`).
  ///
  /// Run `dart run linguaflow:setup` to create this file interactively.
  ///
  /// Returns `null` if the file is missing.
  static Future<AiProvider?> fromConfig({
    String configPath = defaultConfigPath,
  }) async {
    final file = File(configPath);
    if (!file.existsSync()) return null;

    try {
      final raw = await file.readAsString();
      final cfg = jsonDecode(raw) as Map<String, dynamic>;

      final typeStr = cfg['provider'] as String? ?? '';
      final apiKey = cfg['apiKey'] as String? ?? '';
      final model = cfg['model'] as String?;
      final endpoint = cfg['endpoint'] as String?;

      final type = AiProviderType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => AiProviderType.openai,
      );

      return create(type: type, apiKey: apiKey, model: model, endpoint: endpoint);
    } catch (e) {
      throw Exception('[LinguaFlow] Failed to read config "$configPath": $e');
    }
  }

  // ── From Flutter assets (mobile / web) ─────────────────────────────────

  /// Reads provider config from a Flutter asset file.
  ///
  /// Works on **all platforms** (Android, iOS, web, desktop) because it uses
  /// `rootBundle` instead of `dart:io`.
  ///
  /// Add the config file to your app's assets:
  /// ```yaml
  /// # pubspec.yaml
  /// flutter:
  ///   assets:
  ///     - assets/linguaflow_config.json
  /// ```
  ///
  /// ⚠️  Only use this for keys that are safe to bundle in the APK/IPA
  ///     (e.g. LibreTranslate with no key, or a restricted read-only key).
  ///     Prefer `--dart-define` for sensitive API keys.
  ///
  /// Returns `null` if the asset is not found.
  static Future<AiProvider?> fromFlutterAssets({
    String assetPath = 'assets/linguaflow_config.json',
  }) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final cfg = jsonDecode(raw) as Map<String, dynamic>;

      final typeStr = cfg['provider'] as String? ?? '';
      final apiKey = cfg['apiKey'] as String? ?? '';
      final model = cfg['model'] as String?;
      final endpoint = cfg['endpoint'] as String?;

      final type = AiProviderType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => AiProviderType.libretranslate,
      );

      return create(type: type, apiKey: apiKey, model: model, endpoint: endpoint);
    } catch (_) {
      return null; // asset not present — silently skip
    }
  }

  // ── From environment variables / --dart-define ──────────────────────────

  /// Reads the API key from environment variables or `--dart-define` values.
  ///
  /// Priority order:
  /// 1. `OPENAI_API_KEY` → [OpenAiProvider]
  /// 2. `GEMINI_API_KEY` → [GeminiProvider]
  /// 3. `ANTHROPIC_API_KEY` → [ClaudeProvider]
  /// 4. `DEEPL_API_KEY` → [DeepLProvider]
  /// 5. `NVIDIA_API_KEY` → [NvidiaProvider]
  /// 6. `LIBRETRANSLATE_API_KEY` → [LibreTranslateProvider]
  ///
  /// Returns `null` if no key is found.
  ///
  /// ### Setting keys via --dart-define at build time:
  /// ```bash
  /// flutter run --dart-define=NVIDIA_API_KEY=nvapi-...
  /// flutter build apk --dart-define=OPENAI_API_KEY=sk-...
  /// ```
  static AiProvider? fromEnv() {
    // --dart-define values (compile-time constants — safe for all platforms).
    const openAiKey = String.fromEnvironment('OPENAI_API_KEY');
    const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
    const claudeKey = String.fromEnvironment('ANTHROPIC_API_KEY');
    const deeplKey = String.fromEnvironment('DEEPL_API_KEY');
    const nvidiaKey = String.fromEnvironment('NVIDIA_API_KEY');
    const libreKey = String.fromEnvironment('LIBRETRANSLATE_API_KEY');

    if (openAiKey.isNotEmpty) return OpenAiProvider(apiKey: openAiKey);
    if (geminiKey.isNotEmpty) return GeminiProvider(apiKey: geminiKey);
    if (claudeKey.isNotEmpty) return ClaudeProvider(apiKey: claudeKey);
    if (deeplKey.isNotEmpty) return DeepLProvider(apiKey: deeplKey);
    if (nvidiaKey.isNotEmpty) return NvidiaProvider(apiKey: nvidiaKey);
    if (libreKey.isNotEmpty) return LibreTranslateProvider(apiKey: libreKey);

    // Runtime environment variables (mobile / desktop only, not web).
    if (!_isWeb) {
      final env = Platform.environment;
      final rOpenAi = env['OPENAI_API_KEY'] ?? '';
      final rGemini = env['GEMINI_API_KEY'] ?? '';
      final rClaude = env['ANTHROPIC_API_KEY'] ?? '';
      final rDeepl = env['DEEPL_API_KEY'] ?? '';
      final rNvidia = env['NVIDIA_API_KEY'] ?? '';
      final rLibre = env['LIBRETRANSLATE_API_KEY'] ?? '';

      if (rOpenAi.isNotEmpty) return OpenAiProvider(apiKey: rOpenAi);
      if (rGemini.isNotEmpty) return GeminiProvider(apiKey: rGemini);
      if (rClaude.isNotEmpty) return ClaudeProvider(apiKey: rClaude);
      if (rDeepl.isNotEmpty) return DeepLProvider(apiKey: rDeepl);
      if (rNvidia.isNotEmpty) return NvidiaProvider(apiKey: rNvidia);
      if (rLibre.isNotEmpty) return LibreTranslateProvider(apiKey: rLibre);
    }

    return null;
  }

  // ── Explicit creation ───────────────────────────────────────────────────

  /// Creates a provider of the given [type] with an explicit [apiKey].
  ///
  /// [model] overrides the default model (OpenAI / Gemini / Claude / NVIDIA).
  /// [endpoint] overrides the server URL (LibreTranslate self-hosted).
  static AiProvider create({
    required AiProviderType type,
    required String apiKey,
    String? model,
    String? endpoint,
  }) {
    return switch (type) {
      AiProviderType.openai =>
        OpenAiProvider(apiKey: apiKey, model: model ?? 'gpt-4.1-mini'),
      AiProviderType.gemini =>
        GeminiProvider(apiKey: apiKey, model: model ?? 'gemini-2.0-flash'),
      AiProviderType.claude =>
        ClaudeProvider(apiKey: apiKey, model: model ?? 'claude-haiku-4-5-20251001'),
      AiProviderType.deepl =>
        DeepLProvider(apiKey: apiKey),
      AiProviderType.nvidia =>
        NvidiaProvider(apiKey: apiKey, model: model ?? 'meta/llama-3.3-70b-instruct'),
      AiProviderType.libretranslate =>
        LibreTranslateProvider(
          apiKey: apiKey.isEmpty ? null : apiKey,
          endpoint: endpoint ?? 'https://translate.argosopentech.com',
        ),
    };
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static bool get _isWeb {
    try {
      return Platform.isAndroid == false &&
          Platform.isIOS == false &&
          Platform.isLinux == false &&
          Platform.isMacOS == false &&
          Platform.isWindows == false;
    } catch (_) {
      return true; // Platform not available → assume web
    }
  }
}
