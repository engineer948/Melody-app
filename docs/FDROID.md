# Submitting to F-Droid

Melody is only published on F-Droid (and as APKs on GitHub releases).
F-Droid **builds the app from source on its own servers** and signs it with
its own key. So everything in the repository must be open source and no
prebuilt binaries may be downloaded.

## 1. Readiness

| Requirement | Status |
|---|---|
| Free license (MIT) | ✅ |
| No closed-source dependencies (Play Services, Firebase, Cast SDK) | ✅ checked in the built APK |
| Google's encrypted dependency report turned off (`dependenciesInfo`) | ✅ |
| Original app icon | ✅ |
| Store texts (`fastlane/metadata/android`, en / tr / az) | ✅ |
| Unsigned build option (`MELODY_UNSIGNED=1`) | ✅ |
| `pubspec.lock` in the repository | ✅ |
| SQLite built from source | ✅ official 3.54.1 source, see section 2 |
| Public repository | ❌ |
| Version tag (`v0.x.y`) and GitHub release | ✅ automatic when a tag is pushed |
| Screenshots | ❌ not added yet |

## 2. SQLite

By default `package:sqlite3` downloads a prebuilt SQLite library from
GitHub; F-Droid does not accept that. So the official SQLite source
(`third_party/sqlite/sqlite3.c`, public domain) is kept in the repository
and compiled from source during the build through the
`hooks.user_defines.sqlite3` setting in `pubspec.yaml`. To update it, see
`third_party/sqlite/README.md`.

## 3. Publishing a release (every release)

1. Bump `version:` in `pubspec.yaml` (e.g. `0.3.0+3`; the number after `+`
   must grow with every release).
2. Write `fastlane/metadata/android/<locale>/changelogs/<number>.txt` for
   every locale (`en-US`, `tr-TR`, `az-AZ`).
3. Merge into the main branch and tag it:

   ```bash
   git tag v0.3.0
   git push origin v0.3.0
   ```

When the tag arrives, GitHub Actions (`.github/workflows/release.yml`)
builds the APKs and attaches them to the GitHub release:
`melody-<version>.apk` (all CPUs) plus separate files for `arm64-v8a`,
`armeabi-v7a` and `x86_64`. The release notes are taken from
`fastlane/metadata/android/en-US/changelogs/<number>.txt`, so **GitHub
release notes are always in English**. The tag must match the version in
`pubspec.yaml`.

These APKs are signed with our own key, which is **not** in the repository.
The key lives in the GitHub repository secrets (Settings → Secrets and
variables → Actions):

- `MELODY_KEYSTORE`: the keystore file in base64 (alias `melody`)
- `MELODY_KEYSTORE_PASSWORD`: the password of the file and of the key

Keep a backup of the keystore file somewhere safe; if it is lost, new APKs
can no longer be installed over the old ones.

Once F-Droid has accepted the app, it finds new tags by itself and
publishes the new version within a few days (`AutoUpdateMode`).
The APK published on F-Droid (signed with F-Droid's own permanent key) is
downloaded from f-droid.org and attached to the same GitHub release, next
to the debug APK:

```bash
gh release upload v0.5.0 io.github.engineer948.melody_6.apk
```

## 4. First submission

There are two ways.

**Easy way: open a request.** Open a new "Request For Packaging" at
https://gitlab.com/fdroid/rfp/-/issues with a GitLab account. Give the
repository address, the license and a short description. A volunteer
prepares the recipe; this can take weeks, sometimes months.

**Fast way: submit the recipe yourself.**

1. Create a GitLab account and fork https://gitlab.com/fdroid/fdroiddata.
2. Copy `docs/fdroid/io.github.engineer948.melody.yml` to
   `metadata/io.github.engineer948.melody.yml` in your fork.
3. Optionally try it locally (Linux / Docker):

   ```bash
   fdroid readmeta
   fdroid lint io.github.engineer948.melody
   fdroid build -v -l io.github.engineer948.melody
   ```

4. Commit, push to your fork and open a merge request against fdroiddata.
   GitLab CI builds the app; if it fails, read the log, fix it and push
   again.
5. Answer the reviewers' questions. After the merge the app usually
   appears on F-Droid within a few days.

## 5. Watch out

- **The application id** is `io.github.engineer948.melody`; it cannot be
  changed after the first release (changing it means a new app).
- **The recipe is a draft.** The Flutter version (`srclibs: flutter@3.47.9`)
  and the output path have not been verified on F-Droid's build server.
- Because F-Droid signs with its own key, the GitHub APK and the APK signed
  by F-Droid cannot be updated over each other; switching from one to the
  other requires uninstalling and reinstalling the app.
