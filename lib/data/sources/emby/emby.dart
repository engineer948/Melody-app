import 'package:dio/dio.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_connector.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_discovery.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';

/// Emby speaks the same MediaBrowser API as Jellyfin; only what differs is
/// here. Emby reads the client identity from its own header, answers a
/// different discovery message and has no Quick Connect or lyrics endpoint.
abstract final class Emby {
  /// Header Emby reads the client identity and token from.
  static const authHeader = 'X-Emby-Authorization';

  /// Discovery message Emby servers answer to.
  static const discoveryMessage = 'who is EmbyServer?';

  /// API client for an Emby server.
  static JellyfinApi api({
    required Uri baseUrl,
    required ClientIdentity identity,
    String? token,
    HttpClientAdapter? adapter,
    void Function()? onUnauthorized,
  }) => JellyfinApi(
    baseUrl: baseUrl,
    identity: identity,
    token: token,
    adapter: adapter,
    onUnauthorized: onUnauthorized,
    authHeader: authHeader,
  );
}

/// Signs users in to Emby servers.
class EmbyConnector extends JellyfinConnector {
  /// Creates a connector.
  EmbyConnector({required super.identity, super.adapter})
    : super(
        type: SourceType.emby,
        authHeader: Emby.authHeader,
        discovery: const JellyfinDiscovery(message: Emby.discoveryMessage),
      );

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) async =>
      const Ok(false);
}

/// [MusicSource] backed by an Emby server.
class EmbyMusicSource extends JellyfinMusicSource {
  /// Creates a source for [userId], optionally limited to [libraryId].
  EmbyMusicSource({required super.api, required super.userId, super.libraryId});

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
    favorites: true,
    playlists: true,
    editablePlaylists: true,
    instantMix: true,
    transcoding: true,
    genres: true,
    multipleLibraries: true,
    playbackReporting: true,
  );

  /// Emby has no lyrics endpoint; the app may still ask LRCLIB.
  @override
  Future<Result<Lyrics?>> lyrics(Track track) async => const Ok(null);
}
