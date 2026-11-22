// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_cards.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The birth year the user gave, if any.

@ProviderFor(BirthYear)
final birthYearProvider = BirthYearProvider._();

/// The birth year the user gave, if any.
final class BirthYearProvider extends $NotifierProvider<BirthYear, int?> {
  /// The birth year the user gave, if any.
  BirthYearProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'birthYearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$birthYearHash();

  @$internal
  @override
  BirthYear create() => BirthYear();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$birthYearHash() => r'86303f2e39fdacf6c343184d075c205472212f3a';

/// The birth year the user gave, if any.

abstract class _$BirthYear extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
