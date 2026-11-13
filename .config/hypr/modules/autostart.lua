-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("sleep 0.5 && ~/.config/quickshell/scripts/theme-system.sh restore-wallpaper")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("env QT_QPA_PLATFORMTHEME=qt6ct qs --no-duplicate --daemonize")
end)
