// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_sections.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bytes currently used by the stream cache.

@ProviderFor(streamCacheSize)
final streamCacheSizeProvider = StreamCacheSizeProvider._();

/// Bytes currently used by the stream cache.

final class StreamCacheSizeProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Bytes currently used by the stream cache.
  StreamCacheSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streamCacheSizeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streamCacheSizeHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return streamCacheSize(ref);
  }
}

String _$streamCacheSizeHash() => r'ded22607106869bb2a8ee76db8c2e61e48c40551';
