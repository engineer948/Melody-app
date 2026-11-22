// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_auto_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction, which it returns. Songs measured before
/// are not measured again. Fails (and is tried again next time) when the
/// start cannot be read: offline, or no MP3 from the server.

@ProviderFor(lyricsAutoSync)
final lyricsAutoSyncProvider = LyricsAutoSyncFamily._();

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction, which it returns. Songs measured before
/// are not measured again. Fails (and is tried again next time) when the
/// start cannot be read: offline, or no MP3 from the server.

final class LyricsAutoSyncProvider
    extends
        $FunctionalProvider<AsyncValue<Duration>, Duration, FutureOr<Duration>>
    with $FutureModifier<Duration>, $FutureProvider<Duration> {
  /// Measures once where the music of [track] really starts and keeps the
  /// matching lyrics correction, which it returns. Songs measured before
  /// are not measured again. Fails (and is tried again next time) when the
  /// start cannot be read: offline, or no MP3 from the server.
  LyricsAutoSyncProvider._({
    required LyricsAutoSyncFamily super.from,
    required Track super.argument,
  }) : super(
         retry: null,
         name: r'lyricsAutoSyncProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lyricsAutoSyncHash();

  @override
  String toString() {
    return r'lyricsAutoSyncProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Duration> create(Ref ref) {
    final argument = this.argument as Track;
    return lyricsAutoSync(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LyricsAutoSyncProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lyricsAutoSyncHash() => r'31af3002f834f59b8b487389e7f5a02642f5883b';

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction, which it returns. Songs measured before
/// are not measured again. Fails (and is tried again next time) when the
/// start cannot be read: offline, or no MP3 from the server.

final class LyricsAutoSyncFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Duration>, Track> {
  LyricsAutoSyncFamily._()
    : super(
        retry: null,
        name: r'lyricsAutoSyncProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Measures once where the music of [track] really starts and keeps the
  /// matching lyrics correction, which it returns. Songs measured before
  /// are not measured again. Fails (and is tried again next time) when the
  /// start cannot be read: offline, or no MP3 from the server.

  LyricsAutoSyncProvider call(Track track) =>
      LyricsAutoSyncProvider._(argument: track, from: this);

  @override
  String toString() => r'lyricsAutoSyncProvider';
}
