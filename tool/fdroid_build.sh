#!/usr/bin/env bash
# Builds the unsigned APK the way F-Droid's build server does: inside
# registry.gitlab.com/fdroid/fdroidserver:buildserver-trixie, as the
# vagrant user, with fdroidserver and the recipe in docs/fdroid, following
# the "fdroid build" job of fdroiddata's CI. The GitHub release signs this
# very file, so F-Droid's own build of the same commit is identical
# (reproducible build) and F-Droid publishes it with our signature.
#
# Usage (inside the container): tool/fdroid_build.sh <commit> <out dir>
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
commit="$1"
out="$2"
appid=io.github.engineer948.melody
line=$(grep -m1 '^version:' "$repo/pubspec.yaml" | awk '{print $2}')
name=${line%%+*}
code=${line##*+}

set +u
# shellcheck disable=SC1091
source /etc/profile.d/bsenv.sh
set -u
export ANDROID_HOME=/opt/android-sdk
apt-get update -q
apt-get install -y -q sudo openjdk-21-jdk-headless git curl python3-yaml
update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java
sdkmanager "platform-tools" "build-tools;31.0.0" > /dev/null

# fdroidserver at the commit fdroiddata's CI pins.
rm -rf "$fdroidserver"
git clone --shallow-since=2026-07-13 https://gitlab.com/fdroid/fdroidserver.git "$fdroidserver"
git -C "$fdroidserver" config transfer.fsckObjects true
git -C "$fdroidserver" checkout -B master a35fdfddd9c66823987a410566a6101186e39c84
export PATH="$fdroidserver:$PATH"
export PYTHONPATH="$fdroidserver:$fdroidserver/examples"
export PYTHONUNBUFFERED=true
export serverwebroot=/tmp
git -C "$home_vagrant/gradlew-fdroid" pull || true

# A small fdroiddata: the Flutter srclib and our recipe for this commit.
data=/tmp/fdroiddata
mkdir -p "$data/metadata" "$data/srclibs" "$data/tmp" "$data/build"
curl -fsSL https://gitlab.com/fdroid/fdroiddata/-/raw/master/srclibs/flutter.yml \
  -o "$data/srclibs/flutter.yml"
python3 - "$repo/docs/fdroid/$appid.yml" "$data/metadata/$appid.yml" \
  "$commit" "$name" "$code" <<'PY'
import sys
import yaml
src, dst, commit, name, code = sys.argv[1:]
m = yaml.safe_load(open(src))
m.pop('Binaries', None)  # nothing to compare with: this build makes it
build = m['Builds'][0]
build.update(versionName=name, versionCode=int(code), commit=commit)
m['Builds'] = [build]
m['CurrentVersion'] = name
m['CurrentVersionCode'] = int(code)
yaml.safe_dump(m, open(dst, 'w'), sort_keys=False, allow_unicode=True)
PY

for d in "$home_vagrant/.android" "$home_vagrant/.gradle" "$home_vagrant/metadata"; do
  mkdir -p "$d"
done
ln -sfn "$data/tmp" "$home_vagrant/tmp"
ln -sfn "$data/srclibs" "$home_vagrant/srclibs"
cp -R "$data/build" "$home_vagrant/build"
cp "$data/metadata/$appid.yml" "$home_vagrant/metadata/"
chown -R vagrant "$home_vagrant" "$data"

fdroid=(sudo --preserve-env --user vagrant
  env "PATH=$PATH" "PYTHONPATH=$PYTHONPATH" PYTHONUNBUFFERED=true
  "HOME=$home_vagrant" fdroid)
cd "$home_vagrant"
ln -sfn "$data" "$home_vagrant/fdroiddata"
"${fdroid[@]}" fetchsrclibs "$appid:$code" --verbose
rm "$home_vagrant/fdroiddata"
(unset CI GITHUB_ACTIONS; "${fdroid[@]}" build --verbose --test --refresh-scanner \
  --on-server --no-tarball "$appid:$code")

mkdir -p "$out"
cp "$data/tmp/${appid}_${code}.apk" "$out/"
sha256sum "$out/${appid}_${code}.apk"
