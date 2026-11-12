import 'package:melody/domain/models/media.dart';

/// What kind of item is being shared; decides the label on the card.
enum ShareKind {
  /// A single song.
  track,

  /// An album.
  album,

  /// An artist.
  artist,

  /// A playlist.
  playlist,
}

/// Everything the share card needs to know about one item.
///
/// No server address or item link is ever shared: Melody plays from the
/// user's own (often private) server, so a link would be useless to others
/// and would leak the address.
class ShareSubject {
  /// Creates a subject.
  const ShareSubject({
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.artwork,
  });

  /// A song: title, artists and its album cover.
  factory ShareSubject.track(Track track) => ShareSubject(
    kind: ShareKind.track,
    title: track.title,
    subtitle: track.artistLine,
    artwork: track.artwork,
  );

  /// An album: title, album artist and cover.
  factory ShareSubject.album(Album album) => ShareSubject(
    kind: ShareKind.album,
    title: album.title,
    subtitle: album.artistLine,
    artwork: album.artwork,
  );

  /// An artist with their picture.
  factory ShareSubject.artist(Artist artist) => ShareSubject(
    kind: ShareKind.artist,
    title: artist.name,
    artwork: artist.artwork,
  );

  /// A playlist; its cover is the first track's cover unless it has one.
  factory ShareSubject.playlist(
    String name, {
    Artwork? artwork,
    List<Track> tracks = const [],
  }) => ShareSubject(
    kind: ShareKind.playlist,
    title: name,
    artwork: artwork ?? tracks.map((t) => t.artwork).nonNulls.firstOrNull,
  );

  /// Card kind.
  final ShareKind kind;

  /// Big line: song, album, artist or playlist name.
  final String title;

  /// Smaller line under the title, usually the artist; may be empty.
  final String subtitle;

  /// Cover or picture; `null` shows a placeholder.
  final Artwork? artwork;

  /// Whether the picture is drawn as a circle (artists).
  bool get circular => kind == ShareKind.artist;

  /// "Title — Subtitle", used as the plain-text share.
  String get line => subtitle.isEmpty ? title : '$title — $subtitle';
}
