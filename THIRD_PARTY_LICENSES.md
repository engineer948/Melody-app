# Third-party licenses

Melody only depends on packages whose licenses allow commercial use
(MIT, BSD, Apache-2.0). GPL, AGPL and non-commercial licenses are not accepted.

The complete license texts, including transitive dependencies, are bundled
with the app and shown under **Settings → About → Open source licenses**.

## Runtime dependencies

| Package | License |
|---|---|
| Flutter SDK (`flutter`, `flutter_localizations`) | BSD-3-Clause |
| `audio_service` | MIT |
| `audio_session` | MIT |
| `cached_network_image` | MIT |
| `connectivity_plus` | BSD-3-Clause |
| `dio` | MIT |
| `drift`, `drift_flutter` (bundles SQLite, public domain) | MIT |
| `dynamic_color` | Apache-2.0 |
| `flutter_blurhash` | MIT |
| `flutter_riverpod` | MIT |
| `flutter_secure_storage` | BSD-3-Clause |
| `freezed_annotation` | MIT |
| `riverpod_annotation` | MIT |
| `go_router` | BSD-3-Clause |
| `intl` | BSD-3-Clause |
| `json_annotation` | BSD-3-Clause |
| `just_audio` (ExoPlayer / Media3 on Android: Apache-2.0) | MIT |
| `path_provider` | BSD-3-Clause |
| SQLite (`third_party/sqlite`, built from source) | Public domain |
| `meta` | BSD-3-Clause |
| `package_info_plus` | BSD-3-Clause |
| `shared_preferences` | BSD-3-Clause |

## Fonts

All bundled fonts use the SIL Open Font License 1.1, which allows
commercial use and redistribution. The license text of each font is in
`assets/fonts/<Family>.OFL.txt` and is shown on the in-app license page.
They come unmodified from the Google Fonts repository
(https://github.com/google/fonts).

Work Sans (default), Inter, Roboto, IBM Plex Sans, Source Sans 3, DM Sans,
Plus Jakarta Sans, Geist, Onest, Albert Sans, Public Sans, Montserrat,
Mulish, Nunito, Lexend, Raleway, Quicksand, Comfortaa, Exo 2,
Space Grotesk, Lora, JetBrains Mono.

## Development-only dependencies (not shipped)

| Package | License |
|---|---|
| `build_runner` | BSD-3-Clause |
| `drift_dev` | MIT |
| `freezed` | MIT |
| `json_serializable` | BSD-3-Clause |
| `riverpod_generator` | MIT |
| `mocktail` | MIT |
| `very_good_analysis` | MIT |

Update this file whenever a dependency is added to `pubspec.yaml`.
