import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/data/downloads/download_store.dart';
import 'package:melody/data/downloads/download_transport.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/player/streaming_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_controller.g.dart';

const _log = AppLogger('downloads');

/// Resolves the folder downloads are kept in; overridden in tests.
@Riverpod(keepAlive: true)
Future<Directory> Function() downloadDirectory(Ref ref) =>
    () async =>
        Directory('${(await getApplicationSupportDirectory()).path}/downloads');

/// Fetches the files; overridden in tests.
@Riverpod(keepAlive: true)
DownloadTransport downloadTransport(Ref ref) => DioDownloadTransport();

/// The persisted list of downloads.
@Riverpod(keepAlive: true)
DownloadStore downloadStore(Ref ref) =>
    DownloadStore(ref.watch(appDatabaseProvider));

/// Downloads of the active account by track id, in the order requested.
///
/// Files are fetched a few at a time, can be paused and resumed, and wait
/// for Wi-Fi when asked to. Work happens while the app is alive.
@Riverpod(keepAlive: true)
class DownloadController extends _$DownloadController {
  final _handles = <String, DownloadHandle>{};
  Directory? _dir;
  String? _accountId;
  int _generation = 0;
  Future<void> _ready = Future.value();

  @override
  Map<String, DownloadItem> build() {
    _accountId = ref.watch(sessionControllerProvider.select((s) => s.activeId));
    final generation = ++_generation;
    ref
      ..listen(onMobileDataProvider, (_, _) => _pump())
      ..listen(downloadSettingsControllerProvider, (previous, next) {
        _pump();
        if (previous?.autoFavorites != next.autoFavorites ||
            previous?.syncedPlaylists != next.syncedPlaylists ||
            previous?.syncLibrary != next.syncLibrary ||
            previous?.libraryLimitGb != next.libraryLimitGb ||
            (next.syncLibrary && previous?.bitrate != next.bitrate)) {
          unawaited(sync());
        }
      })
      ..onDispose(_cancelAll);
    _ready = _load(generation);
    return const {};
  }

  /// Completes once the saved downloads are loaded.
  Future<void> get ready => _ready;

  DownloadStore get _store => ref.read(downloadStoreProvider);
  DownloadSettings get _settings =>
      ref.read(downloadSettingsControllerProvider);

  void _cancelAll() {
    for (final handle in _handles.values) {
      handle.cancel();
    }
    _handles.clear();
  }

  Future<void> _load(int generation) async {
    final accountId = _accountId;
    try {
      final dir = _dir ??= await ref.read(downloadDirectoryProvider)();
      if (!dir.existsSync()) await dir.create(recursive: true);
      if (accountId == null) return;
      final items = await _store.load(accountId);
      if (generation != _generation) return;
      state = {
        for (final item in items)
          item.track.id: switch (item.status) {
            // Interrupted by the app closing.
            DownloadStatus.running => item.copyWith(
              status: DownloadStatus.queued,
            ),
            // The file was removed behind our back: fetch it again.
            DownloadStatus.done when !_file(item).existsSync() => item.copyWith(
              status: DownloadStatus.queued,
              bytes: 0,
            ),
            _ => item,
          },
      };
      _pump();
    } on Object catch (error, stack) {
      _log.error('Could not load downloads', error, stack);
    }
  }

  File _file(DownloadItem item) => File('${_dir!.path}/${item.fileName}');

  File _part(DownloadItem item) => File('${_dir!.path}/${item.fileName}.part');

  static String _safe(String value) =>
      value.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');

  String _fileName(String accountId, Track track) {
    final options = _settings.options;
    final extension = options.isOriginal
        ? _safe(track.container?.split(',').first ?? 'audio')
        : switch (options.format) {
            StreamFormat.opus => 'ogg',
            StreamFormat.aac => 'aac',
            StreamFormat.original || StreamFormat.mp3 => 'mp3',
          };
    return '${_safe(accountId)}_${_safe(track.id)}.$extension';
  }

  /// Path of the finished download of [trackId], or `null`.
  String? localPath(String trackId) {
    final item = state[trackId];
    if (item == null || !item.isDone || _dir == null) return null;
    final file = _file(item);
    return file.existsSync() ? file.path : null;
  }

  /// Cover saved together with a download, or `null`.
  File? coverFile(String artworkItemId) {
    final dir = _dir;
    if (dir == null) return null;
    final file = File('${dir.path}/covers/${_safe(artworkItemId)}');
    return file.existsSync() ? file : null;
  }

  Future<void> _put(DownloadItem item, {bool persist = true}) async {
    final accountId = _accountId;
    state = {...state, item.track.id: item};
    if (persist && accountId != null) await _store.save(accountId, item);
  }

