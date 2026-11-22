// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_analyzer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The voice analyzer in use.

@ProviderFor(voiceAnalyzer)
final voiceAnalyzerProvider = VoiceAnalyzerProvider._();

/// The voice analyzer in use.

final class VoiceAnalyzerProvider
    extends $FunctionalProvider<VoiceAnalyzer, VoiceAnalyzer, VoiceAnalyzer>
    with $Provider<VoiceAnalyzer> {
  /// The voice analyzer in use.
  VoiceAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceAnalyzerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceAnalyzerHash();

  @$internal
  @override
  $ProviderElement<VoiceAnalyzer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceAnalyzer create(Ref ref) {
    return voiceAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceAnalyzer>(value),
    );
  }
}

String _$voiceAnalyzerHash() => r'3a5d5ca6a0c4aba35dc167d8fc92377afc71dc8e';
