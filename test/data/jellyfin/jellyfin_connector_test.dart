import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_connector.dart';

import '../../helpers/fakes.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;

  JellyfinConnector connector(FakeResponse Function(RequestOptions) handler) {
    adapter = FakeHttpAdapter(handler);
    return JellyfinConnector(identity: testIdentity, adapter: adapter);
  }

  const info = {
    'ServerName': 'Home Server',
    'Version': '10.10.3',
    'Id': 'srv1',
    'ProductName': 'Jellyfin Server',
  };

  group('probe', () {
    test('prefers https and reports name and version', () async {
      final c = connector((_) => (status: 200, body: info));
      final server = (await c.probe('music.example.com')).valueOrNull;
      expect(server?.baseUrl.toString(), 'https://music.example.com');
      expect(server?.name, 'Home Server');
      expect(server?.version, '10.10.3');
      expect(server?.id, 'srv1');
      expect(adapter.last.uri.path, '/System/Info/Public');
    });

    test('falls back to http on the Jellyfin port', () async {
      final c = connector(
        (request) => request.uri.scheme == 'http' && request.uri.port == 8096
            ? (status: 200, body: info)
            : connectionError(request),
      );
      final server = (await c.probe('192.168.1.10')).valueOrNull;
      expect(server?.baseUrl.toString(), 'http://192.168.1.10:8096');
      expect(server?.isInsecure, isTrue);
    });

    test('an unreachable host is a NetworkFailure', () async {
      final c = connector(connectionError);
      expect(
        (await c.probe('192.168.1.10')).failureOrNull,
        isA<NetworkFailure>(),
      );
    });

    test('a web page that is not Jellyfin is rejected', () async {
      final c = connector((_) => (status: 200, body: {'hello': 'world'}));
      expect(
        (await c.probe('example.com')).failureOrNull,
        isA<ParsingFailure>(),
      );
    });

    test('an unusable address is rejected without a request', () async {
      final c = connector((_) => (status: 200, body: info));
      expect((await c.probe('  ')).failureOrNull, isA<NotFoundFailure>());
      expect(adapter.requests, isEmpty);
    });
  });

  test('signs in and never keeps the password', () async {
    final c = connector(
      (_) => (status: 200, body: fixture('jellyfin/auth.json')),
    );
    final session = (await c.signIn(
      testServer,
      username: 'ayla',
      password: 'secret',
    )).valueOrNull;
    expect(session?.accessToken, 'tok-123');
    expect(session?.account.id, 'jellyfin:srv1:u1');
    expect(session?.account.userName, 'ayla');
    expect(session?.account.serverName, 'Home Server');
    expect(session?.account.toJson().toString(), isNot(contains('secret')));
    expect(session?.account.toJson().toString(), isNot(contains('tok-123')));
    expect(adapter.last.method, 'POST');
    expect(adapter.last.uri.path, '/Users/AuthenticateByName');
    expect(adapter.last.data, {'Username': 'ayla', 'Pw': 'secret'});
    expect(adapter.last.headers['Authorization'], isNot(contains('Token=')));
  });

  test('wrong credentials are an UnauthorizedFailure', () async {
    final c = connector((_) => (status: 401, body: null));
    final result = await c.signIn(testServer, username: 'a', password: 'b');
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });

  test('lists public users with avatar addresses', () async {
    final c = connector(
      (_) => (
        status: 200,
        body: [
          {'Id': 'u1', 'Name': 'ayla', 'PrimaryImageTag': 'ava'},
          {'Id': 'u2', 'Name': 'guest', 'HasPassword': false},
          {'Name': 'broken'},
        ],
      ),
    );
    final users = (await c.publicUsers(testServer)).valueOrNull!;
    expect(users.map((u) => u.name), ['ayla', 'guest']);
    expect(users.first.avatar?.path, '/Users/u1/Images/Primary');
    expect(users.first.avatar?.queryParameters['tag'], 'ava');
    expect(users.first.hasPassword, isTrue);
    expect(users.last.avatar, isNull);
    expect(users.last.hasPassword, isFalse);
  });

  group('Quick Connect', () {
    test('reports availability', () async {
      var c = connector((_) => (status: 200, body: true));
      expect((await c.quickConnectAvailable(testServer)).valueOrNull, isTrue);
      c = connector((_) => (status: 200, body: false));
      expect((await c.quickConnectAvailable(testServer)).valueOrNull, isFalse);
    });

    test('starts, polls and signs in', () async {
      var approved = false;
      final c = connector(
        (request) => switch (request.uri.path) {
          '/QuickConnect/Initiate' => (
            status: 200,
            body: {'Code': '123456', 'Secret': 's3', 'Authenticated': false},
          ),
          '/QuickConnect/Connect' => (
            status: 200,
            body: {'Code': '123456', 'Secret': 's3', 'Authenticated': approved},
          ),
          _ => (status: 200, body: fixture('jellyfin/auth.json')),
        },
      );
      final request = (await c.quickConnectStart(testServer)).valueOrNull!;
      expect(request.code, '123456');
      expect(adapter.last.method, 'POST');

      expect(
        (await c.quickConnectApproved(testServer, request)).valueOrNull,
        isFalse,
      );
      expect(adapter.last.queryParameters, {'secret': 's3'});
      approved = true;
      expect(
        (await c.quickConnectApproved(testServer, request)).valueOrNull,
        isTrue,
      );

      final session = await c.quickConnectSignIn(testServer, request);
      expect(session.valueOrNull?.accessToken, 'tok-123');
      expect(adapter.last.uri.path, '/Users/AuthenticateWithQuickConnect');
      expect(adapter.last.data, {'Secret': 's3'});
    });

    test('older servers are asked with GET', () async {
      final c = connector(
        (request) => request.method == 'POST'
            ? (status: 405, body: null)
            : (status: 200, body: {'Code': '654321', 'Secret': 'old'}),
      );
      final request = (await c.quickConnectStart(testServer)).valueOrNull;
      expect(request?.code, '654321');
      expect(adapter.requests.map((r) => r.method), ['POST', 'GET']);
    });
  });
}