  /// Queues [tracks] for download; [origin] records why they are kept.
  Future<void> enqueue(
    List<Track> tracks, {
    String origin = DownloadOrigin.manual,
  }) async {
    await _ready;
    final accountId = _accountId;
    if (accountId == null || _dir == null) return;
    for (final track in tracks) {
      final existing = state[track.id];
      if (existing != null) {
        final retry = existing.status == DownloadStatus.failed;
        if (existing.origins.contains(origin) && !retry) continue;
        await _put(
          existing.copyWith(
            origins: {...existing.origins, origin},
            status: retry ? DownloadStatus.queued : null,
          ),
        );
      } else {
        await _put(
          DownloadItem(
            track: track,
            fileName: _fileName(accountId, track),
            origins: {origin},
          ),
        );
      }
    }
    _pump();
  }

  /// Starts queued downloads while slots are free and the network allows.
  void _pump() {
    if (!ref.mounted || _dir == null) return;
    final settings = _settings;
    final mobile = ref.read(onMobileDataProvider).value ?? false;
    if (settings.wifiOnly && mobile) {
      // Back in the queue until Wi-Fi returns.
      for (final id in _handles.keys.toList()) {
        _stop(id, DownloadStatus.queued);
      }
      return;
    }
    var running = _handles.length;
    for (final item in state.values.toList()) {
      if (running >= settings.parallel) break;
      if (item.status != DownloadStatus.queued) continue;
      if (_handles.containsKey(item.track.id)) continue;
      running++;
      final handle = _handles[item.track.id] = DownloadHandle();
      unawaited(_run(item.track.id, handle, _generation));
    }
  }

  void _stop(String trackId, DownloadStatus status) {
    _handles.remove(trackId)?.cancel();
    final item = state[trackId];
    if (item != null && !item.isDone) {
      unawaited(_put(item.copyWith(status: status)));
    }
  }

