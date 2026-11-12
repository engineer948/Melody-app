# Melody

Jellyfin odaklı, çok kaynaklı mobil müzik çalar (Flutter; önce Android, sonra iOS).
Görünen ad tek yerden değişir: `AppConfig.appName`.

## Durum

Erken geliştirme aşamasında. Jellyfin girişi, kütüphane, arama, arka planda
çalma (kuyruk, bildirim, uyku zamanlayıcısı, ses eşitleme, ekolayzer), şarkı
sözleri, çalma listeleri, Wi-Fi / mobil akış kalitesi, çevrimdışı indirme,
Auto DJ, cihazda hesaplanan öneriler ve dinleme istatistikleri (Yıl Özeti),
Android Auto, ana ekran widget'ı ve DLNA cihazlarında çalma var.
F-Droid yayını için: [docs/FDROID.md](docs/FDROID.md).

## Çalıştırma

Flutter 3.47.9 (stable) gerekir.

```bash
flutter pub get
```

```bash
flutter run
```

Kontroller:

```bash
flutter analyze
```

```bash
flutter test
```

Sağlayıcı (`@riverpod`), model (`@freezed`), DTO (`@JsonSerializable`) ya da
veritabanı tablosu eklediğinde / değiştirdiğinde üretilen kodu yenile:

```bash
dart run build_runner build
```

Çeviri dosyaları (`lib/l10n/app_*.arb`) `flutter pub get` ile otomatik derlenir.

## Kaynaklar ve feature flag

Arayüzde yalnızca Jellyfin görünür. Diğer kaynaklar derleme anında açılır:

```bash
flutter run --dart-define=ENABLED_SOURCES=jellyfin,subsonic,local
```

Geçerli değerler: `jellyfin`, `emby`, `subsonic`, `local`, `radio`
(bkz. `lib/core/config/feature_flags.dart`). Birden çok kaynak açıkken giriş
ekranında kaynak seçici görünür. Debug derlemesinde Ayarlar → "Kaynak testi"
gizli kaynakları da bir adrese karşı dener.

| Kaynak | Durum |
|---|---|
| Jellyfin | tam |
| Emby | Jellyfin altyapısı; Quick Connect ve sunucu sözleri yok |
| Subsonic / OpenSubsonic (Navidrome, Airsonic, Gonic) | token + salt girişi (şifre saklanmaz), çalma listeleri, favoriler, sözler, scrobble |
| Cihazdaki dosyalar | Android MediaStore; izin yalnızca kaynak eklenirken istenir. Kapaklar, ReplayGain ve `.lrc` sözler henüz yok |
| İnternet radyosu | Radio Browser; türe göre liste, arama, favoriler, elle adres (kodda). ICY "çalan şarkı" ve ülke / dil filtreleri henüz yok |

## Klasör yapısı

```
lib/
  core/       config, device, errors (Result/Failure), logging, network (dio),
              router, settings, theme, utils, widgets
  domain/     models (Track, Album, Artist, ...), repositories (MusicSource,
              ServerConnector arayüzleri), stats (istatistik), recommendation
              (öneri puanlaması)
  data/       sources/jellyfin (API, DTO, mapper, keşif), db (drift),
              repositories (önbellek, hesap deposu, LibraryRepository),
              downloads (indirme deposu ve aktarımı), history (dinleme
              geçmişi), dlna (SSDP keşfi, AVTransport)
  player/     kuyruk (PlayQueue), oynatıcı denetleyicisi, ses motorları
              (just_audio, DLNA), bildirim / kilit ekranı (audio_service),
              Android Auto ağacı, Auto DJ, geçmiş kaydı, widget
  features/   auth, home, library, album, artist, genre, playlist, search,
              player, downloads, stats, settings, shell
  l10n/       ARB dosyaları (tr, en, az)
```

Arayüz ve (ileride) oynatıcı yalnızca `MusicSource` arayüzünü tanır; Jellyfin'e
özgü her şey `lib/data/sources/jellyfin/` altındadır.
