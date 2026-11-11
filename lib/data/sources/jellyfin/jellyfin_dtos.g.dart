// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jellyfin_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicSystemInfoDto _$PublicSystemInfoDtoFromJson(Map<String, dynamic> json) =>
    PublicSystemInfoDto(
      id: json['Id'] as String?,
      serverName: json['ServerName'] as String?,
      version: json['Version'] as String?,
      productName: json['ProductName'] as String?,
    );

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['Id'] as String?,
  name: json['Name'] as String?,
  primaryImageTag: json['PrimaryImageTag'] as String?,
  hasPassword: json['HasPassword'] as bool?,
);

AuthenticationResultDto _$AuthenticationResultDtoFromJson(
  Map<String, dynamic> json,
) => AuthenticationResultDto(
  user: json['User'] == null
      ? null
      : UserDto.fromJson(json['User'] as Map<String, dynamic>),
  accessToken: json['AccessToken'] as String?,
  serverId: json['ServerId'] as String?,
);

QuickConnectResultDto _$QuickConnectResultDtoFromJson(
  Map<String, dynamic> json,
) => QuickConnectResultDto(
  authenticated: json['Authenticated'] as bool?,
  secret: json['Secret'] as String?,
  code: json['Code'] as String?,
);

NameIdDto _$NameIdDtoFromJson(Map<String, dynamic> json) =>
    NameIdDto(name: json['Name'] as String?, id: json['Id'] as String?);

UserDataDto _$UserDataDtoFromJson(Map<String, dynamic> json) => UserDataDto(
  isFavorite: json['IsFavorite'] as bool?,
  playCount: (json['PlayCount'] as num?)?.toInt(),
);

BaseItemDto _$BaseItemDtoFromJson(Map<String, dynamic> json) => BaseItemDto(
  id: json['Id'] as String?,
  name: json['Name'] as String?,
  type: json['Type'] as String?,
  collectionType: json['CollectionType'] as String?,
  album: json['Album'] as String?,
  albumId: json['AlbumId'] as String?,
  albumArtist: json['AlbumArtist'] as String?,
  albumPrimaryImageTag: json['AlbumPrimaryImageTag'] as String?,
  albumArtists: (json['AlbumArtists'] as List<dynamic>?)
      ?.map((e) => NameIdDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  artistItems: (json['ArtistItems'] as List<dynamic>?)
      ?.map((e) => NameIdDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  artists: (json['Artists'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  productionYear: (json['ProductionYear'] as num?)?.toInt(),
  runTimeTicks: (json['RunTimeTicks'] as num?)?.toInt(),
  indexNumber: (json['IndexNumber'] as num?)?.toInt(),
  parentIndexNumber: (json['ParentIndexNumber'] as num?)?.toInt(),
  childCount: (json['ChildCount'] as num?)?.toInt(),
  overview: json['Overview'] as String?,
  genres: (json['Genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
  dateCreated: json['DateCreated'] == null
      ? null
      : DateTime.parse(json['DateCreated'] as String),
  container: json['Container'] as String?,
  imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  imageBlurHashes: (json['ImageBlurHashes'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
  ),
  userData: json['UserData'] == null
      ? null
      : UserDataDto.fromJson(json['UserData'] as Map<String, dynamic>),
  normalizationGain: (json['NormalizationGain'] as num?)?.toDouble(),
  playlistItemId: json['PlaylistItemId'] as String?,
);

ItemsResultDto _$ItemsResultDtoFromJson(Map<String, dynamic> json) =>
    ItemsResultDto(
      items: (json['Items'] as List<dynamic>?)
          ?.map((e) => BaseItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecordCount: (json['TotalRecordCount'] as num?)?.toInt(),
    );
