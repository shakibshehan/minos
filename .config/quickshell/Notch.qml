import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.panels
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick.Effects  // Qt 6.5+ (QuickShell ships with this)

PanelWindow {
    id: window

    readonly property int contentPadding: 14
    readonly property int collapsedHeight: 28
    readonly property int cornerWing: 16
    readonly property int canvasWidth: 900
    readonly property int canvasHeight: 600
    readonly property int requestedTopPadding: ShellState.panel === "launcher" ? 10 : contentPadding
    readonly property int requestedBottomPadding: ShellState.panel === "launcher" ? 4 : contentPadding
    readonly property int displayedTopPadding: displayedPanel === "launcher" ? 10 : contentPadding
    readonly property int displayedBottomPadding: displayedPanel === "launcher" ? 4 : contentPadding

    


    // SYSTEM MONITOR
    property int cpuUsage: 0
    property int ramUsage: 0
    property int cpuTemperature: 0

    // MUSIC PLAYER
    readonly property var musicPlayer: {
        const players = Mpris.players.values;

        for (const player of players) {
            if (player.isPlaying)
                return player;
        }

        return players.length > 0 ? players[0] : null;
    }

    // CAVA VISUALIZER
    property var cavaBars: Array(24).fill(0)

    // Independent hover state
    property bool hovered: false

    readonly property bool visualExpanded: hovered || ShellState.expanded

    // Notch dimensions
    readonly property real targetVisualWidth: ShellState.expanded
        ? ShellState.targetWidth + cornerWing * 2
        : hovered ? 600 : 220


    // NETWORK
    readonly property bool networkConnected: {
        for (const device of Networking.devices.values) {
            if (device.connected)
                return true;
        }
        return false;
    }

    readonly property real wifiSignalStrength: {
        for (const device of Networking.devices.values) {
            if (!device.connected)
                continue;

            for (const network of device.networks.values) {
                if (network.connected)
                    return Math.round(network.signalStrength * 100);
            }
        }

        return 0;
    }
    // BATTERY
    readonly property var battery: {
        for (const device of UPower.devices.values) {
            if (device.isLaptopBattery)
                return device;
        }
        return UPower.displayDevice;
    }

    readonly property real targetVisualHeight: ShellState.expanded
            ? panelContentHeight + requestedTopPadding + requestedBottomPadding
            : hovered ? 100: collapsedHeight
        readonly property real panelContentHeight: {
        if (!ShellState.expanded)
            return 0;

    if (ShellState.panel === "launcher" || ShellState.panel === "wallpaper")
        return requestedPanel ? requestedPanel.implicitHeight : 0;

        return Math.max(
            ShellState.panelHeights[ShellState.panel] || 0,
            requestedPanel ? requestedPanel.implicitHeight : 0
        );
    }
    property bool contentRevealed: false
    property bool clockRevealed: true
    property string displayedPanel: "control"
    readonly property Item activePanel: {
        const panels = {
            "control": controlPanel,
            "launcher": launcherPanel,
            "clipboard": clipboardPanel,
            "todo": todoPanel,
            "notes": quickNotesPanel,
            "theme": themePanel,
            "wallpaper": wallpaperPanel,
            "capture": capturePanel,
            "power": powerPanel
        };
        return panels[displayedPanel] || null;
    }
    readonly property Item requestedPanel: {
        const panels = {
            "control": controlPanel,
            "launcher": launcherPanel,
            "clipboard": clipboardPanel,
            "todo": todoPanel,
            "notes": quickNotesPanel,
            "theme": themePanel,
            "wallpaper": wallpaperPanel,
            "capture": capturePanel,
            "power": powerPanel
        };
        return panels[ShellState.panel] || null;
    }

    function focusInitialControl() {
        if (!ShellState.expanded || !activePanel)
            return ;

        if (typeof activePanel.takeInitialFocus === "function") {
            activePanel.takeInitialFocus();
            return ;
        }
        activePanel.forceActiveFocus(Qt.TabFocusReason);
        const firstControl = activePanel.nextItemInFocusChain(true);
        if (firstControl && firstControl !== activePanel)
            firstControl.forceActiveFocus(Qt.TabFocusReason);

    }

    function moveFocus(forward) {
        const current = window.activeFocusItem;
        if (!current) {
            focusInitialControl();
            return ;
        }
        const target = current.nextItemInFocusChain(forward);
        if (target)
            target.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);

    }

    margins.left: Math.round((screen.width - canvasWidth) / 2)
    implicitWidth: canvasWidth
    implicitHeight: canvasHeight
    color: "transparent"
    aboveWindows: true
    focusable: ShellState.expanded
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    Connections {
        function onPanelChanged() {
            window.contentRevealed = ShellState.expanded;
            if (ShellState.expanded) {
                clockRevealTimer.stop();
                window.clockRevealed = false;
                window.displayedPanel = ShellState.panel;
                focusTimer.restart();
            } else {
                clockRevealTimer.restart();
            }
        }

        target: ShellState
    }

    FocusScope {
        id: notchSurface

        y: window.floatOffset
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.targetVisualWidth
        height: window.targetVisualHeight
        focus: true

        Behavior on y {
            NumberAnimation {
                duration: 320
                easing.type: Easing.InOutCubic
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                ShellState.close();
                event.accepted = true;
                return ;
            }
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                window.moveFocus(true);
                event.accepted = true;
                return ;
            }
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                window.moveFocus(false);
                event.accepted = true;
                return ;
            }
        }

        HoverHandler {
            enabled: !ShellState.expanded

            onHoveredChanged: {
                window.hovered = hovered;
            }
        }

        Rectangle {
            id: notchBody

            x: window.cornerWing
            y: 4
            width: parent.width - window.cornerWing * 2
            height: parent.height + 2
            radius: Theme.radius
            color: Theme.bg0
        }

        MultiEffect {
            source: notchBody
            anchors.fill: notchBody

            shadowEnabled: true
            shadowColor: "#99000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 5
            shadowHorizontalOffset: 0
            shadowOpacity: 0.65
        }

    

        Row {
            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            opacity: ShellState.expanded ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

            height: window.collapsedHeight
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            // LEFT: WORKSPACES
            Item {
                y: 4
                width: parent.width * 0.30
                height: parent.height

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: window.hovered && !ShellState.expanded ? 40 : 0
                    height: parent.height
                    spacing: window.hovered && !ShellState.expanded ? 12 : 5

                    Repeater {
                       model: window.hovered && !ShellState.expanded ? 6 : 5

                        delegate: Item {
                            required property int index

                            width: 5
                            height: parent.height

                            Rectangle {
                                anchors.centerIn: parent

                                width: Hyprland.focusedWorkspace?.id === index + 1
                                    ? (window.hovered && !ShellState.expanded ? 14 : 7)
                                    : (window.hovered && !ShellState.expanded ? 10 : 7)

                                height: Hyprland.focusedWorkspace?.id === index + 1
                                    ? (window.hovered && !ShellState.expanded ? 26 : 18)
                                    : (window.hovered && !ShellState.expanded ? 20 : 14)

                                radius: 3

                                color: Hyprland.focusedWorkspace?.id === index + 1
                                    ? Theme.primary
                                    : Theme.muted

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                    }
                }
            }

            // CENTER: CLOCK
            ShellText {
                y: 4
                width: parent.width * 0.36
                height: parent.height *  1.1

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Row {
                    spacing: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                

                    Text {
                        text: Qt.formatDateTime(clock.date, "HH")
                        color: Theme.foreground
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Text {
                        text: ":"
                        color: Theme.aqua
                        font.pixelSize: 16
                        font.weight: Font.Bold

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0
                                duration: 1200
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 1
                                duration: 1200
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "mm")
                        color: Theme.foreground
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                }

                color: Theme.foreground
                font.family: "JetBrains Mono"
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            // RIGHT: NETWORK + BATTERY
            Item {
                y: 4
                width: parent.width * 0.34
                height: parent.height

                opacity: window.hovered && !ShellState.expanded ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    // WIFI SIGNAL BARS
                    Item {
                        width: 17
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            Repeater {
                                model: 4

                                delegate: Item {
                                    required property int index

                                    width: 5
                                    height: 16

                                    Rectangle {
                                        anchors.bottom: parent.bottom

                                        width: parent.width
                                        height: 4 + index * 3
                                        radius: 3

                                        color: Theme.primary

                                        opacity: window.networkConnected
                                            && window.wifiSignalStrength >= (index + 1) * 25
                                            ? 1 : 0.25
                                    }
                                }
                            }
                        }
                    }
                         //gaph between network and bettary
                        Item {
                            width: 0.1
                            height: 0.1
                        }

                    // BATTERY
                    Item {
                        width: 24
                        height: 15
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            x: 0
                            y: 2
                            width: 24
                            height: 13
                            radius: 3
                            color: "transparent"
                            border.width: 1.4
                            border.color: Theme.muted
                            

                            Rectangle {
                                x: 2
                                y: 2
                                width: Math.max(0, Math.min(1, window.battery
                                    ? window.battery.percentage : 0)) * 20
                                height: 9.5
                                radius: 1
                                color: Theme.muted
                                
                            }
                        }

                        Rectangle {
                            x: 22
                            y: 6
                            width: 6
                            height: 5
                            radius: 1
                            color: Theme.muted
                        }

                        Text {
                            anchors.centerIn: parent
                            text: UPower.onBattery ? "" : "ϟ"
                            color: theme.bg4
                            font.pixelSize: 9
                            font.bold: true
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
        // EXPANDED CLOCK AND DATE
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12
            width: window.visualExpanded ? 150 : 0
            height: window.visualExpanded ? 28 : 0

            radius: 7
            color: Theme.bg2
            opacity: window.visualExpanded && !ShellState.expanded ? 1 : 0

            visible: opacity > 0

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: Qt.formatDateTime(clock.date, "HH")
                        color: Theme.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }

                    Text {
                        text: ":"
                        color: Theme.aqua
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.weight: Font.Bold

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 1
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "mm")
                        color: Theme.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: Qt.formatDateTime(clock.date, "ddd, MMM d")
                    color: Theme.muted
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }
            }
        }

        Text {
            anchors.left: notchBody.left
            anchors.leftMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 23

            text: "Work Spaces"
            color: Theme.primary
            font.pixelSize: 10
            font.family: "JetBrains Mono Nerd Font"
            font.weight: Font.DemiBold

            opacity: window.hovered && !ShellState.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
        }

        Text {
            anchors.right: notchBody.right
            anchors.rightMargin: 18
            anchors.top: parent.top
            anchors.topMargin: 22

            text: "System Monitor"
            color: Theme.primary
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.family: "JetBrains Mono Nerd Font"

            opacity: window.hovered && !ShellState.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
        }

        // SYSTEM MONITOR CARD

        Row {
            anchors.right: notchBody.right
            anchors.rightMargin: 18
            anchors.top: parent.top
            anchors.topMargin: 40

            spacing: 18

            opacity: window.hovered && !ShellState.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            Repeater {
                model: [
                    { name: "CPU", value: window.cpuUsage + "%" },
                    { name: "RAM", value: window.ramUsage + "%" },
                    { name: "TEMP", value: window.cpuTemperature + "°C" }
                ]

                delegate: Column {
                    required property var modelData

                    spacing: 3

                    Text {
                        text: modelData.name
                        color: Theme.primary
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: modelData.value
                        color: Theme.muted
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !ShellState.expanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.show("control")
        }

        // COMPACT MUSIC CARD
        Rectangle {
            id: mediaCard

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 7
            }

            width: 280
            height: 45

            radius: 9
            color: Theme.bg2

            opacity: window.hovered && !ShellState.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 7

                // ALBUM ARTWORK
            Rectangle {
                id: albumArt

                width: 30
                height: 30
                radius: 5
                color: Theme.bg4
                clip: true

                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: albumImage

                    anchors.fill: parent

                    source: window.musicPlayer
                        ? window.musicPlayer.trackArtUrl
                        : ""

                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    sourceSize.width: 120
                    sourceSize.height: 120

                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent

                    text: "♫"
                    color: Theme.aqua
                    font.pixelSize: 20

                    visible: albumImage.status !== Image.Ready
                }
            }

                // TRACK INFORMATION
                Column {
                    width: 145
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: window.musicPlayer
                            ? window.musicPlayer.trackTitle || "Unknown Track"
                            : "No music playing"

                        color: Theme.aqua
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: window.musicPlayer
                            ? window.musicPlayer.trackArtist || "Unknown Artist"
                            : "Play music to get started"

                        color: Theme.aqua
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                // PLAYBACK CONTROLS
               // CAVA + PLAYBACK CONTROLS
                Item {
                    width: 86
                    height: 30

                    anchors.verticalCenter: parent.verticalCenter

                    // PLAYBACK BUTTONS
                    Row {
                            id: playbackButtons
                            anchors.centerIn: parent
                            spacing: 4
                            z: 10

                            // PREVIOUS
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: prevMouse.containsMouse ? "#3A5360" : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    color: prevMouse.containsMouse ? "#66DDF5" : Theme.foreground
                                    font.pixelSize: 17
                                }

                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (window.musicPlayer)
                                            window.musicPlayer.previous()
                                    }
                                }
                            }

                            // PLAY / PAUSE
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: playMouse.containsMouse ? "#3A5360" : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: window.musicPlayer && window.musicPlayer.isPlaying
                                        ? "󰏤" : "󰐊"
                                    color: playMouse.containsMouse ? "#66DDF5" : Theme.foreground
                                    font.pixelSize: 17
                                }

                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (window.musicPlayer &&
                                            window.musicPlayer.canTogglePlaying)
                                            window.musicPlayer.togglePlaying()
                                    }
                                }
                            }

                            // NEXT
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: nextMouse.containsMouse ? "#3A5360" : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    color: nextMouse.containsMouse ? "#66DDF5" : Theme.foreground
                                    font.pixelSize: 17
                                }

                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (window.musicPlayer)
                                            window.musicPlayer.next()
                                    }
                                }
                            }
                        }

                    // CAVA OVERLAY
                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        z: 2

                        Repeater {
                            model: window.cavaBars

                            Rectangle {
                                required property var modelData

                                width: 4
                                height: Math.max(3, modelData * 0.22)
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2
                                color: Theme.aqua
                                opacity: 0.45

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: panelHost

            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: window.contentPadding
            anchors.rightMargin: window.contentPadding
            anchors.topMargin: window.displayedTopPadding
            anchors.bottomMargin: window.displayedBottomPadding
            visible: opacity > 0
            opacity: window.contentRevealed ? 1 : 0
            clip: true

            ControlPanel {
                id: controlPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "control"
            }

            LauncherPanel {
                id: launcherPanel

                width: parent.width
                visible: window.displayedPanel === "launcher"
            }

            ClipboardPanel {
                id: clipboardPanel

                width: parent.width
                visible: window.displayedPanel === "clipboard"
            }

            TodoPanel {
                id: todoPanel

                width: parent.width
                visible: window.displayedPanel === "todo"
            }

            QuickNotesPanel {
                id: quickNotesPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "notes"
            }

            ThemePanel {
                id: themePanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "theme"
            }

            WallpaperPanel {
                id: wallpaperPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "wallpaper"
            }

            CapturePanel {
                id: capturePanel

                width: parent.width
                visible: window.displayedPanel === "capture"
            }

            PowerPanel {
                id: powerPanel

                width: parent.width
                visible: window.displayedPanel === "power"
            }

            VolumePanel {
                id: volumePanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "volume"
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }

        }

        Behavior on height {
            enabled: !clipboardPanel.previewTransitionActive

            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

    }

    
    Process {
        id: monitorProcess

            command: ["bash", "-c", `
            read cpu user nice system idle iowait irq softirq steal rest < /proc/stat
            idle1=$((idle + iowait))
            total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

            sleep 0.2

            read cpu user nice system idle iowait irq softirq steal rest < /proc/stat
            idle2=$((idle + iowait))
            total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

            cpu=$(awk -v i1="$idle1" -v i2="$idle2" -v t1="$total1" -v t2="$total2" 'BEGIN {
                if (t2 == t1) print 0;
                else printf "%.0f", 100 * (1 - (i2-i1)/(t2-t1));
            }')

            ram=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

            temp=$(sensors | awk '/Package id 0:/ {
                gsub(/[+°C]/,"",$4);
                print int($4);
                exit
            }')

            echo "$cpu $ram $temp"
            `]
        running: true

        stdout: StdioCollector {
            id: monitorOutput

            onStreamFinished: {
                const values = monitorOutput.text.trim().split(/\s+/);

                console.log("PARSED VALUES:", JSON.stringify(values));

                if (values.length >= 3) {
                    window.cpuUsage = parseInt(values[0], 10);
                    window.ramUsage = parseInt(values[1], 10);
                    window.cpuTemperature = parseInt(values[2], 10);

                    console.log("MONITOR UPDATED:",
                        window.cpuUsage,
                        window.ramUsage,
                        window.cpuTemperature);
                }
            }
        }
    }

    Timer {
        id: monitorTimer

        interval: 2000
        repeat: true
        running: true

        onTriggered: {
            if (!monitorProcess.running)
                monitorProcess.running = true;
        }
    }

   Process {
        id: cavaProcess

        command: [
            "cava",
            "-p",
            Quickshell.env("HOME") + "/.config/cava/quickshell.conf"
        ]

        running: true

        stdout: SplitParser {
            onRead: data => {
                const values = data.trim()
                    .split(";")
                    .filter(value => value.length > 0)
                    .map(Number);

                if (values.length > 0 && values.every(Number.isFinite)) {
                    window.cavaBars = values.map(value =>
                        Math.max(0, Math.min(100, value))
                    );
                }
            }
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    HyprlandFocusGrab {
        windows: [window]
        active: ShellState.expanded && Backend.captureSelectionMode !== "region"
        onCleared: {
            if (ShellState.expanded && Backend.captureSelectionMode !== "region")
                ShellState.close();

        }
    }

    Timer {
        id: focusTimer
        interval: 35
        onTriggered: window.focusInitialControl()
    }

    Timer {
        id: clockRevealTimer

        interval: 150
        onTriggered: {
            if (!ShellState.expanded)
                window.clockRevealed = true;

        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: ShellState.expanded
        onActivated: ShellState.close()
    }

    mask: Region {
        item: notchBody
        topLeftRadius: Theme.radius
        topRightRadius: Theme.radius
        bottomLeftRadius: Theme.radius
        bottomRightRadius: Theme.radius
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: window
            property: "floatOffset"
            to: -3
            duration: 1200
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: window
            property: "floatOffset"
            to: 0
            duration: 1200
            easing.type: Easing.InOutSine
        }
    }
}
