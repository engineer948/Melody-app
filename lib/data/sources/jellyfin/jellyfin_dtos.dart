import 'package:json_annotation/json_annotation.dart';

part 'jellyfin_dtos.g.dart';

const _dto = JsonSerializable(
  fieldRename: FieldRename.pascal,
  createToJson: false,
);

/// Response of `/System/Info/Public`.
@_dto
class PublicSystemInfoDto {
  /// Creates the DTO.
  const PublicSystemInfoDto({
    this.id,
    this.serverName,
    this.version,
    this.productName,
  });

  /// Parses the DTO.
  factory PublicSystemInfoDto.fromJson(Map<String, dynamic> json) =>
      _$PublicSystemInfoDtoFromJson(json);

  /// Server id.
  final String? id;

  /// Display name.
  final String? serverName;

  /// Server version.
  final String? version;

  /// Product, e.g. "Jellyfin Server".
  final String? productName;
}

/// A server user.
@_dto
class UserDto {
  /// Creates the DTO.
  const UserDto({this.id, this.name, this.primaryImageTag, this.hasPassword});

  /// Parses the DTO.
  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  /// User id.
  final String? id;

  /// User name.
  final String? name;

  /// Tag of the avatar, when one is set.
  final String? primaryImageTag;

  /// Whether a password is required.
  final bool? hasPassword;
}

/// Response of the authentication endpoints.
@_dto
class AuthenticationResultDto {
  /// Creates the DTO.
  const AuthenticationResultDto({this.user, this.accessToken, this.serverId});

  /// Parses the DTO.
  factory AuthenticationResultDto.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationResultDtoFromJson(json);

  /// Signed-in user.
  final UserDto? user;

  /// Token for later requests.
  final String? accessToken;

  /// Server id.
  final String? serverId;
}

/// State of a Quick Connect request.
@_dto
class QuickConnectResultDto {
  /// Creates the DTO.
  const QuickConnectResultDto({this.authenticated, this.secret, this.code});

  /// Parses the DTO.
  factory QuickConnectResultDto.fromJson(Map<String, dynamic> json) =>
      _$QuickConnectResultDtoFromJson(json);

  /// Whether the request was approved.
  final bool? authenticated;

  /// Secret identifying the request.
  final String? secret;

  /// Code the user types on another device.
  final String? code;
}

/// Name and id pair used for artists and genres.
@_dto
class NameIdDto {
  /// Creates the DTO.
  const NameIdDto({this.name, this.id});

  /// Parses the DTO.
  factory NameIdDto.fromJson(Map<String, dynamic> json) =>
      _$NameIdDtoFromJson(json);

  /// Display name.
  final String? name;

  /// Item id.
  final String? id;
}

/// Per-user state of an item.
@_dto
class UserDataDto {
  /// Creates the DTO.
  const UserDataDto({this.isFavorite, this.playCount});

  /// Parses the DTO.
  factory UserDataDto.fromJson(Map<String, dynamic> json) =>
      _$UserDataDtoFromJson(json);

  /// Favourite flag.
  final bool? isFavorite;

  /// Number of plays.
  final int? playCount;
}

/// Any library item: album, artist, track, playlist, genre or view.
@_dto
class BaseItemDto {
  /// Creates the DTO.
  const BaseItemDto({
    this.id,
    this.name,
    this.type,
    this.collectionType,
    this.album,
    this.albumId,
    this.albumArtist,
    this.albumPrimaryImageTag,
    this.albumArtists,
    this.artistItems,
    this.artists,
    this.productionYear,
    this.runTimeTicks,
    this.indexNumber,
    this.parentIndexNumber,
    this.childCount,
    this.overview,
    this.genres,
    this.dateCreated,
    this.container,
    this.imageTags,
    this.imageBlurHashes,
    this.userData,
    this.normalizationGain,
    this.playlistItemId,
  });

  /// Parses the DTO.
  factory BaseItemDto.fromJson(Map<String, dynamic> json) =>
      _$BaseItemDtoFromJson(json);

  /// Item id.
  final String? id;

  /// Display name.
  final String? name;

  /// Item kind, e.g. `MusicAlbum`.
  final String? type;

  /// Kind of a library view, e.g. `music`.
  final String? collectionType;

  /// Album title of a track.
  final String? album;

  /// Album id of a track.
  final String? albumId;

  /// Album artist name.
  final String? albumArtist;

  /// Cover tag of a track's album.
  final String? albumPrimaryImageTag;

  /// Album artists.
  final List<NameIdDto>? albumArtists;

  /// Track artists.
  final List<NameIdDto>? artistItems;

  /// Track artist names.
  final List<String>? artists;

  /// Release year.
  final int? productionYear;

  /// Duration in 100 ns ticks.
  final int? runTimeTicks;

  /// Track number.
  final int? indexNumber;

  /// Disc number.
  final int? parentIndexNumber;

  /// Number of children.
  final int? childCount;

  /// Description or biography.
  final String? overview;

  /// Genre names.
  final List<String>? genres;

  /// When the item was added.
  final DateTime? dateCreated;

  /// File container, e.g. `flac`.
  final String? container;

  /// Image tags by image type.
  final Map<String, String>? imageTags;

  /// BlurHashes by image type and tag.
  final Map<String, Map<String, String>>? imageBlurHashes;

  /// Per-user state.
  final UserDataDto? userData;

  /// Loudness normalisation gain in dB (Jellyfin 10.9+).
  final double? normalizationGain;

  /// Entry id inside a playlist.
  final String? playlistItemId;
}

/// A page of items.
@_dto
class ItemsResultDto {
  /// Creates the DTO.
  const ItemsResultDto({this.items, this.totalRecordCount});

  /// Parses the DTO.
  factory ItemsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ItemsResultDtoFromJson(json);

  /// Items of the page.
  final List<BaseItemDto>? items;

  /// Size of the whole result.
  final int? totalRecordCount;
}
