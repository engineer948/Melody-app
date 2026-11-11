# SQLite

Official public-domain SQLite amalgamation, version **3.54.1**
(`SQLITE_SOURCE_ID` 2026-10-16 14:45:20 555e07ef…), taken unmodified from
`sqlite-amalgamation-3540100.zip` on https://sqlite.org/download.html.
`shell.c` (the command-line shell) is not needed and left out.

`package:sqlite3` compiles `sqlite3.c` in its build hook
(`hooks.user_defines.sqlite3` in `pubspec.yaml`) instead of downloading
precompiled libraries, so the whole app builds from source (F-Droid).

| File | SHA-256 |
|---|---|
| `sqlite3.c` | `0c657666d819f261cc4007526ad57e1669de9949df7a8ea847aa284a2bf0ee52` |
| `sqlite3.h` | `d6c84557261893439b341d2e6c35187ae3ea24fbfd843ad94616f72d89242b8c` |
| `sqlite3ext.h` | `48963abfefb41ac329ef9d706acb5eadba952a99a748285c9ded6b5e0942721b` |

To update, download a newer `sqlite-amalgamation-*.zip` from sqlite.org,
replace the three files and update this table.
