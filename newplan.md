# Next steps (handoff)

State on 2026-11-23: `main` = `claude/new-session-j42vuv` = `698a78c`.
Last release: 0.28.2+45. Released 0.29.0+46 (removals + previous-button fix). Released 0.30.0+47 (quality presets, home shelves, settings search). Next: 0.31.0+48.

Maintainer chose for 1.0: all of "Must have", Navidrome/Subsonic visible, tablet/landscape layout, and all of "Polish" (TalkBack + large font, What's new, GitHub Pages site). Done so far: presets, shelves, settings search.

Maintainer writes Azerbaijani/Turkish; answer in Azerbaijani, keep repo
content English (see CLAUDE.md). When everything below is done and checks
pass, release without asking (CLAUDE.md "Releasing").

## Done (in 0.29.0)

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
  compares. Run 3 on `698a78c` PASSED (both builds equal).
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

## 4. Release 0.30.0+47

- `pubspec.yaml` version, `docs/fdroid/io.github.engineer948.melody.yml`
  (versionName, versionCode, commit `v0.30.0`, CurrentVersion*).
- Changelogs `fastlane/metadata/android/{en-US,tr-TR,az-AZ}/changelogs/47.txt`
  (en-US first, < 500 chars): presets, home shelves.
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

## 1.0 ideas (proposed to the maintainer, not decided yet)

1.0 = "stable and ready for everyone", released together with F-Droid
inclusion (~Feb 2027).

- **Must have:** quality presets, home shelves, first-run guide (find
  server / Tailscale invite / pick a quality preset), settings search,
  F-Droid release wired into release.yml, crash-free on a 50k-song
  library (profile startup, lists, search), DB migration tests.
- **More users:** make Navidrome / Subsonic visible (code exists behind a
  flag), tablet / landscape layout, translations through Hosted Weblate
  (free for libre projects).
- **Polish:** TalkBack labels and large-font check, a short in-app
  "What's new" after updates, a simple project website (GitHub Pages).
- **Later (maintainer):** song letters and house party back in a new
  form.
