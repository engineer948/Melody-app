import 'package:flutter/material.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/l10n/l10n.dart';

/// Localized, user-facing description of [failure].
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      TimeoutFailure() => l10n.errorTimeout,
      UnauthorizedFailure() => l10n.errorUnauthorized,
      NotFoundFailure() => l10n.errorNotFound,
      ServerFailure() => l10n.errorServer,
      ParsingFailure() => l10n.errorParsing,
      UnsupportedFailure() => l10n.errorUnsupported,
      UnknownFailure() => l10n.errorGenericBody,
    };

/// Converts anything a provider may throw into a [Failure].
Failure asFailure(Object error) =>
    error is Failure ? error : UnknownFailure(cause: error);

/// Full-area explanation of a [Failure] with a retry button.
class FailureView extends StatelessWidget {
  /// Creates the view.
  const FailureView({required this.failure, this.onRetry, super.key});

  /// What went wrong.
  final Failure failure;

  /// Shows a retry button when provided.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = failure is NetworkFailure || failure is TimeoutFailure;
    return EmptyState(
      icon: offline ? Icons.cloud_off_outlined : Icons.error_outline,
      title: l10n.errorGenericTitle,
      message: failureMessage(l10n, failure),
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Thin strip telling the user that cached content is shown.
class OfflineBanner extends StatelessWidget {
  /// Creates the banner.
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.offlineBanner,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
