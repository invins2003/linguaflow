import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linguaflow/src/core/locale_manager.dart';

/// Adds `.tr(context)` to every String.
///
/// **Synchronous** — returns an already-loaded translation instantly.
/// For AI fallback on missing keys, use [trAsync].
///
/// ```dart
/// Text('welcome'.tr(context))
/// ```
extension TranslateExtension on String {
  /// Returns the current-locale translation for this key synchronously.
  /// Falls back to the fallback locale, then returns the raw key.
  String tr(BuildContext context) {
    final manager = Provider.of<LocaleManager>(context, listen: false);
    return manager.translateSync(this);
  }

  /// Returns a [Future<String>] — triggers AI translation if the key is missing.
  ///
  /// ```dart
  /// FutureBuilder<String>(
  ///   future: 'checkout'.trAsync(context),
  ///   builder: (ctx, snap) => Text(snap.data ?? '...'),
  /// )
  /// ```
  Future<String> trAsync(BuildContext context) {
    final manager = Provider.of<LocaleManager>(context, listen: false);
    return manager.translate(this);
  }
}
