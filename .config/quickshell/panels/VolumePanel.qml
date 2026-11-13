
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

FocusScope {
    id: root

    property real volume: 0
    property bool muted: false
    property var pendingCommand: []

    readonly property int percentage: Math.round(Math.max(0, Math.min(1, volume)) * 100)

    implicitWidth: 220
    implicitHeight: 28

    function updateFromOutput(output) {
        const match = output.match(/Volume:\s*([0-9.]+)/);

        if (match)
            volume = Math.max(0, Math.min(1, Number(match[1])));

        muted = output.includes("[MUTED]");
    }

    function refresh() {
        if (!queryProcess.running)
            queryProcess.running = true;
    }

    function execute(command) {
        if (commandProcess.running)
            return;

        pendingCommand = command;
        commandProcess.running = true;
    }

    function volumeUp() {
        execute("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+");
    }

    function volumeDown() {
        execute("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-");
    }

    function toggleMute() {
        execute("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Up:
            volumeUp();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            volumeDown();
            event.accepted = true;
            break;
        case Qt.Key_M:
            toggleMute();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            ShellState.close();
            event.accepted = true;
            break;
        }
    }

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus();
            refresh();
        }
    }

    Process {
        id: queryProcess

        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.updateFromOutput(text.trim())
        }
    }

    Process {
        id: commandProcess

        command: [
            "bash",
            "-c",
            root.pendingCommand + " && wpctl get-volume @DEFAULT_AUDIO_SINK@"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: root.updateFromOutput(text.trim())
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Column {
        width: parent.width
        spacing: 0

        Row {
            width: parent.width
            height: 24

            ShellText {
                text: "SYSTEM VOLUME"
                color: Theme.muted
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: Theme.headingFontFamily
                font.letterSpacing: 0.5
            }

            Item {
                width: 1
                height: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            ShellText {
                anchors.right: parent.right
                text: root.muted ? "MUTED" : root.percentage + "%"
                color: root.muted ? Theme.yellow : Theme.primary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "JetBrainsMono Nerd"

            }
        }

        Rectangle {
            id: volumeTrack

            width: parent.width
            height: 10
            radius: 5
            color: Theme.bg1

            Rectangle {
                width: volumeTrack.width * (root.muted ? 0 : root.volume)
                height: parent.height
                radius: 5
                color: Theme.primary

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animationFast
                    }
                }
            }
        }
    }

}
