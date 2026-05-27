# Contributing to LinguaFlow

Thanks for taking the time to contribute! 🎉

## How to contribute

### Reporting bugs
Open an issue and include:
- Flutter / Dart version
- Steps to reproduce
- Expected vs actual behaviour
- Logs if available

### Suggesting features
Open an issue with the `enhancement` label and describe the use case.

### Submitting a pull request

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Run tests: `dart test`
5. Run analysis: `dart analyze lib bin test`
6. Push and open a PR against `main`

### Adding a new AI provider

1. Create `lib/src/services/ai/your_provider.dart` extending `AiProvider`
2. Add the enum value to `AiProviderType` in `ai_provider_factory.dart`
3. Wire it into `AiProviderFactory.create()` and `fromEnv()`
4. Export it from `lib/linguaflow.dart`
5. Add tests in `test/linguaflow_pkg_test.dart`
6. Document it in `README.md`

## Code style

- Follow standard Dart/Flutter conventions (`dart format .`)
- Add doc comments to all public APIs
- Keep PRs focused — one feature or fix per PR
