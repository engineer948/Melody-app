import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';

/// One song line of an M3U playlist.
@immutable
class M3uEntry {
  /// Creates an entry.
  const M3uEntry({required this.title, this.artist, this.duration, this.path});

  /// Song title.
  final String title;

  /// Artist, when known.
  final String? artist;

  /// Length, when known.
  final Duration? duration;

  /// File path or address as written in the playlist.
  final String? path;

  @override
  String toString() => artist == null ? title : '$artist – $title';
}

/// A parsed M3U playlist.
typedef M3uPlaylist = ({String? name, List<M3uEntry> entries});

/// Reads and writes M3U / M3U8 playlists.
abstract final class M3u {
  /// Parses [text]; plain lists of file paths work too.
  static M3uPlaylist parse(String text) {
    String? name;
    final entries = <M3uEntry>[];
    ({String? artist, String title, Duration? duration})? info;
    for (final raw in text.replaceFirst('﻿', '').split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        if (line.startsWith('#PLAYLIST:')) {
          name = _blankToNull(line.substring('#PLAYLIST:'.length));
        } else if (line.startsWith('#EXTINF:')) {
          info = _extinf(line.substring('#EXTINF:'.length));
        }
        continue;
      }
      final fromPath = _fromPath(line);
      final title = info?.title ?? fromPath.title;
      if (title.isNotEmpty) {
        entries.add(
          M3uEntry(
            title: title,
            artist: info?.artist ?? fromPath.artist,
            duration: info?.duration,
            path: line,
          ),
        );
      }
      info = null;
    }
    return (name: name, entries: entries);
  }

  /// Writes [tracks] as an extended M3U8 playlist called [name].
  ///
  /// Paths look like `Artist/Album/01 - Title.flac`, so other players can
  /// match them by file name; the `#EXTINF` lines carry artist and title.
  static String write(String name, List<Track> tracks) {
    final out = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#PLAYLIST:${_oneLine(name)}');
    for (final t in tracks) {
      final seconds = t.duration?.inSeconds ?? -1;
      final artist = _oneLine(t.artistLine);
      final title = _oneLine(t.title);
      out
        ..writeln(
          '#EXTINF:$seconds,${artist.isEmpty ? title : '$artist - $title'}',
        )
        ..writeln(_path(t));
    }
    return out.toString();
  }

  /// File name for a playlist called [name].
  static String fileName(String name) {
    final safe = _safe(name);
    return '${safe.isEmpty ? 'playlist' : safe}.m3u8';
  }

  static String _path(Track t) {
    final artist = _safe(t.albumArtist ?? t.artistLine);
    final album = _safe(t.albumTitle ?? '');
    final number = t.trackNumber == null
        ? ''
        : '${t.trackNumber.toString().padLeft(2, '0')} - ';
    final ext = (t.container ?? 'mp3').split(',').first.trim();
    return [
      if (artist.isNotEmpty) artist,
      if (album.isNotEmpty) album,
      '$number${_safe(t.title)}.$ext',
    ].join('/');
  }

  static String _oneLine(String s) => s.replaceAll(RegExp(r'[\r\n]+'), ' ');

  static String _safe(String s) =>
      _oneLine(s)
          .replaceAll(RegExp(r'[\\/:*?"<>|#]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

  static ({String? artist, String title, Duration? duration}) _extinf(
    String rest,
  ) {
    // "<seconds> [attributes],<Artist> - <Title>"
    final comma = rest.indexOf(',');
    final head = comma < 0 ? rest : rest.substring(0, comma);
    final text = comma < 0 ? '' : rest.substring(comma + 1).trim();
    final seconds = int.tryParse(head.trim().split(RegExp(r'\s')).first);
    final split = _splitArtist(text);
    return (
      artist: split.artist,
      title: split.title,
      duration: seconds == null || seconds < 0
          ? null
          : Duration(seconds: seconds),
    );
  }

  static ({String? artist, String title}) _fromPath(String line) {
    var name = _tryDecode(line).split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    if (dot > 0 && name.length - dot <= 5) name = name.substring(0, dot);
    // Leading track numbers: "01 - ", "01. ", "1-03 ".
    name = name.replaceFirst(
      RegExp(r'^\d{1,3}([-.]\d{1,3})?\s*[-._)]?\s+'),
      '',
    );
    return _splitArtist(name.replaceAll('_', ' ').trim());
  }

  static String _tryDecode(String s) {
    try {
      return Uri.decodeFull(s);
    } on FormatException {
      return s;
    }
  }

  static ({String? artist, String title}) _splitArtist(String text) {
    final i = text.indexOf(' - ');
    if (i <= 0) return (artist: null, title: text.trim());
    return (
      artist: text.substring(0, i).trim(),
      title: text.substring(i + 3).trim(),
    );
  }
}

/// Outcome of matching an M3U playlist against a library.
typedef M3uMatch = ({List<Track> found, List<M3uEntry> missing});

/// Finds the songs of [entries] in [source] by title, artist and length.
Future<M3uMatch> matchM3u(
  MusicSource source,
  List<M3uEntry> entries, {
  void Function(int done)? onProgress,
}) async {
  final found = <Track>[];
  final missing = <M3uEntry>[];
  for (final (i, entry) in entries.indexed) {
    final result = await source.search(entry.title, limit: 25);
    final track = bestM3uMatch(entry, result.valueOrNull?.tracks ?? const []);
    if (track == null) {
      missing.add(entry);
    } else {
      found.add(track);
    }
    onProgress?.call(i + 1);
  }
  return (found: found, missing: missing);
}

/// The candidate that fits [entry] best, or `null` when none has its title.
Track? bestM3uMatch(M3uEntry entry, List<Track> candidates) {
  final title = _norm(entry.title);
  final artist = entry.artist == null ? null : _norm(entry.artist!);
  Track? best;
  var bestScore = 0;
  for (final t in candidates) {
    final candidate = _norm(t.title);
    var score = 0;
    if (candidate == title) {
      score += 10;
    } else if (candidate.contains(title) || title.contains(candidate)) {
      score += 4;
    } else {
      continue;
    }
    if (artist != null && artist.isNotEmpty) {
      final names = [
        for (final a in t.artists) _norm(a.name),
        if (t.albumArtist case final a?) _norm(a),
      ];
      if (names.any((n) => n == artist)) {
        score += 6;
      } else if (names.any((n) => n.contains(artist) || artist.contains(n))) {
        score += 3;
      } else {
        score -= 5;
      }
    }
    final want = entry.duration;
    final have = t.duration;
    if (want != null && have != null) {
      final diff = (want - have).inSeconds.abs();
      if (diff <= 3) score += 2;
      if (diff > 30) score -= 3;
    }
    if (score > bestScore) {
      bestScore = score;
      best = t;
    }
  }
  return best;
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[\(\[].*?[\)\]]'), ' ')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
