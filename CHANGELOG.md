## 0.1.0

* Initial release.
* Runtime language switching with `setLocale()` and `.tr(context)` extension.
* JSON-based translations loaded from Flutter assets.
* AI translation of missing keys with automatic caching.
* Six AI providers: OpenAI, Google Gemini, Anthropic Claude, NVIDIA NIM, DeepL, LibreTranslate.
* `AiProviderFactory` with four resolution strategies: config file, Flutter assets, `--dart-define`, explicit.
* `dart run linguaflow:setup` — interactive CLI wizard to configure a provider.
* `dart run linguaflow:generate` — batch CLI to generate translation files.
* `SharedPreferences` persistence of selected locale across app restarts.
