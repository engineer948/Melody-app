import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_section.g.dart';

/// Music libraries of the active account; empty when they cannot be loaded.
@riverpod
Future<List<MusicLibrary>> musicLibraries(Ref ref) async {
  final source = ref.watch(activeSourceProvider);
  if (source == null || !source.capabilities.multipleLibraries) return const [];
  return (await source.libraries()).valueOrNull ?? const [];
}

/// Saved accounts: switch, add, sign out and pick a library.
class AccountSection extends ConsumerWidget {
  /// Creates the section.
  const AccountSection({super.key});

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    ServerAccount account,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOut),
        content: Text(
          l10n.accountSignOutConfirm(account.userName, account.serverName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(sessionControllerProvider.notifier).signOut(account.id);
    }
  }

  Future<void> _pickLibrary(
    BuildContext context,
    WidgetRef ref,
    ServerAccount account,
    List<MusicLibrary> libraries,
  ) async {
    final l10n = context.l10n;
    // An empty string stands for "all libraries".
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.accountLibrary),
        children: [
          RadioGroup<String>(
            groupValue: account.libraryId ?? '',
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              children: [
                RadioListTile(value: '', title: Text(l10n.libraryAll)),
                for (final library in libraries)
                  RadioListTile(value: library.id, title: Text(library.name)),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .setLibrary(account.id, picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final active = session.active;
    final libraries = ref.watch(musicLibrariesProvider).value ?? const [];
    final selected = libraries
        .where((l) => l.id == active?.libraryId)
        .firstOrNull;
    return Column(
      children: [
        for (final account in session.accounts)
          ListTile(
            leading: Icon(
              account.id == session.activeId
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(account.userName),
            subtitle: Text(account.serverName),
            selected: account.id == session.activeId,
            onTap: account.id == session.activeId
                ? null
                : () => ref
                      .read(sessionControllerProvider.notifier)
                      .switchTo(account.id),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.accountSignOut,
              onPressed: () => _signOut(context, ref, account),
            ),
          ),
        if (active != null && libraries.length > 1)
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: Text(l10n.accountLibrary),
            subtitle: Text(selected?.name ?? l10n.libraryAll),
            onTap: () => _pickLibrary(context, ref, active, libraries),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.accountAdd),
          onTap: () => context.push(AppRoutes.connect),
        ),
      ],
    );
  }
}
