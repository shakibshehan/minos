#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR=""
while (($#)); do
  case "$1" in
    --repo-dir) REPO_DIR=${2:?Missing value for --repo-dir}; shift 2 ;;
    *) printf 'Minos: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

log() { printf '\n\033[1;36mMinos\033[0m: %s\n' "$*"; }
warn() { printf '\n\033[1;33mMinos warning\033[0m: %s\n' "$*" >&2; }
fail() { printf '\n\033[1;31mMinos error\033[0m: %s\n' "$*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -ne 0 ]] || fail "Run this installer as your regular user, not root."
[[ -n "$REPO_DIR" && -d "$REPO_DIR/.config" ]] || fail "Repository configuration directory not found."
[[ -f "$REPO_DIR/packages/official.txt" && -f "$REPO_DIR/packages/aur.txt" ]] || fail "Package manifests are missing."
[[ -r /etc/arch-release ]] || fail "This installer supports Arch Linux only."
command -v sudo >/dev/null 2>&1 || fail "sudo is required."

sudo -v || fail "Could not obtain sudo authorization."

read_packages() {
  local file=$1
  grep -Ev '^[[:space:]]*(#|$)' "$file"
}
mapfile -t official_packages < <(read_packages "$REPO_DIR/packages/official.txt")
mapfile -t aur_packages < <(read_packages "$REPO_DIR/packages/aur.txt")
( ${#official_packages[@]} ) || fail "Official package manifest is empty."

log "Updating Arch and installing Minos official-repository packages."
sudo pacman -Syu --needed --noconfirm -- "${official_packages[@]}"

intel_gpu=false
for vendor_file in /sys/class/drm/card*/device/vendor; do
  [[ -r "$vendor_file" ]] || continue
  if [[ $(<"$vendor_file") == "0x8086" ]]; then intel_gpu=true; break; fi
done
if [[ "$intel_gpu" == true ]]; then
  log "Intel graphics hardware detected; installing the Intel userspace stack used by this setup."
  sudo pacman -S --needed --noconfirm -- vulkan-intel libva-intel-driver xf86-video-intel linux-firmware-intel
else
  log "No Intel DRM device detected; skipping the Intel-specific graphics packages."
fi

if ! command -v yay >/dev/null 2>&1; then
  log "Bootstrapping yay from the AUR."
  command -v git >/dev/null 2>&1 || fail "git is required to bootstrap yay."
  aur_tmp=$(mktemp -d "${TMPDIR:-/tmp}/minos-yay.XXXXXX")
  cleanup_aur() { rm -rf -- "$aur_tmp"; }
  trap cleanup_aur EXIT INT TERM
  git clone --depth 1 https://aur.archlinux.org/yay.git "$aur_tmp/yay"
  (cd "$aur_tmp/yay" && makepkg -si --noconfirm)
  cleanup_aur
  trap - EXIT INT TERM
fi

if ( ${#aur_packages[@]} ); then
  log "Installing Minos AUR packages with yay."
  yay -S --needed --noconfirm -- "${aur_packages[@]}"
fi

config_backup=""
if [[ -d "$HOME/.config" ]]; then
  backup_dir="$HOME/.local/state/minos/backups"
  mkdir -p "$backup_dir"
  chmod 700 "$HOME/.local/state" "$HOME/.local/state/minos" "$backup_dir" 2>/dev/null || true
  stamp=$(date +%Y%m%d-%H%M%S)
  config_backup="$backup_dir/config-$stamp.tar.gz"
  log "Backing up the existing ~/.config to $config_backup"
  tar -czf "$config_backup" -C "$HOME" .config
  chmod 600 "$config_backup"
fi

log "Restoring Minos-managed configuration files."
mkdir -p "$HOME/.config"
cp -a "$REPO_DIR/.config/." "$HOME/.config/"

qt6ct_file="$HOME/.config/qt6ct/qt6ct.conf"
if [[ -f "$qt6ct_file" ]]; then
  mkdir -p "$HOME/.config/qt6ct/colors"
  if grep -q '^color_scheme_path=' "$qt6ct_file"; then
    sed -i "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/Minos.conf|" "$qt6ct_file"
  fi
fi

if [[ -d "$HOME/.config/quickshell/scripts" ]]; then
  find "$HOME/.config/quickshell/scripts" -maxdepth 1 -type f -name '*.sh' -exec chmod u+x {} +
fi

if [[ -d "$REPO_DIR/wallpapers" ]]; then
  mkdir -p "$HOME/Pictures/Wallpapers"
  cp -an "$REPO_DIR/wallpapers/." "$HOME/Pictures/Wallpapers/"
fi

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update || warn "Could not create XDG user directories automatically."
fi
if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service xdg-user-dirs.service \
      || warn "Could not enable every user-session unit; they can be enabled after logging into the desktop."
  else
    warn "No active user systemd manager was detected; user services were not enabled in this run."
  fi
fi

log "Enabling the system services used by this desktop."
sudo systemctl enable NetworkManager.service bluetooth.service firewalld.service power-profiles-daemon.service
sudo systemctl enable sddm.service

log "Minos files and packages have been installed."
printf '\nNext steps:\n'
printf '  1. Reboot the computer.\n'
printf '  2. Select the Hyprland session in SDDM.\n'
printf '  3. If anything looks wrong, restore your previous config from: %s\n' "${config_backup:-No backup was needed.}"
printf '\nNotes:\n'
printf '  - Existing unrelated files in ~/.config were left in place. Conflicting config was backed up before Minos files were merged.\n'
printf '  - Bootloader, partitioning, kernel selection, and user account settings were intentionally not changed.\n'
printf '  - Wallpapers are copied only if the repository contains wallpaper files.\n'
printf '  - OBS Studio, VSCodium, and Ryotunes are not installed or configured by Minos.\n'
