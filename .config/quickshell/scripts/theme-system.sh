#!/usr/bin/env bash
set -euo pipefail

theme_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/minos/themes
cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/minos/theme
state_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/minos
wallpaper_cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/minos/wallpapers

dynamic_theme_file=$cache_dir/dynamic-theme.json
theme_mode_file=$state_dir/theme-mode

# This setup deliberately uses ~/Pictures/Wallpapers. xdg-user-dir may resolve
# PICTURES to $HOME when XDG user directories have not been configured.
pictures_dir=${XDG_PICTURES_DIR:-"$HOME/Pictures"}
wallpaper_root=$pictures_dir/Wallpapers
sddm_cache_dir=${MINOS_SDDM_CACHE_DIR:-/var/cache/minos-sddm}

die() {
  printf 'theme-system: %s\n' "$*" >&2
  exit 1
}

theme_file() {
  local slug=$1
  [[ $slug =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid theme name: $slug"
  [[ -f $theme_dir/$slug.json ]] || die "unknown theme: $slug"
  printf '%s\n' "$theme_dir/$slug.json"
}


current_appearance() {
  local appearance=dark

  if [[ -s $state_dir/appearance ]]; then
    IFS= read -r appearance < "$state_dir/appearance"
  fi

  [[ $appearance == light ]] || appearance=dark
  printf '%s\n' "$appearance"
}

resolve_theme() {
  local file=$1 appearance=${2:-$(current_appearance)}

  jq -e --arg appearance "$appearance" '
    . as $theme |
    ($theme.colors[$appearance] //
      (if $theme.appearance == $appearance then $theme.colors else null end)
    ) as $colors |
    select($colors != null) |
    {
      name: $theme.name,
      slug: $theme.slug,
      appearance: $appearance,
      colors: $colors,
      applications: ($theme.applications // {})
    }
  ' "$file" || die "Unable to resolve $appearance palette"
}

hex_to_rgb() {
  local hex=${1#\#}

  printf '%d,%d,%d' \
    "$((16#${hex:0:2}))" \
    "$((16#${hex:2:2}))" \
    "$((16#${hex:4:2}))"
}
qt_argb() {
  local hex=${1#\#}
  printf '#ff%s' "${hex,,}"
}

apply_dolphin_theme() {
  local resolved_file=${1:?resolved theme required}
  local scheme_dir="$HOME/.local/share/color-schemes"
  local scheme_file="$scheme_dir/Minos.colors"
  local tmp_file

  local bg_dim
  local qt_scheme_dir="$HOME/.config/qt6ct/colors"
  local qt_scheme_file="$qt_scheme_dir/Minos.conf"
  local qt_tmp_file

  local bg0 bg1 bg2 bg3
  local foreground muted muted_dark
  local primary primary_container blue aqua
  local red yellow green purple

  bg0=$(jq -r '.colors.bg0' "$resolved_file")
  bg1=$(jq -r '.colors.bg1' "$resolved_file")
  bg2=$(jq -r '.colors.bg2' "$resolved_file")
  bg3=$(jq -r '.colors.bg3' "$resolved_file")
  foreground=$(jq -r '.colors.foreground' "$resolved_file")
  muted=$(jq -r '.colors.muted' "$resolved_file")
  muted_dark=$(jq -r '.colors.muted_dark' "$resolved_file")
  primary=$(jq -r '.colors.primary' "$resolved_file")
  primary_container=$(jq -r '.colors.primary_container' "$resolved_file")
  blue=$(jq -r '.colors.blue' "$resolved_file")
  aqua=$(jq -r '.colors.aqua' "$resolved_file")
  red=$(jq -r '.colors.red' "$resolved_file")
  yellow=$(jq -r '.colors.yellow' "$resolved_file")
  green=$(jq -r '.colors.green' "$resolved_file")
  purple=$(jq -r '.colors.purple' "$resolved_file")
  bg_dim=$(jq -r '.colors.bg_dim' "$resolved_file")

  mkdir -p "$scheme_dir"
  tmp_file=$(mktemp "$scheme_dir/.Minos.colors.XXXXXX")

  cat > "$tmp_file" <<EOF
[General]
Name=Minos

[Colors:Window]
BackgroundNormal=$(hex_to_rgb "$bg0")
BackgroundAlternate=$(hex_to_rgb "$bg1")
ForegroundNormal=$(hex_to_rgb "$foreground")
ForegroundInactive=$(hex_to_rgb "$muted_dark")
ForegroundActive=$(hex_to_rgb "$primary")
ForegroundLink=$(hex_to_rgb "$blue")
ForegroundVisited=$(hex_to_rgb "$purple")
ForegroundNegative=$(hex_to_rgb "$red")
ForegroundNeutral=$(hex_to_rgb "$yellow")
ForegroundPositive=$(hex_to_rgb "$green")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$aqua")

[Colors:View]
BackgroundNormal=$(hex_to_rgb "$bg0")
BackgroundAlternate=$(hex_to_rgb "$bg1")
ForegroundNormal=$(hex_to_rgb "$foreground")
ForegroundInactive=$(hex_to_rgb "$muted_dark")
ForegroundActive=$(hex_to_rgb "$primary")
ForegroundLink=$(hex_to_rgb "$blue")
ForegroundVisited=$(hex_to_rgb "$purple")
ForegroundNegative=$(hex_to_rgb "$red")
ForegroundNeutral=$(hex_to_rgb "$yellow")
ForegroundPositive=$(hex_to_rgb "$green")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$aqua")

[Colors:Button]
BackgroundNormal=$(hex_to_rgb "$bg1")
BackgroundAlternate=$(hex_to_rgb "$bg2")
ForegroundNormal=$(hex_to_rgb "$foreground")
ForegroundInactive=$(hex_to_rgb "$muted")
ForegroundActive=$(hex_to_rgb "$primary")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$aqua")

[Colors:Selection]
BackgroundNormal=$(hex_to_rgb "$primary_container")
BackgroundAlternate=$(hex_to_rgb "$primary")
ForegroundNormal=$(hex_to_rgb "$foreground")
ForegroundInactive=$(hex_to_rgb "$muted")

[Colors:Tooltip]
BackgroundNormal=$(hex_to_rgb "$bg1")
BackgroundAlternate=$(hex_to_rgb "$bg2")
ForegroundNormal=$(hex_to_rgb "$foreground")
ForegroundInactive=$(hex_to_rgb "$muted")

EOF

  mv -f -- "$tmp_file" "$scheme_file"

  
  mkdir -p "$qt_scheme_dir"
  qt_tmp_file=$(mktemp "$qt_scheme_dir/.Minos.conf.XXXXXX")

  local qt_active qt_disabled

  qt_active="$(
    printf '%s, ' \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$bg3")" \
      "$(qt_argb "$bg2")" \
      "$(qt_argb "$bg_dim")" \
      "$(qt_argb "$bg2")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$bg0")" \
      "$(qt_argb "$bg0")" \
      "$(qt_argb "$bg_dim")" \
      "$(qt_argb "$primary")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$blue")" \
      "$(qt_argb "$purple")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$muted")"
  )"
  qt_active=${qt_active%, }

  qt_disabled="$(
    printf '%s, ' \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$bg3")" \
      "$(qt_argb "$bg2")" \
      "$(qt_argb "$bg_dim")" \
      "$(qt_argb "$bg2")" \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$foreground")" \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$bg0")" \
      "$(qt_argb "$bg0")" \
      "$(qt_argb "$bg_dim")" \
      "$(qt_argb "$primary")" \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$blue")" \
      "$(qt_argb "$purple")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$bg1")" \
      "$(qt_argb "$muted")" \
      "$(qt_argb "$muted")"
  )"
  qt_disabled=${qt_disabled%, }

  cat > "$qt_tmp_file" <<EOF
[ColorScheme]
active_colors=$qt_active
inactive_colors=$qt_active
disabled_colors=$qt_disabled
EOF

  mv -f -- "$qt_tmp_file" "$qt_scheme_file"


  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$HOME/.config/kdeglobals" \
      --group General --key ColorScheme Minos
    kwriteconfig6 --file "$HOME/.config/dolphinrc" \
  --group UiSettings --key ColorScheme '*'
    kwriteconfig6 --file "$HOME/.config/qt6ct/qt6ct.conf" \
  --group Appearance --key color_scheme_path "$qt_scheme_file"

    kwriteconfig6 --file "$HOME/.config/qt6ct/qt6ct.conf" \
      --group Appearance --key custom_palette true

    kwriteconfig6 --file "$HOME/.config/kdeglobals" \
  --group Colors:View --key BackgroundNormal "$(hex_to_rgb "$bg0")"

    kwriteconfig6 --file "$HOME/.config/kdeglobals" \
      --group Colors:View --key BackgroundAlternate "$(hex_to_rgb "$bg1")"

    kwriteconfig6 --file "$HOME/.config/kdeglobals" \
      --group Colors:View --key ForegroundNormal "$(hex_to_rgb "$foreground")"

    kwriteconfig6 --file "$HOME/.config/kdeglobals" \
      --group Colors:View --key ForegroundInactive "$(hex_to_rgb "$muted")"
  else
    printf 'Warning: kwriteconfig6 not found; KDE scheme not activated\n' >&2
  fi
}

