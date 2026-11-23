# Listening together

Open to everyone on the server: the headphones button on the full-screen
player (or Settings → Listening together) lists open groups, starts a new
one with the current queue, or leaves.

Code: `lib/features/social/listen_together.dart` and
`lib/data/sources/jellyfin/jellyfin_syncplay.dart`.

Built on Jellyfin SyncPlay (both users need SyncPlay access in their
Jellyfin user settings, the default). No extra server is needed. While in
a group, play, pause, seek, skip and choosing new songs go to the group;
the server's commands are carried out at the server time they name, after
measuring the clock difference to the server. When a song ends, the group
moves on together. Queue edits (play next, add to queue) stay local. The
WebSocket also works through the built-in Tailscale proxy.
