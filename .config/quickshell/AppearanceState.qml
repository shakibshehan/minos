import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    readonly property string helper: Quickshell.shellPath("scripts/theme-system.sh")
    property var themes: []
    property var wallpapers: []
    property string currentWallpaper: ""
    property string themeMode: "preset"
    property string appearance: "dark"
    property string wallpaperSource: "current"
    property bool dynamicActivationPending: false
    property string error: ""
    property bool busy: applyProcess.running ||
                    wallpaperProcess.running ||
                    wallpaperCurrentProcess.running ||
                    dynamicApplyProcess.running ||
                    appearanceApplyProcess.running

    property bool wallpaperRefreshPending: false
    property bool tintEnabled: true

    function refreshThemes() {
        if (!themeListProcess.running)
            themeListProcess.running = true;
    }

    function refreshThemeMode() {
        if (!themeModeProcess.running)
            themeModeProcess.running = true;
    }

    function refreshWallpapers() {
        if (wallpaperListProcess.running) {
            wallpaperRefreshPending = true;
            return;
        }
        wallpaperListProcess.running = true;
    }

    function refreshAppearance() {
    if (!appearanceProcess.running)
        appearanceProcess.running = true;
}

function setAppearance(mode) {
    if (mode !== "dark" && mode !== "light")
        return;

    if (mode === appearance || busy)
        return;

    appearanceApplyProcess.exec([
        helper,
        "set-appearance",
        mode
    ]);
}

    function setWallpaperSource(source) {
        if (source !== "current" && source !== "dynamic")
            return;

        if (wallpaperSource === source)
            return;

        wallpaperSource = source;
        refreshWallpapers();
    }

    function applyTheme(slug) {
        if (!busy)
            applyProcess.exec([helper, "apply", slug]);
    }

    function applyDynamicTheme() {
        if (!busy && !wallpaperCurrentProcess.running) {
            dynamicActivationPending = true;
            wallpaperCurrentProcess.running = true;
        }
    }

    function setWallpaper(path) {
        if (!busy)
            wallpaperProcess.exec([helper, "wallpaper", path]);
    }

    function refreshCurrentWallpaper() {
        if (!wallpaperCurrentProcess.running)
            wallpaperCurrentProcess.running = true;
    }
    

    function openWallpaperFolder() {
        if (!folderProcess.running)
            folderProcess.exec([
                helper,
                "open-wallpapers",
                wallpaperSource
            ]);
    }

    function refreshTint() {
        if (!tintStatusProcess.running)
            tintStatusProcess.running = true;
    }

    function toggleTint() {
        if (!tintProcess.running && !busy)
            tintProcess.exec([
                helper,
                "tint",
                tintEnabled ? "off" : "on"
            ]);
    }

    Process {
        id: tintStatusProcess

        command: [root.helper, "tint", "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.tintEnabled =
                    text.trim() === "Wallpaper tint: enabled";
            }
        }
    }

    Process {
        id: tintProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.refreshTint();
            } else {
                root.error = "Wallpaper tint change failed";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = text.trim();
            }
        }
    }

    Component.onCompleted: {
        refreshThemes();
        refreshWallpapers();
        refreshTint();
        themeModeProcess.running = true;
        refreshAppearance();
    }

    Process {
        id: themeListProcess
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text || "[]");
                    root.error = "";
                } catch (error) {
                    root.error = "Unable to read themes";
                }
            }
        }
    }

    Process {
        id: wallpaperListProcess
        command: [root.helper, "wallpapers", root.wallpaperSource]
        onExited: {
            if (root.wallpaperRefreshPending) {
                root.wallpaperRefreshPending = false;
                wallpaperListProcess.running = true;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.wallpapers = JSON.parse(text || "[]");
                    root.error = "";
                } catch (error) {
                    root.error = "Unable to read wallpapers";
                }
            }
        }
    }

    Process {
        id: applyProcess
        onExited: (exitCode) => {
            if (exitCode === 0) {
                Theme.reload();
                root.refreshThemeMode();
                root.refreshWallpapers();
            } else {
                root.error = "Theme switch failed";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
    }

    Process {
        id: wallpaperProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                Theme.reload();
                root.refreshThemeMode();
                root.refreshCurrentWallpaper();
                root.refreshWallpapers();
            } else {
                root.error = "Wallpaper switch failed";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = text.trim();
            }
        }
    }

    Process {
        id: folderProcess
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
    }
    
    Process {
        id: wallpaperCurrentProcess
        command: [root.helper, "wallpaper-current"]

        onExited: (exitCode) => {
            if (exitCode !== 0 && root.dynamicActivationPending) {
                root.dynamicActivationPending = false;
                root.error = "Unable to retrieve current wallpaper";
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();

                if (path) {
                    root.currentWallpaper = path;

                    if (root.dynamicActivationPending) {
                        root.dynamicActivationPending = false;

                        root.dynamicApplyProcess.exec([
                            root.helper,
                            "apply-dynamic",
                            path
                        ]);
                    }
                } else if (root.dynamicActivationPending) {
                    root.dynamicActivationPending = false;
                    root.error = "No current wallpaper found";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = text.trim();
            }
        }
    }

    Process {
        id: dynamicApplyProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                Theme.reload();
                root.refreshWallpapers();
                root.refreshThemeMode();
                ShellState.close();
            } else {
                root.error = "Dynamic theme activation failed";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = text.trim();
            }
        }
    }

    Process {
        id: themeModeProcess
        command: [root.helper, "theme-mode"]

        stdout: StdioCollector {
            onStreamFinished: {
                const mode = text.trim();
                root.themeMode = mode === "dynamic" ? "dynamic" : "preset";
            }
        }
    }

    Process {
        id: appearanceProcess

        command: [root.helper, "appearance"]

        stdout: StdioCollector {
            onStreamFinished: {
                const mode = text.trim();
                root.appearance = mode === "light" ? "light" : "dark";
            }
        }
    }

    Process {
        id: appearanceApplyProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                Theme.reload();
                root.refreshAppearance();
            } else {
                root.error = "Appearance change failed";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = text.trim();
            }
        }
    }
}
