// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_colors.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wallpaper based primary color (Material You), or `null` when the platform
/// does not provide dynamic colors.

@ProviderFor(systemSeedColor)
final systemSeedColorProvider = SystemSeedColorProvider._();

/// Wallpaper based primary color (Material You), or `null` when the platform
/// does not provide dynamic colors.

final class SystemSeedColorProvider
    extends $FunctionalProvider<AsyncValue<Color?>, Color?, FutureOr<Color?>>
    with $FutureModifier<Color?>, $FutureProvider<Color?> {
  /// Wallpaper based primary color (Material You), or `null` when the platform
  /// does not provide dynamic colors.
  SystemSeedColorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemSeedColorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemSeedColorHash();

  @$internal
  @override
  $FutureProviderElement<Color?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Color?> create(Ref ref) {
    return systemSeedColor(ref);
  }
}

String _$systemSeedColorHash() => r'aef9348e7d7935b747d5473ac9c5a08d99e04598';
