import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/media_browser.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';

const _log = AppLogger('media-session');

/// Connects the player to the system: notification, lock screen, headset
/// and Bluetooth buttons, audio focus and "headphones unplugged".
class MelodyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  MelodyAudioHandler._(this._container) : _browser = MediaBrowser(_container);

  final ProviderContainer _container;
  final MediaBrowser _browser;
  Timer? _clickTimer;
  int _clicks = 0;

  PlayerController get _player =>
      _container.read(playerControllerProvider.notifier);

  /// Starts the system service and keeps it in sync with the player.
  static Future<void> start(ProviderContainer container) async {
    try {
      final handler = await AudioService.init(
        builder: () => MelodyAudioHandler._(container),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'io.github.engineer948.melody.playback',
          androidNotificationChannelName: AppConfig.appName,
          androidNotificationOngoing: true,
          androidBrowsableRootExtras: MediaBrowser.rootExtras,
        ),
      );
      handler._bind();
      await _configureSession(container);
    } on Object catch (error, stack) {
      // Playback still works in the foreground without the service.
      _log.error('Media session unavailable', error, stack);
    }
  }

  static Future<void> _configureSession(ProviderContainer container) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.becomingNoisyEventStream.listen(
      (_) => container.read(playerControllerProvider.notifier).pause(),
    );
  }

  void _bind() {
    _container
      ..listen(
        playerControllerProvider,
        (_, state) => _sync(state),
        fireImmediately: true,
      )
      ..listen(playerPositionProvider, (_, position) {
        final value = position.value;
        if (value != null) {
          playbackState.add(
            playbackState.value.copyWith(updatePosition: value),
          );
        }
      });
  }

  MediaItem _item(PlayerState state, QueueEntry entry) {
    final track = entry.track;
    final source = _container.read(activeSourceProvider);
    final isCurrent = entry == state.queue.current;
    return MediaItem(
      id: '${entry.uid}',
      title: track.title,
      artist: track.artistLine,
      album: track.albumTitle,
      duration: isCurrent ? state.duration ?? track.duration : track.duration,
      artUri: source?.artworkUri(track.artwork, size: 640),
      artHeaders: source?.requestHeaders,
    );
  }

  void _sync(PlayerState state) {
    final current = state.queue.current;
    queue.add([for (final e in state.queue.entries) _item(state, e)]);
    mediaItem.add(current == null ? null : _item(state, current));
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToQueueItem,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: !state.hasQueue
            ? AudioProcessingState.idle
            : state.buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        playing: state.playing,
        speed: state.speed,
        queueIndex: state.hasQueue ? state.queue.index : null,
        shuffleMode: state.queue.shuffled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: switch (state.queue.repeat) {
          QueueRepeat.off => AudioServiceRepeatMode.none,
          QueueRepeat.all => AudioServiceRepeatMode.all,
          QueueRepeat.one => AudioServiceRepeatMode.one,
        },
        errorMessage: state.error,
      ),
    );
  }

  // ---- Android Auto and other media browsers ---------------------------

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) => _browser.children(parentMediaId);

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) => _browser.play(mediaId);

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) => _browser.search(query);

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) =>
      _browser.playFromSearch(query, extras);

  // ---- Transport controls ------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.pause();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> skipToQueueItem(int index) => _player.skipTo(index);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final wanted = shuffleMode != AudioServiceShuffleMode.none;
    final current = _container.read(playerControllerProvider).queue.shuffled;
    if (wanted != current) await _player.toggleShuffle();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final wanted = switch (repeatMode) {
      AudioServiceRepeatMode.none => QueueRepeat.off,
      AudioServiceRepeatMode.one => QueueRepeat.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => QueueRepeat.all,
    };
    for (var i = 0; i < 3; i++) {
      if (_container.read(playerControllerProvider).queue.repeat == wanted) {
        return;
      }
      await _player.cycleRepeat();
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Headset button: one press toggles, two skip forward, three go back.
  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    if (button != MediaButton.media) {
      await super.click(button);
      return;
    }
    _clicks++;
    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(milliseconds: 400), () {
      final clicks = _clicks;
      _clicks = 0;
      unawaited(switch (clicks) {
        1 => _player.togglePlay(),
        2 => _player.next(),
        _ => _player.previous(),
      });
    });
  }
}
