import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/sources/jellyfin/server_address.dart';

void main() {
  List<String> candidates(String input) =>
      ServerAddress.candidates(input).map((u) => u.toString()).toList();

  test('a bare host tries https and http, each with the default port', () {
    expect(candidates('192.168.1.10'), [
      'https://192.168.1.10',
      'https://192.168.1.10:8920',
      'http://192.168.1.10',
      'http://192.168.1.10:8096',
    ]);
  });

  test('an explicit port is kept', () {
    expect(candidates(' music.local:8096/ '), [
      'https://music.local:8096',
      'http://music.local:8096',
    ]);
  });

  test('an explicit scheme is respected', () {
    expect(candidates('HTTP://music.local'), [
      'http://music.local',
      'http://music.local:8096',
    ]);
    expect(candidates('https://example.com:443/jellyfin/'), [
      'https://example.com/jellyfin',
    ]);
  });

  test('a base path survives', () {
    expect(candidates('example.com/jf').first, 'https://example.com/jf');
  });

  test('nonsense yields nothing', () {
    expect(candidates(''), isEmpty);
    expect(candidates('   '), isEmpty);
    expect(candidates('my server'), isEmpty);
    expect(candidates('ftp://example.com'), isEmpty);
  });
}
