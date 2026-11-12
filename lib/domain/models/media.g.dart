// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Artwork _$ArtworkFromJson(Map<String, dynamic> json) => _Artwork(
  itemId: json['itemId'] as String,
  tag: json['tag'] as String?,
  blurHash: json['blurHash'] as String?,
);

Map<String, dynamic> _$ArtworkToJson(_Artwork instance) => <String, dynamic>{
  'itemId': instance.itemId,
  'tag': instance.tag,
  'blurHash': instance.blurHash,
};

_NamedRef _$NamedRefFromJson(Map<String, dynamic> json) =>
    _NamedRef(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$NamedRefToJson(_NamedRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
  id: json['id'] as String,
  title: json['title'] as String,
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => NamedRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NamedRef>[],
  albumId: json['albumId'] as String?,
  albumTitle: json['albumTitle'] as String?,
  albumArtist: json['albumArtist'] as String?,
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  trackNumber: (json['trackNumber'] as num?)?.toInt(),
  discNumber: (json['discNumber'] as num?)?.toInt(),
  year: (json['year'] as num?)?.toInt(),
  artwork: json['artwork'] == null
      ? null
      : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
  container: json['container'] as String?,
  isFavorite: json['isFavorite'] as bool? ?? false,
  playCount: (json['playCount'] as num?)?.toInt() ?? 0,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  trackGainDb: (json['trackGainDb'] as num?)?.toDouble(),
  albumGainDb: (json['albumGainDb'] as num?)?.toDouble(),
  playlistItemId: json['playlistItemId'] as String?,
);

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artists': instance.artists.map((e) => e.toJson()).toList(),
  'albumId': instance.albumId,
  'albumTitle': instance.albumTitle,
  'albumArtist': instance.albumArtist,
  'duration': instance.duration?.inMicroseconds,
  'trackNumber': instance.trackNumber,
  'discNumber': instance.discNumber,
  'year': instance.year,
  'artwork': instance.artwork?.toJson(),
  'container': instance.container,
  'isFavorite': instance.isFavorite,
  'playCount': instance.playCount,
  'genres': instance.genres,
  'trackGainDb': instance.trackGainDb,
  'albumGainDb': instance.albumGainDb,
  'playlistItemId': instance.playlistItemId,
};

_Album _$AlbumFromJson(Map<String, dynamic> json) => _Album(
  id: json['id'] as String,
  title: json['title'] as String,
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => NamedRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NamedRef>[],
  artistName: json['artistName'] as String?,
  year: (json['year'] as num?)?.toInt(),
  trackCount: (json['trackCount'] as num?)?.toInt(),
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  artwork: json['artwork'] == null
      ? null
      : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
  dateAdded: json['dateAdded'] == null
      ? null
      : DateTime.parse(json['dateAdded'] as String),
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  isFavorite: json['isFavorite'] as bool? ?? false,
  gainDb: (json['gainDb'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AlbumToJson(_Album instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artists': instance.artists.map((e) => e.toJson()).toList(),
  'artistName': instance.artistName,
  'year': instance.year,
  'trackCount': instance.trackCount,
  'duration': instance.duration?.inMicroseconds,
  'artwork': instance.artwork?.toJson(),
  'dateAdded': instance.dateAdded?.toIso8601String(),
  'genres': instance.genres,
  'isFavorite': instance.isFavorite,
  'gainDb': instance.gainDb,
};

_Artist _$ArtistFromJson(Map<String, dynamic> json) => _Artist(
  id: json['id'] as String,
  name: json['name'] as String,
  artwork: json['artwork'] == null
      ? null
      : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
  overview: json['overview'] as String?,
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$ArtistToJson(_Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'artwork': instance.artwork?.toJson(),
  'overview': instance.overview,
  'isFavorite': instance.isFavorite,
};

_ArtistDetail _$ArtistDetailFromJson(Map<String, dynamic> json) =>
    _ArtistDetail(
      artist: Artist.fromJson(json['artist'] as Map<String, dynamic>),
      albums:
          (json['albums'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Album>[],
      topTracks:
          (json['topTracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Track>[],
    );

Map<String, dynamic> _$ArtistDetailToJson(_ArtistDetail instance) =>
    <String, dynamic>{
      'artist': instance.artist.toJson(),
      'albums': instance.albums.map((e) => e.toJson()).toList(),
      'topTracks': instance.topTracks.map((e) => e.toJson()).toList(),
    };

_AlbumDetail _$AlbumDetailFromJson(Map<String, dynamic> json) => _AlbumDetail(
  album: Album.fromJson(json['album'] as Map<String, dynamic>),
  tracks:
      (json['tracks'] as List<dynamic>?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Track>[],
);

Map<String, dynamic> _$AlbumDetailToJson(_AlbumDetail instance) =>
    <String, dynamic>{
      'album': instance.album.toJson(),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

_Playlist _$PlaylistFromJson(Map<String, dynamic> json) => _Playlist(
  id: json['id'] as String,
  name: json['name'] as String,
  trackCount: (json['trackCount'] as num?)?.toInt(),
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
  artwork: json['artwork'] == null
      ? null
      : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlaylistToJson(_Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'trackCount': instance.trackCount,
  'duration': instance.duration?.inMicroseconds,
  'artwork': instance.artwork?.toJson(),
};

_Genre _$GenreFromJson(Map<String, dynamic> json) => _Genre(
  id: json['id'] as String,
  name: json['name'] as String,
  artwork: json['artwork'] == null
      ? null
      : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GenreToJson(_Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'artwork': instance.artwork?.toJson(),
};

_LyricLine _$LyricLineFromJson(Map<String, dynamic> json) => _LyricLine(
  text: json['text'] as String,
  start: json['start'] == null
      ? null
      : Duration(microseconds: (json['start'] as num).toInt()),
);

Map<String, dynamic> _$LyricLineToJson(_LyricLine instance) =>
    <String, dynamic>{
      'text': instance.text,
      'start': instance.start?.inMicroseconds,
    };

_TrackLyrics _$TrackLyricsFromJson(Map<String, dynamic> json) => _TrackLyrics(
  trackId: json['trackId'] as String,
  lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrackLyricsToJson(_TrackLyrics instance) =>
    <String, dynamic>{
      'trackId': instance.trackId,
      'lyrics': instance.lyrics.toJson(),
    };

_Lyrics _$LyricsFromJson(Map<String, dynamic> json) => _Lyrics(
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LyricLine>[],
  synced: json['synced'] as bool? ?? false,
  origin:
      $enumDecodeNullable(_$LyricsOriginEnumMap, json['origin']) ??
      LyricsOrigin.server,
);

Map<String, dynamic> _$LyricsToJson(_Lyrics instance) => <String, dynamic>{
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'synced': instance.synced,
  'origin': _$LyricsOriginEnumMap[instance.origin]!,
};

const _$LyricsOriginEnumMap = {
  LyricsOrigin.server: 'server',
  LyricsOrigin.lrclib: 'lrclib',
};
