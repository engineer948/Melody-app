// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_playlists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Smart playlists of the active account, saved on this device.

@ProviderFor(SmartPlaylists)
final smartPlaylistsProvider = SmartPlaylistsProvider._();

/// Smart playlists of the active account, saved on this device.
final class SmartPlaylistsProvider
    extends $NotifierProvider<SmartPlaylists, List<SmartPlaylist>> {
  /// Smart playlists of the active account, saved on this device.
  SmartPlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartPlaylistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartPlaylistsHash();

  @$internal
  @override
  SmartPlaylists create() => SmartPlaylists();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SmartPlaylist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SmartPlaylist>>(value),
    );
  }
}

String _$smartPlaylistsHash() => r'98bac6cd17dcd8cf31cd1aa67a1f4850499ec9cf';

/// Smart playlists of the active account, saved on this device.

abstract class _$SmartPlaylists extends $Notifier<List<SmartPlaylist>> {
  List<SmartPlaylist> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<SmartPlaylist>, List<SmartPlaylist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SmartPlaylist>, List<SmartPlaylist>>,
              List<SmartPlaylist>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The songs a smart playlist picks right now.

@ProviderFor(smartPlaylistTracks)
final smartPlaylistTracksProvider = SmartPlaylistTracksFamily._();

/// The songs a smart playlist picks right now.

final class SmartPlaylistTracksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Track>>,
          List<Track>,
          FutureOr<List<Track>>
        >
    with $FutureModifier<List<Track>>, $FutureProvider<List<Track>> {
  /// The songs a smart playlist picks right now.
  SmartPlaylistTracksProvider._({
    required SmartPlaylistTracksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'smartPlaylistTracksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$smartPlaylistTracksHash();

  @override
  String toString() {
    return r'smartPlaylistTracksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Track>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Track>> create(Ref ref) {
    final argument = this.argument as String;
    return smartPlaylistTracks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SmartPlaylistTracksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$smartPlaylistTracksHash() =>
    r'6b97a5f0b14d8485e2407a1c74529dfa91a03760';

/// The songs a smart playlist picks right now.

final class SmartPlaylistTracksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Track>>, String> {
  SmartPlaylistTracksFamily._()
    : super(
        retry: null,
        name: r'smartPlaylistTracksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The songs a smart playlist picks right now.

  SmartPlaylistTracksProvider call(String id) =>
      SmartPlaylistTracksProvider._(argument: id, from: this);

  @override
  String toString() => r'smartPlaylistTracksProvider';
}
