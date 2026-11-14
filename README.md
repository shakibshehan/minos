# Minos

Minos is a personal Arch Linux desktop restoration project built around Hyprland and Quickshell. Its goal is to reproduce the Minos desktop on a fresh Arch Linux installation with one command.

## One-command installation

From a regular user account on a minimal Arch Linux installation, run:

```bash
sudo pacman -Sy --needed curl && bash -c "$(curl -fsSL https://raw.githubusercontent.com/shakibshehan/minos/main/install.sh)"
```

Do not run the installer as root. It uses `sudo` only for system package and service operations.

## What the installer does

- Updates the Arch package database and installs Minos packages from official repositories.
- Bootstraps `yay` when needed and installs the Minos AUR package set.
- Detects Intel graphics and installs the Intel userspace graphics packages used by the reference setup.
- Backs up the existing `~/.config` before merging Minos configuration.
- Restores repository configuration under `~/.config/`.
- Rewrites the Qt6ct color-scheme path for the account running the installer.
- Makes Quickshell shell helper scripts executable.
- Copies repository wallpapers into `~/Pictures/Wallpapers` without overwriting existing files.
- Enables NetworkManager, Bluetooth, firewalld, power-profiles-daemon, and SDDM.
- Enables PipeWire/WirePlumber user units when a user systemd manager is available.

The installer intentionally does not partition disks, install a bootloader, replace the kernel, change the user's login shell, or overwrite unrelated files. Reboot after installation and select the Hyprland session in SDDM.

## Repository principles

- Paths under `.config/` mirror Minos-managed paths in the user's home directory.
- Source theme definitions live in `.config/minos/themes/`; generated runtime caches are not committed.
- Package manifests distinguish official-repository packages from AUR packages.
- Existing configuration is backed up before Minos files are merged.
- Only applications and configuration intentionally managed by Minos are included.

## Exclusions

OBS Studio, VSCodium, and Ryotunes are intentionally excluded from Minos. Their existing installations and personal settings are not removed by the installer.

## Important status note

The installer is the first implementation and still requires validation on a clean Arch installation. In particular, hardware-specific behavior, SDDM theme selection, wallpaper completeness, and the full first-boot desktop experience must be tested before calling the restoration process complete.
