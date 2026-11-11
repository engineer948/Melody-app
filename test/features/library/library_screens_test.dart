import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/album/album_screen.dart';
import 'package:melody/features/artist/artist_screen.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/genre/genre_screen.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/library_screen.dart';
import 'package:melody/features/playlist/playlist_screen.dart';
import 'package:melody/features/search/search_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  const en = {LocaleController.localeKey: 'en'};

  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
  }

  Future<void> openCategory(WidgetTester tester, String label) async {
    await openLibrary(tester);
    await tester.tap(find.widgetWithText(ListTile, label));
    await tester.pumpAndSettle();
  }

  testWidgets('home greets and shows shelves from the source', (tester) async {
    await pumpApp(tester, preferences: en);
    expect(
      find.textContaining(RegExp('^Good (morning|afternoon|evening|night)')),
      findsWidgets,
    );
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);
    expect(find.text('Gülümse'), findsWidgets);
    expect(find.text('Firuze'), findsWidgets);
  });

  testWidgets('home explains failures and can retry', (tester) async {
    final source = FakeMusicSource()..failure = const NetworkFailure();
    await pumpApp(tester, preferences: en, source: source);
    expect(
      find.text('The server cannot be reached. Check your connection.'),
      findsOneWidget,
    );
    source.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recently added'), findsOneWidget);
  });

  testWidgets('the library lists categories and recent albums', (tester) async {
    await pumpApp(tester, preferences: en, size: const Size(400, 1400));
    await openLibrary(tester);
    for (final label in [
      'Playlists',
      'Artists',
      'Albums',
      'Songs',
      'Genres',
      'Favorites',
    ]) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Gülümse'), findsOneWidget);
  });

  testWidgets('each category opens its own page', (tester) async {
    final source = FakeMusicSource();
    await source.addToPlaylist('p1', ['t1']);
    await pumpApp(
      tester,
      preferences: en,
      source: source,
      size: const Size(400, 1400),
    );
    await openCategory(tester, 'Artists');
    expect(find.text('Sezen'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    expect(find.text('Firuze'), findsOneWidget);
    expect(find.text('3:05'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Playlists'));
    await tester.pumpAndSettle();
    expect(find.text('Yol şarkıları'), findsOneWidget);
    await tester.tap(find.text('Yol şarkıları'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistScreen), findsOneWidget);
    expect(find.text('Firuze'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Genres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pop'));
    await tester.pumpAndSettle();
    expect(find.byType(GenreScreen), findsOneWidget);
    expect(find.text('Gülümse'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('albums can be re-sorted', (tester) async {
    final source = FakeMusicSource();
    await pumpApp(tester, preferences: en, source: source);
    await openCategory(tester, 'Albums');
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year').last);
    await tester.pumpAndSettle();
    expect(source.albumQueries.last.sort, AlbumSort.year);
  });

  testWidgets('scrolling loads further pages', (tester) async {
    final source = FakeMusicSource(
      albums: [for (var i = 0; i < 150; i++) makeAlbum('a$i')],
    );
    final container = await pumpApp(tester, preferences: en, source: source);
    await openCategory(tester, 'Albums');
    const query = AlbumQuery();
    expect(container.read(albumListProvider(query)).items, hasLength(60));
    expect(container.read(albumListProvider(query)).hasMore, isTrue);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    expect(container.read(albumListProvider(query)).items, hasLength(120));

    await container.read(albumListProvider(query).notifier).loadMore();
    await container.read(albumListProvider(query).notifier).loadMore();
    final state = container.read(albumListProvider(query));
    expect(state.items, hasLength(150));
    expect(state.hasMore, isFalse);
  });

  testWidgets('album page: cover, play / shuffle, discs and favourite', (
    tester,
  ) async {
    final source = FakeMusicSource();
    await pumpApp(
      tester,
      preferences: en,
      source: source,
      size: const Size(400, 1400),
    );
    await openLibrary(tester);
    await tester.tap(find.text('Gülümse'));
    await tester.pumpAndSettle();

    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('2001 · 2 songs · 6:10'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Shuffle'), findsOneWidget);
    expect(find.text('Disc 1'), findsOneWidget);
    expect(find.text('Disc 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(source.favoriteCalls, [('a1', true)]);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Sezen'));
    await tester.pumpAndSettle();
    expect(find.byType(ArtistScreen), findsOneWidget);
    expect(find.text('Popular songs'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bio text'), 300);
    expect(find.text('Bio text'), findsOneWidget);
  });

  testWidgets('cached content stays visible while offline', (tester) async {
    final source = FakeMusicSource();
    final container = await pumpApp(tester, preferences: en, source: source);
    await openLibrary(tester);
    expect(find.text('Gülümse'), findsOneWidget);

    source.failure = const NetworkFailure();
    container.invalidate(albumListProvider(recentlyAddedQuery));
    await tester.pumpAndSettle();
    expect(find.text('Gülümse'), findsOneWidget);
    expect(find.text('Offline — showing saved content'), findsOneWidget);
  });

  testWidgets('search waits for a pause, then groups results', (tester) async {
    final source = FakeMusicSource();
    await pumpApp(tester, preferences: en, source: source);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'f');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'fi');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'fir');
    await tester.pump(const Duration(milliseconds: 250));
    expect(source.searches, isEmpty);

    await tester.pump(SearchQueryController.debounce);
    await tester.pumpAndSettle();
    expect(source.searches, ['fir']);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Firuze'), findsOneWidget);
    expect(find.text('Albums'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(SearchQueryController.debounce);
    await tester.pumpAndSettle();
    expect(find.text('No results for “zzz”'), findsOneWidget);
  });

  testWidgets('submitted searches are remembered and can be cleared', (
    tester,
  ) async {
    final container = await pumpApp(tester, preferences: en);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'deli');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(SearchQueryController.debounce);
    await tester.pumpAndSettle();
    expect(container.read(recentSearchesProvider), ['deli']);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);

    await tester.tap(find.text('deli'));
    await tester.pump(SearchQueryController.debounce);
    await tester.pumpAndSettle();
    expect(find.text('Deli'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(container.read(recentSearchesProvider), isEmpty);
  });

  testWidgets('settings list accounts, libraries and sign out', (tester) async {
    final container = await pumpApp(
      tester,
      preferences: en,
      size: const Size(400, 3200),
    );
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('ayla'), findsOneWidget);
    expect(find.text('Home Server'), findsOneWidget);
    expect(find.text('All libraries'), findsOneWidget);

    await tester.tap(find.text('Music library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audiobooks'));
    await tester.pumpAndSettle();
    expect(container.read(sessionControllerProvider).active?.libraryId, 'lib2');

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sign ayla out of Home Server?'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(container.read(sessionControllerProvider).accounts, isEmpty);
    expect(find.text('Connect to Jellyfin'), findsOneWidget);
  });

  testWidgets('library and album pages are accessible', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, preferences: en);
    await openLibrary(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.tap(find.text('Gülümse'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
