# Minos

Minos is a personal desktop environment configuration and setup project for Arch Linux, built around Hyprland and Quickshell.

This repository is the source of truth for Minos-owned configuration, theme definitions, assets, package manifests, and installation scripts.

## Repository principles

- Keep source configuration in Git; do not commit generated caches.
- Keep theme definitions in `configs/minos/themes/`; the installer will place them at `~/.config/minos/themes/`.
- Keep generated theme output under the user's cache directory, not in the repository.
- Separate core dependencies, desktop applications, optional applications, and hardware-specific packages.
- Preserve user data and unrelated application configuration during installation.
- Include only applications and configuration that are intentionally part of Minos.

## Planned layout

```text
minos/
├── README.md
├── applications/       # Minos-managed application configurations
├── configs/
│   ├── hypr/           # Hyprland, Hypridle, Hyprlock and modules
│   ├── minos/
│   │   └── themes/     # Source theme definitions
│   ├── quickshell/     # Quickshell shell, components and scripts
│   └── environment.d/  # Session environment configuration
├── themes/             # GTK, Qt and other shared theme resources
├── assets/             # Fonts, icons and images
├── wallpapers/
├── packages/           # Core, application, optional and hardware manifests
├── scripts/            # Theme and desktop helper scripts
└── installer/          # Installation and upgrade tooling
```

## Status

Repository scaffolding is being established. Audited configuration files and assets will be added after their contents and destinations are verified.

## Scope

OBS Studio, Code - OSS, and Ryotunes are not Minos-managed configurations. Their personal settings are intentionally excluded.
