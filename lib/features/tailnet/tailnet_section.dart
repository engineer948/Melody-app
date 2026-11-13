import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/data/tailnet/tailnet_bridge.dart';
import 'package:melody/features/tailnet/create_invite_screen.dart';
import 'package:melody/features/tailnet/join_tailnet_screen.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// Settings: the built-in Tailscale connection and invite codes.
class TailnetSection extends ConsumerWidget {
  /// Creates the section.
  const TailnetSection({super.key});

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    String server,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.link_off_rounded),
        title: Text(l10n.tailnetLeaveTitle),
        content: Text(l10n.tailnetLeaveBody(server)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tailnetLeave),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(tailnetControllerProvider.notifier).leave();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(tailnetControllerProvider);
    final report = state.report;
    final target = state.target;
    final server = state.name ?? target?.host ?? '';
    final (icon, color, text) = switch (report.status) {
      TailnetStatus.running => (
        Icons.check_circle_rounded,
        scheme.primary,
        l10n.tailnetStatusRunning(report.ip ?? ''),
      ),
      TailnetStatus.needsApproval => (
        Icons.hourglass_top_rounded,
        scheme.tertiary,
        l10n.tailnetStatusApproval,
      ),
      TailnetStatus.starting => (
        Icons.sync_rounded,
        scheme.onSurfaceVariant,
        l10n.tailnetStatusStarting,
      ),
      TailnetStatus.error || TailnetStatus.needsLogin => (
        Icons.error_outline_rounded,
        scheme.error,
        tailnetErrorText(l10n, report),
      ),
      TailnetStatus.stopped => (
        Icons.cloud_off_rounded,
        scheme.onSurfaceVariant,
        l10n.tailnetStatusStopped,
      ),
    };
    return Column(
      children: [
        if (target != null) ...[
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(server),
            subtitle: Text(text),
          ),
          if (state.crashed) ...[
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: Text(l10n.tailnetRetry),
              onTap: () => unawaited(
                ref.read(tailnetControllerProvider.notifier).retry(),
              ),
            ),
            if (state.crashReport case final report?)
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.tailnetCopyReport),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: report));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.tailnetReportCopied)),
                  );
                },
              ),
          ],
          ListTile(
            leading: const Icon(Icons.link_off_rounded),
            title: Text(l10n.tailnetLeave),
            onTap: () => _leave(context, ref, server),
          ),
        ] else if (state.available)
          ListTile(
            leading: const Icon(Icons.vpn_lock_outlined),
            title: Text(l10n.tailnetJoin),
            subtitle: Text(l10n.tailnetJoinSubtitle),
            onTap: () => unawaited(context.push(AppRoutes.joinTailnet)),
          ),
        ListTile(
          leading: const Icon(Icons.qr_code_2_rounded),
          title: Text(l10n.tailnetInviteCreate),
          subtitle: Text(l10n.tailnetInviteCreateSubtitle),
          onTap: () => unawaited(CreateInviteScreen.open(context)),
        ),
      ],
    );
  }
}
