#!/usr/bin/env bash
# Builds android/app/libs/tsbridge.aar (the Tailscale node built into
# Melody) from native/tailscale with gomobile.
#
# Needs Go (the version in native/tailscale/go.mod is fetched
# automatically), the Android SDK with NDK (ANDROID_HOME, ANDROID_NDK_HOME)
# and network access to the Go module proxy. Without the .aar the app
# still builds; the Tailscale feature is then left out.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/native/tailscale"

# Pinned so every build of the same commit uses the same tools.
mobile_version=v0.0.0-20261011034528-197770444867
export GOTOOLCHAIN="${GOTOOLCHAIN:-auto}"
export GOFLAGS="${GOFLAGS:-} -mod=readonly"
export PATH="$(go env GOPATH)/bin:$PATH"

go install "golang.org/x/mobile/cmd/gomobile@$mobile_version" \
  "golang.org/x/mobile/cmd/gobind@$mobile_version"

mkdir -p "$root/android/app/libs"
# Reduced Tailscale: only what a client that dials one server needs
# (no Taildrop, SSH, log upload, port listing, incoming services, ...).
gomobile bind \
  -target=android/arm64,android/arm,android/amd64 \
  -androidapi 24 \
  -javapkg io.github.engineer948.melody.go \
  -tags "$(tr -d '\n' < build_tags.txt)" \
  -trimpath \
  -ldflags "-s -w -buildid=" \
  -o "$root/android/app/libs/tsbridge.aar" \
  .
rm -f "$root/android/app/libs/tsbridge-sources.jar"
ls -l "$root/android/app/libs/tsbridge.aar"
