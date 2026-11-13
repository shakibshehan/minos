---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "kitty"
local fileManager = "dolphin"
local browser = "brave-origin"
-- local menu = "hyprlauncher"


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local hyper = "MOD3" -- Caps Lock is remapped to a Hyper key (caps:hyper)

-- Lock and suspend the system when the laptop lid closes. logind is
-- configured to leave lid handling to Hyprland, avoiding duplicate actions.
hl.bind(
	"switch:on:Lid Switch",
	hl.dsp.exec_cmd(
		"pidof hyprlock >/dev/null || hyprlock --config ~/.config/hypr/hyprlock.conf & sleep 1; systemctl suspend"
	),
	{ locked = true }
)
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "enable" }), { locked = true })

-- Quickshell notch. The IPC target keeps compositor binds independent of UI internals.
hl.bind(hyper .. " + C", hl.dsp.exec_cmd("qs ipc call notch toggle control"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call notch toggle launcher"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs ipc call notch toggle clipboard"))
hl.bind(hyper .. " + slash", hl.dsp.exec_cmd("qs ipc call notch toggle todo"))
hl.bind(hyper .. " + N", hl.dsp.exec_cmd("qs ipc call notch toggle notes"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("qs ipc call notch toggle theme"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("qs ipc call notch toggle wallpaper"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("qs ipc call notch toggle capture"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("qs ipc call notch toggle power"))
hl.bind("ALT + V", hl.dsp.exec_cmd("qs ipc call notch toggleVolume"))

-- Direct capture shortcuts.
hl.bind("ALT + SHIFT + 1", hl.dsp.exec_cmd("qs ipc call capture screenshot full"))
hl.bind("ALT + SHIFT + 2", hl.dsp.exec_cmd("qs ipc call capture screenshot window"))
hl.bind("ALT + SHIFT + 3", hl.dsp.exec_cmd("qs ipc call capture screenshot region"))
hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd("qs ipc call capture toggleRecording"))

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- hl.bind(
-- 	mainMod .. " + M",
-- 	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
-- )
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.layout("togglesplit"))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- Toggle fullscreen

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move window with mainMod + SHIFT + hjkl
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
    "F7",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "F6",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
	"F8",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("F10", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("F9", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
