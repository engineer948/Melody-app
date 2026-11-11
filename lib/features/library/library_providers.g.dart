// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Endless list of albums matching [query] (its paging fields set the page
/// size).

@ProviderFor(AlbumList)
final albumListProvider = AlbumListFamily._();

/// Endless list of albums matching [query] (its paging fields set the page
/// size).
final class AlbumListProvider
    extends $NotifierProvider<AlbumList, PagedState<Album>> {
  /// Endless list of albums matching [query] (its paging fields set the page
  /// size).
  AlbumListProvider._({
    required AlbumListFamily super.from,
    required AlbumQuery super.argument,
  }) : super(
         retry: null,
         name: r'albumListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$albumListHash();

  @override
  String toString() {
    return r'albumListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AlbumList create() => AlbumList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PagedState<Album> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PagedState<Album>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AlbumListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$albumListHash() => r'f9f34c36358ec4c7904a609a0532c82fefdb6702';

/// Endless list of albums matching [query] (its paging fields set the page
/// size).

final class AlbumListFamily extends $Family
    with
        $ClassFamilyOverride<
          AlbumList,
          PagedState<Album>,
          PagedState<Album>,
          PagedState<Album>,
          AlbumQuery
        > {
  AlbumListFamily._()
    : super(
        retry: null,
        name: r'albumListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Endless list of albums matching [query] (its paging fields set the page
  /// size).

  AlbumListProvider call(AlbumQuery query) =>
      AlbumListProvider._(argument: query, from: this);

  @override
  String toString() => r'albumListProvider';
}

/// Endless list of albums matching [query] (its paging fields set the page
/// size).

abstract class _$AlbumList extends $Notifier<PagedState<Album>> {
  late final _$args = ref.$arg as AlbumQuery;
  AlbumQuery get query => _$args;

  PagedState<Album> build(AlbumQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PagedState<Album>, PagedState<Album>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PagedState<Album>, PagedState<Album>>,
              PagedState<Album>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Endless list of album artists.

@ProviderFor(ArtistList)
final artistListProvider = ArtistListProvider._();

/// Endless list of album artists.
final class ArtistListProvider
    extends $NotifierProvider<ArtistList, PagedState<Artist>> {
  /// Endless list of album artists.
  ArtistListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'artistListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$artistListHash();

  @$internal
  @override
  ArtistList create() => ArtistList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PagedState<Artist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PagedState<Artist>>(value),
    );
  }
}

String _$artistListHash() => r'0fca752ef375da68dec5338b33fcf6a877e5aac7';

/// Endless list of album artists.

abstract class _$ArtistList extends $Notifier<PagedState<Artist>> {
  PagedState<Artist> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PagedState<Artist>, PagedState<Artist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PagedState<Artist>, PagedState<Artist>>,
              PagedState<Artist>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Endless list of tracks matching [query].

@ProviderFor(TrackList)
final trackListProvider = TrackListFamily._();

/// Endless list of tracks matching [query].
final class TrackListProvider
    extends $NotifierProvider<TrackList, PagedState<Track>> {
  /// Endless list of tracks matching [query].
  TrackListProvider._({
    required TrackListFamily super.from,
    required TrackQuery super.argument,
  }) : super(
         retry: null,
         name: r'trackListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trackListHash();

  @override
  String toString() {
    return r'trackListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TrackList create() => TrackList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PagedState<Track> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PagedState<Track>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrackListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trackListHash() => r'eb51bc06232e050b610c523e5aa12a9263c62455';

/// Endless list of tracks matching [query].

final class TrackListFamily extends $Family
    with
        $ClassFamilyOverride<
          TrackList,
          PagedState<Track>,
          PagedState<Track>,
          PagedState<Track>,
          TrackQuery
        > {
  TrackListFamily._()
    : super(
        retry: null,
        name: r'trackListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Endless list of tracks matching [query].

  TrackListProvider call(TrackQuery query) =>
      TrackListProvider._(argument: query, from: this);

  @override
  String toString() => r'trackListProvider';
}

/// Endless list of tracks matching [query].

abstract class _$TrackList extends $Notifier<PagedState<Track>> {
  late final _$args = ref.$arg as TrackQuery;
  TrackQuery get query => _$args;

  PagedState<Track> build(TrackQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PagedState<Track>, PagedState<Track>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PagedState<Track>, PagedState<Track>>,
              PagedState<Track>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// All playlists of the active account.

@ProviderFor(playlists)
final playlistsProvider = PlaylistsProvider._();

/// All playlists of the active account.

final class PlaylistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Loaded<List<Playlist>>>,
          Loaded<List<Playlist>>,
          Stream<Loaded<List<Playlist>>>
        >
    with
        $FutureModifier<Loaded<List<Playlist>>>,
        $StreamProvider<Loaded<List<Playlist>>> {
  /// All playlists of the active account.
  PlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistsHash();

  @$internal
  @override
  $StreamProviderElement<Loaded<List<Playlist>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Loaded<List<Playlist>>> create(Ref ref) {
    return playlists(ref);
  }
}

String _$playlistsHash() => r'd4fa50a1461561827d68e2234563e14781873567';

/// All genres of the active account.

@ProviderFor(genres)
final genresProvider = GenresProvider._();

/// All genres of the active account.

final class GenresProvider
    extends
        $FunctionalProvider<
          AsyncValue<Loaded<List<Genre>>>,
          Loaded<List<Genre>>,
          Stream<Loaded<List<Genre>>>
        >
    with
        $FutureModifier<Loaded<List<Genre>>>,
        $StreamProvider<Loaded<List<Genre>>> {
  /// All genres of the active account.
  GenresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'genresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$genresHash();

  @$internal
  @override
  $StreamProviderElement<Loaded<List<Genre>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Loaded<List<Genre>>> create(Ref ref) {
    return genres(ref);
  }
}

String _$genresHash() => r'eab4d5710b7fc98a7943ffa03444fd92d12d028d';

/// One album with its tracks.

@ProviderFor(albumDetail)
final albumDetailProvider = AlbumDetailFamily._();

/// One album with its tracks.

final class AlbumDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Loaded<AlbumDetail>>,
          Loaded<AlbumDetail>,
          Stream<Loaded<AlbumDetail>>
        >
    with
        $FutureModifier<Loaded<AlbumDetail>>,
        $StreamProvider<Loaded<AlbumDetail>> {
  /// One album with its tracks.
  AlbumDetailProvider._({
    required AlbumDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'albumDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$albumDetailHash();

  @override
  String toString() {
    return r'albumDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Loaded<AlbumDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Loaded<AlbumDetail>> create(Ref ref) {
    final argument = this.argument as String;
    return albumDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AlbumDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$albumDetailHash() => r'd0de95c1e0f96f83d30131924fd25433dabc6c1f';

/// One album with its tracks.

final class AlbumDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Loaded<AlbumDetail>>, String> {
  AlbumDetailFamily._()
    : super(
        retry: null,
        name: r'albumDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One album with its tracks.

  AlbumDetailProvider call(String id) =>
      AlbumDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'albumDetailProvider';
}

/// One artist with albums and popular tracks.

@ProviderFor(artistDetail)
final artistDetailProvider = ArtistDetailFamily._();

/// One artist with albums and popular tracks.

final class ArtistDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Loaded<ArtistDetail>>,
          Loaded<ArtistDetail>,
          Stream<Loaded<ArtistDetail>>
        >
    with
        $FutureModifier<Loaded<ArtistDetail>>,
        $StreamProvider<Loaded<ArtistDetail>> {
  /// One artist with albums and popular tracks.
  ArtistDetailProvider._({
    required ArtistDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'artistDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$artistDetailHash();

  @override
  String toString() {
    return r'artistDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Loaded<ArtistDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Loaded<ArtistDetail>> create(Ref ref) {
    final argument = this.argument as String;
    return artistDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArtistDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$artistDetailHash() => r'6d96b1623d527a806f4a98563b0366a2794a80ad';

/// One artist with albums and popular tracks.

final class ArtistDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Loaded<ArtistDetail>>, String> {
  ArtistDetailFamily._()
    : super(
        retry: null,
        name: r'artistDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One artist with albums and popular tracks.

  ArtistDetailProvider call(String id) =>
      ArtistDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'artistDetailProvider';
}
