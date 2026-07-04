#!/usr/bin/env bash
# wear bootstrap — the literal one-liner install:
#   curl -fsSL https://raw.githubusercontent.com/1ay1/wear/main/bootstrap.sh | bash
# Flags are forwarded to install.sh:
#   curl -fsSL .../bootstrap.sh | bash -s -- --theme tokyo-night
set -euo pipefail

REPO_URL="${PHOSPHOR_REPO_URL:-https://github.com/1ay1/wear.git}"
DEST="${PHOSPHOR_DIR:-$HOME/.local/share/wear}"

if command -v git >/dev/null 2>&1; then
  if [ -d "$DEST/.git" ]; then
    echo ":: Updating existing clone in $DEST"
    git -C "$DEST" pull --ff-only || echo "!! pull failed (local changes?) — installing from what's there"
  else
    echo ":: Cloning $REPO_URL → $DEST"
    git clone --depth 1 "$REPO_URL" "$DEST"
  fi
else
  # no git? grab the tarball instead
  echo ":: git not found — downloading tarball"
  command -v curl >/dev/null 2>&1 || { echo "!! need git or curl"; exit 1; }
  tmp="$(mktemp -d)"
  curl -fsSL https://github.com/1ay1/wear/archive/refs/heads/main.tar.gz | tar -xz -C "$tmp"
  mkdir -p "$DEST"
  cp -a "$tmp"/wear-main/. "$DEST/"
  rm -rf "$tmp"
fi

cd "$DEST"
chmod +x install.sh
# under `curl | bash` stdin is the pipe — hand install.sh the real terminal so
# sudo can prompt for a password
if [ -e /dev/tty ] && ( : </dev/tty ) 2>/dev/null; then
  exec ./install.sh "$@" </dev/tty
fi
exec ./install.sh "$@"
