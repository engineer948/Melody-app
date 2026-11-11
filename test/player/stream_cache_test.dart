import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/player/stream_cache.dart';
import 'package:melody/player/streaming_settings.dart';

void main() {
  late Directory dir;
  late StreamCache cache;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('melody-cache');
    cache = StreamCache(() async => dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, int bytes, Duration age) => File('${dir.path}/$name')
    ..writeAsBytesSync(List.filled(bytes, 0))
    ..setLastModifiedSync(DateTime.now().subtract(age));

  test('keys become safe file names', () async {
    final file = await cache.fileFor('acc:1/../t 1');
    expect(file?.parent.path, dir.path);
    expect(file?.path.split('/').last, 'acc_1_.._t_1');
  });

  test('trims the least recently used files first', () async {
    write('old', 100, const Duration(days: 3));
    write('mid', 100, const Duration(days: 2));
    write('new', 100, const Duration(days: 1));
    expect(await cache.size(), 300);

    await cache.fileFor('old'); // Using a file makes it recent.
    await cache.trim(150);
    expect(File('${dir.path}/mid').existsSync(), isFalse);
    expect(File('${dir.path}/new').existsSync(), isFalse);
    expect(File('${dir.path}/old').existsSync(), isTrue);
  });

  test('clear removes everything but files in use', () async {
    write('a', 10, const Duration(hours: 1));
    write('playing', 10, Duration.zero);
    await cache.clear();
    expect(File('${dir.path}/a').existsSync(), isFalse);
    expect(File('${dir.path}/playing').existsSync(), isTrue);
  });

  test('stream options follow the connection and data saver', () {
    const s = StreamingSettings(
      wifiBitrate: 320,
      mobileBitrate: 192,
      format: StreamFormat.opus,
    );
    expect(s.optionsFor(mobile: false).maxBitrateKbps, 320);
    expect(s.optionsFor(mobile: true).maxBitrateKbps, 192);
    expect(s.optionsFor(mobile: true).format, StreamFormat.opus);
    final saver = s.copyWith(dataSaver: true, clearMobile: true);
    expect(saver.optionsFor(mobile: true).maxBitrateKbps, dataSaverBitrate);
    expect(saver.optionsFor(mobile: false).maxBitrateKbps, 320);
    expect(
      const StreamingSettings().optionsFor(mobile: true).isOriginal,
      isTrue,
    );
    expect(StreamingSettings.fromJson(s.toJson()), s);
  });
}
