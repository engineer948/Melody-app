import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/playlists/m3u.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _log = AppLogger('m3u');

/// Shares [tracks] as an M3U8 file called after [name] (save it to Files,
/// send it, open it in another player).
Future<void> exportM3u(
  BuildContext context,
  String name,
  List<Track> tracks,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  try {
    final dir = Directory('${(await getTemporaryDirectory()).path}/share');
    await dir.create(recursive: true);
    final file = File('${dir.path}/${M3u.fileName(name)}');
    await file.writeAsString(M3u.write(name, tracks), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'audio/x-mpegurl')],
        subject: name,
        sharePositionOrigin: origin,
      ),
    );
  } on Object catch (e) {
    _log.error('M3U export failed', e);
    messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
  }
}

/// Picks an M3U file, finds its songs in the library and saves them as a
/// new playlist.
Future<void> importM3u(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final source = ref.read(activeSourceProvider);
  if (source == null) return;
  // No type filter: Android file pickers disagree on the MIME type of .m3u.
  final file = await openFile();
  if (file == null || !context.mounted) return;
  final M3uPlaylist parsed;
  try {
    final bytes = await file.readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes); // Old Windows players write Latin-1.
    }
    parsed = M3u.parse(text);
  } on Object catch (e) {
    _log.error('M3U read failed', e);
    messenger.showSnackBar(SnackBar(content: Text(l10n.m3uEmpty)));
    return;
  }
  if (parsed.entries.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.m3uEmpty)));
    return;
  }
  if (!context.mounted) return;

  final progress = ValueNotifier(0);
  final total = parsed.entries.length;
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.m3uImporting),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (context, done, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: done / total),
                const SizedBox(height: 12),
                Text(l10n.m3uProgress(done, total)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  final M3uMatch match;
  try {
    match = await matchM3u(
      source,
      parsed.entries,
      onProgress: (done) => progress.value = done,
    );
  } finally {
    navigator.pop();
    progress.dispose();
  }
  if (!context.mounted) return;
  if (match.found.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.m3uNoneFound)));
    return;
  }
  final fallbackName = file.name.replaceFirst(
    RegExp(r'\.m3u8?$', caseSensitive: false),
    '',
  );
  final name = await askPlaylistName(
    context,
    title: l10n.m3uFound(match.found.length, total),
    action: l10n.create,
    initial: parsed.name ?? fallbackName,
  );
  if (name == null || !context.mounted) return;
  final result = await source.createPlaylist(name, [
    for (final t in match.found) t.id,
  ]);
  if (!context.mounted) return;
  ref.invalidate(playlistsProvider);
  switch (result) {
    case Ok(:final value):
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.m3uImported(match.found.length, total)),
          action: match.missing.isEmpty
              ? null
              : SnackBarAction(
                  label: l10n.m3uShowMissing,
                  onPressed: () =>
                      unawaited(_showMissing(navigator.context, match.missing)),
                ),
        ),
      );
      unawaited(
        context.push(AppRoutes.playlist(context, value.id, value.name)),
      );
    case Err(:final failure):
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
  }
}

Future<void> _showMissing(BuildContext context, List<M3uEntry> missing) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.m3uMissingTitle(missing.length)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final e in missing)
                ListTile(
                  dense: true,
                  title: Text(e.title),
                  subtitle: e.artist == null ? null : Text(e.artist!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
