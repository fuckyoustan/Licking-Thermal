#!/bin/sh
# build.sh — deterministic module.zip assembler (P0-5).
#
# The repo layout (src/ + other/) differs from the runtime layout the module
# scripts expect ($MODPATH/PornArchive/..., webroot/...). Until now the
# release zip was assembled by hand, so one missed rename shipped a module
# whose apply/restore scripts never exist and whose WebUI is unreachable.
# This script maps the repo into the flashable structure and fails fast when
# a required file is missing.
#
# Layout produced:
#   LickingT.zip
#   ├── META-INF/...                                          (src/META-INF)
#   ├── service.sh customize.sh uninstall.sh module.prop      (src/)
#   ├── webroot/...                                           (src/webui)
#   ├── PornArchive/{MILF,amature,anal}.sh + PornCategories.txt
#   │                                                         (other/, list.txt renamed)
#   └── toast.apk                                             (optional; repo root)
#
# Usage: sh build.sh [output.zip]     default: dist/LickingT.zip
# Also writes dist/update.json next to the zip (referenced by module.prop
# updateJson= for manager-side update checks).
set -eu

cd "$(dirname "$0")"
OUT="${1:-dist/LickingT.zip}"

VER="$(sed -n 's/^version=//p' src/module.prop)"
VCODE="$(sed -n 's/^versionCode=//p' src/module.prop)"
[ -n "$VER" ] && [ -n "$VCODE" ] || { echo "FATAL: cannot read version/versionCode from src/module.prop" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT INT HUP

mkdir -p "$STAGE/META-INF" "$STAGE/webroot" "$STAGE/PornArchive"
cp -a src/META-INF/. "$STAGE/META-INF/"
cp src/service.sh src/customize.sh src/uninstall.sh src/module.prop "$STAGE/"
cp -a src/webui/. "$STAGE/webroot/"
cp other/MILF.sh other/amature.sh other/anal.sh "$STAGE/PornArchive/"
cp other/list.txt "$STAGE/PornArchive/PornCategories.txt"

# module.prop declares banner=webroot/assets/banner.jpg and the WebUI falls
# back to assets/banner.jpg — ship the repo-root banner inside the webroot so
# the manager and the WebUI both resolve it (optional, warn when absent).
if [ -f banner.jpg ]; then
    cp banner.jpg "$STAGE/webroot/assets/banner.jpg"
else
    echo "WARN: banner.jpg not in repo root - managers will show no banner (optional component)" >&2
fi

if [ -f toast.apk ]; then
    cp toast.apk "$STAGE/toast.apk"
else
    echo "WARN: toast.apk not in repo root - Notip notifications will be skipped on install (optional component)" >&2
fi

# fail-fast sanity: every file the runtime scripts reference must be present
for f in service.sh customize.sh uninstall.sh module.prop \
         webroot/index.html webroot/assets/script.js webroot/assets/style.css \
         PornArchive/MILF.sh PornArchive/amature.sh PornArchive/anal.sh \
         PornArchive/PornCategories.txt \
         META-INF/com/google/android/update-binary; do
    [ -f "$STAGE/$f" ] || { echo "FATAL: $f missing from the assembled module" >&2; exit 1; }
done

mkdir -p "$(dirname "$OUT")"
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
( cd "$STAGE" && zip -qr9 "$OUT_ABS" . )

cat > "$(dirname "$OUT")/update.json" <<EOF
{
  "version": "$VER",
  "versionCode": $VCODE,
  "zipUrl": "https://github.com/fuckyoustan/Licking-Thermal/releases/latest/download/LickingT.zip",
  "changelog": "https://github.com/fuckyoustan/Licking-Thermal/releases/latest"
}
EOF

echo "OK: $OUT_ABS"
echo "OK: $(dirname "$OUT")/update.json (version=$VER versionCode=$VCODE)"