current_theme() {
  local slug=everforest
  if [[ -s $state_dir/current-theme ]]; then
    IFS= read -r slug < "$state_dir/current-theme"
  fi
  if [[ ! -f $theme_dir/$slug.json ]]; then
    slug=everforest
  fi
  printf '%s\n' "$slug"
}

list_themes() {
  jq -s 'map({name, slug, appearance, colors}) | sort_by(.name)' "$theme_dir"/*.json
}

wallpaper_directory() {
  if [[ -f $theme_mode_file ]] &&
     [[ $(<"$theme_mode_file") == dynamic ]]; then
    printf '%s\n' "$wallpaper_root/dynamic"
  else
    printf '%s\n' "$wallpaper_root/$(current_theme)"
  fi
}


list_wallpapers() {
  local source=${1:-current}
  local directory path first=true

  case "$source" in
    dynamic)
      directory="$wallpaper_root/dynamic"
      ;;
    current)
      directory="$wallpaper_root/$(current_theme)"
      ;;
    *)
      die "unknown wallpaper source: $source"
      ;;
  esac

  printf '['
  if [[ -d $directory ]]; then
    while IFS= read -r -d '' path; do
      $first || printf ','
      first=false
      jq -cn --arg path "$path" --arg name "$(basename "$path")" \
        '{name:$name,path:$path}'
    done < <(
      find "$directory" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
        -print0 | sort -z
    )
  fi
  printf ']\n'
}


open_wallpaper_folder() {
  local source=${1:-current}
  local directory

  case "$source" in
    dynamic)
      directory="$wallpaper_root/dynamic"
      ;;
    current)
      directory="$wallpaper_root/$(current_theme)"
      ;;
    *)
      die "unknown wallpaper source: $source"
      ;;
  esac

  mkdir -p "$directory"
  xdg-open "$directory" >/dev/null 2>&1
}

wallpaper_for_theme() {
  local slug=$1 directory saved=
  directory=$wallpaper_root/$slug
  if [[ -s $state_dir/wallpapers/$slug ]]; then
    IFS= read -r saved < "$state_dir/wallpapers/$slug"
  elif [[ -s $state_dir/current-wallpaper ]]; then
    IFS= read -r saved < "$state_dir/current-wallpaper"
  fi
  if [[ -n $saved && -f $saved && $(realpath -- "$saved") == "$(realpath -m -- "$directory")/"* ]]; then
    printf '%s\n' "$saved"
    return
  fi
  find "$directory" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) -print -quit 2>/dev/null || true
}

write_sddm_theme() {
  local file=$1 output=$2 use_wallpaper=$3
  local bg_dim bg0 bg1 bg2 bg3 foreground primary yellow red
  bg_dim=$(jq -er '.colors.bg_dim' "$file")
  bg0=$(jq -er '.colors.bg0' "$file")
  bg1=$(jq -er '.colors.bg1' "$file")
  bg2=$(jq -er '.colors.bg2' "$file")
  bg3=$(jq -er '.colors.bg3' "$file")
  foreground=$(jq -er '.colors.foreground' "$file")
  primary=$(jq -er '.colors.primary' "$file")
  yellow=$(jq -er '.colors.yellow' "$file")
  red=$(jq -er '.colors.red' "$file")

  {
    printf '[LockScreen]\nbackground = "minos-wallpaper.jpg"\nuse-background-color = %s\nbackground-color = "%s"\nblur = 28\nbrightness = -0.12\n\n' "$([[ $use_wallpaper == true ]] && printf false || printf true)" "$bg0"
    printf '[LockScreen.Clock]\ncolor = "%s"\nfont-size = 84\n\n[LockScreen.Date]\ncolor = "%s"\nfont-size = 17\n\n' "$foreground" "$foreground"
    printf '[LockScreen.Message]\ncolor = "%s"\nfont-size = 14\n\n' "$foreground"
    printf '[LoginScreen]\nbackground = "minos-wallpaper.jpg"\nuse-background-color = %s\nbackground-color = "%s"\nblur = 28\nbrightness = -0.12\n\n' "$([[ $use_wallpaper == true ]] && printf false || printf true)" "$bg0"
    printf '[LoginScreen.LoginArea.Avatar]\nactive-border-color = "%s"\ninactive-border-color = "%s"\n\n' "$primary" "$primary"
    printf '[LoginScreen.LoginArea.Username]\ncolor = "%s"\nfont-size = 19\n\n' "$foreground"
    printf '[LoginScreen.LoginArea.PasswordInput]\ncontent-color = "%s"\nbackground-color = "%s"\nborder-color = "%s"\nfont-size = 14\n\n' "$foreground" "$bg1" "$primary"
    printf '[LoginScreen.LoginArea.LoginButton]\nbackground-color = "%s"\nactive-background-color = "%s"\ncontent-color = "%s"\nactive-content-color = "%s"\nborder-color = "%s"\nfont-size = 14\n\n' "$bg1" "$primary" "$primary" "$bg_dim" "$primary"
    printf '[LoginScreen.LoginArea.Spinner]\ncolor = "%s"\nfont-size = 17\n\n' "$foreground"
    printf '[LoginScreen.LoginArea.WarningMessage]\nnormal-color = "%s"\nwarning-color = "%s"\nerror-color = "%s"\nfont-size = 13\n\n' "$foreground" "$yellow" "$red"
    printf '[LoginScreen.MenuArea.Popups]\nbackground-color = "%s"\nactive-option-background-color = "%s"\ncontent-color = "%s"\nactive-content-color = "%s"\nborder-color = "%s"\nfont-size = 13\n\n' "$bg1" "$bg2" "$foreground" "$primary" "$primary"
    local section
    for section in Session Layout Keyboard Power; do
      printf '[LoginScreen.MenuArea.%s]\nbackground-color = "%s"\ncontent-color = "%s"\nactive-content-color = "%s"\nfont-size = 12\n\n' "$section" "$primary" "$foreground" "$bg_dim"
    done
    printf '[LoginScreen.VirtualKeyboard]\nbackground-color = "%s"\nkey-content-color = "%s"\nkey-color = "%s"\nkey-active-background-color = "%s"\nselection-background-color = "%s"\nselection-content-color = "%s"\nprimary-color = "%s"\nborder-color = "%s"\n\n' "$bg1" "$foreground" "$bg2" "$primary" "$primary" "$bg_dim" "$primary" "$bg3"
    printf '[Tooltips]\ncontent-color = "%s"\nbackground-color = "%s"\nfont-size = 13\n' "$foreground" "$bg1"
  } > "$output"
}

sync_sddm_theme() {
  local file=$1 slug wallpaper config_tmp wallpaper_tmp source_key cached_source= use_wallpaper=false
  [[ -d $sddm_cache_dir && -w $sddm_cache_dir ]] || return 0
  slug=$(jq -er '.slug' "$file")
  wallpaper=$(wallpaper_for_theme "$slug")

  if [[ -n $wallpaper && -f $wallpaper ]] && command -v ffmpeg >/dev/null; then
    source_key="$(realpath -- "$wallpaper")|$(stat -c '%s:%Y' -- "$wallpaper")"
    [[ ! -s $sddm_cache_dir/wallpaper-source ]] || IFS= read -r cached_source < "$sddm_cache_dir/wallpaper-source"
    if [[ $source_key == "$cached_source" && -s $sddm_cache_dir/minos-wallpaper.jpg ]]; then
      use_wallpaper=true
    else
      wallpaper_tmp=$(mktemp "$sddm_cache_dir/.wallpaper.XXXXXX.jpg")
      if ffmpeg -loglevel error -y -i "$wallpaper" -frames:v 1 -q:v 2 "$wallpaper_tmp"; then
        mv -f -- "$wallpaper_tmp" "$sddm_cache_dir/minos-wallpaper.jpg"
        printf '%s\n' "$source_key" > "$sddm_cache_dir/wallpaper-source"
        use_wallpaper=true
      else
        rm -f -- "$wallpaper_tmp"
      fi
    fi
  fi

  config_tmp=$(mktemp "$sddm_cache_dir/.theme.XXXXXX.conf")
  write_sddm_theme "$file" "$config_tmp" "$use_wallpaper"
  mv -f -- "$config_tmp" "$sddm_cache_dir/theme.conf.user"
  chmod 644 "$sddm_cache_dir/theme.conf.user"
  [[ ! -f $sddm_cache_dir/minos-wallpaper.jpg ]] || chmod 644 "$sddm_cache_dir/minos-wallpaper.jpg"
}

sync_sddm_latest() {
  [[ -d $sddm_cache_dir && -w $sddm_cache_dir ]] || return 0
  exec 9>"$sddm_cache_dir/sync.lock"
  flock 9
  sync_sddm_theme "$(theme_file "$(current_theme)")"
}

schedule_sddm_sync() {
  [[ -d $sddm_cache_dir && -w $sddm_cache_dir ]] || return 0
  setsid -f "$0" sync-sddm-latest </dev/null >/dev/null 2>&1
}

apply_folder_icons() {
  local file=$1 color source_root icon_root theme_name size source_dir target_dir source name target
  color=$(jq -er '.applications.folder_color // "blue"' "$file")
  [[ $color =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid folder color: $color"
  source_root=/usr/share/icons/Papirus-Dark
  icon_root=${XDG_DATA_HOME:-"$HOME/.local/share"}/icons
  theme_name=minos-Papirus-Dark-$color
  [[ -d $source_root ]] || return 0

  if [[ ! -f $icon_root/$theme_name/.complete ]]; then
    mkdir -p "$icon_root/$theme_name"
    {
      printf '[Icon Theme]\nName=Minos Papirus Dark (%s)\nComment=Theme-managed Papirus folder colors\n' "$color"
      printf 'Inherits=Papirus-Dark,hicolor\nDirectories='
      local separator=
      for size in 16 22 24 32 48 64; do
        printf '%s%sx%s/places' "$separator" "$size" "$size"
        separator=,
      done
      printf '\n\n'
      for size in 16 22 24 32 48 64; do
        printf '[%sx%s/places]\nContext=Places\nSize=%s\nType=Fixed\n\n' "$size" "$size" "$size"
      done
    } > "$icon_root/$theme_name/index.theme"

    for size in 16 22 24 32 48 64; do
      source_dir=$(realpath -- "$source_root/${size}x${size}/places")
      target_dir=$icon_root/$theme_name/${size}x${size}/places
      mkdir -p "$target_dir"
      while IFS= read -r -d '' source; do
        [[ -L $source ]] && continue
        name=$(basename "$source")
        cp -- "$source" "$target_dir/$name"
        target=${name/-$color/}
        ln -sfn -- "$name" "$target_dir/$target"
      done < <(find -L "$source_dir" -maxdepth 1 -type f \( -name "folder-$color*.svg" -o -name "user-$color*.svg" \) -print0)
    done
    gtk-update-icon-cache -qf "$icon_root/$theme_name" >/dev/null 2>&1 || true
    : > "$icon_root/$theme_name/.complete"
  fi
  gsettings set org.gnome.desktop.interface icon-theme "$theme_name" >/dev/null 2>&1 || true
}


apply_kitty_theme() {
  local file=$1 tmp
  mkdir -p "$HOME/.config/kitty" "$cache_dir"
  tmp=$(mktemp "$cache_dir/.kitty.XXXXXX")

  jq -er '
    .colors as $c |
    "foreground \($c.foreground)",
    "background \($c.bg0)",
    "cursor \($c.primary)",
    "cursor_text_color \($c.bg0)",
    "selection_background \($c.bg2)",
    "selection_foreground \($c.foreground)",
    "url_color \($c.blue)",
    "color0 \($c.bg_dim)",
    "color1 \($c.red)",
    "color2 \($c.green)",
    "color3 \($c.yellow)",
    "color4 \($c.blue)",
    "color5 \($c.purple)",
    "color6 \($c.aqua)",
    "color7 \($c.foreground)",
    "color8 \($c.muted_dark)",
    "color9 \($c.red)",
    "color10 \($c.green)",
    "color11 \($c.yellow)",
    "color12 \($c.blue)",
    "color13 \($c.purple)",
    "color14 \($c.aqua)",
    "color15 \($c.foreground)"
  ' "$file" > "$tmp" || {
    rm -f "$tmp"
    die "failed to generate Kitty theme"
  }

  mv -f "$tmp" "$cache_dir/kitty.conf"
}

apply_fish_theme() {
  command -v fish >/dev/null || return 0
  fish -c 'source $argv[1]' "$cache_dir/fish.fish" >/dev/null 2>&1
}

write_generated_files() {
  local file=$1 slug name appearance
  slug=$(jq -er '.slug' "$file")
  name=$(jq -er '.name' "$file")
  appearance=$(jq -er '.appearance' "$file")
  mkdir -p "$cache_dir"

  jq -e '
    .colors as $c |
    ["bg_dim","bg0","bg1","bg2","bg3","bg4","primary_container",
     "secondary_container","foreground","muted","muted_dark","red","yellow",
     "green","primary","blue","aqua","orange","purple"] |
    all(. as $key | $c[$key] | strings | test("^#[0-9a-fA-F]{6}$"))
  ' "$file" >/dev/null || die "$slug has missing or invalid colors"

  local tmp
  tmp=$(mktemp -d "$cache_dir/.generate.XXXXXX")
  trap 'rm -rf -- "$tmp"' RETURN
  cp -- "$file" "$tmp/current.json"

  {
    printf 'return {\n  name = %s,\n  slug = %s,\n' \
      "$(jq -Rn --arg value "$name" '$value')" "$(jq -Rn --arg value "$slug" '$value')"
    while IFS=$'\t' read -r key value; do
      value=${value#\#}
      printf '  %s = "rgba(%see)",\n' "$key" "$value"
    done < <(jq -r '.colors | to_entries[] | [.key,.value] | @tsv' "$file")
    printf '}\n'
  } > "$tmp/hyprland.lua"

  {
    while IFS=$'\t' read -r key value; do
      printf '$%s = rgb(%s)\n' "$key" "${value#\#}"
    done < <(jq -r '.colors | to_entries[] | [.key,.value] | @tsv' "$file")
  } > "$tmp/hyprlock.conf"

  {
    printf '/* Generated from %s. */\n' "$slug"
    while IFS=$'\t' read -r key value; do
      printf '@define-color minos_%s %s;\n' "$key" "$value"
    done < <(jq -r '.colors | to_entries[] | [.key,.value] | @tsv' "$file")
    printf '\n@define-color accent_color @minos_primary;\n@define-color accent_bg_color @minos_primary;\n'
    printf '@define-color accent_fg_color @minos_bg_dim;\n@define-color destructive_color @minos_red;\n'
    printf '@define-color destructive_bg_color @minos_red;\n@define-color destructive_fg_color @minos_bg_dim;\n'
    printf '@define-color success_color @minos_green;\n@define-color warning_color @minos_yellow;\n@define-color error_color @minos_red;\n'
    printf '@define-color window_bg_color @minos_bg0;\n@define-color window_fg_color @minos_foreground;\n'
    printf '@define-color view_bg_color @minos_bg0;\n@define-color view_fg_color @minos_foreground;\n'
    printf '@define-color headerbar_bg_color @minos_bg1;\n@define-color headerbar_fg_color @minos_foreground;\n'
    printf '@define-color headerbar_border_color @minos_bg2;\n@define-color border_color @minos_bg2;\n'
    printf '@define-color popover_bg_color @minos_bg1;\n@define-color popover_fg_color @minos_foreground;\n'
    printf '@define-color tooltip_bg_color @minos_bg3;\n@define-color tooltip_fg_color @minos_foreground;\n'
    printf '@define-color sidebar_bg_color @minos_bg1;\n@define-color sidebar_fg_color @minos_foreground;\n'
    printf '@define-color menu_bg_color @minos_bg1;\n@define-color menu_fg_color @minos_foreground;\n'
    printf '@define-color card_bg_color @minos_bg1;\n@define-color card_fg_color @minos_foreground;\n'
  } > "$tmp/gtk.css"

  local primary foreground green aqua yellow red
  primary=$(jq -r '.colors.primary[1:]' "$file")
  foreground=$(jq -r '.colors.foreground[1:]' "$file")
  green=$(jq -r '.colors.green[1:]' "$file")
  aqua=$(jq -r '.colors.aqua[1:]' "$file")
  yellow=$(jq -r '.colors.yellow[1:]' "$file")
  red=$(jq -r '.colors.red[1:]' "$file")
  {
    printf 'set -Ux MINOS_THEME %s\n' "$slug"
    printf 'set -Ux MINOS_PRIMARY %s\n' "$primary"
    printf 'set -Ux EZA_COLORS "di=38;2;%s:fi=38;2;%s:ex=38;2;%s:ln=38;2;%s:or=38;2;%s"\n' \
      "$(printf '%d;%d;%d' "0x${green:0:2}" "0x${green:2:2}" "0x${green:4:2}")" \
      "$(printf '%d;%d;%d' "0x${foreground:0:2}" "0x${foreground:2:2}" "0x${foreground:4:2}")" \
      "$(printf '%d;%d;%d' "0x${primary:0:2}" "0x${primary:2:2}" "0x${primary:4:2}")" \
      "$(printf '%d;%d;%d' "0x${aqua:0:2}" "0x${aqua:2:2}" "0x${aqua:4:2}")" \
      "$(printf '%d;%d;%d' "0x${red:0:2}" "0x${red:2:2}" "0x${red:4:2}")"
    printf 'set -Ux MINOS_PROMPT_PATH %s\nset -Ux MINOS_PROMPT_MUTED %s\nset -Ux MINOS_PROMPT_GIT %s\nset -Ux MINOS_PROMPT_OK %s\nset -Ux MINOS_PROMPT_ERROR %s\n' \
      "$aqua" "$(jq -r '.colors.muted_dark[1:]' "$file")" "$yellow" "$green" "$red"
  } > "$tmp/fish.fish"

  {
    printf 'vim.cmd("highlight clear")\nvim.o.termguicolors = true\nvim.g.colors_name = "MINOS-%s"\n' "$slug"
    while IFS=$'\t' read -r group fg bg extra; do
      printf 'vim.api.nvim_set_hl(0, "%s", {' "$group"
      [[ $fg != - ]] && printf ' fg = "%s",' "$(jq -r ".colors.$fg" "$file")"
      [[ $bg != - ]] && printf ' bg = "%s",' "$(jq -r ".colors.$bg" "$file")"
      [[ $extra != - ]] && printf ' %s = true,' "$extra"
      printf ' })\n'
    done <<'HIGHLIGHTS'
Normal	foreground	bg0	-
NormalFloat	foreground	bg1	-
FloatBorder	primary	bg1	-
Comment	muted_dark	-	italic
Identifier	blue	-	-
Function	green	-	-
Statement	purple	-	-
Keyword	purple	-	-
Type	yellow	-	-
String	green	-	-
Number	orange	-	-
Constant	orange	-	-
Special	aqua	-	-
Error	red	-	bold
Visual	-	bg3	-
Search	bg_dim	yellow	-
CursorLine	-	bg1	-
LineNr	muted_dark	-	-
CursorLineNr	primary	-	bold
Pmenu	foreground	bg1	-
PmenuSel	bg_dim	primary	-
StatusLine	foreground	bg2	-
DiagnosticError	red	-	-
DiagnosticWarn	yellow	-	-
DiagnosticInfo	blue	-	-
DiagnosticHint	aqua	-	-
HIGHLIGHTS
  } > "$tmp/nvim.lua"

  for generated in "$tmp"/*; do
    mv -f -- "$generated" "$cache_dir/$(basename "$generated")"
  done
  trap - RETURN
  rmdir -- "$tmp"

    mkdir -p "$state_dir" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

  printf '%s\n' "$slug" > "$state_dir/current-theme"

  ln -sfn -- "$cache_dir/gtk.css" "$HOME/.config/gtk-3.0/minos-theme.css"
  ln -sfn -- "$cache_dir/gtk.css" "$HOME/.config/gtk-4.0/minos-theme.css"

  local gtk_theme gtk_dark
  if [[ $appearance == light ]]; then
    gtk_theme="Qogir-Round-Light"
    gtk_dark=0
  else
    gtk_theme="Qogir-Round-Dark"
    gtk_dark=1
  fi

  for version in 3.0 4.0; do
    local settings="$HOME/.config/gtk-$version/settings.ini"
    mkdir -p "$(dirname "$settings")"
    touch "$settings"

    if grep -q '^\[Settings\]' "$settings"; then
      if grep -q '^gtk-theme-name=' "$settings"; then
        sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$gtk_theme|" "$settings"
      else
        sed -i "/^\[Settings\]/a gtk-theme-name=$gtk_theme" "$settings"
      fi

      if grep -q '^gtk-application-prefer-dark-theme=' "$settings"; then
        sed -i "s|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=$gtk_dark|" "$settings"
      else
        sed -i "/^\[Settings\]/a gtk-application-prefer-dark-theme=$gtk_dark" "$settings"
      fi
    else
      printf '\n[Settings]\ngtk-theme-name=%s\ngtk-application-prefer-dark-theme=%s\n' \
        "$gtk_theme" "$gtk_dark" >> "$settings"
    fi
  done

  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface color-scheme "prefer-$appearance" >/dev/null 2>&1 || true
}



generate_dynamic_theme() {
  local wallpaper=${1:?wallpaper path required}
  local slug palette tmp

  [[ -f $wallpaper ]] || die "dynamic theme wallpaper does not exist: $wallpaper"
  command -v matugen >/dev/null 2>&1 || die "matugen is not installed"

  slug=$(current_theme)

  palette=$(matugen image "$wallpaper" \
    --mode dark \
    --type scheme-tonal-spot \
    --json hex \
    --source-color-index 0 \
    --dry-run) || die "Matugen palette generation failed"

  mkdir -p "$cache_dir"
  tmp=$(mktemp "$cache_dir/.dynamic-theme.XXXXXX")

  if ! jq -e --arg slug "$slug" '
    def palette($mode):
      {
        bg_dim: .colors.surface_container_lowest[$mode].color,
        bg0: .colors.surface[$mode].color,
        bg1: .colors.surface_container[$mode].color,
        bg2: .colors.surface_container_high[$mode].color,
        bg3: .colors.surface_container_highest[$mode].color,
        bg4: .colors.outline_variant[$mode].color,
        primary_container: .colors.primary_container[$mode].color,
        secondary_container: .colors.secondary_container[$mode].color,
        foreground: .colors.on_surface[$mode].color,
        muted: .colors.on_surface_variant[$mode].color,
        muted_dark: .colors.outline[$mode].color,
        red: .colors.error[$mode].color,
        yellow: .colors.tertiary[$mode].color,
        green: .colors.secondary[$mode].color,
        primary: .colors.primary[$mode].color,
        blue: .colors.tertiary[$mode].color,
        aqua: .colors.secondary[$mode].color,
        orange: .colors.tertiary[$mode].color,
        purple: .colors.primary[$mode].color
      };

    {
      name: "Dynamic Wallpaper",
      slug: $slug,
      colors: {
        dark: palette("dark"),
        light: palette("light")
      }
    }
  ' <<< "$palette" > "$tmp"; then
    rm -f -- "$tmp"
    die "Unable to build dynamic theme JSON"
  fi

  if ! jq -e '
    .colors as $colors |
    ["dark", "light"] |
    all(. as $mode |
      ["bg_dim","bg0","bg1","bg2","bg3","bg4","primary_container",
       "secondary_container","foreground","muted","muted_dark","red","yellow",
       "green","primary","blue","aqua","orange","purple"] |
      all(. as $key |
        $colors[$mode][$key] |
        strings | test("^#[0-9a-fA-F]{6}$")
      )
    )
  ' "$tmp" >/dev/null; then
    rm -f -- "$tmp"
    die "Generated dynamic theme contains invalid colors"
  fi

  mv -f -- "$tmp" "$dynamic_theme_file"
  printf 'Dynamic palettes generated: %s\n' "$dynamic_theme_file"
}



apply_dynamic_theme() {
  local wallpaper=${1:?wallpaper path required}
  local file=$dynamic_theme_file
  local resolved_file
  local slug nautilus_was_running=false

  mkdir -p "$cache_dir" "$state_dir"

  generate_dynamic_theme "$wallpaper"

  resolved_file=$(mktemp "$cache_dir/.resolved-theme.XXXXXX")
  resolve_theme "$file" > "$resolved_file"

  slug=$(current_theme)
  printf 'dynamic\n' > "$theme_mode_file"

  pgrep -x nautilus >/dev/null 2>&1 && nautilus_was_running=true

  write_generated_files "$resolved_file"
  apply_dolphin_theme "$resolved_file"
  apply_kitty_theme "$resolved_file"
  apply_fish_theme
  apply_folder_icons "$resolved_file"
  

  rm -f -- "$resolved_file"

  hyprctl reload >/dev/null 2>&1 || true
  qs ipc call theme reload >/dev/null 2>&1 || true

  schedule_sddm_sync

  if $nautilus_was_running; then
    nautilus -q >/dev/null 2>&1 || true
    setsid -f nautilus >/dev/null 2>&1 || true
  fi

  command -v notify-send >/dev/null &&
    notify-send "Dynamic theme enabled" "Colors generated from wallpaper" >/dev/null 2>&1 || true
}




set_wallpaper() {
  local path=${1:?wallpaper path required}
  local sync=${2:-true}
  local slug preset_dir dynamic_dir resolved mode=preset

  slug=$(current_theme)
  preset_dir=$(realpath -m -- "$wallpaper_root/$slug")
  dynamic_dir=$(realpath -m -- "$wallpaper_root/dynamic")

  [[ -f $path ]] || die "wallpaper does not exist: $path"

  resolved=$(realpath -- "$path")

  if [[ $resolved == "$dynamic_dir/"* ]]; then
    mode=dynamic
  elif [[ $resolved == "$preset_dir/"* ]]; then
    mode=preset
  else
    die "wallpaper must be inside $preset_dir or $dynamic_dir"
  fi

  if [[ $mode == dynamic ]]; then
    apply_dynamic_theme "$resolved"
  elif [[ -f $theme_mode_file ]] &&
       [[ $(<"$theme_mode_file") == dynamic ]]; then
    apply_theme "$slug"
  fi

  display_wallpaper "$resolved"

  mkdir -p "$state_dir"
  printf '%s\n' "$resolved" > "$state_dir/current-wallpaper"

  mkdir -p "$state_dir/wallpapers"
  printf '%s\n' "$resolved" > "$state_dir/wallpapers/$slug"

  [[ $sync != true ]] || schedule_sddm_sync
}




theme_tinted_wallpaper() {
  local source=$1
  local slug dominant key output tmp
  local tint=22

    if [[ -f $state_dir/wallpaper-tint ]] &&
     [[ $(<"$state_dir/wallpaper-tint") == disabled ]]; then
    printf '%s\n' "$source"
    return 0
  fi
  

  slug=$(current_theme)
  mkdir -p "$wallpaper_cache_dir"

  # Extract the most prominent usable color from the wallpaper.
  dominant=$(
    magick "${source}[0]" \
      -auto-orient \
      -resize '160x160!' \
      -alpha off \
      -colors 8 \
      -depth 8 \
      -format '%c' histogram:info:- |
      sed -nE 's/^[[:space:]]*([0-9]+): \(([0-9]+),([0-9]+),([0-9]+)\) (#[[:xdigit:]]{6}).*/\1 \2 \3 \4 \5/p' |
      awk '
        {
          count = $1
          r = $2
          g = $3
          b = $4
          hex = $5

          max = r
          if (g > max) max = g
          if (b > max) max = b

          min = r
          if (g < min) min = g
          if (b < min) min = b

          saturation = max == 0 ? 0 : (max - min) / max
          brightness = 0.2126*r + 0.7152*g + 0.0722*b

          if (count > fallback_count) {
            fallback_count = count
            fallback = hex
          }

          if (saturation >= 0.18 &&
              brightness >= 35 &&
              brightness <= 235 &&
              count > best_count) {
            best_count = count
            color = hex
          }
        }

        END {
          if (color != "")
            print color
          else
            print fallback
        }
      '
  )

  [[ $dominant =~ ^#[[:xdigit:]]{6}$ ]] || {
    printf 'theme-system: could not extract wallpaper color\n' >&2
    return 1
  }

  # Cache depends on the wallpaper and its extracted color.
  key=$(
    printf '%s\0%s\0%s\0%s\0' \
      "$source" \
      "$(stat -c '%Y:%s' "$source")" \
      "$dominant" \
      "$tint" |
      sha256sum | cut -d' ' -f1
  )

  output=$wallpaper_cache_dir/$slug-$key.png

  if [[ ! -s $output ]]; then
    tmp=$wallpaper_cache_dir/.$slug-$key-$$.png

    if magick "${source}[0]" \
      -auto-orient \
      -fill "$dominant" \
      -colorize "${tint}%" \
      "$tmp"; then
      mv -f -- "$tmp" "$output"
    else
      rm -f -- "$tmp"
      printf 'theme-system: wallpaper tint failed\n' >&2
      return 1
    fi
  fi

  printf '%s\n' "$output"
}

