import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_browser.g.dart';

/// Top-level entries of the tree shown by Android Auto.
enum AutoTab {
  /// Recently played songs.
  recent,

  /// Favourite songs.
  favorites,

  /// Playlists.
  playlists,

  /// Albums.
  albums,

  /// Artists.
  artists,

  /// Genres.
  genres,

  /// Downloaded songs.
  downloads,

  /// The current queue.
  queue,
}

/// Which [AutoTab]s are shown in the car; all of them by default.
@Riverpod(keepAlive: true)
class AutoTabs extends _$AutoTabs {
  /// Preference key (names of the hidden tabs).
  static const key = 'auto.hiddenTabs';

  @override
  Set<AutoTab> build() {
    final hidden = ref.watch(preferencesProvider).getStringList(key) ?? [];
    return {
      for (final tab in AutoTab.values)
        if (!hidden.contains(tab.name)) tab,
    };
  }

  /// Shows or hides [tab].
  Future<void> setVisible(AutoTab tab, {required bool visible}) async {
    state = visible ? {...state, tab} : ({...state}..remove(tab));
    await ref.read(preferencesProvider).setStringList(key, [
      for (final t in AutoTab.values)
        if (!state.contains(t)) t.name,
    ]);
  }
}

/// Title of [tab] in the given language.
String autoTabLabel(AppLocalizations l10n, AutoTab tab) => switch (tab) {
  AutoTab.recent => l10n.homeRecentlyPlayed,
  AutoTab.favorites => l10n.libraryFavorites,
  AutoTab.playlists => l10n.libraryPlaylists,
  AutoTab.albums => l10n.libraryAlbums,
  AutoTab.artists => l10n.libraryArtists,
  AutoTab.genres => l10n.libraryGenres,
  AutoTab.downloads => l10n.libraryDownloads,
  AutoTab.queue => l10n.queue,
};

/// The library as a tree of media items, for Android Auto and other media
/// browsers, plus "play this" and voice search.
///
/// Ids: `tab:<name>` for the top level, `album:<id>` / `artist:<id>` /
/// `playlist:<id>` / `genre:<id>` for containers and
/// `play|<container id>|<track id>` for songs, so that playing a song
/// queues everything next to it.
class MediaBrowser {
  /// Creates the browser on top of the app's providers.
  MediaBrowser(this._container);

  final ProviderContainer _container;

  static const _gridHint = 2;
  static const _listHint = 1;

  /// Extras announcing that content style hints are supported.
  static const rootExtras = <String, dynamic>{
    'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
    'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': _listHint,
    'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': _listHint,
  };

  MusicSource? get _source => _container.read(activeSourceProvider);

