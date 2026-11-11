import 'package:flutter/material.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/l10n/l10n.dart';

/// Friendly replacement for Flutter's red error box.
///
/// Works even when it is built outside of the app's localization scope.
class AppErrorView extends StatelessWidget {
  /// Creates the error view.
  const AppErrorView({this.onRetry, super.key});

  /// Shows a retry button when provided.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorGenericTitle,
          message: l10n.errorGenericBody,
          actionLabel: onRetry == null ? null : l10n.retry,
          onAction: onRetry,
        ),
      ),
    );
  }
}
