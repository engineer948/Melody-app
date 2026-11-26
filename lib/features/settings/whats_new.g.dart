// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_new.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notes of this version after an update, in the app's language; `null`
/// on a fresh install, when they were seen, or when there are none.

@ProviderFor(whatsNew)
final whatsNewProvider = WhatsNewFamily._();

/// Notes of this version after an update, in the app's language; `null`
/// on a fresh install, when they were seen, or when there are none.

final class WhatsNewProvider
    extends
        $FunctionalProvider<
          AsyncValue<({String notes, String version})?>,
          ({String notes, String version})?,
          FutureOr<({String notes, String version})?>
        >
    with
        $FutureModifier<({String notes, String version})?>,
        $FutureProvider<({String notes, String version})?> {
  /// Notes of this version after an update, in the app's language; `null`
  /// on a fresh install, when they were seen, or when there are none.
  WhatsNewProvider._({
    required WhatsNewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'whatsNewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$whatsNewHash();

  @override
  String toString() {
    return r'whatsNewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<({String notes, String version})?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({String notes, String version})?> create(Ref ref) {
    final argument = this.argument as String;
    return whatsNew(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WhatsNewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$whatsNewHash() => r'14a3f83a5d8d3904bb846eb415b055a02b80c05d';

/// Notes of this version after an update, in the app's language; `null`
/// on a fresh install, when they were seen, or when there are none.

final class WhatsNewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<({String notes, String version})?>,
          String
        > {
  WhatsNewFamily._()
    : super(
        retry: null,
        name: r'whatsNewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notes of this version after an update, in the app's language; `null`
  /// on a fresh install, when they were seen, or when there are none.

  WhatsNewProvider call(String language) =>
      WhatsNewProvider._(argument: language, from: this);

  @override
  String toString() => r'whatsNewProvider';
}
