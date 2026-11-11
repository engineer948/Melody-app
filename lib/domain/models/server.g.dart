// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerAccount _$ServerAccountFromJson(Map<String, dynamic> json) =>
    _ServerAccount(
      id: json['id'] as String,
      type: $enumDecode(_$SourceTypeEnumMap, json['type']),
      baseUrl: Uri.parse(json['baseUrl'] as String),
      serverName: json['serverName'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      serverId: json['serverId'] as String?,
      serverVersion: json['serverVersion'] as String?,
      libraryId: json['libraryId'] as String?,
    );

Map<String, dynamic> _$ServerAccountToJson(_ServerAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SourceTypeEnumMap[instance.type]!,
      'baseUrl': instance.baseUrl.toString(),
      'serverName': instance.serverName,
      'userId': instance.userId,
      'userName': instance.userName,
      'serverId': instance.serverId,
      'serverVersion': instance.serverVersion,
      'libraryId': instance.libraryId,
    };

const _$SourceTypeEnumMap = {
  SourceType.jellyfin: 'jellyfin',
  SourceType.emby: 'emby',
  SourceType.subsonic: 'subsonic',
  SourceType.local: 'local',
  SourceType.radio: 'radio',
};
