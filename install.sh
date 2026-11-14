#!/usr/bin/env bash
set -Eeuo pipefail

# Minos bootstrap. Run as a regular user, never as root.
REPO="https://github.com/shakibshehan/minos"
BRANCH="main"

fail() { printf 'Minos: ERROR: %s\n' "$*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -ne 0 ]] || fail "Do not run Minos as root. Run it from your normal user account."
command -v pacman >/dev/null 2>&1 || fail "This installer supports Arch Linux only (pacman not found)."
command -v sudo >/dev/null 2>&1 || fail "sudo is required. Install/configure sudo, then retry."

if ! command -v curl >/dev/null 2>&1; then
  printf 'Minos: installing bootstrap dependency curl...\n'
  sudo pacman -Sy --needed --noconfirm curl || fail "Could not install curl."
fi
command -v tar >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm tar

workdir=$(mktemp -d "${TMPDIR:-/tmp}/minos-bootstrap.XXXXXX")
cleanup() { rm -rf -- "$workdir"; }
trap cleanup EXIT INT TERM

archive="$workdir/minos.tar.gz"
printf 'Minos: downloading %s (%s)...\n' "$REPO" "$BRANCH"
curl --fail --location --retry 3 --output "$archive" "$REPO/archive/refs/heads/$BRANCH.tar.gz"
tar -xzf "$archive" -C "$workdir"
repo_dir="$workdir/minos-$BRANCH"
[[ -f "$repo_dir/installer/install.sh" ]] || fail "Installer files are missing from the downloaded repository."

bash "$repo_dir/installer/install.sh" --repo-dir "$repo_dir" "$@"
