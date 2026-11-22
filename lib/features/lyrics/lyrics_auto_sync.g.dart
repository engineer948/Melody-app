// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_auto_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Measures once where the singing of [track] starts and keeps the lyrics
/// correction that puts the first sung line there, which it returns. When
/// the singing cannot be found (or the phone cannot decode audio), the
/// silence at the start is used instead. Songs measured before are not
/// measured again. Fails (and is tried again next time) when the start
/// cannot be read: offline, or no MP3 from the server.

@ProviderFor(lyricsAutoSync)
final lyricsAutoSyncProvider = LyricsAutoSyncFamily._();

/// Measures once where the singing of [track] starts and keeps the lyrics
/// correction that puts the first sung line there, which it returns. When
/// the singing cannot be found (or the phone cannot decode audio), the
/// silence at the start is used instead. Songs measured before are not
/// measured again. Fails (and is tried again next time) when the start
/// cannot be read: offline, or no MP3 from the server.

final class LyricsAutoSyncProvider
    extends
        $FunctionalProvider<AsyncValue<Duration>, Duration, FutureOr<Duration>>
    with $FutureModifier<Duration>, $FutureProvider<Duration> {
  /// Measures once where the singing of [track] starts and keeps the lyrics
  /// correction that puts the first sung line there, which it returns. When
  /// the singing cannot be found (or the phone cannot decode audio), the
  /// silence at the start is used instead. Songs measured before are not
  /// measured again. Fails (and is tried again next time) when the start
  /// cannot be read: offline, or no MP3 from the server.
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

String _$lyricsAutoSyncHash() => r'3f293c5d6d479c5bc81442f39c2ce6c76efbb03b';

/// Measures once where the singing of [track] starts and keeps the lyrics
/// correction that puts the first sung line there, which it returns. When
/// the singing cannot be found (or the phone cannot decode audio), the
/// silence at the start is used instead. Songs measured before are not
/// measured again. Fails (and is tried again next time) when the start
/// cannot be read: offline, or no MP3 from the server.

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

  /// Measures once where the singing of [track] starts and keeps the lyrics
  /// correction that puts the first sung line there, which it returns. When
  /// the singing cannot be found (or the phone cannot decode audio), the
  /// silence at the start is used instead. Songs measured before are not
  /// measured again. Fails (and is tried again next time) when the start
  /// cannot be read: offline, or no MP3 from the server.

  LyricsAutoSyncProvider call(Track track) =>
      LyricsAutoSyncProvider._(argument: track, from: this);

  @override
  String toString() => r'lyricsAutoSyncProvider';
}
