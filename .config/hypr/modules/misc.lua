----------------
----  MISC  ----
----------------
local theme = dofile(os.getenv("HOME") .. "/.cache/minos/theme/hyprland.lua")

hl.config({
	misc = {
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
		disable_splash_rendering = true,
		background_color = theme.primary_container:gsub("rgba", "rgb"):gsub("ee%)", ")"),
	},
})