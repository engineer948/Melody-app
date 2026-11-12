// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_palette.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Palette of [artwork], or `null` while loading, offline or without art.

@ProviderFor(artworkPalette)
final artworkPaletteProvider = ArtworkPaletteFamily._();

/// Palette of [artwork], or `null` while loading, offline or without art.

final class ArtworkPaletteProvider
    extends
        $FunctionalProvider<
          AsyncValue<ArtworkPalette?>,
          ArtworkPalette?,
          FutureOr<ArtworkPalette?>
        >
    with $FutureModifier<ArtworkPalette?>, $FutureProvider<ArtworkPalette?> {
  /// Palette of [artwork], or `null` while loading, offline or without art.
  ArtworkPaletteProvider._({
    required ArtworkPaletteFamily super.from,
    required Artwork? super.argument,
  }) : super(
         retry: null,
         name: r'artworkPaletteProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$artworkPaletteHash();

  @override
  String toString() {
    return r'artworkPaletteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ArtworkPalette?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ArtworkPalette?> create(Ref ref) {
    final argument = this.argument as Artwork?;
    return artworkPalette(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArtworkPaletteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$artworkPaletteHash() => r'c7a99f98b525123f73bf32b3b5d8ad4acaf35e79';

/// Palette of [artwork], or `null` while loading, offline or without art.

final class ArtworkPaletteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ArtworkPalette?>, Artwork?> {
  ArtworkPaletteFamily._()
    : super(
        retry: null,
        name: r'artworkPaletteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Palette of [artwork], or `null` while loading, offline or without art.

  ArtworkPaletteProvider call(Artwork? artwork) =>
      ArtworkPaletteProvider._(argument: artwork, from: this);

  @override
  String toString() => r'artworkPaletteProvider';
}
