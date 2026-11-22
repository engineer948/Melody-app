// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_extras.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Letters received or kept, newest first.

@ProviderFor(LetterInbox)
final letterInboxProvider = LetterInboxProvider._();

/// Letters received or kept, newest first.
final class LetterInboxProvider
    extends $NotifierProvider<LetterInbox, List<InboxLetter>> {
  /// Letters received or kept, newest first.
  LetterInboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'letterInboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$letterInboxHash();

  @$internal
  @override
  LetterInbox create() => LetterInbox();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InboxLetter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InboxLetter>>(value),
    );
  }
}

String _$letterInboxHash() => r'c0376e3252817b593b94d7b427b7e461c8a44449';

/// Letters received or kept, newest first.

abstract class _$LetterInbox extends $Notifier<List<InboxLetter>> {
  List<InboxLetter> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<InboxLetter>, List<InboxLetter>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<InboxLetter>, List<InboxLetter>>,
              List<InboxLetter>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Kept letters whose day has come and that were not opened yet.

@ProviderFor(dueLetters)
final dueLettersProvider = DueLettersProvider._();

/// Kept letters whose day has come and that were not opened yet.

final class DueLettersProvider
    extends
        $FunctionalProvider<
          List<InboxLetter>,
          List<InboxLetter>,
          List<InboxLetter>
        >
    with $Provider<List<InboxLetter>> {
  /// Kept letters whose day has come and that were not opened yet.
  DueLettersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dueLettersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dueLettersHash();

  @$internal
  @override
  $ProviderElement<List<InboxLetter>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<InboxLetter> create(Ref ref) {
    return dueLetters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InboxLetter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InboxLetter>>(value),
    );
  }
}

String _$dueLettersHash() => r'14806a837e8265410e31b9bf8bcf2c8c030176ca';

/// The phone's NFC.

@ProviderFor(nfcBridge)
final nfcBridgeProvider = NfcBridgeProvider._();

/// The phone's NFC.

final class NfcBridgeProvider
    extends $FunctionalProvider<NfcBridge, NfcBridge, NfcBridge>
    with $Provider<NfcBridge> {
  /// The phone's NFC.
  NfcBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nfcBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nfcBridgeHash();

  @$internal
  @override
  $ProviderElement<NfcBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NfcBridge create(Ref ref) {
    return nfcBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NfcBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NfcBridge>(value),
    );
  }
}

String _$nfcBridgeHash() => r'5ca96f4001b514cf28a7ca3268db54458c1ad6ec';
