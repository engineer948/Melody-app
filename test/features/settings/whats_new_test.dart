import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/features/settings/whats_new.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(prefs);
  PackageInfo.setMockInitialValues(
    appName: 'Melody',
    packageName: 'io.github.engineer948.melody',
    version: '0.30.0',
    buildNumber: '47',
    buildSignature: '',
  );
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [preferencesProvider.overrideWithValue(p)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('nothing on a fresh install, but the version is remembered', () async {
    final c = await _container({});
    expect(await c.read(whatsNewProvider('en').future), isNull);
    expect(c.read(preferencesProvider).getInt(whatsNewKey), 47);
  });

  test('the notes in the app language after an update, once', () async {
    final c = await _container({whatsNewKey: 46});
    final news = await c.read(whatsNewProvider('az').future);
    expect(news?.version, '0.30.0');
    expect(news?.notes, contains('Ana ekran'));
    await c.read(preferencesProvider).setInt(whatsNewKey, 47);
    c.invalidate(whatsNewProvider);
    expect(await c.read(whatsNewProvider('az').future), isNull);
  });

  test('English when the language has no notes', () async {
    expect(await loadChangelog(47, 'de'), contains('Home shelves'));
  });
}
