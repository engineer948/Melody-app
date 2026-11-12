import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/network/tailnet_address.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';

const key = 'tskey-auth-kX7a9bQ2CNTRL-abcdefGHIJ1234567890';

Matcher throwsProblem(InviteProblem p) =>
    throwsA(isA<InviteException>().having((e) => e.problem, 'problem', p));

void main() {
  group('TailnetAddress', () {
    test('recognises Tailscale addresses only', () {
      for (final host in [
        '100.64.0.1',
        '100.101.102.103',
        '100.127.255.255',
        'nas.tail1234.ts.net',
        'fd7a:115c:a1e0::1',
        '[fd7a:115c:a1e0:ab12::5]',
      ]) {
        expect(TailnetAddress.isTailnetHost(host), isTrue, reason: host);
      }
      for (final host in [
        '100.63.0.1',
        '100.128.0.1',
        '192.168.1.5',
        '10.0.0.1',
        'example.com',
        'ts.net',
        'evil-ts.net.example.com',
        '100.64.0.256',
      ]) {
        expect(TailnetAddress.isTailnetHost(host), isFalse, reason: host);
      }
    });
  });

  group('TailnetInvite', () {
    test('round-trips through text, ignoring chat line breaks', () {
      final invite = TailnetInvite.create(
        authKey: key,
        server: '100.101.102.103',
        name: 'Ali',
      );
      expect(invite.server.toString(), 'http://100.101.102.103:8096');
      final code = invite.encode();
      expect(code, startsWith('MELODY1-'));
      final wrapped = '  ${code.substring(0, 20)}\n${code.substring(20)} ';
      expect(TailnetInvite.decode(wrapped), invite);
    });

    test('detects edits and garbage', () {
      final code = TailnetInvite.create(
        authKey: key,
        server: 'nas.tail1234.ts.net:8096',
      ).encode();
      final i = code.length ~/ 2;
      final flipped =
          code.substring(0, i) +
          (code[i] == 'A' ? 'B' : 'A') +
          code.substring(i + 1);
      expect(
        () => TailnetInvite.decode(flipped),
        throwsProblem(InviteProblem.corrupted),
      );
      expect(
        () => TailnetInvite.decode('hello'),
        throwsProblem(InviteProblem.malformed),
      );
      expect(
        () => TailnetInvite.decode('MELODY1-abc.00000000'),
        throwsProblem(InviteProblem.corrupted),
      );
    });

    test('refuses keys that would give control over the tailnet', () {
      for (final bad in [
        'tskey-api-k123456789-abcdef',
        'tskey-client-k123456789-abcdef',
        'tskey-auth-',
        'not a key',
      ]) {
        expect(
          () => TailnetInvite.create(authKey: bad, server: '100.64.0.1'),
          throwsProblem(InviteProblem.notAuthKey),
          reason: bad,
        );
      }
    });

    test('refuses servers outside the tailnet', () {
      for (final bad in [
        'example.com',
        '192.168.1.10:8096',
        'ftp://100.64.0.1',
        'http://user:pw@100.64.0.1',
        'http://100.64.0.1/?x=1',
      ]) {
        expect(
          () => TailnetInvite.create(authKey: key, server: bad),
          throwsProblem(InviteProblem.notTailnetServer),
          reason: bad,
        );
      }
      expect(
        TailnetInvite.parseServer('https://nas.tail1.ts.net/'),
        Uri.parse('https://nas.tail1.ts.net:443'),
      );
    });

    test('never prints the key', () {
      final invite = TailnetInvite.create(authKey: key, server: '100.64.0.1');
      expect(invite.toString(), isNot(contains('tskey')));
    });
  });

  group('TailnetRouter', () {
    final router = TailnetRouter(
      target: Uri.parse('http://100.64.0.5:8096'),
      local: Uri.parse('http://127.0.0.1:41641/s3cr3t'),
    );

    test('sends the server through the proxy and back', () {
      final url = Uri.parse('http://100.64.0.5:8096/Items/1?api_key=x');
      final routed = router.route(url);
      expect(
        routed.toString(),
        'http://127.0.0.1:41641/s3cr3t/Items/1?api_key=x',
      );
      expect(router.unroute(routed), url);
      expect(router.handles(url), isTrue);
    });

    test('leaves other addresses alone', () {
      for (final other in [
        'http://100.64.0.6:8096/Items',
        'http://100.64.0.5:8097/Items',
        'https://100.64.0.5:8096/Items',
        'http://example.com/',
      ]) {
        final url = Uri.parse(other);
        expect(router.route(url), url);
        expect(router.unroute(url), url);
      }
      expect(
        router.unroute(Uri.parse('http://127.0.0.1:41641/other/Items')),
        Uri.parse('http://127.0.0.1:41641/other/Items'),
      );
      const empty = TailnetRouter();
      expect(empty.route(Uri.parse('http://100.64.0.5:8096/x')).port, 8096);
    });
  });
}
