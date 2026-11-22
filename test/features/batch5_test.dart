import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/player/house_party.dart';
import 'package:melody/features/stats/month_album.dart';
import 'package:melody/features/stats/music_dna.dart';
import 'package:melody/features/stats/year_film.dart';
import 'package:melody/features/stats/year_game.dart';
import 'package:melody/l10n/app_localizations.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_places.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const Map<String, Object> _prefs = {
  LocaleController.localeKey: 'en',
  PlaybackSettingsController.key: '{"fadeMs":0}',
};

PlayEvent _play(String id, DateTime at, {String? title}) => PlayEvent(
  track: makeTrack(id, title: title),
  startedAt: at,
  listened: const Duration(minutes: 3),
);

class _RealHttp extends HttpOverrides;

void main() {
  test('year choices: the right year and three near it, none ahead', () {
    for (var seed = 0; seed < 50; seed++) {
      final choices = yearChoices(2020, Random(seed), now: 2022);
      expect(choices, contains(2020));
      expect(choices.toSet(), hasLength(4));
      expect(choices.every((y) => y <= 2022 && (y - 2020).abs() <= 8), isTrue);
      expect(choices, [...choices]..sort());
    }
  });

  test('film: times and the song of each month', () {
    final times = filmTimes(5, const Duration(seconds: 45));
    expect(times.first, Duration.zero);
    expect(times[1], const Duration(seconds: 3));
    expect(times.last, const Duration(seconds: 41));
    expect(times, [...times]..sort());
    final songs = topSongByMonth([
      _play('a', DateTime(2026, 1, 2)),
      _play('b', DateTime(2026, 1, 3)),
      _play('b', DateTime(2026, 1, 4)),
      _play('c', DateTime(2026, 3)),
    ]);
    expect(songs.map((m, t) => MapEntry(m, t.id)), {1: 'b', 3: 'c'});
  });

  testWidgets('film frames are drawn as pictures', (tester) async {
    final dir = Directory.systemTemp.createTempSync('melody_film');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = await tester.runAsync(
      () => renderFilmFrame(
        (big: 'March', small: '♪ Firuze', photo: null),
        dir,
        0,
      ),
    );
    expect(file!.lengthSync(), greaterThan(1000));
  });

  testWidgets('music DNA draws the statistics', (tester) async {
    expect(dnaColor('Rock'), dnaColor('rock'));
    final stats = ListeningStats.of([
      for (var i = 0; i < 20; i++)
        _play('t${i % 4}', DateTime(2026, 3, 1 + i, i % 24)),
    ], now: DateTime(2026, 4));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SizedBox(width: 360, height: 640, child: DnaPoster(stats: stats)),
      ),
    );
    expect(find.byType(DnaPoster), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the album of a month: its top songs as sides A and B', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: _prefs,
      size: const Size(400, 1600),
      overrides: [placesBridgeProvider.overrideWithValue(FakePlacesBridge())],
    );
    final month = lastMonth();
    final store = c.read(historyStoreProvider);
    for (var i = 0; i < 6; i++) {
      await store.add(
        testAccount.id,
        _play('m$i', month.add(Duration(days: i, hours: 12)), title: 'Song $i'),
      );
    }
    final album = await c.read(monthAlbumProvider(month).future);
    expect(album!.songs, hasLength(6));
    expect(album.firsts, 6);
    expect(
      await c.read(monthAlbumProvider(DateTime(month.year - 5)).future),
      isNull,
    );

    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showMonthAlbum(context, month));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('B3'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(c.read(playerControllerProvider).queue.entries, hasLength(6));
    await c.read(playerControllerProvider.notifier).clear();
  });

  test('house party: guests search and add songs with the key only', () async {
    final c = await createContainer(preferences: _prefs);
    final party = c.read(housePartyProvider.notifier);
    expect(await party.start(host: '127.0.0.1'), isTrue);
    final url = Uri.parse(c.read(housePartyProvider).url!);
    final key = url.queryParameters['k']!;
    // flutter_test answers every HttpClient call with 400: use real ones.
    final client = HttpOverrides.runWithHttpOverrides(
      HttpClient.new,
      _RealHttp(),
    );
    addTearDown(client.close);
    Future<(int, String)> call(String method, String path) async {
      final request = await client.openUrl(method, url.resolve(path));
      final response = await request.close();
      return (response.statusCode, await utf8.decodeStream(response));
    }

    expect((await call('GET', '/?k=wrong')).$1, 403);
    final page = await call('GET', '/?k=$key');
    expect(page.$1, 200);
    expect(page.$2, contains('Melody'));
    final found = await call('GET', '/search?k=$key&q=fir');
    final songs = jsonDecode(found.$2) as List<dynamic>;
    expect((songs.single as Map)['title'], 'Firuze');
    final added = await call('POST', '/add?k=$key&id=t1');
    expect(added.$1, 200);
    expect(c.read(playerControllerProvider).current?.id, 't1');
    expect(c.read(housePartyProvider).added, 1);
    // Too fast for the same guest.
    expect((await call('POST', '/add?k=$key&id=t1')).$1, 429);
    await party.stop();
    expect(c.read(housePartyProvider).running, isFalse);
    await c.read(playerControllerProvider.notifier).clear();
  });

  testWidgets('which year: pick a year, see if it was right', (tester) async {
    final source = FakeMusicSource(
      tracks: [
        for (var i = 0; i < 4; i++)
          Track(
            id: 'y$i',
            title: 'Song $i',
            year: 2000 + i,
            duration: const Duration(minutes: 3),
          ),
      ],
    );
    final c = await pumpApp(
      tester,
      preferences: _prefs,
      source: source,
      size: const Size(400, 1600),
    );
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showYearGame(context));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Song 1 of 4'), findsOneWidget);
    final playing = c.read(playerControllerProvider).current!;
    await tester.tap(find.text('${playing.year}'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1 point'), findsOneWidget);
    expect(find.text(playing.title), findsOneWidget);
    await c.read(playerControllerProvider.notifier).clear();
  });
}
