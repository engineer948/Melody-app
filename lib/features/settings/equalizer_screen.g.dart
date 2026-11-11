// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equalizer_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bands of the platform equaliser.

@ProviderFor(equalizerBands)
final equalizerBandsProvider = EqualizerBandsProvider._();

/// Bands of the platform equaliser.

final class EqualizerBandsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EqualizerBand>>,
          List<EqualizerBand>,
          FutureOr<List<EqualizerBand>>
        >
    with
        $FutureModifier<List<EqualizerBand>>,
        $FutureProvider<List<EqualizerBand>> {
  /// Bands of the platform equaliser.
  EqualizerBandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'equalizerBandsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$equalizerBandsHash();

  @$internal
  @override
  $FutureProviderElement<List<EqualizerBand>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EqualizerBand>> create(Ref ref) {
    return equalizerBands(ref);
  }
}

String _$equalizerBandsHash() => r'f9312363860a7de279d011cad883fac3694b8edd';
