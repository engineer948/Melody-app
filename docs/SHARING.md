# Sharing with someone

A server administrator can share music with one other user of the same
Jellyfin server: songs with a note, a shared playlist, a personal greeting
and accent color, and listening together. **Nothing is shown to the other
person until they allow it**, feature by feature, and they can change their
answer at any time (Settings → "Sharing with …").

Code: `lib/features/social/`, `lib/domain/social/`,
`lib/data/sources/jellyfin/jellyfin_social.dart` and
`jellyfin_syncplay.dart`.

## How it works

No extra server is needed. Everything uses Jellyfin's own API:

| Data | Where | Written by |
|---|---|---|
| Inbox (permission request, songs, greeting + color, shared playlist, listening invitation) | recipient's display preferences `melody-inbox` (client `melody`) | the sender only; Jellyfin allows writing another user's preferences to administrators only |
| Answer (allowed features, seen, liked) | recipient's display preferences `melody-consent` | the recipient only; the administrator can read it |
| Shared playlist | a normal playlist owned by the sender, shared with the recipient with edit rights | the sender creates it, both add songs |
| Listening together | a Jellyfin SyncPlay group | both |

Each record has a single writer, so the two sides never overwrite each
other. Both apps refresh every two minutes and on pull-to-refresh.

## For the sender (administrator)

Settings → **Share with someone**:

1. Choose the person and the name they will see, then **Ask for
   permission**. Their home screen shows the request.
2. After they allow it: set the greeting (shown instead of "Good morning")
   and color at any time, create the shared playlist, start listening
   together. Songs are sent from the song menu: **Send to …**, with an
   optional note.
3. The screen shows their answer, and which songs they saw or liked.

## For the recipient

The request card on the home screen lists what would be shared. **Allow**
lets them pick features; **No, thanks** shows nothing and the sender
cannot send anything. Settings → **Sharing with …** has a switch per feature
and **Stop sharing**.

## Listening together

Built on Jellyfin SyncPlay (both users need SyncPlay access in their
Jellyfin user settings, the default). While in a group, play, pause, seek,
skip and choosing new songs go to the group; the server's commands are
carried out at the server time they name, after measuring the clock
difference to the server. When a song ends, the group moves on together.
Queue edits (play next, add to queue) stay local. The WebSocket also
works through the built-in Tailscale proxy.
