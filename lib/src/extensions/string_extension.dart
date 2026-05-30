import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linguaflow/src/core/locale_manager.dart';

extension TranslateExtension on String {
  /// Returns the translation for this key in the current locale.
  ///
  /// Pass [args] to substitute `{placeholders}` in the translation value:
  /// ```dart
  /// 'welcome_user'.tr(context, args: {'name': 'Ambit'})
  /// // "Welcome, Ambit!" (from "Welcome, {name}!")
  /// ```
  String tr(BuildContext context, {Map<String, String>? args}) {
    final manager = Provider.of<LocaleManager>(context, listen: false);
    return manager.translateSync(this, args: args);
  }

  /// Async version of [tr] — triggers AI translation for missing keys.
  Future<String> trAsync(BuildContext context, {Map<String, String>? args}) {
    final manager = Provider.of<LocaleManager>(context, listen: false);
    return manager.translate(this, args: args);
  }

  /// Returns the singular or plural translation based on [count].
  ///
  /// Looks up `{key}_one` when count == 1, otherwise `{key}_other`.
  /// Always injects `{count}` into args automatically.
  ///
  /// JSON:
  /// ```json
  /// "item_count_one":   "You have 1 item",
  /// "item_count_other": "You have {count} items"
  /// ```
  /// Usage:
  /// ```dart
  /// 'item_count'.trPlural(context, count: 3)  // "You have 3 items"
  /// 'item_count'.trPlural(context, count: 1)  // "You have 1 item"
  /// ```
  String trPlural(
    BuildContext context, {
    required int count,
    Map<String, String>? args,
  }) {
    final key = count == 1 ? '${this}_one' : '${this}_other';
    final allArgs = {'count': '$count', ...?args};
    return key.tr(context, args: allArgs);
  }

  /// Async version of [trPlural] — triggers AI translation for missing keys.
  Future<String> trPluralAsync(
    BuildContext context, {
    required int count,
    Map<String, String>? args,
  }) {
    final key = count == 1 ? '${this}_one' : '${this}_other';
    final allArgs = {'count': '$count', ...?args};
    return key.trAsync(context, args: allArgs);
  }
}
