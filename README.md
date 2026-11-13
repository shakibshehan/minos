# Minos

Minos is a personal desktop environment configuration and setup project for Arch Linux, built around Hyprland and Quickshell.

This repository is the source of truth for Minos-managed configuration, theme definitions, application inventory, assets, package manifests, and installation scripts.

## Repository principles

- Mirror Minos-managed home configuration paths under the repository's `.config/` directory.
- Upload actual audited configuration files; placeholders only mark directories awaiting their files.
- Keep source theme definitions in `.config/minos/themes/`; install them to `~/.config/minos/themes/`.
- Do not commit generated theme caches or runtime output.
- Separate core dependencies, desktop applications, optional applications, and hardware-specific packages.
- Preserve user data and unrelated personal application configuration during installation.
- Include only applications and configuration intentionally managed by Minos.

## Planned layout

```text
minos/
├── README.md
├── .config/
│   ├── cava/
│   ├── fish/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── hypr/
│   │   └── modules/
│   ├── kitty/
│   ├── minos/
│   │   └── themes/
│   ├── qt6ct/
│   │   ├── colors/
│   │   └── qss/
│   ├── quickshell/
│   │   └── components/
│   ├── environment.d/
│   └── xsettingsd/
├── applications/       # Minos desktop application inventory and app-specific resources
├── themes/             # Shared theme resources not stored in an application's config
├── assets/             # Fonts, icons and images
├── wallpapers/
├── packages/           # Core, application, optional and hardware manifests
├── scripts/            # Theme and desktop helper scripts
└── installer/          # Installation and upgrade tooling
```

## Configuration mapping

Repository paths under `.config/` mirror the user's home configuration directory. For example, `.config/kitty/` maps to `~/.config/kitty/`, and `.config/minos/themes/` maps to `~/.config/minos/themes/`.

## Status

Repository structure is being prepared. Audited configuration files will be added in stages after their contents and destinations are verified.

## Scope

OBS Studio, Code - OSS, and Ryotunes are not Minos-managed configurations. Their personal settings are intentionally excluded.
