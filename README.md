# Melody

Jellyfin odaklı, çok kaynaklı mobil müzik çalar (Flutter; önce Android, sonra iOS).
Görünen ad tek yerden değişir: `AppConfig.appName`.

## Durum

Erken geliştirme aşamasında. Jellyfin girişi, kütüphane, arama, arka planda
çalma (kuyruk, bildirim, uyku zamanlayıcısı, ses eşitleme, ekolayzer), şarkı
sözleri, çalma listeleri ve Wi-Fi / mobil akış kalitesi çalışıyor.
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
(bkz. `lib/core/config/feature_flags.dart`).

## Klasör yapısı

```
lib/
  core/       config, device, errors (Result/Failure), logging, network (dio),
              router, settings, theme, utils, widgets
  domain/     models (Track, Album, Artist, ...), repositories (MusicSource,
              ServerConnector arayüzleri)
  data/       sources/jellyfin (API, DTO, mapper, keşif), db (drift),
              repositories (önbellek, hesap deposu, LibraryRepository)
  player/     kuyruk (PlayQueue), oynatıcı denetleyicisi, ses motoru
              (just_audio), bildirim / kilit ekranı (audio_service)
  features/   auth, home, library, album, artist, genre, playlist, search,
              player, settings, shell
  l10n/       ARB dosyaları (tr, en, az)
```

Arayüz ve (ileride) oynatıcı yalnızca `MusicSource` arayüzünü tanır; Jellyfin'e
özgü her şey `lib/data/sources/jellyfin/` altındadır.
