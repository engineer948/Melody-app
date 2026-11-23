# Next steps (handoff)

State on 2026-11-23: `main` = `claude/new-session-j42vuv` = `698a78c`.
Last release: 0.28.2+45. Next release: **0.29.0+46**.

Maintainer writes Azerbaijani/Turkish; answer in Azerbaijani, keep repo
content English (see CLAUDE.md). When everything below is done and checks
pass, release without asking (CLAUDE.md "Releasing").

## Done, not released yet

Removed (commits `d30b802`, `d1010d8` legal text): song letters (mixtape,
hidden-in-photo, NFC, capsule, relay, inbox), house party, star map, Music
DNA poster, "Share with someone" (social inbox, greeting, shared playlist,
send-to; listening together stays), turning record in story videos, extra
fonts (kept WorkSans, Inter, Roboto, Nunito, Lora, JetBrainsMono), iOS CI
job. Unused ARB keys removed in all three ARBs; docs updated.
Profile picture stays (maintainer chose item 11 by mistake).

## 1. F-Droid reproducible test build

- `.github/workflows/fdroid-build.yml` builds the APK twice inside
  F-Droid's `buildserver-trixie` image (`tool/fdroid_build.sh`) and
  compares. Run 3 was dispatched on `698a78c`.
- Previous failure: `gomobile: failed to find android SDK platform (API
  level: 24)`. Fix: recipe `sudo:` now runs
  `sdkmanager 'platforms;android-36'`. If it still fails, read logs
  (`get_job_logs` with `failed_only`) and fix the recipe or script.
- When both APKs are identical: wire into `release.yml` — the universal
  APK is this unsigned build signed with `apksigner` and our key; split
  APKs built as before. Our cert SHA-256:
  `28a0ba96918e8a33a3f168b94a41611439b201f380f9e907129cf0504d6342c6`.
- Scheduled check `trig_01Y2PRTXqXnHzzfospC1h3kH` already fired; delete
  it if it is still listed.

## 2. Quality presets (keep all detailed settings)

Add a preset row on top of the existing quality settings (streaming
format, data saver, download quality, save-space Opus, format), e.g.
"Data saver / Balanced / Best / Custom". Choosing a preset sets the
detailed values; changing a detail shows "Custom". Strings in all three
ARBs. Add tests.

## 3. Configurable home shelves

Settings → Home: show/hide and reorder the home shelves (Recently added,
Mix for you, Recently played, Most played, Forgotten favourites, Random
albums, Discover, and the life/month-album shelf if present). Store the
order + hidden set in settings (with backup/restore), default = today's
order, everything on. Use a `ReorderableListView` with switches. Home
screen renders shelves in that order. Tests.

## 4. Release 0.29.0+46

- `pubspec.yaml` version, `docs/fdroid/io.github.engineer948.melody.yml`
  (versionName, versionCode, commit `v0.29.0`, CurrentVersion*).
- Changelogs `fastlane/metadata/android/{en-US,tr-TR,az-AZ}/changelogs/46.txt`
  (en-US first, < 500 chars): presets, home shelves, removed features.
- Checks: `dart run build_runner build`, `flutter gen-l10n`,
  `dart format lib test`, `flutter analyze`, `flutter test --concurrency=2`.
- Push to branch and `main`, run Release workflow on `main`, report the
  link. NDK download is flaky: `rerun_failed_jobs`.

## Later

- F-Droid resubmission around 2027-02-11 (fdroiddata MR !58809 was
  closed: app younger than 3 months). Recipe already follows the
  reviewer's notes (no comments, Debian golang-go, `--enforce-lockfile`,
  reproducible build with Binaries + AllowedAPKSigningKeys).
- Maintainer will add song letters and house party back later in a
  different form.