  Future<void> _run(
    String trackId,
    DownloadHandle handle,
    int generation,
  ) async {
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        identical(_handles[trackId], handle);
    final source = ref.read(activeSourceProvider);
    final item = state[trackId];
    if (source == null || item == null) {
      _handles.remove(trackId);
      return;
    }
    await _put(item.copyWith(status: DownloadStatus.running));
    if (!current()) return;
    var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await ref
          .read(downloadTransportProvider)
          .fetch(
            source.downloadUri(item.track, _settings.options),
            _part(item),
            handle: handle,
            headers: source.requestHeaders,
            onProgress: (bytes, total) {
              final now = DateTime.now();
              if (now.difference(lastUpdate).inMilliseconds < 300) return;
              lastUpdate = now;
              final latest = state[trackId];
              if (!current() || latest == null) return;
              state = {
                ...state,
                trackId: latest.copyWith(bytes: bytes, totalBytes: total),
              };
            },
          );
      if (!current()) return;
      final file = await _part(item).rename(_file(item).path);
      final size = file.lengthSync();
      if (!ref.mounted) return;
      final latest = state[trackId] ?? item;
      await _put(
        latest.copyWith(
          status: DownloadStatus.done,
          bytes: size,
          totalBytes: size,
        ),
      );
      unawaited(_saveExtras(source, item.track));
    } on DownloadCancelled {
      // Whoever cancelled already set the new status.
    } on Object catch (error) {
      _log.error('Download failed', error);
      if (current()) {
        final latest = state[trackId];
        if (latest != null) {
          await _put(latest.copyWith(status: DownloadStatus.failed));
        }
      }
    } finally {
      if (identical(_handles[trackId], handle)) _handles.remove(trackId);
      if (generation == _generation) _pump();
    }
  }

  /// Cover and lyrics, so the track is complete offline.
  Future<void> _saveExtras(MusicSource source, Track track) async {
    final artwork = track.artwork;
    final uri = source.artworkUri(artwork, size: 640);
    final dir = _dir;
    try {
      if (artwork != null && uri != null && dir != null) {
        final covers = Directory('${dir.path}/covers');
        if (!covers.existsSync()) await covers.create(recursive: true);
        final file = File('${covers.path}/${_safe(artwork.itemId)}');
        if (!file.existsSync()) {
          final part = File('${file.path}.part');
          if (part.existsSync()) await part.delete();
          await ref
              .read(downloadTransportProvider)
              .fetch(
                uri,
                part,
                handle: DownloadHandle(),
                headers: source.requestHeaders,
              );
          await part.rename(file.path);
        }
      }
      if (ref.mounted) await ref.read(trackLyricsProvider(track).future);
    } on Object catch (error) {
      _log.error('Could not save cover or lyrics', error);
    }
  }

  /// Pauses the download of [trackId].
  void pause(String trackId) => _stop(trackId, DownloadStatus.paused);

  /// Resumes or retries the download of [trackId].
  Future<void> resume(String trackId) async {
    final item = state[trackId];
    if (item == null || item.isDone) return;
    await _put(item.copyWith(status: DownloadStatus.queued));
    _pump();
  }

  /// Pauses everything that is not finished.
  void pauseAll() {
    for (final item in state.values.toList()) {
      if (item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.running) {
        _stop(item.track.id, DownloadStatus.paused);
      }
    }
  }

  /// Resumes everything paused or failed.
  Future<void> resumeAll() async {
    for (final item in state.values.toList()) {
      if (item.status == DownloadStatus.paused ||
          item.status == DownloadStatus.failed) {
        await _put(item.copyWith(status: DownloadStatus.queued));
      }
    }
    _pump();
  }

  /// Deletes the downloads of [trackIds] (all of them when `null`).
  Future<void> remove([Iterable<String>? trackIds]) async {
    await _ready;
    final accountId = _accountId;
    if (accountId == null || _dir == null) return;
    final ids = (trackIds ?? state.keys).toList();
    final next = {...state};
    for (final id in ids) {
      final item = next.remove(id);
      if (item == null) continue;
      _handles.remove(id)?.cancel();
      for (final file in [_file(item), _part(item)]) {
        try {
          if (file.existsSync()) await file.delete();
        } on Object catch (error) {
          _log.error('Could not delete a download', error);
        }
      }
      await _store.remove(accountId, id);
    }
    state = next;
    _pump();
  }

  /// Makes the downloads kept for [origin] match [tracks]: new ones are
  /// queued, and ones no longer listed are deleted unless kept for another
  /// reason.
  Future<void> reconcile(String origin, List<Track> tracks) async {
    await _ready;
    final wanted = {for (final t in tracks) t.id};
    final gone = <String>[];
    for (final item in state.values.toList()) {
      if (!item.origins.contains(origin) || wanted.contains(item.track.id)) {
        continue;
      }
      final rest = {...item.origins}..remove(origin);
      if (rest.isEmpty) {
        gone.add(item.track.id);
      } else {
        await _put(item.copyWith(origins: rest));
      }
    }
    if (gone.isNotEmpty) await remove(gone);
    await enqueue(tracks, origin: origin);
  }

  /// The whole library, newest first, cut at the space limit (estimated
  /// from length and download quality); `null` when it cannot be read.
  Future<List<Track>?> _libraryTracks(
    MusicSource source,
    DownloadSettings settings,
  ) async {
    const page = 500;
    final all = <Track>[];
    for (var offset = 0; ; offset += page) {
      final result = await source.tracks(
        TrackQuery(sort: TrackSort.dateAdded, offset: offset, limit: page),
      );
      final tracks = result.valueOrNull;
      if (tracks == null) return null;
      all.addAll(tracks);
      if (tracks.length < page) break;
    }
    final limitGb = settings.libraryLimitGb;
    if (limitGb == null) return all;
    // Original files are guessed at 320 kbps.
    final kbps = settings.bitrate ?? 320;
    final budget = limitGb * 1000 * 1000 * 1000;
    var used = 0;
    final kept = <Track>[];
    for (final track in all) {
      final seconds = (track.duration ?? const Duration(minutes: 4)).inSeconds;
      final known = state[track.id]?.totalBytes ?? 0;
      final size = known > 0 ? known : seconds * kbps * 1000 ~/ 8;
      if (used + size > budget) break;
      used += size;
      kept.add(track);
    }
    return kept;
  }

  /// Brings automatic downloads (favourites, synced playlists) up to date.
  /// Does nothing when the source cannot be reached.
  Future<void> sync() async {
    await _ready;
    final source = ref.read(activeSourceProvider);
    final accountId = _accountId;
    if (source == null || accountId == null) return;
    final settings = _settings;
    if (settings.autoFavorites) {
      final result = await source.favorites(limit: 2000);
      final tracks = result.valueOrNull;
      if (tracks != null) await reconcile(DownloadOrigin.favorites, tracks);
    } else {
      await reconcile(DownloadOrigin.favorites, const []);
    }
    if (settings.syncLibrary) {
      final tracks = await _libraryTracks(source, settings);
      if (tracks != null) await reconcile(DownloadOrigin.library, tracks);
    } else {
      await reconcile(DownloadOrigin.library, const []);
    }
    final prefix = DownloadSettings.playlistKey(accountId, '');
    final synced = {
      for (final key in settings.syncedPlaylists)
        if (key.startsWith(prefix)) key.substring(prefix.length),
    };
    for (final id in synced) {
      final result = await source.tracks(
        TrackQuery(playlistId: id, sort: TrackSort.natural, limit: 2000),
      );
      final tracks = result.valueOrNull;
      if (tracks != null) {
        await reconcile(DownloadOrigin.playlist(id), tracks);
      }
    }
    // Playlists that are no longer synced.
    final stale = <String>{
      for (final item in state.values)
        for (final origin in item.origins)
          if (origin.startsWith('playlist:') &&
              !synced.contains(origin.substring('playlist:'.length)))
            origin,
    };
    for (final origin in stale) {
      await reconcile(origin, const []);
    }
  }
}
