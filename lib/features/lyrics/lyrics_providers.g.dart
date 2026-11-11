// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [LyricsSettings].

@ProviderFor(LyricsSettingsController)
final lyricsSettingsControllerProvider = LyricsSettingsControllerProvider._();

/// Holds and persists [LyricsSettings].
final class LyricsSettingsControllerProvider
    extends $NotifierProvider<LyricsSettingsController, LyricsSettings> {
  /// Holds and persists [LyricsSettings].
  LyricsSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsSettingsControllerHash();

  @$internal
  @override
  LyricsSettingsController create() => LyricsSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LyricsSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LyricsSettings>(value),
    );
  }
}

String _$lyricsSettingsControllerHash() =>
    r'a47a6e22643139fd89a9e6b9c2b030c733f162c0';

/// Holds and persists [LyricsSettings].

abstract class _$LyricsSettingsController extends $Notifier<LyricsSettings> {
  LyricsSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LyricsSettings, LyricsSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LyricsSettings, LyricsSettings>,
              LyricsSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// LRCLIB client; overridden in tests.

@ProviderFor(lrclib)
final lrclibProvider = LrclibProvider._();

/// LRCLIB client; overridden in tests.

final class LrclibProvider
    extends $FunctionalProvider<LrclibClient, LrclibClient, LrclibClient>
    with $Provider<LrclibClient> {
  /// LRCLIB client; overridden in tests.
  LrclibProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lrclibProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lrclibHash();

  @$internal
  @override
  $ProviderElement<LrclibClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LrclibClient create(Ref ref) {
    return lrclib(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LrclibClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LrclibClient>(value),
    );
  }
}

String _$lrclibHash() => r'2a34b7641fc03ffd217817b6a5c05b4be106960a';

/// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
/// `null` means there are none.

@ProviderFor(trackLyrics)
final trackLyricsProvider = TrackLyricsFamily._();

/// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
/// `null` means there are none.

final class TrackLyricsProvider
    extends $FunctionalProvider<AsyncValue<Lyrics?>, Lyrics?, FutureOr<Lyrics?>>
    with $FutureModifier<Lyrics?>, $FutureProvider<Lyrics?> {
  /// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
  /// `null` means there are none.
  TrackLyricsProvider._({
    required TrackLyricsFamily super.from,
    required Track super.argument,
  }) : super(
         retry: null,
         name: r'trackLyricsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trackLyricsHash();

  @override
  String toString() {
    return r'trackLyricsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Lyrics?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Lyrics?> create(Ref ref) {
    final argument = this.argument as Track;
    return trackLyrics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackLyricsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trackLyricsHash() => r'4d742eb06b24dd0b0b47a776c729a6dedeab7d8a';

/// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
/// `null` means there are none.

final class TrackLyricsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Lyrics?>, Track> {
  TrackLyricsFamily._()
    : super(
        retry: null,
        name: r'trackLyricsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
  /// `null` means there are none.

  TrackLyricsProvider call(Track track) =>
      TrackLyricsProvider._(argument: track, from: this);

  @override
  String toString() => r'trackLyricsProvider';
}