wallpaper_tint() {
  mkdir -p "$state_dir"

  case "${1:-status}" in
    on)
      printf 'enabled\n' > "$state_dir/wallpaper-tint"
      echo "Wallpaper tint enabled"
      restore_wallpaper
      ;;
    off)
      printf 'disabled\n' > "$state_dir/wallpaper-tint"
      echo "Wallpaper tint disabled"
      restore_wallpaper
      ;;
    status)
      if [[ ! -f $state_dir/wallpaper-tint ]] ||
         [[ $(<"$state_dir/wallpaper-tint") == enabled ]]; then
        echo "Wallpaper tint: enabled"
      else
        echo "Wallpaper tint: disabled"
      fi
      ;;
    *)
      die "usage: $0 tint {on|off|status}"
      ;;
  esac
}

display_wallpaper() {
  local outputs= arguments=()
  if command -v hyprctl >/dev/null && command -v jq >/dev/null; then
    outputs=$(hyprctl monitors -j 2>/dev/null | jq -r 'map(.name) | join(",")' 2>/dev/null || true)
    [[ -z $outputs ]] || arguments+=(--outputs "$outputs")
  fi
  local wallpaper=$1
  wallpaper=$(theme_tinted_wallpaper "$1") || wallpaper=$1

  local transitions=(fade wipe wave grow outer)
  local transition=${transitions[RANDOM % ${#transitions[@]}]}

  awww img "$wallpaper" "${arguments[@]}" \
    --transition-type "$transition" \
    --transition-duration 0.8 \
    --transition-fps 60
}


restore_wallpaper() {
  local slug directory saved first mode

  slug=$(current_theme)
  mode=preset

  if [[ -f $theme_mode_file ]]; then
    mode=$(<"$theme_mode_file")
  fi

  if [[ $mode == dynamic ]]; then
    directory=$wallpaper_root/dynamic
  else
    directory=$wallpaper_root/$slug
  fi

  saved=
  if [[ -s $state_dir/wallpapers/$slug ]]; then
    IFS= read -r saved < "$state_dir/wallpapers/$slug"
  elif [[ -s $state_dir/current-wallpaper ]]; then
    IFS= read -r saved < "$state_dir/current-wallpaper"
  fi

  if [[ -n $saved && -f $saved &&
        $(realpath -- "$saved") == "$(realpath -m -- "$directory")/"* ]]; then
    display_wallpaper "$saved"
    return
  fi

  first=$(find "$directory" -type f \( \
    -iname '*.jpg' -o \
    -iname '*.jpeg' -o \
    -iname '*.png' -o \
    -iname '*.webp' -o \
    -iname '*.gif' \
  \) -print -quit 2>/dev/null || true)

  if [[ -n $first ]]; then
    display_wallpaper "$first"
  else
    awww clear "$(jq -r '.colors.bg0[1:]' "$(theme_file "$slug")")" >/dev/null 2>&1 || true
  fi
}



apply_theme() {
  local slug=$1 file nautilus_was_running=false
  file=$(theme_file "$slug")

  pgrep -x nautilus >/dev/null 2>&1 && nautilus_was_running=true

  mkdir -p "$state_dir"
  printf 'preset\n' > "$theme_mode_file"

  local resolved_file
  mkdir -p "$cache_dir"
  resolved_file=$(mktemp "$cache_dir/.resolved-theme.XXXXXX")
  resolve_theme "$file" > "$resolved_file"

  write_generated_files "$resolved_file"
  apply_dolphin_theme "$resolved_file"
  apply_kitty_theme "$resolved_file"
  apply_fish_theme
  apply_folder_icons "$resolved_file"

  rm -f -- "$resolved_file"

  hyprctl reload >/dev/null 2>&1 || true
  qs ipc call theme reload >/dev/null 2>&1 || true
  restore_wallpaper || true
  schedule_sddm_sync

  if $nautilus_was_running; then
    nautilus -q >/dev/null 2>&1 || true
    setsid -f nautilus >/dev/null 2>&1 || true
  fi

  command -v notify-send >/dev/null &&
    notify-send "Theme changed" "$(jq -r .name "$file")" >/dev/null 2>&1 || true
}


set_appearance() {
  local appearance=${1:?appearance required}
  local file resolved_file mode
  local nautilus_was_running=false
  pgrep -x nautilus >/dev/null 2>&1 && nautilus_was_running=true

  [[ $appearance == dark || $appearance == light ]] ||
    die "appearance must be dark or light"

  mode=preset
  if [[ -f $theme_mode_file ]] &&
     [[ $(<"$theme_mode_file") == dynamic ]] &&
     [[ -s $dynamic_theme_file ]]; then
    mode=dynamic
  fi

  if [[ $mode == dynamic ]]; then
    file=$dynamic_theme_file
  else
    file=$(theme_file "$(current_theme)")
  fi

  mkdir -p "$cache_dir" "$state_dir"
  resolved_file=$(mktemp "$cache_dir/.resolved-theme.XXXXXX")

  if ! resolve_theme "$file" "$appearance" > "$resolved_file"; then
    rm -f -- "$resolved_file"
    die "Unable to apply $appearance appearance"
  fi

  printf '%s\n' "$appearance" > "$state_dir/appearance"

  write_generated_files "$resolved_file"
  apply_dolphin_theme "$resolved_file"
  apply_kitty_theme "$resolved_file"
  apply_fish_theme
  apply_folder_icons "$resolved_file"

  rm -f -- "$resolved_file"

  hyprctl reload >/dev/null 2>&1 || true
  qs ipc call theme reload >/dev/null 2>&1 || true

  schedule_sddm_sync
  if $nautilus_was_running; then
  nautilus -q >/dev/null 2>&1 || true
  setsid -f nautilus >/dev/null 2>&1 || true
  fi
  command -v notify-send >/dev/null &&
    notify-send "Appearance changed" "Switched to $appearance mode" >/dev/null 2>&1 || true
}


case ${1:-} in
  apply) apply_theme "${2:?theme name required}" ;;
  current) current_theme ;;
 
  current-json)
    if [[ -f $theme_mode_file ]] &&
       [[ $(<"$theme_mode_file") == dynamic ]] &&
       [[ -s $dynamic_theme_file ]]; then
      resolve_theme "$dynamic_theme_file"
    else
      resolve_theme "$(theme_file "$(current_theme)")"
    fi
    ;;

  list) list_themes ;;
  wallpapers) list_wallpapers "${2:-}" ;;
  open-wallpapers) open_wallpaper_folder "${2:-}" ;;
  wallpaper) set_wallpaper "${2:?wallpaper path required}" ;;
  restore-wallpaper) restore_wallpaper ;;
  wallpaper-current)
    [[ -s $state_dir/current-wallpaper ]] &&
      cat "$state_dir/current-wallpaper"
    ;;
  sync-sddm-latest) sync_sddm_latest ;;
  generate) write_generated_files "$(theme_file "${2:-$(current_theme)}")" ;;
  generate-dynamic) generate_dynamic_theme "${2:?wallpaper path required}" ;;
  apply-dynamic) apply_dynamic_theme "${2:?wallpaper path required}" ;;
  theme-mode)
    if [[ -f $theme_mode_file ]]; then
        cat "$theme_mode_file"
    else
        printf 'preset\n'
    fi
    ;;
  set-appearance) set_appearance "${2:?appearance required}" ;;
  appearance) current_appearance ;;
  tint) wallpaper_tint "${2:-status}" ;;
  *) die "usage: $0 {apply THEME|current|current-json|list|wallpapers [THEME]|open-wallpapers [THEME]|wallpaper PATH|restore-wallpaper|generate [THEME]}" ;;
esac
