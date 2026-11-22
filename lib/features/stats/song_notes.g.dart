// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_notes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The song memories of every account.

@ProviderFor(songNotesStore)
final songNotesStoreProvider = SongNotesStoreProvider._();

/// The song memories of every account.

final class SongNotesStoreProvider
    extends $FunctionalProvider<SongNotesStore, SongNotesStore, SongNotesStore>
    with $Provider<SongNotesStore> {
  /// The song memories of every account.
  SongNotesStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songNotesStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songNotesStoreHash();

  @$internal
  @override
  $ProviderElement<SongNotesStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SongNotesStore create(Ref ref) {
    return songNotesStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SongNotesStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SongNotesStore>(value),
    );
  }
}

String _$songNotesStoreHash() => r'69ffb36e7d1eba0a30d87f910efb3caa8f0a088d';

/// Folder of the photos added to memories.

@ProviderFor(memoriesDir)
final memoriesDirProvider = MemoriesDirProvider._();

/// Folder of the photos added to memories.

final class MemoriesDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// Folder of the photos added to memories.
  MemoriesDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoriesDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoriesDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return memoriesDir(ref);
  }
}

String _$memoriesDirHash() => r'2ce65dc63225496ae38f2deb1f2d55e7c5eeb544';

/// Memories of the active account, newest first.

@ProviderFor(SongNotes)
final songNotesProvider = SongNotesProvider._();

/// Memories of the active account, newest first.
final class SongNotesProvider
    extends $AsyncNotifierProvider<SongNotes, List<SongNote>> {
  /// Memories of the active account, newest first.
  SongNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songNotesHash();

  @$internal
  @override
  SongNotes create() => SongNotes();
}

String _$songNotesHash() => r'5be0adf62f3b533b7b57c64eeaee0c82ae7670ea';

/// Memories of the active account, newest first.

abstract class _$SongNotes extends $AsyncNotifier<List<SongNote>> {
  FutureOr<List<SongNote>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SongNote>>, List<SongNote>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SongNote>>, List<SongNote>>,
              AsyncValue<List<SongNote>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The memory of [trackId], if any.

@ProviderFor(songNote)
final songNoteProvider = SongNoteFamily._();

/// The memory of [trackId], if any.

final class SongNoteProvider
    extends $FunctionalProvider<SongNote?, SongNote?, SongNote?>
    with $Provider<SongNote?> {
  /// The memory of [trackId], if any.
  SongNoteProvider._({
    required SongNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'songNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$songNoteHash();

  @override
  String toString() {
    return r'songNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SongNote?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SongNote? create(Ref ref) {
    final argument = this.argument as String;
    return songNote(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SongNote? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SongNote?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SongNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$songNoteHash() => r'bb90b108269f811df102075585045e3e44244c52';

/// The memory of [trackId], if any.

final class SongNoteFamily extends $Family
    with $FunctionalFamilyOverride<SongNote?, String> {
  SongNoteFamily._()
    : super(
        retry: null,
        name: r'songNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The memory of [trackId], if any.

  SongNoteProvider call(String trackId) =>
      SongNoteProvider._(argument: trackId, from: this);

  @override
  String toString() => r'songNoteProvider';
}

/// How often [trackId] was played today.

@ProviderFor(playsToday)
final playsTodayProvider = PlaysTodayFamily._();

/// How often [trackId] was played today.

final class PlaysTodayProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How often [trackId] was played today.
  PlaysTodayProvider._({
    required PlaysTodayFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playsTodayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playsTodayHash();

  @override
  String toString() {
    return r'playsTodayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return playsToday(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaysTodayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playsTodayHash() => r'4747f9ad52738a49be2519c196b86be2b810e8c9';

/// How often [trackId] was played today.

final class PlaysTodayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  PlaysTodayFamily._()
    : super(
        retry: null,
        name: r'playsTodayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How often [trackId] was played today.

  PlaysTodayProvider call(String trackId) =>
      PlaysTodayProvider._(argument: trackId, from: this);

  @override
  String toString() => r'playsTodayProvider';
}
