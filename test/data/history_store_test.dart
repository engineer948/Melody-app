import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/history/history_store.dart';
import 'package:melody/domain/stats/play_event.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late HistoryStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = HistoryStore(db);
  });
  tearDown(() => db.close());

  PlayEvent play(String id, DateTime at) => PlayEvent(
    track: makeTrack(id),
    startedAt: at,
    listened: const Duration(minutes: 2),
  );

  test('keeps plays per account, oldest first, filtered by time', () async {
    await store.add('acc1', play('t2', DateTime(2026, 3)));
    await store.add('acc1', play('t1', DateTime(2025, 12, 31)));
    await store.add('acc2', play('t9', DateTime(2026, 2)));

    final all = await store.events('acc1');
    expect(all.map((e) => e.track.id), ['t1', 't2']);
    expect(all.first.listened, const Duration(minutes: 2));

    final year = await store.events(
      'acc1',
      from: DateTime(2026),
      to: DateTime(2027),
    );
    expect(year.map((e) => e.track.id), ['t2']);
    expect(await store.count('acc1'), 2);
  });

  test('clear removes one account or everything', () async {
    await store.add('acc1', play('t1', DateTime(2026)));
    await store.add('acc2', play('t2', DateTime(2026)));
    await store.clear('acc1');
    expect(await store.events('acc1'), isEmpty);
    expect(await store.count('acc2'), 1);
    await store.clear();
    expect(await store.count('acc2'), 0);
  });
}
