import 'package:dio/dio.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/core/network/http_client.dart';
import 'package:melody/domain/lyrics/lrc_parser.dart';
import 'package:melody/domain/models/media.dart';

/// Looks lyrics up on LRCLIB (https://lrclib.net), a free public database.
///
/// Only title, artist, album and duration of the track are sent.
class LrclibClient {
  /// Creates the client.
  LrclibClient({HttpClientAdapter? adapter, String version = '0'})
    : _dio = createHttpClient(
        baseUrl: Uri.parse('https://lrclib.net/api'),
        adapter: adapter,
        retries: 1,
        headers: {
          'User-Agent':
              '${AppConfig.appName} $version (+https://github.com/engineer948)',
        },
      );

  final Dio _dio;

  /// Lyrics of [track], or `null` when LRCLIB has none.
  Future<Result<Lyrics?>> lookup(Track track) => Result.guard(() async {
    final duration = track.duration;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'get',
        queryParameters: {
          'track_name': track.title,
          'artist_name': track.artistLine,
          'album_name': ?track.albumTitle,
          if (duration != null) 'duration': duration.inSeconds,
        },
      );
      final data = response.data ?? const {};
      if (data['instrumental'] == true) return null;
      final synced = data['syncedLyrics'];
      final plain = data['plainLyrics'];
      final text = synced is String && synced.trim().isNotEmpty
          ? synced
          : plain is String
          ? plain
          : null;
      if (text == null) return null;
      final lyrics = parseLrc(text, origin: LyricsOrigin.lrclib);
      return lyrics.isEmpty ? null : lyrics;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }, onError: mapNetworkError);

  /// Releases the connection pool.
  void close() => _dio.close();
}
