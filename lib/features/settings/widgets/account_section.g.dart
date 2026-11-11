// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Music libraries of the active account; empty when they cannot be loaded.

@ProviderFor(musicLibraries)
final musicLibrariesProvider = MusicLibrariesProvider._();

/// Music libraries of the active account; empty when they cannot be loaded.

final class MusicLibrariesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MusicLibrary>>,
          List<MusicLibrary>,
          FutureOr<List<MusicLibrary>>
        >
    with
        $FutureModifier<List<MusicLibrary>>,
        $FutureProvider<List<MusicLibrary>> {
  /// Music libraries of the active account; empty when they cannot be loaded.
  MusicLibrariesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicLibrariesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicLibrariesHash();

  @$internal
  @override
  $FutureProviderElement<List<MusicLibrary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MusicLibrary>> create(Ref ref) {
    return musicLibraries(ref);
  }
}

String _$musicLibrariesHash() => r'1aadab7378bb8ffa86e3ad02f271a28ad5ade6f5';
