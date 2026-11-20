import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/backup/settings_backup.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  final created = DateTime.utc(2026, 11, 20, 9);

  Future<SharedPreferences> prefsWith(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('settings survive a round trip; phone-only ones stay out', () async {
    final prefs = await prefsWith({
      'theme.mode': 'dark',
      'theme.accentArgb': 0xFF00AA00,
      'theme.barOpacity': 0.5,
      'theme.pureBlack': true,
      'search.recent': ['firuze', 'hadi'],
      'smartPlaylists.acc1': '[{"id":"s","name":"Mix"}]',
      'tailnet.proxySecret': 'secret',
      'tailnet.target': 'http://100.70.0.5:8096',
      'app.deviceId': 'device-1',
      'session.activeAccount': 'acc1',
      'player.queue': '{}',
    });
    final backup = SettingsBackup.collect(prefs, [testAccount], now: created);
    final text = backup.encode();
    expect(text, isNot(contains('secret')));
    expect(text, isNot(contains('device-1')));
    expect(text, isNot(contains('100.70.0.5')));

    final back = SettingsBackup.decode(text);
    expect(back.created, created);
    expect(back.preferences, {
      'theme.mode': 'dark',
      'theme.accentArgb': 0xFF00AA00,
      'theme.barOpacity': 0.5,
      'theme.pureBlack': true,
      'search.recent': ['firuze', 'hadi'],
      'smartPlaylists.acc1': '[{"id":"s","name":"Mix"}]',
    });
    expect(back.accounts.single, testAccount);

    final fresh = await prefsWith({'theme.mode': 'light', 'app.deviceId': 'x'});
    await back.restoreInto(fresh);
    expect(fresh.getString('theme.mode'), 'dark');
    expect(fresh.getDouble('theme.barOpacity'), 0.5);
    expect(fresh.getStringList('search.recent'), ['firuze', 'hadi']);
    expect(fresh.getString('app.deviceId'), 'x', reason: 'kept');
  });

  test('other files are refused; phone-only keys in a file are ignored', () {
    expect(() => SettingsBackup.decode('nope'), throwsFormatException);
    expect(
      () => SettingsBackup.decode('{"kind":"something"}'),
      throwsFormatException,
    );
    expect(
      () => SettingsBackup.decode('{"kind":"melody-settings","version":99}'),
      throwsFormatException,
    );
    final backup = SettingsBackup.decode('''
{"kind":"melody-settings","version":1,"preferences":{
  "tailnet.target":{"t":"s","v":"http://evil"},
  "theme.mode":{"t":"s","v":"dark"},
  "theme.tint":{"t":"i","v":"not a number"}
},"accounts":[{"broken":true}]}''');
    expect(backup.preferences, {'theme.mode': 'dark'});
    expect(backup.accounts, isEmpty);
  });

  test('servers from a backup are added without a token', () async {
    final c = await createContainer();
    final notifier = c.read(sessionControllerProvider.notifier);
    final before = c.read(sessionControllerProvider);
    final other = ServerAccount(
      id: 'srv2:user2',
      type: SourceType.jellyfin,
      baseUrl: Uri.parse('https://other.example.com'),
      serverName: 'Other',
      userId: 'user2',
      userName: 'ayla',
    );
    final added = await notifier.addFromBackup([...before.accounts, other]);
    expect(added, 1);
    final after = c.read(sessionControllerProvider);
    expect(after.accounts.last, other);
    expect(after.tokens.containsKey(other.id), isFalse);
    expect(after.activeId, before.activeId);
    expect(c.read(preferencesProvider).getKeys(), isNotEmpty);
  });
}
