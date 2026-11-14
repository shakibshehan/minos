# Manual installation

This guide installs Minos without running the all-in-one installer. It is intended for users who want to review and execute each stage themselves.

> Run these commands from your regular user account on a minimal Arch Linux installation. Do not run the steps as root. Commands below are compatible with Fish; the AUR build command is run by `makepkg` as your normal user.

## 1. Prepare the system

Make sure your base Arch installation has a working network connection, a configured non-root user, and `sudo` access. Install the tools needed to obtain and build Minos packages:

```sh
sudo pacman -Syu --needed git base-devel
```

Clone the single Minos repository:

```sh
git clone https://github.com/shakibshehan/minos.git
cd minos
```

## 2. Install official Arch packages

Review `packages/official.txt`, then install its package list:

```sh
grep -Ev '^[[:space:]]*(#|$)' packages/official.txt | xargs -r sudo pacman -Syu --needed --
```

If a package is unavailable in your configured repositories, stop and review that package rather than skipping errors blindly.

## 3. Install AUR packages

Review `packages/aur.txt`. Minos uses `yay` to install these packages. If you do not already have `yay`, build it from the AUR as your regular user:

```sh
git clone https://aur.archlinux.org/yay.git /tmp/minos-yay
cd /tmp/minos-yay
makepkg -si
cd -
```

Then install the Minos AUR package list:

```sh
grep -Ev '^[[:space:]]*(#|$)' packages/aur.txt | xargs -r yay -S --needed --
```

Read AUR PKGBUILDs before building if you want to inspect exactly what will run on your system.

## 4. Back up and deploy the configuration

Back up your current configuration before merging Minos files:

```sh
mkdir -p ~/.local/state/minos/backups ~/.config
tar -czf ~/.local/state/minos/backups/config-manual-$(date +%Y%m%d-%H%M%S).tar.gz -C ~ .config
cp -a .config/. ~/.config/
```

This merges the tracked Minos configuration into `~/.config`; unrelated files remain, while files with matching paths are replaced. The backup lets you restore the previous configuration if needed.

The Qt6ct configuration contains a machine-specific color-scheme path in the source setup. Rewrite it for your own home directory:

```sh
mkdir -p ~/.config/qt6ct/colors
sed -i "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/Minos.conf|" ~/.config/qt6ct/qt6ct.conf
```

Make Quickshell helper scripts executable:

```sh
find ~/.config/quickshell/scripts -maxdepth 1 -type f -name '*.sh' -exec chmod u+x {} +
```

## 5. Initialize the theme

For a fresh Minos setup, seed the reference theme state and generate its runtime files:

```sh
mkdir -p ~/.local/state/minos
printf '%s\n' 'tokyo-night' > ~/.local/state/minos/current-theme
printf '%s\n' 'dark' > ~/.local/state/minos/appearance
bash ~/.config/quickshell/scripts/theme-system.sh apply tokyo-night
```

If you already have Minos state you want to keep, do not overwrite your existing `current-theme` or `appearance` files. Choose a theme from `.config/minos/themes/` and pass its filename without `.json` to the theme script.

## 6. Restore wallpapers

The repository stores wallpapers in `Pictures/Wallpapers/`. Copy them while preserving their theme subfolders:

```sh
mkdir -p ~/Pictures/Wallpapers
cp -an Pictures/Wallpapers/. ~/Pictures/Wallpapers/
```

The tracked wallpaper collection is included in `Pictures/Wallpapers/` and will be copied into `~/Pictures/Wallpapers/` by this step.

## 7. Enable services

Enable the system services used by the reference desktop:

```sh
sudo systemctl enable NetworkManager.service bluetooth.service firewalld.service power-profiles-daemon.service systemd-timesyncd.service
```

If your user systemd manager is available, enable the user services:

```sh
systemctl --user enable p11-kit-server.socket pipewire.socket pipewire-pulse.socket wireplumber.service xdg-user-dirs.service
xdg-user-dirs-update
```

For the reference Hyprland lid-switch behavior, create the logind drop-in:

```sh
sudo install -d -m 755 /etc/systemd/logind.conf.d
printf '%s\n' '[Login]' 'HandleLidSwitch=ignore' 'HandleLidSwitchExternalPower=ignore' 'HandleLidSwitchDocked=ignore' | sudo tee /etc/systemd/logind.conf.d/10-minos-lid.conf
```

## 8. Configure SDDM (optional)

Only do this if you want Minos to use the included SilentSDDM theme and you are not keeping a different display manager. The AUR package should have installed the theme under `/usr/share/sddm/themes/silent`.

```sh
sudo install -d -m 755 /etc/sddm.conf.d
printf '%s\n' '[General]' 'InputMethod=qtvirtualkeyboard' 'GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard' '' '[Theme]' 'Current=silent' | sudo tee /etc/sddm.conf.d/10-minos-silent-theme.conf
sudo systemctl set-default graphical.target
sudo systemctl enable sddm.service
```

If another display manager is already configured, do not enable SDDM or replace its configuration unless you intend to switch.

## 9. Hardware-specific note and reboot

The reference machine uses Intel graphics. If your machine also has Intel graphics, review and install the matching packages as appropriate:

```sh
sudo pacman -S --needed vulkan-intel libva-intel-driver xf86-video-intel linux-firmware-intel
```

Do not install Intel-specific graphics packages on unrelated hardware just because they appear in this note. Review your GPU and driver requirements first.

When the steps you want are complete, reboot and choose the **Hyprland** session in SDDM. Minos does not partition disks, install a bootloader, select a kernel, or create user accounts.

## What is intentionally not migrated

OBS Studio, VSCodium, and Ryotunes are excluded. Personal browser profiles, application histories, databases, logs, caches, trash, and machine-specific web-app launchers are not copied.
