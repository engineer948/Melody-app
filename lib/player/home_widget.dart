import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';
import 'package:path_provider/path_provider.dart';

const _log = AppLogger('widget');

/// Keeps the Android home screen widget in sync with the player: title,
/// artist, play state and a small copy of the cover.
class HomeWidgetUpdater {
  HomeWidgetUpdater._(this._container);

  static const _channel = MethodChannel('melody/widget');

  final ProviderContainer _container;
  final _dio = Dio();
  String? _trackId;
  bool? _playing;
  String? _coverFor;
  String? _coverPath;

  /// Starts mirroring the player to the widget. Android only.
  static void start(ProviderContainer container) {
    if (!Platform.isAndroid) return;
    final updater = HomeWidgetUpdater._(container);
    container.listen(
      playerControllerProvider,
      (_, state) => unawaited(updater._onState(state)),
      fireImmediately: true,
    );
  }

  Future<void> _onState(PlayerState state) async {
    final track = state.current;
    if (track?.id == _trackId && state.playing == _playing) return;
    final changedTrack = track?.id != _trackId;
    _trackId = track?.id;
    _playing = state.playing;
    await _push(track, playing: state.playing);
    if (changedTrack && track != null) {
      await _loadCover(track);
      if (_trackId == track.id) await _push(track, playing: _playing ?? false);
    }
  }

  Future<void> _push(Track? track, {required bool playing}) async {
    try {
      await _channel.invokeMethod<void>('update', {
        'title': track?.title ?? '',
        'artist': track?.artistLine ?? '',
        'playing': playing,
        'cover': track != null && _coverFor == track.artwork?.itemId
            ? _coverPath
            : null,
      });
    } on Object catch (error) {
      _log.error('Could not update the widget', error);
    }
  }

  Future<void> _loadCover(Track track) async {
    final artwork = track.artwork;
    final source = _container.read(activeSourceProvider);
    final uri = source?.artworkUri(artwork, size: 320);
    if (artwork == null || uri == null || _coverFor == artwork.itemId) return;
    try {
      final dir = await getApplicationCacheDirectory();
      // A new name per cover, so the widget never shows a stale bitmap.
      final file = File('${dir.path}/widget_cover_${artwork.itemId.hashCode}');
      await _dio.downloadUri(
        uri,
        file.path,
        options: Options(headers: source?.requestHeaders),
      );
      final old = _coverPath;
      _coverFor = artwork.itemId;
      _coverPath = file.path;
      if (old != null && old != file.path) {
        final previous = File(old);
        if (previous.existsSync()) await previous.delete();
      }
    } on Object catch (error) {
      _log.error('Could not load the widget cover', error);
    }
  }
}
