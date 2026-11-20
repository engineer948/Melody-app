import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/backup/settings_backup.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _log = AppLogger('backup');

/// Saving the settings to a file and bringing them back on a new phone.
class BackupSection extends ConsumerWidget {
  /// Creates the section.
  const BackupSection({super.key});

  Future<void> _export(BuildContext button, WidgetRef ref) async {
    final l10n = button.l10n;
    final messenger = ScaffoldMessenger.of(button);
    final box = button.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final backup = SettingsBackup.collect(
        ref.read(preferencesProvider),
        ref.read(sessionControllerProvider).accounts,
      );
      final dir = Directory('${(await getTemporaryDirectory()).path}/backup');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final file = File(
        '${dir.path}/${SettingsBackup.fileName(backup.created)}',
      );
      await file.writeAsString(backup.encode(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Backup failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await openFile();
    if (picked == null || !context.mounted) return;
    final SettingsBackup backup;
    try {
      backup = SettingsBackup.decode(await picked.readAsString());
    } on Object catch (e) {
      _log.info('Not a backup: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupInvalid)));
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestoreTitle),
        content: Text(
          l10n.backupRestoreBody(
            MaterialLocalizations.of(context)
                .formatMediumDate(backup.created.toLocal()),
            backup.preferences.length,
            backup.accounts.length,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.backupRestore),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await backup.restoreInto(ref.read(preferencesProvider));
    await ref
        .read(sessionControllerProvider.notifier)
        .addFromBackup(backup.accounts);
    if (!context.mounted) return;
    // Most settings are read when the app starts.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestored),
        content: Text(l10n.backupRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.backupLater),
          ),
          FilledButton(
            onPressed: () => unawaited(SystemNavigator.pop()),
            child: Text(l10n.backupCloseApp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      children: [
        Builder(
          builder: (button) => ListTile(
            leading: const Icon(Icons.save_alt_rounded),
            title: Text(l10n.backupExport),
            subtitle: Text(l10n.backupExportBody),
            onTap: () => unawaited(_export(button, ref)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore_rounded),
          title: Text(l10n.backupRestore),
          subtitle: Text(l10n.backupRestoreSubtitle),
          onTap: () => unawaited(_import(context, ref)),
        ),
      ],
    );
  }
}
