import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/auth_providers.dart';
import 'package:melody/l10n/l10n.dart';

/// Shows a Quick Connect code and waits until it is approved elsewhere.
///
/// Pops with the resulting [AuthSession], or `null` when cancelled.
class QuickConnectDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for [server].
  const QuickConnectDialog({
    required this.server,
    this.pollInterval = const Duration(seconds: 3),
    super.key,
  });

  /// Server to sign in to.
  final ServerInfo server;

  /// How often approval is checked.
  final Duration pollInterval;

  @override
  ConsumerState<QuickConnectDialog> createState() => _QuickConnectState();
}

class _QuickConnectState extends ConsumerState<QuickConnectDialog> {
  QuickConnectRequest? _request;
  Failure? _failure;
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _timer?.cancel();
    setState(() {
      _request = null;
      _failure = null;
    });
    final result = await ref
        .read(serverConnectorProvider)
        .quickConnectStart(widget.server);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _request = value);
        _timer = Timer.periodic(widget.pollInterval, (_) => _check(value));
      case Err(:final failure):
        setState(() => _failure = failure);
    }
  }

  Future<void> _check(QuickConnectRequest request) async {
    if (_checking) return;
    _checking = true;
    try {
      final connector = ref.read(serverConnectorProvider);
      final approved = await connector.quickConnectApproved(
        widget.server,
        request,
      );
      if (!mounted) return;
      if (approved case Err(:final failure)) {
        // Keep waiting through hiccups; give up when the request is gone.
        if (failure is NotFoundFailure || failure is UnauthorizedFailure) {
          _timer?.cancel();
          setState(() => _failure = failure);
        }
        return;
      }
      if (approved.valueOrNull != true) return;
      _timer?.cancel();
      final session = await connector.quickConnectSignIn(
        widget.server,
        request,
      );
      if (!mounted) return;
      switch (session) {
        case Ok(:final value):
          Navigator.pop(context, value);
        case Err(:final failure):
          setState(() => _failure = failure);
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final request = _request;
    final failure = _failure;
    return AlertDialog(
      title: Text(l10n.quickConnectTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null)
            Text(failureMessage(l10n, failure))
          else if (request == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else ...[
            Text(l10n.quickConnectBody),
            const SizedBox(height: 20),
            Semantics(
              label: request.code.split('').join(' '),
              excludeSemantics: true,
              child: SelectableText(
                request.code,
                style: theme.textTheme.displaySmall?.copyWith(
                  letterSpacing: 6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(l10n.quickConnectWaiting)),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (failure != null)
          TextButton(onPressed: _start, child: Text(l10n.retry)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
