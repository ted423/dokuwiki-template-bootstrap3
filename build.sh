#!/bin/sh
# =============================================================
#  DokuWiki template packaging script (Linux / macOS / Git Bash)
#
#  Usage:  ./build.sh [version]
#
#  Produces: dist/<template>-<version>.zip
#  The archive root folder is the template name taken from the
#  "base" field of template.info.txt, so it can be unpacked
#  straight into lib/tpl/ of a DokuWiki installation.
# =============================================================
set -eu

cd "$(dirname "$0")"

DIST_DIR="dist"

if [ ! -f template.info.txt ]; then
    echo "[build] ERROR: template.info.txt not found in $(pwd)" >&2
    exit 1
fi

# ---------- read template name / version from template.info.txt ----------
TPL_NAME=$(sed -n 's/^base[[:space:]=]*//p' template.info.txt | head -n 1 | tr -d '\r')
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(sed -n 's/^build[[:space:]=]*//p' template.info.txt | head -n 1 | tr -d '\r')
fi

[ -n "$TPL_NAME" ] || TPL_NAME="bootstrap3"
[ -n "$VERSION" ] || VERSION="unknown"
VERSION=$(printf '%s' "$VERSION" | tr '/' '-')

ZIP_NAME="$TPL_NAME-$VERSION.zip"
ZIP_PATH="$(pwd)/$DIST_DIR/$ZIP_NAME"

echo "[build] template : $TPL_NAME"
echo "[build] version  : $VERSION"
echo "[build] output   : $ZIP_PATH"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"

# ---------- stage a clean copy of the template ----------
STAGE_ROOT=$(mktemp -d 2>/dev/null || mktemp -d -t dokuwiki-tpl)
STAGE="$STAGE_ROOT/$TPL_NAME"
mkdir -p "$STAGE"

cleanup() {
    rm -rf "$STAGE_ROOT"
}
trap cleanup EXIT INT TERM

tar -cf - \
    --exclude='./.git' \
    --exclude='./.github' \
    --exclude='./.ai' \
    --exclude='./.vscode' \
    --exclude='./_test' \
    --exclude="./$DIST_DIR" \
    --exclude='./.editorconfig' \
    --exclude='./.travis.yml' \
    --exclude='./.gitignore' \
    --exclude='./*.zip' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='Thumbs.db' \
    . | (cd "$STAGE" && tar -xf -)

# ---------- compress ----------
if command -v zip >/dev/null 2>&1; then
    (cd "$STAGE_ROOT" && zip -r -q "$ZIP_PATH" "$TPL_NAME")
elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PY=$(command -v python3 || command -v python)
    echo "[build] zip unavailable, falling back to python zipfile"
    "$PY" - "$STAGE_ROOT" "$ZIP_PATH" "$TPL_NAME" <<'PY'
import os, sys, zipfile

stage, out, name = sys.argv[1], sys.argv[2], sys.argv[3]
root = os.path.join(stage, name)

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for base, dirs, files in os.walk(root):
        dirs.sort()
        for fn in sorted(files):
            full = os.path.join(base, fn)
            zf.write(full, os.path.relpath(full, stage))
PY
else
    echo "[build] ERROR: neither 'zip' nor 'python' is available" >&2
    exit 1
fi

if [ ! -s "$ZIP_PATH" ]; then
    echo "[build] ERROR: archive was not created" >&2
    exit 1
fi

ZIP_SIZE=$(wc -c < "$ZIP_PATH" | tr -d ' ')
echo "[build] OK  $ZIP_NAME ($ZIP_SIZE bytes)"
echo "[build] Install: unpack $ZIP_NAME into lib/tpl/ of your DokuWiki"