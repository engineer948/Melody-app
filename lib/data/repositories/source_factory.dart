import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_connector.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/repositories/server_connector.dart';

/// Creates the [MusicSource] for a signed-in [account].
///
/// Sources other than Jellyfin are added in a later stage.
MusicSource createMusicSource({
  required ServerAccount account,
  required String token,
  required ClientIdentity identity,
  void Function()? onUnauthorized,
}) => switch (account.type) {
  SourceType.jellyfin => JellyfinMusicSource(
    api: JellyfinApi(
      baseUrl: account.baseUrl,
      identity: identity,
      token: token,
      onUnauthorized: onUnauthorized,
    ),
    userId: account.userId,
    libraryId: account.libraryId,
  ),
  SourceType.emby ||
  SourceType.subsonic ||
  SourceType.local ||
  SourceType.radio => throw UnsupportedError('${account.type} is not ready'),
};

/// Creates the [ServerConnector] used to sign in to servers of [type].
ServerConnector createServerConnector(
  SourceType type,
  ClientIdentity identity,
) => switch (type) {
  SourceType.jellyfin => JellyfinConnector(identity: identity),
  SourceType.emby ||
  SourceType.subsonic ||
  SourceType.local ||
  SourceType.radio => throw UnsupportedError('$type is not ready'),
};
