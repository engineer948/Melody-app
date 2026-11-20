import 'dart:convert';
import 'dart:io';

import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/playlists/m3u.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';

/// One song of a [Mixtape]: its id on the sender's server, plus what is
/// needed to find it on another one.
@immutable
class MixtapeSong {
  /// Creates a song.
  const MixtapeSong({
    required this.id,
    required this.title,
    this.artist = '',
    this.duration,
  });

  /// From a [track] of the sender's library.
  factory MixtapeSong.of(Track track) => MixtapeSong(
    id: track.id,
    title: track.title,
    artist: track.artistLine,
    duration: track.duration,
  );

  /// Id on the sender's server.
  final String id;

  /// Title.
  final String title;

  /// Artists, may be empty.
  final String artist;

  /// Length, when known.
  final Duration? duration;

  @override
  bool operator ==(Object other) =>
      other is MixtapeSong &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(id, title, artist, duration);
}

/// A few songs with a note, sent to someone like a letter.
@immutable
class Mixtape {
  /// Creates a mixtape.
  const Mixtape({
    required this.title,
    required this.songs,
    this.note = '',
    this.from = '',
    this.color = defaultColor,
  });

  /// Reads a code made by [encode]; throws [FormatException] otherwise.
  /// Text around the code (a chat message) is ignored.
  factory Mixtape.decode(String text) {
    final match = RegExp('$prefix([A-Za-z0-9_-]+)').firstMatch(text);
    if (match == null) throw const FormatException('no mixtape code');
    final Map<String, dynamic> json;
    try {
      final packed = base64Url.decode(base64Url.normalize(match.group(1)!));
      json = jsonDecode(
        utf8.decode(ZLibCodec(raw: true).decode(packed)),
      ) as Map<String, dynamic>;
    } on Object {
      throw const FormatException('broken mixtape code');
    }
    final songs = [
      for (final s in json['s'] as List<dynamic>? ?? const [])
        if (s is List && s.length >= 2)
          MixtapeSong(
            id: '${s[0]}',
            title: '${s[1]}',
            artist: s.length > 2 ? '${s[2]}' : '',
            duration: s.length > 3 && s[3] is int
                ? Duration(seconds: s[3] as int)
                : null,
          ),
    ];
    if (songs.isEmpty) throw const FormatException('empty mixtape');
    return Mixtape(
      title: _cut(json['t'] as String? ?? '', maxTitle),
      note: _cut(json['n'] as String? ?? '', maxNote),
      from: _cut(json['f'] as String? ?? '', maxTitle),
      color: json['c'] as int? ?? defaultColor,
      songs: songs.take(maxSongs).toList(),
    );
  }

  /// Start of every code.
  static const prefix = 'MELODY-MIX1:';

  /// Most songs in one mixtape.
  static const maxSongs = 12;

  /// Longest title.
  static const maxTitle = 60;

  /// Longest note.
  static const maxNote = 280;

  /// Label colours to choose from.
  static const colors = [
    0xFFE8505B, // red
    0xFFF9A03F, // orange
    0xFF3DB2A0, // teal
    0xFF5B7FE8, // blue
    0xFFB05BE8, // purple
  ];

  /// First of [colors].
  static const defaultColor = 0xFFE8505B;

  /// Name of the mixtape.
  final String title;

  /// Message to the person.
  final String note;

  /// Who made it.
  final String from;

  /// Label colour (ARGB).
  final int color;

  /// The songs in order.
  final List<MixtapeSong> songs;

  /// The mixtape as a short text code (compressed JSON).
  String encode() {
    final json = jsonEncode({
      't': _cut(title, maxTitle),
      if (note.isNotEmpty) 'n': _cut(note, maxNote),
      if (from.isNotEmpty) 'f': _cut(from, maxTitle),
      'c': color,
      's': [
        for (final s in songs.take(maxSongs))
          [s.id, s.title, s.artist, ?s.duration?.inSeconds],
      ],
    });
    final packed = ZLibCodec(raw: true, level: 9).encode(utf8.encode(json));
    return '$prefix${base64Url.encode(packed).replaceAll('=', '')}';
  }

  static String _cut(String s, int max) {
    final t = s.trim();
    return t.length > max ? t.substring(0, max) : t;
  }
}

/// Finds the songs of [mixtape] in [source]: the same id when it is the
/// sender's server, otherwise by title, artist and length. Missing songs
/// are left out.
Future<List<Track>> findMixtapeSongs(
  MusicSource source,
  Mixtape mixtape, {
  void Function(int done)? onProgress,
}) async {
  final found = <Track>[];
  for (final (i, song) in mixtape.songs.indexed) {
    final result = await source.search(song.title, limit: 25);
    final candidates = result.valueOrNull?.tracks ?? const <Track>[];
    final same = candidates.where((t) => t.id == song.id).firstOrNull;
    final track =
        same ??
        bestM3uMatch(
          M3uEntry(
            title: song.title,
            artist: song.artist.isEmpty ? null : song.artist,
            duration: song.duration,
          ),
          candidates,
        );
    if (track != null) found.add(track);
    onProgress?.call(i + 1);
  }
  return found;
}
