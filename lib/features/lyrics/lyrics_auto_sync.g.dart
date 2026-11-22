// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_auto_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction. Does nothing when the song was corrected by
/// hand, was measured before, or auto sync is off; a failure (offline, no
/// MP3 from the server) is tried again next time.

@ProviderFor(lyricsAutoSync)
final lyricsAutoSyncProvider = LyricsAutoSyncFamily._();

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction. Does nothing when the song was corrected by
/// hand, was measured before, or auto sync is off; a failure (offline, no
/// MP3 from the server) is tried again next time.

final class LyricsAutoSyncProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Measures once where the music of [track] really starts and keeps the
  /// matching lyrics correction. Does nothing when the song was corrected by
  /// hand, was measured before, or auto sync is off; a failure (offline, no
  /// MP3 from the server) is tried again next time.
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
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
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

String _$lyricsAutoSyncHash() => r'a8f0754f33d084da81c07dd3256a7d260b0f9d58';

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction. Does nothing when the song was corrected by
/// hand, was measured before, or auto sync is off; a failure (offline, no
/// MP3 from the server) is tried again next time.

final class LyricsAutoSyncFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, Track> {
  LyricsAutoSyncFamily._()
    : super(
        retry: null,
        name: r'lyricsAutoSyncProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Measures once where the music of [track] really starts and keeps the
  /// matching lyrics correction. Does nothing when the song was corrected by
  /// hand, was measured before, or auto sync is off; a failure (offline, no
  /// MP3 from the server) is tried again next time.

  LyricsAutoSyncProvider call(Track track) =>
      LyricsAutoSyncProvider._(argument: track, from: this);

  @override
  String toString() => r'lyricsAutoSyncProvider';
}
