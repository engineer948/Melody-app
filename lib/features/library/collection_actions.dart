import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

void _report(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failureMessage(context.l10n, failure))),
  );
}

/// Marks [track] as favourite or not, everywhere it is shown.
Future<void> toggleTrackFavorite(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final source = ref.read(activeSourceProvider);
  if (source == null) return;
  final value = !track.isFavorite;
  final result = await source.setFavorite(track.id, value: value);
  if (!context.mounted) return;
  switch (result) {
    case Ok():
      ref
          .read(playerControllerProvider.notifier)
          .updateTrack(track.copyWith(isFavorite: value));
      ref.invalidate(trackListProvider);
      if (ref.read(downloadSettingsControllerProvider).autoFavorites) {
        unawaited(ref.read(downloadControllerProvider.notifier).sync());
      }
    case Err(:final failure):
      _report(context, failure);
  }
}

/// Asks for a playlist name; returns `null` when cancelled.
Future<String?> askPlaylistName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) =>
        _NameDialog(title: title, action: action, initial: initial),
  );
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Owns its text controller, so it lives until the closing animation ends.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.playlistName,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// Creates a playlist, optionally filled with [tracks].
Future<Playlist?> createPlaylist(
  BuildContext context,
  WidgetRef ref, {
  List<Track> tracks = const [],
}) async {
  final l10n = context.l10n;
  final source = ref.read(activeSourceProvider);
  if (source == null) return null;
  final name = await askPlaylistName(
    context,
    title: l10n.newPlaylist,
    action: l10n.create,
  );
  if (name == null || !context.mounted) return null;
  final result = await source.createPlaylist(name, [
    for (final t in tracks) t.id,
  ]);
  if (!context.mounted) return null;
  ref.invalidate(playlistsProvider);
  switch (result) {
    case Ok(:final value):
      if (tracks.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToPlaylist(value.name))),
        );
      }
      return value;
    case Err(:final failure):
      _report(context, failure);
      return null;
  }
}

/// Lets the user pick a playlist (or create one) and adds [tracks] to it.
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  final l10n = context.l10n;
  final source = ref.read(activeSourceProvider);
  if (source == null || tracks.isEmpty) return;
  final picked = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final playlists = ref.watch(playlistsProvider).value?.value ?? const [];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.newPlaylist),
                  onTap: () => Navigator.pop(context, true),
                ),
                for (final p in playlists)
                  ListTile(
                    leading: ArtworkImage(
                      artwork: p.artwork,
                      size: 44,
                      radius: 6,
                      icon: Icons.queue_music_outlined,
                    ),
                    title: Text(p.name),
                    onTap: () => Navigator.pop(context, p),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (!context.mounted || picked == null) return;
  if (picked == true) {
    await createPlaylist(context, ref, tracks: tracks);
    return;
  }
  final playlist = picked as Playlist;
  final result = await source.addToPlaylist(playlist.id, [
    for (final t in tracks) t.id,
  ]);
  if (!context.mounted) return;
  ref
    ..invalidate(playlistsProvider)
    ..invalidate(trackListProvider);
  unawaited(ref.read(downloadControllerProvider.notifier).sync());
  switch (result) {
    case Ok():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedToPlaylist(playlist.name))),
      );
    case Err(:final failure):
      _report(context, failure);
  }
}
