# 🌐 LinguaFlow

**AI-powered localization for Flutter apps.**

Runtime language switching · JSON translations · Automatic AI translation of missing keys

[![pub.dev](https://img.shields.io/pub/v/linguaflow)](https://pub.dev/packages/linguaflow)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Features

| Feature | Status |
| --- | --- |
| Runtime language switching | ✅ |
| JSON-based translations | ✅ |
| `.tr(context)` extension | ✅ |
| String interpolation (`{placeholders}`) | ✅ |
| Pluralization (`trPlural`) | ✅ |
| RTL language detection | ✅ |
| Device locale auto-detection | ✅ |
| Persist selected language | ✅ |
| AI translation of missing keys | ✅ |
| Translation caching | ✅ |
| CLI batch translation generator | ✅ |
| Interactive provider setup wizard | ✅ |
| OpenAI provider | ✅ |
| Google Gemini provider | ✅ |
| Anthropic Claude provider | ✅ |
| NVIDIA NIM provider | ✅ |
| DeepL provider | ✅ |
| LibreTranslate provider (free) | ✅ |

---

## Installation

```yaml
dependencies:
  linguaflow: ^0.1.0
```

---

## Quick Setup

### 1. Add your JSON translation files

```txt
assets/
  lang/
    en.json
    hi.json
    fr.json
```

#### en.json

```json
{
  "welcome": "Welcome Back",
  "welcome_user": "Welcome, {name}!",
  "hello": "Hello",
  "item_count_one": "You have 1 item",
  "item_count_other": "You have {count} items"
}
```

### 2. Declare assets in pubspec.yaml

```yaml
flutter:
  assets:
    - assets/lang/en.json
    - assets/lang/hi.json
    - assets/lang/fr.json
```

### 3. Configure your AI provider

Run the interactive setup wizard **once** in your project:

```bash
dart run linguaflow:setup
```

It will ask you:

```txt
  ── Step 1 — Choose your AI provider

  [1]  OpenAI          default: GPT-4.1-mini      Best quality
  [2]  Google Gemini   default: Gemini 2.0 Flash  Fast & cheap
  [3]  Anthropic Claude  default: Haiku 4.5       Balanced
  [4]  DeepL                                      Translation-focused
  [5]  LibreTranslate                             Free & open source

  Enter choice [1–5]: _

  ── Step 2 — Enter your API key

  API key: _

  ✓ Saved to .linguaflow_config.json
  ✓ Added .linguaflow_config.json to .gitignore
```

### 4. Wrap your app

```dart
import 'package:linguaflow/linguaflow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final aiProvider =
      await AiProviderFactory.fromConfig() ?? AiProviderFactory.fromEnv();

  runApp(
    LinguaFlowProvider(
      config: const LocaleConfig(
        fallbackLocale: 'en',
        supportedLocales: ['en', 'hi', 'fr'],
        autoDetectLocale: true,   // switches to device locale on first launch
      ),
      aiProvider: aiProvider,
      child: const MyApp(),
    ),
  );
}
```

---

## Usage

### Translate a string

```dart
Text('welcome'.tr(context))
```

### String interpolation

Embed `{placeholders}` in your JSON values and pass `args` at call time:

```json
{ "welcome_user": "Welcome, {name}!" }
```

```dart
Text('welcome_user'.tr(context, args: {'name': 'Ambit'}))
// → "Welcome, Ambit!"
```

Multiple placeholders work the same way:

```json
{ "order_summary": "Order #{id} — {count} items" }
```

```dart
'order_summary'.tr(context, args: {'id': '1042', 'count': '3'})
// → "Order #1042 — 3 items"
```

### Pluralization

Add `_one` and `_other` variants to your JSON:

```json
{
  "item_count_one":   "You have 1 item",
  "item_count_other": "You have {count} items"
}
```

```dart
'item_count'.trPlural(context, count: 1)   // → "You have 1 item"
'item_count'.trPlural(context, count: 5)   // → "You have 5 items"
```

`{count}` is injected automatically. Pass extra `args` for additional placeholders.

### Switch language at runtime

```dart
LinguaFlow.of(context).setLocale('hi');
```

The selected locale is **persisted automatically** — next app launch restores it.

### Device locale auto-detection

When `autoDetectLocale: true` (the default), LinguaFlow reads the device locale on first launch and activates it if it is in `supportedLocales`. Set it to `false` to always start with `fallbackLocale`.

### RTL support

```dart
final manager = LinguaFlow.of(context);

manager.isRtl          // true for Arabic, Hebrew, Farsi, Urdu and more
manager.textDirection  // TextDirection.rtl or TextDirection.ltr
```

Use it with Flutter's `Directionality` widget:

```dart
Directionality(
  textDirection: LinguaFlow.of(context).textDirection,
  child: MyWidget(),
)
```

RTL is detected automatically for: Arabic, Hebrew, Farsi, Urdu, Yiddish, Pashto, Sindhi, Uyghur.

### AI translation for missing keys (async)

```dart
FutureBuilder<String>(
  future: 'new_key'.trAsync(context),
  builder: (ctx, snap) => Text(snap.data ?? '...'),
)
```

Missing keys are automatically:

1. Translated by AI
2. Cached to disk
3. Returned instantly on future calls

Interpolation and pluralization work with `trAsync` and `trPluralAsync` too:

```dart
'welcome_user'.trAsync(context, args: {'name': 'Ambit'})
'item_count'.trPluralAsync(context, count: 5)
```

---

## Configuring the AI Provider

There are three ways to supply the API key — use whichever fits your workflow.

### Option A — Interactive wizard (recommended for development)

```bash
dart run linguaflow:setup
```

Saves a `.linguaflow_config.json` that is auto-loaded at runtime and
auto-added to `.gitignore`.

```dart
aiProvider: await AiProviderFactory.fromConfig()
```

### Option B — `--dart-define` at build time (recommended for CI / production)

No config file needed. The key is baked into the binary at compile time.

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-...
flutter run --dart-define=GEMINI_API_KEY=AIza...
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
flutter run --dart-define=NVIDIA_API_KEY=nvapi-...
flutter run --dart-define=DEEPL_API_KEY=your-key:fx
```

```dart
aiProvider: AiProviderFactory.fromEnv()
```

### Option C — Explicit provider (full control)

```dart
aiProvider: OpenAiProvider(apiKey: 'sk-...')
aiProvider: GeminiProvider(apiKey: 'AIza...', model: 'gemini-2.0-flash')
aiProvider: ClaudeProvider(apiKey: 'sk-ant-...', model: 'claude-haiku-4-5-20251001')
aiProvider: NvidiaProvider(apiKey: 'nvapi-...')
aiProvider: DeepLProvider(apiKey: 'your-key:fx')
aiProvider: LibreTranslateProvider()                              // free, no key
aiProvider: LibreTranslateProvider(endpoint: 'http://localhost:5000') // self-hosted
```

---

## CLI — Batch Translation Generator

Generate all translation files from your base JSON in one command:

```bash
dart run linguaflow:generate \
  --key=sk-YOUR_OPENAI_KEY \
  --source=assets/lang/en.json \
  --targets=hi,fr,de,es,ja
```

Output:

```txt
[LinguaFlow] Loaded 12 keys from assets/lang/en.json
[LinguaFlow] Translating → Hindi...
[LinguaFlow] ✓ Saved assets/lang/hi.json
[LinguaFlow] Translating → French...
[LinguaFlow] ✓ Saved assets/lang/fr.json
[LinguaFlow] Done.
```

---

## API Reference

### String extensions

| Method | Description |
| --- | --- |
| `'key'.tr(context)` | Synchronous translation |
| `'key'.tr(context, args: {...})` | Synchronous with placeholder substitution |
| `'key'.trAsync(context)` | Async — triggers AI for missing keys |
| `'key'.trAsync(context, args: {...})` | Async with placeholder substitution |
| `'key'.trPlural(context, count: n)` | Picks `_one` or `_other`, injects `{count}` |
| `'key'.trPluralAsync(context, count: n)` | Async plural with AI fallback |

### LocaleManager

| Property / Method | Description |
| --- | --- |
| `locale` | Current `Locale` |
| `isRtl` | `true` if the current language is right-to-left |
| `textDirection` | `TextDirection.rtl` or `.ltr` |
| `isInitialized` | `true` after translations are loaded |
| `setLocale(code)` | Switch locale and persist the choice |
| `translate(key)` | Async lookup with AI fallback |
| `translateSync(key)` | Synchronous lookup, no AI |

### LocaleConfig

| Parameter | Default | Description |
| --- | --- | --- |
| `supportedLocales` | required | List of locale codes your app supports |
| `fallbackLocale` | `'en'` | Used when no saved locale is found |
| `assetPath` | `'assets/lang/'` | Folder containing JSON files |
| `enableLogging` | `true` | Print debug messages |
| `autoDetectLocale` | `true` | Match device locale on first launch |

---

## Architecture

```txt
lib/
 ├── linguaflow.dart               ← Public barrel export
 └── src/
      ├── core/
      │    ├── locale_manager.dart        ← ChangeNotifier, orchestrates everything
      │    ├── translation_store.dart     ← In-memory translation map
      │    ├── cache_manager.dart         ← SharedPreferences AI cache
      │    └── constants.dart
      ├── models/
      │    └── locale_config.dart         ← Config passed to LinguaFlowProvider
      ├── services/
      │    ├── ai/
      │    │    ├── ai_provider.dart          ← Abstract interface
      │    │    ├── ai_provider_factory.dart  ← Factory: config / env / explicit
      │    │    ├── openai_provider.dart
      │    │    ├── gemini_provider.dart
      │    │    ├── claude_provider.dart
      │    │    ├── nvidia_provider.dart
      │    │    ├── deepl_provider.dart
      │    │    └── libretranslate_provider.dart
      │    ├── file_loader.dart           ← Loads JSON from assets
      │    └── storage_service.dart       ← Persists locale choice
      ├── extensions/
      │    └── string_extension.dart     ← .tr() / .trAsync() / .trPlural()
      ├── widgets/
      │    └── linguaflow_provider.dart  ← Root widget + LinguaFlow accessor
      └── cli/
           ├── setup.dart               ← dart run linguaflow:setup
           └── generate_translations.dart ← dart run linguaflow:generate
```

### Missing key resolution order

```txt
.tr() called
    │
    ▼
In-memory store ──found──▶ interpolate → return
    │
   not found
    ▼
Persistent cache ──found──▶ warm store → interpolate → return
    │
   not found
    ▼
AI provider ──success──▶ cache + store → interpolate → return
    │
   fail / no provider
    ▼
Fallback locale ──found──▶ interpolate → return
    │
   not found
    ▼
Return raw key
```

---

## Supported AI Providers

| Provider | Class | Default model | API key |
| --- | --- | --- | --- |
| OpenAI | `OpenAiProvider` | `gpt-4.1-mini` | [platform.openai.com](https://platform.openai.com/api-keys) |
| Google Gemini | `GeminiProvider` | `gemini-2.0-flash` | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| Anthropic Claude | `ClaudeProvider` | `claude-haiku-4-5-20251001` | [console.anthropic.com](https://console.anthropic.com) |
| NVIDIA NIM | `NvidiaProvider` | `meta/llama-3.3-70b-instruct` | [build.nvidia.com](https://build.nvidia.com) (free credits) |
| DeepL | `DeepLProvider` | — | [deepl.com/account](https://www.deepl.com/account/summary) |
| LibreTranslate | `LibreTranslateProvider` | — | Free — no key needed |

### Bring your own provider

```dart
class MyProvider extends AiProvider {
  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    // call your API and return the translated string
  }
}
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT © Ambit Misra
