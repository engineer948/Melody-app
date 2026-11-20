import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mixtape.dart';

import '../helpers/fakes.dart';

void main() {
  final mixtape = Mixtape(
    title: 'Yol için',
    note: 'Bunları dinle, beni düşün 💛',
    from: 'Ayla',
    color: Mixtape.colors[2],
    songs: const [
      MixtapeSong(
        id: 't1',
        title: 'Firuze',
        artist: 'Sezen Aksu',
        duration: Duration(seconds: 185),
      ),
      MixtapeSong(id: 'x9', title: 'Hadi'),
    ],
  );

  test('a code survives a trip through a chat message', () {
    final code = mixtape.encode();
    expect(code, startsWith(Mixtape.prefix));
    expect(code, matches(RegExp(r'^MELODY-MIX1:[A-Za-z0-9_-]+$')));
    final back = Mixtape.decode('Bak bunu aç 👉\n$code\nsevgiler');
    expect(back.title, 'Yol için');
    expect(back.note, 'Bunları dinle, beni düşün 💛');
    expect(back.from, 'Ayla');
    expect(back.color, Mixtape.colors[2]);
    expect(back.songs, mixtape.songs);
  });

  test('anything else is refused', () {
    expect(() => Mixtape.decode('merhaba'), throwsFormatException);
    expect(
      () => Mixtape.decode('${Mixtape.prefix}bozuk!!'),
      throwsFormatException,
    );
    expect(
      () => Mixtape.decode(const Mixtape(title: 'x', songs: []).encode()),
      throwsFormatException,
    );
  });

  test('long notes and too many songs are cut', () {
    final big = Mixtape(
      title: 'x' * 100,
      note: 'y' * 500,
      songs: [for (var i = 0; i < 20; i++) MixtapeSong(id: '$i', title: 's')],
    );
    final back = Mixtape.decode(big.encode());
    expect(back.title, hasLength(Mixtape.maxTitle));
    expect(back.note, hasLength(Mixtape.maxNote));
    expect(back.songs, hasLength(Mixtape.maxSongs));
  });

  test('songs are found by id, then by title; missing ones left out', () async {
    final source = FakeMusicSource(
      tracks: [
        makeTrack('t1', title: 'Firuze'),
        const Track(
          id: 'other-id',
          title: 'Hadi',
          artists: [NamedRef(id: 'a', name: 'Tarkan')],
        ),
      ],
    );
    final found = await findMixtapeSongs(
      source,
      Mixtape(
        title: 'x',
        songs: [
          ...mixtape.songs,
          const MixtapeSong(id: 'zz', title: 'Yok böyle şarkı'),
        ],
      ),
    );
    expect(found.map((t) => t.id), ['t1', 'other-id']);
  });
}
