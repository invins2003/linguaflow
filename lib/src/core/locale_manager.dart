import 'package:flutter/material.dart';
import 'package:linguaflow/src/core/constants.dart';
import 'package:linguaflow/src/core/translation_store.dart';
import 'package:linguaflow/src/core/cache_manager.dart';
import 'package:linguaflow/src/models/locale_config.dart';
import 'package:linguaflow/src/services/ai/ai_provider.dart';
import 'package:linguaflow/src/services/file_loader.dart';
import 'package:linguaflow/src/services/storage_service.dart';

/// Central manager for locale state.
class LocaleManager extends ChangeNotifier {
  final LocaleConfig config;
  final TranslationStore _store;
  final CacheManager _cache;
  final AiProvider? _aiProvider;

  Locale _locale;
  bool _initialized = false;

  static const _rtlLanguages = {
    'ar', 'he', 'fa', 'ur', 'yi', 'ps', 'sd', 'ug',
  };

  LocaleManager({
    required this.config,
    required this._store,
    required this._cache,
    this._aiProvider,
  }) : _locale = Locale(config.fallbackLocale);

  Locale get locale => _locale;
  bool get isInitialized => _initialized;

  /// Whether the current locale is right-to-left.
  bool get isRtl => _rtlLanguages.contains(_locale.languageCode);

  /// Text direction for the current locale — use with [Directionality].
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    await _cache.init();

    for (final code in config.supportedLocales) {
      final data = await FileLoader.load(config.assetPath, code);
      if (data.isNotEmpty) _store.load(code, data);
    }

    final saved = await StorageService.loadLocale();
    if (saved != null && config.supportedLocales.contains(saved)) {
      _locale = Locale(saved);
    } else if (config.autoDetectLocale) {
      final detected = _detectDeviceLocale();
      if (detected != null) {
        _locale = Locale(detected);
        await StorageService.saveLocale(detected);
        _log('Auto-detected locale: $detected');
      }
    }

    _initialized = true;
    _log('Initialized. Active locale: ${_locale.languageCode}');
    notifyListeners();
  }

  // ── Locale switching ──────────────────────────────────────────────────────

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

  /// Async translation with AI fallback for missing keys.
  ///
  /// Pass [args] to substitute `{placeholders}`:
  /// ```dart
  /// manager.translate('welcome_user', args: {'name': 'Ambit'})
  /// ```
  Future<String> translate(String key, {Map<String, String>? args}) async {
    final code = _locale.languageCode;

    final stored = _store.get(code, key);
    if (stored != null) return _interpolate(stored, args);

    final cached = _cache.get(code, key);
    if (cached != null) {
      _store.put(code, key, cached);
      return _interpolate(cached, args);
    }

    if (_aiProvider != null) {
      _log('Missing key: "$key" for locale "$code".');
      try {
        final translated = await _aiProvider.translate(
          text: key,
          targetLanguage: _languageName(code),
        );
        _store.put(code, key, translated);
        await _cache.put(code, key, translated);
        _log('AI translation cached: "$key" → "$translated"');
        return _interpolate(translated, args);
      } catch (e) {
        _log('AI translation failed for "$key": $e');
      }
    }

    final fallback = _store.get(config.fallbackLocale, key);
    if (fallback != null) return _interpolate(fallback, args);

    return _interpolate(key, args);
  }

  /// Synchronous translation — does not trigger AI.
  ///
  /// Pass [args] to substitute `{placeholders}`:
  /// ```dart
  /// manager.translateSync('greeting', args: {'name': 'Ambit'})
  /// ```
  String translateSync(String key, {Map<String, String>? args}) {
    final code = _locale.languageCode;
    final result = _store.get(code, key) ??
        _cache.get(code, key) ??
        _store.get(config.fallbackLocale, key) ??
        key;
    return _interpolate(result, args);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _interpolate(String text, Map<String, String>? args) {
    if (args == null || args.isEmpty) return text;
    var result = text;
    args.forEach((k, v) => result = result.replaceAll('{$k}', v));
    return result;
  }

  String? _detectDeviceLocale() {
    try {
      final deviceLocale =
          WidgetsBinding.instance.platformDispatcher.locale;
      final code = deviceLocale.languageCode;
      if (config.supportedLocales.contains(code)) return code;
    } catch (_) {}
    return null;
  }

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
