import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/domain/playlists/smart_playlist.dart';

import '../helpers/fakes.dart';

void main() {
  final tracks = [
    for (var i = 0; i < 30; i++)
      makeTrack('t$i').copyWith(year: 1980 + i, playCount: i.isEven ? 0 : 3),
  ];

  test('server-side rules stop at the limit', () async {
    final source = FakeMusicSource(tracks: tracks);
    const p = SmartPlaylist(id: 's', name: 'New', limit: 5);
    final result = await p.resolve(source);
    expect(result.valueOrNull?.map((t) => t.id), [
      't0',
      't1',
      't2',
      't3',
      't4',
    ]);
  });

  test('years and "never played" are checked on the device', () async {
    final source = FakeMusicSource(tracks: tracks);
    const p = SmartPlaylist(
      id: 's',
      name: '90s',
      yearFrom: 1990,
      yearTo: 1999,
      unplayedOnly: true,
    );
    final result = (await p.resolve(source)).valueOrNull!;
    expect(result.map((t) => t.year), [1990, 1992, 1994, 1996, 1998]);
  });

  test('"never played" is ignored when sorting by plays', () {
    const p = SmartPlaylist(
      id: 's',
      name: 'Top',
      sort: SmartSort.mostPlayed,
      unplayedOnly: true,
    );
    expect(p.filtersLocally, isFalse);
    expect(p.matches(tracks[1]), isTrue);
  });

  test('random picks a different order from the whole pool', () async {
    final source = FakeMusicSource(tracks: tracks);
    const p = SmartPlaylist(
      id: 's',
      name: 'Mix',
      sort: SmartSort.random,
      limit: 10,
    );
    final result = (await p.resolve(source, random: Random(1))).valueOrNull!;
    expect(result, hasLength(10));
    expect(result.map((t) => t.id).toSet(), hasLength(10));
    expect(result.map((t) => t.id), isNot(tracks.take(10).map((t) => t.id)));
  });

  test('failures come back as errors', () async {
    final source = FakeMusicSource()..failure = const NetworkFailure();
    const p = SmartPlaylist(id: 's', name: 'x');
    expect((await p.resolve(source)).failureOrNull, isNotNull);
  });

  test('survives a JSON round trip', () {
    const p = SmartPlaylist(
      id: 's',
      name: 'Pop 90s',
      sort: SmartSort.random,
      favoritesOnly: true,
      genreId: 'g1',
      genreName: 'Pop',
      yearFrom: 1990,
      limit: 100,
    );
    final back = SmartPlaylist.fromJson(p.toJson());
    expect(back.toJson(), p.toJson());
  });
}
