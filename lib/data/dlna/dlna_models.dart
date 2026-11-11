import 'package:meta/meta.dart';

/// A UPnP / DLNA device on the local network that can play audio.
@immutable
class DlnaRenderer {
  /// Creates a renderer description.
  const DlnaRenderer({
    required this.id,
    required this.name,
    required this.avTransportUrl,
    this.renderingControlUrl,
  });

  /// Unique device name (UDN), or the description address.
  final String id;

  /// Name shown to the user.
  final String name;

  /// Control address of the AVTransport service.
  final Uri avTransportUrl;

  /// Control address of the RenderingControl service (volume), if any.
  final Uri? renderingControlUrl;

  @override
  bool operator ==(Object other) => other is DlnaRenderer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What a renderer is doing.
enum DlnaTransportState {
  /// Playing.
  playing,

  /// Paused.
  paused,

  /// Stopped, or nothing loaded.
  stopped,

  /// Loading or switching tracks.
  transitioning,
}

/// Position inside the current track, as reported by a renderer.
typedef DlnaPosition = ({Duration position, Duration? duration});

/// What the renderer shows about the track being played.
@immutable
class DlnaMetadata {
  /// Creates the metadata.
  const DlnaMetadata({
    required this.title,
    this.artist,
    this.album,
    this.artUri,
  });

  /// Song title.
  final String title;

  /// Artist name.
  final String? artist;

  /// Album title.
  final String? album;

  /// Cover address reachable by the renderer.
  final Uri? artUri;
}
