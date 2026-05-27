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
  "hello": "Hello",
  "settings": "Settings"
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

  // Reads .linguaflow_config.json saved by `dart run linguaflow:setup`
  final aiProvider =
      await AiProviderFactory.fromConfig() ?? AiProviderFactory.fromEnv();

  runApp(
    LinguaFlowProvider(
      config: const LocaleConfig(
        fallbackLocale: 'en',
        supportedLocales: ['en', 'hi', 'fr'],
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

### Switch language at runtime

```dart
LinguaFlow.of(context).setLocale('hi');
```

The selected locale is **persisted automatically** — next app launch restores it.

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
# OpenAI
flutter run --dart-define=OPENAI_API_KEY=sk-...

# Google Gemini
flutter run --dart-define=GEMINI_API_KEY=AIza...

# Anthropic Claude
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...

# NVIDIA NIM
flutter run --dart-define=NVIDIA_API_KEY=nvapi-...

# DeepL
flutter run --dart-define=DEEPL_API_KEY=your-key:fx

# LibreTranslate (public server — no key needed)
flutter run
```

```dart
aiProvider: AiProviderFactory.fromEnv()
```

### Option C — Explicit provider (full control)

```dart
// OpenAI
aiProvider: OpenAiProvider(apiKey: 'sk-...')

// Google Gemini
aiProvider: GeminiProvider(apiKey: 'AIza...', model: 'gemini-2.0-flash')

// Anthropic Claude
aiProvider: ClaudeProvider(apiKey: 'sk-ant-...', model: 'claude-haiku-4-5-20251001')

// NVIDIA NIM (LLaMA, Nemotron, Mixtral, and more)
aiProvider: NvidiaProvider(apiKey: 'nvapi-...')
aiProvider: NvidiaProvider(apiKey: 'nvapi-...', model: 'nvidia/llama-3.1-nemotron-70b-instruct')

// DeepL (free tier key ends with :fx)
aiProvider: DeepLProvider(apiKey: 'your-key:fx')

// LibreTranslate — free, no key required on public servers
aiProvider: LibreTranslateProvider()

// LibreTranslate — self-hosted
aiProvider: LibreTranslateProvider(endpoint: 'http://localhost:5000')
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
      │    └── string_extension.dart     ← .tr() / .trAsync()
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
In-memory store ──found──▶ return translation
    │
   not found
    ▼
Persistent cache ──found──▶ warm store → return
    │
   not found
    ▼
AI provider ──success──▶ cache + store → return
    │
   fail / no provider
    ▼
Fallback locale ──found──▶ return
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

Extend `AiProvider` to plug in any translation backend:

```dart
class MyProvider extends AiProvider {
  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    // call your API and return translated string
  }
}
```

---

## License

MIT © Ambit Misra
