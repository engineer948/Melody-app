import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/social/sync_play.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/social/listen_together.dart';
import 'package:melody/l10n/l10n.dart';

/// Listening together with anyone on the server (Jellyfin SyncPlay
/// groups): start a group or join an open one.
class ListenTogetherScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ListenTogetherScreen({super.key});

  /// Opens the screen above everything.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => const ListenTogetherScreen()));

  @override
  ConsumerState<ListenTogetherScreen> createState() =>
      _ListenTogetherScreenState();
}

class _ListenTogetherScreenState extends ConsumerState<ListenTogetherScreen> {
  Future<List<SyncGroup>>? _groups;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(
    () => _groups = ref.read(listenTogetherProvider.notifier).groups(),
  );

  Future<void> _run(Future<bool> Function() action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.listenFailed)));
    }
    _reload();
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final user = ref.read(sessionControllerProvider).active?.userName ?? '';
    final controller = TextEditingController(
      text: l10n.listenGroupDefault(user),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.listenCreate),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.listenGroupName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.listenCreate),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await _run(
      () async =>
          await ref.read(listenTogetherProvider.notifier).createGroup(name) !=
          null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final listen = ref.watch(listenTogetherProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.socialFeatureListen),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: _busy ? null : _reload,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(l10n.listenHint, style: theme.textTheme.bodyLarge),
          ),
          if (listen.active)
            Card(
              color: theme.colorScheme.primaryContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.headphones_rounded),
                title: Text(l10n.listenActive(listen.participants.join(', '))),
                trailing: TextButton(
                  onPressed: () async {
                    await ref.read(listenTogetherProvider.notifier).leave();
                    _reload();
                  },
                  child: Text(l10n.listenLeave),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.listenCreate),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<SyncGroup>>(
              future: _groups,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final groups = snapshot.data ?? const <SyncGroup>[];
                if (snapshot.hasError || groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.listenNoGroups,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final group in groups)
                      ListTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: Text(group.name),
                        subtitle: Text(group.participants.join(', ')),
                        trailing: FilledButton.tonal(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(listenTogetherProvider.notifier)
                                      .joinGroup(group.id),
                                ),
                          child: Text(l10n.listenJoin),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
