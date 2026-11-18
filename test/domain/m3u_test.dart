import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/playlists/m3u.dart';

import '../helpers/fakes.dart';

void main() {
  group('M3u.parse', () {
    test('reads extended entries with name, artist and length', () {
      final parsed = M3u.parse(
        '\uFEFF#EXTM3U\r\n#PLAYLIST:Yol\r\n'
        '#EXTINF:185,Sezen Aksu - Firuze\r\nSezen/Firuze.flac\r\n'
        '#EXTINF:-1 tvg-id="x",Hadi\r\nhadi.mp3\r\n',
      );
      expect(parsed.name, 'Yol');
      expect(parsed.entries, hasLength(2));
      expect(parsed.entries[0].artist, 'Sezen Aksu');
      expect(parsed.entries[0].title, 'Firuze');
      expect(parsed.entries[0].duration, const Duration(seconds: 185));
      expect(parsed.entries[1].artist, isNull);
      expect(parsed.entries[1].title, 'Hadi');
      expect(parsed.entries[1].duration, isNull);
    });

    test('takes titles from plain file paths', () {
      final parsed = M3u.parse(
        r'C:\Music\Sezen Aksu\01 - Firuze.mp3'
        '\n/sdcard/Music/Tarkan%20-%20Kuzu%20Kuzu.m4a\n',
      );
      expect(parsed.name, isNull);
      expect(parsed.entries[0].title, 'Firuze');
      expect(parsed.entries[0].artist, isNull);
      expect(parsed.entries[1].artist, 'Tarkan');
      expect(parsed.entries[1].title, 'Kuzu Kuzu');
    });
  });

  test('write produces a file parse reads back', () {
    final tracks = [
      const Track(
        id: '1',
        title: 'Firuze',
        artists: [NamedRef(id: 'a', name: 'Sezen Aksu')],
        albumArtist: 'Sezen Aksu',
        albumTitle: 'Firuze',
        trackNumber: 3,
        container: 'flac',
        duration: Duration(seconds: 185),
      ),
    ];
    final text = M3u.write('Yol: şarkılar', tracks);
    expect(text, startsWith('#EXTM3U\n#PLAYLIST:Yol: şarkılar\n'));
    expect(text, contains('#EXTINF:185,Sezen Aksu - Firuze\n'));
    expect(text, contains('Sezen Aksu/Firuze/03 - Firuze.flac\n'));
    final parsed = M3u.parse(text);
    expect(parsed.name, 'Yol: şarkılar');
    expect(parsed.entries.single.artist, 'Sezen Aksu');
    expect(parsed.entries.single.title, 'Firuze');
    expect(M3u.fileName('Yol: şarkılar'), 'Yol_ şarkılar.m3u8');
  });

  group('bestM3uMatch', () {
    Track song(String id, String title, String artist, int seconds) => Track(
      id: id,
      title: title,
      artists: [NamedRef(id: artist, name: artist)],
      duration: Duration(seconds: seconds),
    );

    test('prefers the right artist and length', () {
      final candidates = [
        song('cover', 'Firuze', 'Someone Else', 200),
        song('live', 'Firuze (Live)', 'Sezen Aksu', 260),
        song('orig', 'Firuze', 'Sezen Aksu', 186),
      ];
      const entry = M3uEntry(
        title: 'Firuze',
        artist: 'Sezen Aksu',
        duration: Duration(seconds: 185),
      );
      expect(bestM3uMatch(entry, candidates)?.id, 'orig');
    });

    test('returns null when no title fits', () {
      expect(
        bestM3uMatch(const M3uEntry(title: 'Hadi'), [
          song('x', 'Firuze', 'Sezen Aksu', 186),
        ]),
        isNull,
      );
    });
  });

  test('matchM3u splits found and missing songs', () async {
    final source = FakeMusicSource();
    final match = await matchM3u(source, const [
      M3uEntry(title: 'Firuze'),
      M3uEntry(title: 'Unknown song'),
      M3uEntry(title: 'hadi'),
    ]);
    expect([for (final t in match.found) t.id], ['t1', 't2']);
    expect(match.missing.single.title, 'Unknown song');
  });
}