  AppLocalizations get _l10n {
    final wanted =
        _container.read(localeControllerProvider) ??
        PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == wanted.languageCode,
    );
    return lookupAppLocalizations(
      supported ? Locale(wanted.languageCode) : const Locale('en'),
    );
  }

  MediaItem _folder(
    String id,
    String title, {
    Artwork? art,
    bool grid = false,
  }) => MediaItem(
    id: id,
    title: title,
    playable: false,
    artUri: _source?.artworkUri(art, size: 320),
    extras: {
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': grid
          ? _gridHint
          : _listHint,
    },
  );

  List<MediaItem> _songs(String container, List<Track> tracks) => [
    for (final t in tracks)
      MediaItem(
        id: 'play|$container|${t.id}',
        title: t.title,
        artist: t.artistLine,
        album: t.albumTitle,
        duration: t.duration,
        artUri: _source?.artworkUri(t.artwork, size: 320),
      ),
  ];

  static List<T> _list<T>(Result<List<T>> result) => result.valueOrNull ?? [];

  /// Songs inside [container], or `null` when it holds no songs.
  Future<List<Track>?> _tracksOf(String container) async {
    final source = _source;
    if (source == null) return null;
    final (kind, id) = _split(container);
    switch (kind) {
      case 'tab':
        final tab = AutoTab.values.asNameMap()[id];
        return switch (tab) {
          AutoTab.recent => _list(
            await source.tracks(
              const TrackQuery(sort: TrackSort.recentlyPlayed, limit: 50),
            ),
          ),
          AutoTab.favorites => _list(await source.favorites(limit: 200)),
          AutoTab.downloads => [
            for (final d in _container.read(downloadControllerProvider).values)
              if (d.isDone) d.track,
          ],
          AutoTab.queue =>
            _container.read(playerControllerProvider).queue.tracks,
          _ => null,
        };
      case 'album':
        return (await source.album(id)).valueOrNull?.tracks ?? [];
      case 'playlist':
        return _list(
          await source.tracks(
            TrackQuery(playlistId: id, sort: TrackSort.natural, limit: 500),
          ),
        );
      case 'top':
        return (await source.artist(id)).valueOrNull?.topTracks ?? [];
      default:
        return null;
    }
  }

  static (String, String) _split(String id) {
    final at = id.indexOf(':');
    return at < 0 ? (id, '') : (id.substring(0, at), id.substring(at + 1));
  }

  /// Entries below [parentId].
  Future<List<MediaItem>> children(String parentId) async {
    final source = _source;
    if (source == null) return const [];
    final l10n = _l10n;
    if (parentId == AudioService.browsableRootId) {
      final tabs = _container.read(autoTabsProvider);
      final capabilities = source.capabilities;
      return [
        for (final tab in AutoTab.values)
          if (tabs.contains(tab) &&
              switch (tab) {
                AutoTab.favorites => capabilities.favorites,
                AutoTab.playlists => capabilities.playlists,
                AutoTab.genres => capabilities.genres,
                _ => true,
              })
            _folder('tab:${tab.name}', autoTabLabel(l10n, tab)),
      ];
    }
    if (parentId == AudioService.recentRootId) {
      return _songs('tab:recent', await _tracksOf('tab:recent') ?? []);
    }
    final tracks = await _tracksOf(parentId);
    if (tracks != null) return _songs(parentId, tracks);
    final (kind, id) = _split(parentId);
    switch (kind) {
      case 'tab':
        return switch (AutoTab.values.asNameMap()[id]) {
          AutoTab.playlists => [
            for (final p in _list(await source.playlists()))
              _folder('playlist:${p.id}', p.name, art: p.artwork),
          ],
          AutoTab.albums => [
            for (final a in _list(
              await source.albums(const AlbumQuery(limit: 300)),
            ))
              _folder('album:${a.id}', a.title, art: a.artwork, grid: true),
          ],
          AutoTab.artists => [
            for (final a in _list(await source.artists(limit: 300)))
              _folder('artist:${a.id}', a.name, art: a.artwork),
          ],
          AutoTab.genres => [
            for (final g in _list(await source.genres()))
              _folder('genre:${g.id}', g.name, art: g.artwork),
          ],
          _ => const [],
        };
      case 'artist':
        final detail = (await source.artist(id)).valueOrNull;
        if (detail == null) return const [];
        return [
          if (detail.topTracks.isNotEmpty)
            _folder('top:$id', l10n.artistTopTracks),
          for (final a in detail.albums)
            _folder('album:${a.id}', a.title, art: a.artwork, grid: true),
        ];
      case 'genre':
        return [
          for (final a in _list(
            await source.albums(AlbumQuery(genreId: id, limit: 300)),
          ))
            _folder('album:${a.id}', a.title, art: a.artwork, grid: true),
        ];
      default:
        return const [];
    }
  }

  /// Plays the song behind [mediaId] together with its neighbours.
  Future<void> play(String mediaId) async {
    final parts = mediaId.split('|');
    if (parts.length != 3 || parts.first != 'play') return;
    final container = parts[1];
    final trackId = parts[2];
    final player = _container.read(playerControllerProvider.notifier);
    final tracks = await _tracksOf(container) ?? const <Track>[];
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index < 0) return;
    if (container == 'tab:queue') {
      await player.skipTo(index);
    } else {
      await player.playTracks(
        tracks,
        start: index,
        albumInOrder: container.startsWith('album:'),
      );
    }
  }

  /// Songs matching [query], for the search box of a media browser.
  Future<List<MediaItem>> search(String query) async {
    final result = (await _source?.search(query))?.valueOrNull;
    return result == null ? const [] : _songs('search:$query', result.tracks);
  }

  /// Voice search ("play … by …"): plays the best match. An empty [query]
  /// plays something from the library.
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final source = _source;
    if (source == null) return;
    final player = _container.read(playerControllerProvider.notifier);
    // Assistants pass what they understood as separate fields.
    final title = extras?['android.intent.extra.title'] as String?;
    final artist = extras?['android.intent.extra.artist'] as String?;
    final text = (title ?? query).trim();
    if (text.isEmpty) {
      await player.playTracks(
        _list(await source.randomTracks()),
        shuffle: true,
      );
      return;
    }
    final result = (await source.search(text)).valueOrNull;
    if (result == null) return;
    var songs = result.tracks;
    if (artist != null && artist.isNotEmpty) {
      final wanted = artist.toLowerCase();
      final byArtist = [
        for (final t in songs)
          if (t.artistLine.toLowerCase().contains(wanted)) t,
      ];
      if (byArtist.isNotEmpty) songs = byArtist;
    }
    if (songs.isNotEmpty) {
      await player.playTracks(songs);
    } else if (result.albums.isNotEmpty) {
      final album = (await source.album(result.albums.first.id)).valueOrNull;
      await player.playTracks(album?.tracks ?? const [], albumInOrder: true);
    } else if (result.artists.isNotEmpty) {
      final detail = (await source.artist(result.artists.first.id)).valueOrNull;
      await player.playTracks(detail?.topTracks ?? const []);
    } else if (result.playlists.isNotEmpty) {
      await player.playTracks(
        await _tracksOf('playlist:${result.playlists.first.id}') ?? const [],
      );
    }
  }
}
