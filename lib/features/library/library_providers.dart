import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/paged_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_providers.g.dart';

/// Endless list of albums matching [query] (its paging fields set the page
/// size).
@riverpod
class AlbumList extends _$AlbumList with PagedLoader<Album> {
  @override
  PagedState<Album> build(AlbumQuery query) => start();

  @override
  int get pageSize => query.limit;

  @override
  Stream<Loaded<List<Album>>> firstPage(LibraryRepository repository) =>
      repository.albums(query.page(0, pageSize));

  @override
  Future<Result<List<Album>>> nextPage(
    LibraryRepository repository,
    int offset,
  ) => repository.moreAlbums(query.page(offset, pageSize));
}

/// Endless list of album artists.
@riverpod
class ArtistList extends _$ArtistList with PagedLoader<Artist> {
  @override
  PagedState<Artist> build() => start();

  @override
  int get pageSize => 100;

  @override
  Stream<Loaded<List<Artist>>> firstPage(LibraryRepository repository) =>
      repository.artists(limit: pageSize);

  @override
  Future<Result<List<Artist>>> nextPage(
    LibraryRepository repository,
    int offset,
  ) => repository.moreArtists(offset, limit: pageSize);
}

/// Endless list of tracks matching [query].
@riverpod
class TrackList extends _$TrackList with PagedLoader<Track> {
  @override
  PagedState<Track> build(TrackQuery query) => start();

  @override
  int get pageSize => query.limit;

  @override
  Stream<Loaded<List<Track>>> firstPage(LibraryRepository repository) =>
      repository.tracks(query.page(0, pageSize));

  @override
  Future<Result<List<Track>>> nextPage(
    LibraryRepository repository,
    int offset,
  ) => repository.moreTracks(query.page(offset, pageSize));
}

Stream<T> _signedOut<T>() => Stream.error(const UnauthorizedFailure());

/// All playlists of the active account.
@riverpod
Stream<Loaded<List<Playlist>>> playlists(Ref ref) =>
    ref.watch(libraryRepositoryProvider)?.playlists() ?? _signedOut();

/// All genres of the active account.
@riverpod
Stream<Loaded<List<Genre>>> genres(Ref ref) =>
    ref.watch(libraryRepositoryProvider)?.genres() ?? _signedOut();

/// One album with its tracks.
@riverpod
Stream<Loaded<AlbumDetail>> albumDetail(Ref ref, String id) =>
    ref.watch(libraryRepositoryProvider)?.album(id) ?? _signedOut();

/// One artist with albums and popular tracks.
@riverpod
Stream<Loaded<ArtistDetail>> artistDetail(Ref ref, String id) =>
    ref.watch(libraryRepositoryProvider)?.artist(id) ?? _signedOut();
