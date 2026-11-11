import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_discovery.dart';

void main() {
  test('parses a server reply', () {
    final server = JellyfinDiscovery.parseReply(
      '{"Address":"http://192.168.1.10:8096","Id":"abc","Name":"Ev",'
      '"EndpointAddress":null}',
    );
    expect(server?.baseUrl, Uri.parse('http://192.168.1.10:8096'));
    expect(server?.name, 'Ev');
    expect(server?.id, 'abc');
    expect(server?.isInsecure, isTrue);
  });

  test('falls back to the host when the name is missing', () {
    final server = JellyfinDiscovery.parseReply(
      '{"Address":"https://jf.example.com"}',
    );
    expect(server?.name, 'jf.example.com');
    expect(server?.isInsecure, isFalse);
  });

  test('ignores anything that is not a server reply', () {
    for (final junk in [
      '',
      'who is JellyfinServer?',
      '[1,2]',
      '{"Name":"no address"}',
      '{"Address":42}',
      '{"Address":"not a url"}',
    ]) {
      expect(JellyfinDiscovery.parseReply(junk), isNull, reason: junk);
    }
  });
}
