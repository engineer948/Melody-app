# Melody

A Jellyfin-first, multi-source mobile music player (Flutter; Android first,
then iOS). The display name is changed in one place: `AppConfig.appName`.

## Status

Early development. Working today: Jellyfin sign-in, library, search,
background playback (queue, notification, sleep timer, volume
normalisation, equalizer), lyrics, playlists, Wi-Fi / mobile streaming
quality, offline downloads, Auto DJ, on-device recommendations, listening
statistics (Year in Review), Android Auto, a home screen widget, playback
on DLNA devices, sharing songs, albums, artists and playlists as story
images (Instagram, WhatsApp, …) and a built-in Tailscale node: friends join
your server with an invite code, without the Tailscale app
([docs/TAILSCALE.md](docs/TAILSCALE.md)).
For the F-Droid release, see [docs/FDROID.md](docs/FDROID.md).

## Running

Requires Flutter 3.47.9 (stable).

```bash
flutter pub get
```

```bash
flutter run
```

Checks:

```bash
flutter analyze
```

```bash
flutter test
```

Regenerate the generated code whenever you add or change a provider
(`@riverpod`), model (`@freezed`), DTO (`@JsonSerializable`) or database
table:

```bash
dart run build_runner build
```

Translation files (`lib/l10n/app_*.arb`) are compiled automatically by
`flutter pub get`.

## Sources and feature flag

Only Jellyfin is visible in the UI. Other sources are turned on at build
time:

```bash
flutter run --dart-define=ENABLED_SOURCES=jellyfin,subsonic,local
```

Valid values: `jellyfin`, `emby`, `subsonic`, `local`, `radio`
(see `lib/core/config/feature_flags.dart`). When more than one source is
enabled, the sign-in screen shows a source picker. In debug builds,
Settings → "Source test" also tries the hidden sources against an address.

| Source | Status |
|---|---|
| Jellyfin | complete |
| Emby | Built on the Jellyfin code; no Quick Connect and no server lyrics |
| Subsonic / OpenSubsonic (Navidrome, Airsonic, Gonic) | token + salt sign-in (password not stored), playlists, favorites, lyrics, scrobbling |
| Files on the device | Android MediaStore; permission is only requested when the source is added. No covers, ReplayGain or `.lrc` lyrics yet |
| Internet radio | Radio Browser; lists by genre, search, favorites, manual address (in code). No ICY "now playing" or country / language filters yet |

## Folder layout

```
lib/
  core/       config, device, errors (Result/Failure), logging, network (dio),
              router, settings, theme, utils, widgets
  domain/     models (Track, Album, Artist, ...), repositories (MusicSource,
              ServerConnector interfaces), stats (listening statistics),
              recommendation (recommendation scoring)
  data/       sources/jellyfin (API, DTOs, mapper, discovery), db (drift),
              repositories (cache, account store, LibraryRepository),
              downloads (download store and transport), history (listening
              history), dlna (SSDP discovery, AVTransport), tailnet
              (invite codes, Tailscale bridge, sign-in routing)
  player/     queue (PlayQueue), player controller, audio engines
              (just_audio, DLNA), notification / lock screen (audio_service),
              Android Auto tree, Auto DJ, history recording, widget
  features/   auth, home, library, album, artist, genre, playlist, search,
              player, share, tailnet, downloads, stats, settings, shell
  l10n/       ARB files (tr, en, az)
```

`native/tailscale/` is the Go side of the built-in Tailscale node
(`tool/build_tailscale.sh` turns it into `android/app/libs/tsbridge.aar`;
without it the feature is simply left out).

The UI (and the player) only know the `MusicSource` interface; everything
Jellyfin-specific lives under `lib/data/sources/jellyfin/`.

## Language

All documentation, code comments, commit messages, changelogs and GitHub
release notes are written in **English**. The app itself is translated
into English, Turkish and Azerbaijani (`lib/l10n/`, `fastlane/metadata/`).
See [CLAUDE.md](CLAUDE.md) for the full contributor notes.
