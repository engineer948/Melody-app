import 'package:melody/data/sources/jellyfin/jellyfin_dtos.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';

/// Converts Jellyfin DTOs into domain models.
abstract final class JellyfinMapper {
  /// Jellyfin measures time in 100 ns ticks.
  static const ticksPerMicrosecond = 10;

  /// Converts ticks to a [Duration].
  static Duration? duration(int? ticks) => ticks == null || ticks <= 0
      ? null
      : Duration(microseconds: ticks ~/ ticksPerMicrosecond);

  static Artwork? _primary(BaseItemDto dto) {
    final id = dto.id;
    final tag = dto.imageTags?['Primary'];
    if (id == null || tag == null) return null;
    return Artwork(
      itemId: id,
      tag: tag,
      blurHash: dto.imageBlurHashes?['Primary']?[tag],
    );
  }

  static List<NamedRef> _refs(List<NameIdDto>? items) => [
    for (final item in items ?? const <NameIdDto>[])
      if (item.id != null && item.name != null)
        NamedRef(id: item.id!, name: item.name!),
  ];

  /// Maps an `Audio` item.
  static Track track(BaseItemDto dto) {
    final own = _primary(dto);
    final albumId = dto.albumId;
    final albumTag = dto.albumPrimaryImageTag;
    final albumArt = albumId != null && albumTag != null
        ? Artwork(
            itemId: albumId,
            tag: albumTag,
            blurHash: dto.imageBlurHashes?['Primary']?[albumTag],
          )
        : null;
    return Track(
      id: dto.id ?? '',
      title: dto.name ?? '',
      artists: _refs(dto.artistItems),
      albumId: albumId,
      albumTitle: dto.album,
      albumArtist: dto.albumArtist,
      duration: duration(dto.runTimeTicks),
      trackNumber: dto.indexNumber,
      discNumber: dto.parentIndexNumber,
      year: dto.productionYear,
      artwork: own ?? albumArt,
      container: dto.container,
      isFavorite: dto.userData?.isFavorite ?? false,
      playCount: dto.userData?.playCount ?? 0,
      genres: dto.genres ?? const [],
      trackGainDb: dto.normalizationGain,
      playlistItemId: dto.playlistItemId,
    );
  }

  /// Maps a `MusicAlbum` item.
  static Album album(BaseItemDto dto) => Album(
    id: dto.id ?? '',
    title: dto.name ?? '',
    artists: _refs(dto.albumArtists),
    artistName: dto.albumArtist,
    year: dto.productionYear,
    trackCount: dto.childCount,
    duration: duration(dto.runTimeTicks),
    artwork: _primary(dto),
    dateAdded: dto.dateCreated,
    genres: dto.genres ?? const [],
    isFavorite: dto.userData?.isFavorite ?? false,
    gainDb: dto.normalizationGain,
  );

  /// Maps a `MusicArtist` item.
  static Artist artist(BaseItemDto dto) => Artist(
    id: dto.id ?? '',
    name: dto.name ?? '',
    artwork: _primary(dto),
    overview: _plainText(dto.overview),
    isFavorite: dto.userData?.isFavorite ?? false,
  );

  /// Maps a `Playlist` item.
  static Playlist playlist(BaseItemDto dto) => Playlist(
    id: dto.id ?? '',
    name: dto.name ?? '',
    trackCount: dto.childCount,
    duration: duration(dto.runTimeTicks),
    artwork: _primary(dto),
  );

  /// Maps a `MusicGenre` item.
  static Genre genre(BaseItemDto dto) =>
      Genre(id: dto.id ?? '', name: dto.name ?? '', artwork: _primary(dto));

  /// Maps a user view to a library.
  static MusicLibrary library(BaseItemDto dto) =>
      MusicLibrary(id: dto.id ?? '', name: dto.name ?? '');

  /// Maps the items of a page, skipping entries without an id.
  static List<T> items<T>(ItemsResultDto page, T Function(BaseItemDto) map) => [
    for (final item in page.items ?? const <BaseItemDto>[])
      if (item.id != null) map(item),
  ];

  static final _tag = RegExp('<[^>]+>');

  static String? _plainText(String? html) {
    if (html == null) return null;
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(_tag, '')
        .trim();
    return text.isEmpty ? null : text;
  }
}
