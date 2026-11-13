local theme = dofile(os.getenv("HOME") .. "/.cache/minos/theme/hyprland.lua")

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})



hl.config({
    general = {
        gaps_in = 5,
        gaps_out = { top = 40, right = 15, bottom = 10, left = 10 },

        border_size = 0,

        col = {
            active_border = {
                colors = { theme.primary, theme.blue },
                angle = 45,
            },
            inactive_border = theme.muted_dark:gsub("ee%)", "aa)"),
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 20,
        rounding_power = 3,

        active_opacity = 1.0,
        inactive_opacity = 0.94,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.4,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 4,
            color = 0x99000000,
            color_inactive = 0x66000000,
            offset = { 0, 5 },
            scale = 1.0,
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            vibrancy = 0.15,
        },
    },

    animations = {
        enabled = true,
    },
})
