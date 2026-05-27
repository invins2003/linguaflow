import 'package:flutter/material.dart';
import 'package:linguaflow/src/core/constants.dart';
import 'package:linguaflow/src/core/translation_store.dart';
import 'package:linguaflow/src/core/cache_manager.dart';
import 'package:linguaflow/src/models/locale_config.dart';
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/services/file_loader.dart';
import 'package:linguaflow/src/services/storage_service.dart';

/// Central manager for locale state.
///
/// Responsibilities:
/// - Stores the current locale
/// - Loads JSON translations from assets
/// - Switches locale at runtime and persists the choice
/// - Falls back to AI translation for missing keys
/// - Notifies listeners so the UI rebuilds
class LocaleManager extends ChangeNotifier {
  final LocaleConfig config;
  final TranslationStore _store;
  final CacheManager _cache;
  final AiProvider? _aiProvider;

  Locale _locale;
  bool _initialized = false;

  LocaleManager({
    required this.config,
    required this._store,
    required this._cache,
    this._aiProvider,
  }) : _locale = Locale(config.fallbackLocale);

  Locale get locale => _locale;
  bool get isInitialized => _initialized;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Loads translations for all supported locales and restores the saved locale.
  Future<void> init() async {
    await _cache.init();

    // Load every supported locale's JSON file.
    for (final code in config.supportedLocales) {
      final data = await FileLoader.load(config.assetPath, code);
      if (data.isNotEmpty) _store.load(code, data);
    }

    // Restore previously chosen locale.
    final saved = await StorageService.loadLocale();
    if (saved != null && config.supportedLocales.contains(saved)) {
      _locale = Locale(saved);
    }

    _initialized = true;
    _log('Initialized. Active locale: ${_locale.languageCode}');
    notifyListeners();
  }

  // ── Locale switching ──────────────────────────────────────────────────────

  /// Switches to [code] (e.g. 'hi'), persists the choice, and rebuilds the UI.
  Future<void> setLocale(String code) async {
    if (!config.supportedLocales.contains(code)) {
      _log('Unsupported locale "$code". Ignoring.');
      return;
    }
    if (_locale.languageCode == code) return;

    _locale = Locale(code);
    await StorageService.saveLocale(code);
    _log('Locale changed to "$code".');
    notifyListeners();
  }

  // ── Translation lookup ────────────────────────────────────────────────────

  /// Returns the translation for [key] in the current locale.
  ///
  /// Resolution order:
  /// 1. In-memory translation store
  /// 2. Persistent AI cache (SharedPreferences)
  /// 3. AI provider (if configured) → cached + stored → returned
  /// 4. Fallback locale
  /// 5. The raw key itself
  Future<String> translate(String key) async {
    final code = _locale.languageCode;

    // 1. In-memory store.
    final stored = _store.get(code, key);
    if (stored != null) return stored;

    // 2. Persistent cache.
    final cached = _cache.get(code, key);
    if (cached != null) {
      _store.put(code, key, cached); // warm the in-memory store too
      return cached;
    }

    // 3. AI translation.
    if (_aiProvider != null) {
      _log('Missing key: "$key". Auto-translating via AI...');
      try {
        final languageName = _languageName(code);
        final translated = await _aiProvider.translate(
          text: key,
          targetLanguage: languageName,
        );
        _store.put(code, key, translated);
        await _cache.put(code, key, translated);
        _log('AI translation cached: "$key" → "$translated"');
        return translated;
      } catch (e) {
        _log('AI translation failed for "$key": $e');
      }
    }

    // 4. Fallback locale.
    final fallback = _store.get(config.fallbackLocale, key);
    if (fallback != null) return fallback;

    // 5. Return the raw key.
    return key;
  }

  // ── Synchronous shortcut ──────────────────────────────────────────────────

  /// Returns an already-loaded translation synchronously.
  /// Does NOT trigger AI — use [translate] for async AI fallback.
  String translateSync(String key) {
    final code = _locale.languageCode;
    return _store.get(code, key) ??
        _cache.get(code, key) ??
        _store.get(config.fallbackLocale, key) ??
        key;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps an ISO language code to its English display name for AI prompts.
  String _languageName(String code) {
    const names = {
      'en': 'English', 'hi': 'Hindi', 'fr': 'French',
      'de': 'German', 'es': 'Spanish', 'pt': 'Portuguese',
      'ar': 'Arabic', 'zh': 'Chinese', 'ja': 'Japanese',
      'ko': 'Korean', 'ru': 'Russian', 'it': 'Italian',
      'nl': 'Dutch', 'tr': 'Turkish', 'pl': 'Polish',
      'sv': 'Swedish', 'da': 'Danish', 'fi': 'Finnish',
      'no': 'Norwegian', 'cs': 'Czech', 'bn': 'Bengali',
      'ur': 'Urdu', 'ta': 'Tamil', 'te': 'Telugu',
    };
    return names[code] ?? code;
  }

  void _log(String message) {
    if (config.enableLogging) {
      debugPrint('${LinguaFlowConstants.tag} $message');
    }
  }
}
