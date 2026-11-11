import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_dtos.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_mapper.dart';
import 'package:melody/domain/models/media.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('maps an album', () {
    final album = JellyfinMapper.album(
      BaseItemDto.fromJson(fixture('jellyfin/album.json')),
    );
    expect(album.id, 'a1');
    expect(album.title, 'Gülümse');
    expect(album.artistLine, 'Sezen Aksu');
    expect(album.artists, const [NamedRef(id: 'ar1', name: 'Sezen Aksu')]);
    expect(album.year, 1991);
    expect(album.trackCount, 12);
    expect(album.duration, const Duration(minutes: 45));
    expect(album.genres, ['Pop', 'Türkçe']);
    expect(album.isFavorite, isTrue);
    expect(album.dateAdded, DateTime.utc(2024, 3, 1, 10, 20, 30));
    expect(
      album.artwork,
      const Artwork(
        itemId: 'a1',
        tag: 'tagA',
        blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      ),
    );
  });

  test('maps a track and falls back to the album cover', () {
    final track = JellyfinMapper.track(
      BaseItemDto.fromJson(fixture('jellyfin/track.json')),
    );
    expect(track.title, 'Hadi Bakalım');
    expect(track.artistLine, 'Sezen Aksu, Guest');
    expect(track.albumId, 'a1');
    expect(track.albumTitle, 'Gülümse');
    expect(track.trackNumber, 3);
    expect(track.discNumber, 2);
    expect(track.container, 'flac');
    expect(track.playCount, 7);
    expect(track.isFavorite, isFalse);
    expect(track.duration, const Duration(microseconds: 245123000));
    expect(track.artwork?.itemId, 'a1');
    expect(track.artwork?.tag, 'tagA');
    expect(track.artwork?.blurHash, isNotNull);
  });

  test('maps an artist and strips HTML from the biography', () {
    final artist = JellyfinMapper.artist(
      BaseItemDto.fromJson(fixture('jellyfin/artist.json')),
    );
    expect(artist.name, 'Sezen Aksu');
    expect(artist.overview, 'Türk pop müziğinin\nönemli isimlerinden.');
    expect(artist.isFavorite, isTrue);
    expect(artist.artwork?.tag, 'tagP');
  });

  test('maps loudness normalisation gain', () {
    final json = {...fixture('jellyfin/track.json'), 'NormalizationGain': -7.5};
    expect(JellyfinMapper.track(BaseItemDto.fromJson(json)).trackGainDb, -7.5);
    final album = {...fixture('jellyfin/album.json'), 'NormalizationGain': -6};
    expect(JellyfinMapper.album(BaseItemDto.fromJson(album)).gainDb, -6);
  });

  test('tolerates sparse items', () {
    final track = JellyfinMapper.track(const BaseItemDto(id: 'x'));
    expect(track.title, '');
    expect(track.artistLine, '');
    expect(track.duration, isNull);
    expect(track.artwork, isNull);
    expect(JellyfinMapper.duration(0), isNull);
  });

  test('pages skip entries without an id', () {
    final page = ItemsResultDto.fromJson({
      'Items': [
        {'Name': 'no id'},
        {'Id': 'g1', 'Name': 'Pop'},
      ],
    });
    expect(JellyfinMapper.items(page, JellyfinMapper.genre), const [
      Genre(id: 'g1', name: 'Pop'),
    ]);
    expect(
      JellyfinMapper.items(const ItemsResultDto(), JellyfinMapper.genre),
      isEmpty,
    );
  });

  test('models survive a JSON round trip', () {
    final album = JellyfinMapper.album(
      BaseItemDto.fromJson(fixture('jellyfin/album.json')),
    );
    final track = JellyfinMapper.track(
      BaseItemDto.fromJson(fixture('jellyfin/track.json')),
    );
    final detail = AlbumDetail(album: album, tracks: [track]);
    expect(AlbumDetail.fromJson(detail.toJson()), detail);
  });
}
