# Sharing your server with friends through Tailscale

Melody (Android) has a Tailscale node built in. A friend pastes an
**invite code** (or picks a picture of its QR code) and Melody joins your
tailnet by itself: **no Tailscale app, no Tailscale account, no VPN
permission** on the friend's phone.

The code lives in `native/tailscale` (Go, built with gomobile into
`android/app/libs/tsbridge.aar`) and `lib/features/tailnet`.

## For the server owner

Do this once in the [Tailscale admin console](https://login.tailscale.com/admin):

1. **Access rules** (Access controls → edit policy file). Replace the
   default "allow everything" rule with these two: your own devices keep
   full access (including exit nodes), invited devices reach only
   Jellyfin:

   ```jsonc
   "tagOwners": {
     "tag:melody-friend": ["autogroup:admin"]
   },
   "acls": [
     // your own devices: everything, as before (also exit nodes)
     {"action": "accept", "src": ["autogroup:member"], "dst": ["*:*"]},
     // invited friends: only the music server
     {"action": "accept", "src": ["tag:melody-friend"], "dst": ["100.x.y.z:8096"]}
   ]
   ```

   Do not just delete the default rule without the first line: your own
   devices would lose access to each other and to the internet through
   an exit node. Tagged devices are not `autogroup:member`, so friends stay
   limited.

   Melody shows this rule, filled in with your server, on the invite
   screen (Settings → Tailscale → Create an invite code).

2. **Device approval** (Settings → Device management → "Manually approve
   new devices"), if your plan has it. A leaked code is then useless
   without your click.

For every friend:

3. Settings → Keys → **Generate auth key**: *not* reusable, short expiry
   (e.g. 1 day), *not* ephemeral, tag `tag:melody-friend`.
4. In Melody: Settings → Tailscale → **Create an invite code**. Enter the
   key and your server's Tailscale address (`100.x.y.z:8096` or
   `name.tailnet.ts.net`). Send the code (text or QR picture) to that
   friend only.
5. Create a normal (non-admin) Jellyfin user for the friend.

To cut a friend off: remove their device (`melody-xxxxxx`) in the admin
console and/or delete their Jellyfin user.

## For the friend

1. Install Melody, tap **Join with an invite code** (sign-in screen, or
   Settings → Tailscale).
2. Paste the code, or **Read QR from a picture** (the system file picker;
   no camera or storage permission).
3. If the owner uses device approval, wait until they approve.
4. Sign in to Jellyfin as usual.

Settings → Tailscale → **Leave this network** removes the device from the
tailnet, deletes its keys and signs out of that server.

## Security model

| Threat | Protection |
|---|---|
| Friend reaches other devices in the tailnet | ACL: `tag:melody-friend` may only open the Jellyfin port. Shields up: nobody can connect *to* the phone. |
| Invite code leaks | One-time key with short expiry; device approval; the app refuses API keys and OAuth secrets (`tskey-api-`, `tskey-client-`), which would give control over the tailnet. |
| Auth key stays on the phone | It is used once and never stored. If it came from the clipboard, the clipboard is cleared after joining. |
| Node keys copied off the phone | The Tailscale state is AES-256-GCM encrypted with a key from the Android Keystore-backed secure storage, in `noBackupFilesDir`. Backups and device-to-device transfer are disabled (`allowBackup="false"`, `data_extraction_rules.xml`). A copied file cannot be decrypted elsewhere. |
| Other apps on the phone use the connection | The proxy only listens on `127.0.0.1`, only answers requests whose path starts with a random 256-bit secret, and checks the `Host` header (blocks DNS rebinding from web pages). |
| Telemetry | Log upload to Tailscale is off (`TS_NO_LOGS_NO_SUPPORT`). The build leaves out log upload, port listing, posture checks, Taildrop, SSH, serve/funnel listeners, exit nodes and more (`native/tailscale/build_tags.txt`). The node advertises nothing. |
| Stolen phone | Remove the device in the admin console: its key stops working at once. Its Jellyfin session can be revoked in Jellyfin → Dashboard → Devices. |

## Limits

- Android only. The invite *creation* screen works everywhere.
- One tailnet at a time.
- Casting to DLNA devices does not work for a server reached this way
  (the renderer cannot reach the phone's private proxy).
- Installed size grows by about 20 MB (the Go library). Downloads stay
  small because native libraries are stored compressed: the arm64 APK of
  0.9.0 is ~23 MB, smaller than 0.8.0.
- Tailscale's coordination servers are a non-free network service (F-Droid
  anti-feature `NonFreeNet` for this optional feature).

## Updates

The Tailscale admin console cannot update the node inside Melody (its
"Update" button only works for the official clients, and the update
feature is left out of the build). Tailscale fixes reach users only with a
new Melody release:

- Dependabot (`.github/dependabot.yml`) opens a pull request weekly when
  the Go modules in `native/tailscale` have new versions. Merge it, run
  `tool/go_licenses.sh`, check `build_tags.txt`, release.
- The app shows "Melody X is available" on the home screen when GitHub has
  a newer release (Settings → About → "Check for new versions" turns it
  off). Watch https://tailscale.com/security-bulletins for urgent fixes.

## Development

```bash
# Go tests, including an end-to-end test against a local test tailnet
cd native/tailscale && go test -race -tags "$(cat build_tags.txt)" ./...

# Build the Android library (needs ANDROID_HOME and ANDROID_NDK_HOME)
tool/build_tailscale.sh

# After changing native/tailscale/go.mod: refresh the license list
tool/go_licenses.sh
```

Without `android/app/libs/tsbridge.aar` the app still builds; the feature
is then hidden (`android/app/src/notailscale`).

To update Tailscale: `go get tailscale.com@vX.Y.Z && go mod tidy` in
`native/tailscale`, regenerate `build_tags.txt` with
`go run tailscale.com/cmd/featuretags --min --add=netstack,nattraversal,portmapper,dns,ipnbus,health,bakedroots,tailnetlock,c2n,serve,acme`,
run the tests and `tool/go_licenses.sh`.
