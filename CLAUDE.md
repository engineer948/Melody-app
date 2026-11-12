# Notes for Claude (and other contributors)

## Language rules

- **Write everything in the repository in English**: Markdown docs, code
  comments, commit messages, pull request titles and descriptions.
- **Release notes are English.** For every release:
  - write `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`
    in English first — `.github/workflows/release.yml` uses this file as
    the GitHub release notes;
  - then translate the same notes into `tr-TR` and `az-AZ`
    (F-Droid shows those to Turkish / Azerbaijani users).
  - Keep each changelog short (F-Droid limit: 500 characters).
- The app UI stays translated: add every new string to all three ARB files
  (`lib/l10n/app_en.arb` is the template, plus `app_tr.arb`, `app_az.arb`).
- The maintainer may write to you in Turkish; answer in Turkish, but keep
  repository content English.

## Release checklist

1. Bump `version:` in `pubspec.yaml` (`x.y.z+N`, `N` always grows).
2. Changelogs as described above (en-US first).
3. Update `docs/fdroid/io.github.engineer948.melody.yml`
   (`versionName`, `versionCode`, `commit`, `CurrentVersion*`).
4. Merge to `main`, push tag `vX.Y.Z` (see `docs/FDROID.md`).

## Signing key

- Never commit a keystore (`*.jks`, `*.keystore`) or `android/key.properties`;
  both are ignored in `.gitignore`. The release key lives only in the
  GitHub secrets `MELODY_KEYSTORE` (base64) and `MELODY_KEYSTORE_PASSWORD`.

## Before pushing

```bash
dart run build_runner build   # after changing @riverpod / @freezed / drift
flutter analyze
flutter test
```

- F-Droid builds from source: only add dependencies with permissive
  licenses (MIT / BSD / Apache-2.0) and no Google Play Services / Firebase;
  list each new one in `THIRD_PARTY_LICENSES.md`.
