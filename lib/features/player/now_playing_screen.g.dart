// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_playing_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the now playing screen shows lyrics instead of the cover.

@ProviderFor(NowPlayingLyrics)
final nowPlayingLyricsProvider = NowPlayingLyricsProvider._();

/// Whether the now playing screen shows lyrics instead of the cover.
final class NowPlayingLyricsProvider
    extends $NotifierProvider<NowPlayingLyrics, bool> {
  /// Whether the now playing screen shows lyrics instead of the cover.
  NowPlayingLyricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowPlayingLyricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowPlayingLyricsHash();

  @$internal
  @override
  NowPlayingLyrics create() => NowPlayingLyrics();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$nowPlayingLyricsHash() => r'b059ccbc2d1561f6fbedf6a39ead3dfa30369694';

/// Whether the now playing screen shows lyrics instead of the cover.

abstract class _$NowPlayingLyrics extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
