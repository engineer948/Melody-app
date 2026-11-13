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

## Releasing (standing instruction from the maintainer)

When a change is finished and its checks pass, **do not ask**: push it to
`main` and start the Release workflow (Actions → Release → Run workflow
on `main`), then report the release link. Bump the version first (below).

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

- `native/tailscale/` (Go): run its tests with
  `go test -race -tags "$(cat build_tags.txt)" ./...`, rebuild the library
  with `tool/build_tailscale.sh`, and after any go.mod change run
  `tool/go_licenses.sh`. Keep security properties listed in
  `docs/TAILSCALE.md` intact (no auth key storage, encrypted state, proxy
  secret, shields up, no log upload, reduced feature tags).
- F-Droid builds from source: only add dependencies with permissive
  licenses (MIT / BSD / Apache-2.0) and no Google Play Services / Firebase;
  list each new one in `THIRD_PARTY_LICENSES.md`.
