import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/data/sources/emby/emby.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_connector.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/data/sources/local/local_source.dart';
import 'package:melody/data/sources/radio/radio_source.dart';
import 'package:melody/data/sources/subsonic/subsonic_api.dart';
import 'package:melody/data/sources/subsonic/subsonic_connector.dart';
import 'package:melody/data/sources/subsonic/subsonic_music_source.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/repositories/server_connector.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates the [MusicSource] for a signed-in [account].
///
/// [prefs] keeps on-device data some sources need (saved radio stations).
MusicSource createMusicSource({
  required ServerAccount account,
  required String token,
  required ClientIdentity identity,
  required SharedPreferences prefs,
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
  SourceType.emby => EmbyMusicSource(
    api: Emby.api(
      baseUrl: account.baseUrl,
      identity: identity,
      token: token,
      onUnauthorized: onUnauthorized,
    ),
    userId: account.userId,
    libraryId: account.libraryId,
  ),
  SourceType.subsonic => SubsonicMusicSource(
    api: SubsonicApi(
      baseUrl: account.baseUrl,
      credentials: SubsonicCredentials.decode(account.userName, token),
      clientName: identity.clientName,
      onUnauthorized: onUnauthorized,
    ),
    libraryId: account.libraryId,
  ),
  SourceType.local => LocalSource(),
  SourceType.radio => RadioSource(prefs: prefs),
};

/// Creates the [ServerConnector] used to sign in to servers of [type].
ServerConnector createServerConnector(
  SourceType type,
  ClientIdentity identity,
) => switch (type) {
  SourceType.jellyfin => JellyfinConnector(identity: identity),
  SourceType.emby => EmbyConnector(identity: identity),
  SourceType.subsonic => SubsonicConnector(),
  SourceType.local => const LocalConnector(),
  SourceType.radio => const RadioConnector(),
};
