#!/usr/bin/env bash
# Collects the licenses of every Go module linked into the Tailscale
# library (native/tailscale) into assets/licenses/go_modules.txt, which the
# app shows on its open source licenses page. Run after changing go.mod.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/native/tailscale"
out="$root/assets/licenses/go_modules.txt"
mkdir -p "$(dirname "$out")"
tags="$(tr -d '\n' < build_tags.txt)"
{
  echo "=== Go standard library ($(go env GOVERSION))"
  cat "$(go env GOROOT)/LICENSE"
  go list -deps -tags "$tags" \
    -f '{{if .Module}}{{if .Module.Dir}}{{.Module.Path}}|{{.Module.Version}}|{{.Module.Dir}}{{end}}{{end}}' . |
    sort -u |
    while IFS='|' read -r path version dir; do
      [ "$path" = "melody.local/tsbridge" ] && continue
      license=$(ls "$dir" | grep -iE '^(LICENSE|LICENCE|COPYING)(\.md|\.txt)?$' | head -1 || true)
      if [ -z "$license" ]; then
        echo "missing license: $path" >&2
        exit 1
      fi
      echo
      echo "=== $path $version"
      cat "$dir/$license"
    done
} > "$out"
# Only permissive licenses are allowed (see THIRD_PARTY_LICENSES.md).
if grep -qiE 'GNU (GENERAL|AFFERO|LESSER) PUBLIC LICENSE' "$out"; then
  echo "copyleft license found in $out" >&2
  exit 1
fi
echo "wrote $out"
