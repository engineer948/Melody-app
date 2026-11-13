import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/data/tailnet/tailnet_bridge.dart';
import 'package:melody/features/auth/auth_providers.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// Text for an invite problem.
String inviteProblemText(AppLocalizations l10n, InviteProblem problem) =>
    switch (problem) {
      InviteProblem.malformed => l10n.tailnetErrorMalformed,
      InviteProblem.corrupted => l10n.tailnetErrorCorrupted,
      InviteProblem.notAuthKey => l10n.tailnetErrorNotAuthKey,
      InviteProblem.notTailnetServer => l10n.tailnetErrorNotTailnet,
    };

/// Text for a failed connection report.
String tailnetErrorText(AppLocalizations l10n, TailnetReport report) {
  final error = report.error ?? '';
  if (error == 'crashed') return l10n.tailnetCrashed;
  final lower = error.toLowerCase();
  if (lower.contains('authkey') ||
      lower.contains('auth key') ||
      lower.contains('invalid key') ||
      lower.contains('expired')) {
    return l10n.tailnetErrorKeyRefused;
  }
  return l10n.tailnetErrorGeneric(error);
}

/// Joins a friend's server with an invite code (text or QR picture).
class JoinTailnetScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const JoinTailnetScreen({super.key});

  @override
  ConsumerState<JoinTailnetScreen> createState() => _JoinTailnetScreenState();
}

class _JoinTailnetScreenState extends ConsumerState<JoinTailnetScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  bool _fromClipboard = false;
  String? _error;
  String? _progress;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _code.text = text;
      _fromClipboard = true;
      _error = null;
    });
  }

  Future<void> _readQr() async {
    final l10n = context.l10n;
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
          uniformTypeIdentifiers: ['public.image'],
        ),
      ],
    );
    if (file == null) return;
    setState(() => _busy = true);
    final text = await decodeQrImage(await file.readAsBytes());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (text == null || !text.trim().startsWith(TailnetInvite.prefix)) {
        _error = l10n.tailnetQrNotFound;
      } else {
        _code.text = text.trim();
        _fromClipboard = false;
        _error = null;
      }
    });
  }

  Future<void> _join() async {
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final TailnetInvite invite;
    try {
      invite = TailnetInvite.decode(_code.text);
    } on InviteException catch (e) {
      setState(() => _error = inviteProblemText(l10n, e.problem));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _progress = l10n.tailnetConnecting;
    });
    final controller = ref.read(tailnetControllerProvider.notifier);
    var report = await controller.join(invite);
    if (!mounted) return;
    if (report.status == TailnetStatus.needsApproval) {
      setState(() => _progress = l10n.tailnetWaitingApproval);
      report = await _waitForApproval();
      if (!mounted) return;
    }
    if (report.status != TailnetStatus.running) {
      setState(() {
        _busy = false;
        _progress = null;
        _error = tailnetErrorText(l10n, report);
      });
      return;
    }
    // The key has done its job: drop it from the screen and the clipboard.
    if (_fromClipboard) await Clipboard.setData(const ClipboardData(text: ''));
    _code.clear();
    ref.read(selectedSourceTypeProvider.notifier).select(SourceType.jellyfin);
    final probed = await ref
        .read(serverConnectorProvider)
        .probe(invite.server.toString());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
    switch (probed) {
      case Ok(value: final server):
        final named = invite.name == null
            ? server
            : server.copyWith(name: invite.name!);
        unawaited(context.push(AppRoutes.loginForServer(named)));
      case Err():
        setState(() => _error = l10n.tailnetServerNoAnswer);
    }
  }

  /// Waits (as long as the screen is open) until an admin approves us.
  Future<TailnetReport> _waitForApproval() async {
    final controller = ref.read(tailnetControllerProvider.notifier);
    while (mounted) {
      await Future<void>.delayed(TailnetController.fastPoll);
      final report = await controller.refresh();
      if (report.status != TailnetStatus.needsApproval &&
          report.status != TailnetStatus.starting) {
        return report;
      }
    }
    return const TailnetReport(TailnetStatus.stopped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tailnetJoin)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (ref.watch(tailnetControllerProvider).crashed)
                  const _CrashNotice(),
                Text(l10n.tailnetJoinIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 4,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                  onChanged: (_) => _fromClipboard = false,
                  decoration: InputDecoration(
                    labelText: l10n.tailnetCodeLabel,
                    hintText: '${TailnetInvite.prefix}…',
                    errorText: _error,
                    errorMaxLines: 4,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded),
                      tooltip: l10n.tailnetPaste,
                      onPressed: _busy ? null : _paste,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _readQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(l10n.tailnetReadQr),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _join,
                  child: Text(l10n.tailnetConnect),
                ),
                if (_progress case final progress?) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(progress)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after Tailscale took the app down: explains it and lets the user
/// copy the error report for the developer.
class _CrashNotice extends ConsumerWidget {
  const _CrashNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final report = ref.watch(tailnetControllerProvider).crashReport;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tailnetCrashed,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            if (report != null)
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: report));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.tailnetReportCopied)),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(l10n.tailnetCopyReport),
              ),
          ],
        ),
      ),
    );
  }
}
