
import QtQuick
import Quickshell.Widgets
import qs
import qs.components

FocusScope {
    id: root

    function takeInitialFocus() {
        if (wallpaperGrid.count > 0 && wallpaperGrid.currentIndex < 0)
            wallpaperGrid.currentIndex = 0;

        wallpaperGrid.forceActiveFocus(Qt.TabFocusReason);
    }

    function moveSelection(offset) {
        if (wallpaperGrid.count === 0)
            return;

        const next = Math.max(
            0,
            Math.min(
                wallpaperGrid.count - 1,
                Math.max(0, wallpaperGrid.currentIndex) + offset
            )
        );

        wallpaperGrid.currentIndex = next;
    }

    Connections {
        target: ShellState

        function onPanelChanged() {
            if (ShellState.panel === "wallpaper") {
                AppearanceState.setWallpaperSource(
                    AppearanceState.themeMode === "dynamic"
                        ? "dynamic"
                        : "current"
                );

                AppearanceState.refreshCurrentWallpaper();
            }
        }
    }

    Connections {
        target: AppearanceState

        function onWallpapersChanged() {
            wallpaperGrid.currentIndex =
                AppearanceState.wallpapers.length > 0 ? 0 : -1;
        }
    }

    implicitWidth: 792
    implicitHeight: 210

    Column {
        anchors.fill: parent
        spacing: 7

        // Header and compact controls
        Row {
            width: parent.width
            height: 50
            spacing: 5
            

            ShellText {
                width: 85
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpaper"
                color: Theme.foreground
                font.pixelSize: 15
                font.weight: Font.Bold
                font.family: "JetBrainsMono Nerd"
            }

            Item {
                width: 2
                height: 2
            }

            Repeater {
                model: [
                    { label: "Theme", source: "current" },
                    { label: "Dynamic", source: "dynamic"}
                    
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: modelData.source === "dynamic" ? 75 : 55
                    height: 23
                    radius: Theme.radiusSmall

                    anchors.verticalCenter: parent.verticalCenter

                    color: AppearanceState.wallpaperSource === modelData.source
                        ? Theme.bg2 : "transparent"

                    border.width: AppearanceState.wallpaperSource === modelData.source ? 1 : 0
                    border.color: Theme.aqua

                    ShellText {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: AppearanceState.wallpaperSource === modelData.source
                            ? Theme.aqua : Theme.muted
                        font.pixelSize: 15

                        font.family: "JetBrainsMono Nerd"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppearanceState.setWallpaperSource(modelData.source)
                    }
                }
            }

            // Tint control
            FocusScope {
                id: tintToggle

                width: 85
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: "Dominant color tint " +
                    (AppearanceState.tintEnabled ? "enabled" : "disabled")

                Keys.onReturnPressed: AppearanceState.toggleTint()
                Keys.onEnterPressed: AppearanceState.toggleTint()
                Keys.onSpacePressed: AppearanceState.toggleTint()

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Tint"
                        color: Theme.muted
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd"
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 27
                        height: 14
                        radius: 7
                        color: AppearanceState.tintEnabled
                            ? Theme.aqua : Theme.bg3

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            x: AppearanceState.tintEnabled ? 14 : 3
                            color: Theme.bg0

                            Behavior on x {
                                NumberAnimation { duration: 180 }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppearanceState.toggleTint()
                }
            }

            // Open wallpaper folder
            FocusScope {
                id: folderButton

                width: 27
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: "Open wallpaper folder"

                Keys.onReturnPressed: AppearanceState.openWallpaperFolder()
                Keys.onEnterPressed: AppearanceState.openWallpaperFolder()
                Keys.onSpacePressed: AppearanceState.openWallpaperFolder()

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: folderPointer.containsMouse || folderButton.activeFocus
                        ? Theme.bg2 : "transparent"
                }

                ShellText {
                    anchors.centerIn: parent
                    text: "󰉋"
                    color: Theme.aqua
                    font.pixelSize: 15
                }

                MouseArea {
                    id: folderPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppearanceState.openWallpaperFolder()
                }
            }
        }

        // Horizontal wallpaper carousel
        ListView {
            id: wallpaperGrid

            width: parent.width
            height: 210
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            model: AppearanceState.wallpapers
            keyNavigationWraps: false


            Keys.onLeftPressed: root.moveSelection(-1)
            Keys.onRightPressed: root.moveSelection(1)
            Keys.onReturnPressed: if (currentItem) currentItem.activate()
            Keys.onEnterPressed: if (currentItem) currentItem.activate()
            Keys.onSpacePressed: if (currentItem) currentItem.activate()

            delegate: Item {
                id: wallpaperTile

                required property int index
                required property var modelData

                width: 190
                height: 125

                function activate() {
                    AppearanceState.setWallpaper(modelData.path);
                    ShellState.close();
                }

                ClippingRectangle {
                    width: parent.width
                    height: 100
                    anchors.centerIn: parent

                    radius: Theme.radiusSmall
                    color: Theme.bg1
                    contentUnderBorder: true

                    border.width: wallpaperTile.isApplied ? 1 : 0
                    border.color: Theme.muted

                    Image {
                        anchors.fill: parent
                        source: encodeURI("file://" + wallpaperTile.modelData.path)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 7

                        width: 6
                        height: 6
                        radius: 3

                        visible: wallpaperTile.isApplied
                        color: Theme.aqua

                        ShellText {
                            anchors.centerIn: parent
                            text: ""
                            color: Theme.bg0
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: wallpaperGrid.currentIndex = wallpaperTile.index
                    onClicked: wallpaperTile.activate()
                }

                readonly property bool isApplied:
                    AppearanceState.currentWallpaper === wallpaperTile.modelData.path
                    

                readonly property bool isSelected:
                    wallpaperGrid.currentIndex === wallpaperTile.index

                    z: isSelected ? 4 : 0

                    property real lift: isSelected ? -6 : 0

                    readonly property real targetOpacity: isSelected ? 1.0 : 0.4

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    opacity: targetOpacity

                    Behavior on lift {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                transform: Translate {
                    y: wallpaperTile.lift
                }
            }

            ShellText {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: AppearanceState.wallpapers.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.muted
                text: "No wallpapers available"
                font.pixelSize: 10
            }

            Behavior on contentX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            preferredHighlightBegin: (width - 190) / 2
            preferredHighlightEnd: (width + 190) / 2

            highlightRangeMode: ListView.StrictlyEnforceRange

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 300
            highlightMoveVelocity: -1

            highlight: Item {
                width: 190
                height: 100
                z: 10

                transform: Translate {
                    y: -6
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 190
                    height: 100
                    radius: Theme.radiusSmall
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.aqua
                }
            }
            
        }

        // Footer
        Row {
            width: parent.width
            height: -145

           ShellText {
                width: parent.width - 110
                anchors.verticalCenter: parent.verticalCenter

                text: wallpaperGrid.currentItem
                    ? wallpaperGrid.currentItem.modelData.path.split("/").pop()
                    : "No wallpaper selected"

                color: Theme.muted
                elide: Text.ElideLeft
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd"
            }

            ShellText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: wallpaperGrid.count > 0
                    ? (wallpaperGrid.currentIndex + 1) + "/" + wallpaperGrid.count
                    : "0/0"
                color: Theme.muted
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd"
            }
        }
    }
}
