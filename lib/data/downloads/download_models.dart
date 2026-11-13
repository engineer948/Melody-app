import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';

/// Where a download stands.
enum DownloadStatus {
  /// Waiting for a free slot (or for Wi-Fi).
  queued,

  /// Being fetched.
  running,

  /// Stopped by the user.
  paused,

  /// Complete and playable offline.
  done,

  /// Gave up; can be retried.
  failed,
}

/// Reasons a download is kept. A track stays as long as one remains.
abstract final class DownloadOrigin {
  /// Downloaded on its own, or as part of an album.
  static const manual = 'manual';

  /// Kept because favourites are downloaded automatically.
  static const favorites = 'favorites';

  /// Kept because the whole library is downloaded.
  static const library = 'library';

  /// Kept because the playlist [id] is kept in sync.
  static String playlist(String id) => 'playlist:$id';
}

/// One track saved (or being saved) for offline playback.
@immutable
class DownloadItem {
  /// Creates an item.
  const DownloadItem({
    required this.track,
    required this.fileName,
    this.status = DownloadStatus.queued,
    this.bytes = 0,
    this.totalBytes = 0,
    this.origins = const {DownloadOrigin.manual},
  });

  /// The track.
  final Track track;

  /// File name inside the download folder.
  final String fileName;

  /// Progress state.
  final DownloadStatus status;

  /// Bytes on disk so far.
  final int bytes;

  /// Expected size; 0 when unknown.
  final int totalBytes;

  /// Why it is kept, see [DownloadOrigin].
  final Set<String> origins;

  /// Whether the file is complete.
  bool get isDone => status == DownloadStatus.done;

  /// Fraction fetched, or `null` when the size is unknown.
  double? get progress => isDone
      ? 1
      : totalBytes > 0
      ? (bytes / totalBytes).clamp(0.0, 1.0)
      : null;

  /// Returns a copy with the given fields replaced.
  DownloadItem copyWith({
    Track? track,
    DownloadStatus? status,
    int? bytes,
    int? totalBytes,
    Set<String>? origins,
  }) => DownloadItem(
    track: track ?? this.track,
    fileName: fileName,
    status: status ?? this.status,
    bytes: bytes ?? this.bytes,
    totalBytes: totalBytes ?? this.totalBytes,
    origins: origins ?? this.origins,
  );
}
