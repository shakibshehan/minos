
import QtQuick
import qs
import qs.components

FocusScope {
    id: root
    y: 10

    property int selectedIndex: 0

    readonly property var themeOptions: AppearanceState.themes.concat([{
        name: "Dynamic Wallpaper",
        slug: "dynamic",
        colors: {
            bg0: Theme.bg0,
            foreground: Theme.foreground,
            primary: Theme.primary,
            blue: Theme.blue,
            purple: Theme.purple,
            aqua: Theme.aqua,
            green: Theme.green
        }
    }])

    readonly property var filteredThemeOptions: {
        const query = searchInput.text.trim().toLowerCase();

        return themeOptions
            .map((theme, index) => ({ theme: theme, index: index }))
            .filter(item =>
                item.theme.name.toLowerCase().includes(query)
            );
    }

    readonly property int selectedVisibleIndex: {
        return filteredThemeOptions.findIndex(
            item => item.index === selectedIndex
        );
    }

    function takeInitialFocus() {
        selectedIndex = AppearanceState.themeMode === "dynamic"
            ? AppearanceState.themes.length
            : Math.max(0, AppearanceState.themes.findIndex(
                theme => theme.slug === Theme.slug
            ));

        scrollToTheme(selectedVisibleIndex);

        const item = themeList.itemAtIndex(selectedVisibleIndex);
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function scrollToTheme(index) {
        Qt.callLater(() => {
            const item = themeList.itemAtIndex(index);
            if (!item)
                return;

            const targetX = Math.max(
                0,
                Math.min(
                    themeList.contentWidth - themeList.width,
                    item.x - (themeList.width - item.width) / 2
                )
            );

            scrollAnimation.to = targetX;
            scrollAnimation.start();
        });
    }

    function activate(index) {
        if (index === AppearanceState.themes.length) {
            AppearanceState.applyDynamicTheme();
            return;
        }

        const theme = AppearanceState.themes[index];
        if (!theme)
            return;

        AppearanceState.applyTheme(theme.slug);
        selectedIndex = index;
        ShellState.close();
    }

    function focusTheme(visibleIndex) {
        const next = Math.max(
            0,
            Math.min(filteredThemeOptions.length - 1, visibleIndex)
        );

        if (filteredThemeOptions.length === 0)
            return;

        selectedIndex = filteredThemeOptions[next].index;

        scrollToTheme(next);

        const item = themeList.itemAtIndex(next);
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    implicitWidth: 792
    implicitHeight: 210

    Column {
        anchors.fill: parent
        spacing: 3

        Row {
            width: parent.width
            height: 23
            spacing: 8

            Rectangle {
                width: 760
                height: 32
                radius: Theme.radiusSmall
                color: Theme.bg1
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: Theme.aqua

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenterttt
                        text: "⌕"
                        color: Theme.muted
                        font.pixelSize: 20
                        font.family:"JetBrainsMono Nerd Font Proppo"
                    }

                    TextInput {
                        id: searchInput

                        width: parent.width - 25
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        color: Theme.foreground
                        font.pixelSize: 10
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            if (root.filteredThemeOptions.length > 0
                                && root.selectedVisibleIndex < 0) {
                                root.selectedIndex =
                                    root.filteredThemeOptions[0].index;
                            }
                        }

                        Keys.onEscapePressed: {
                            if (text.length > 0)
                                clear();
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search themes..."
                            color: Theme.muted
                            font: searchInput.font
                            visible: !searchInput.text
                            opacity: 0.7
                        }
                    }
                }
            }

            Item {
                width: parent.width - 190 - 8 - 70
                height: 100
            }

            ShellText {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.selectedIndex + 1) + "/" + root.themeOptions.length
                color: Theme.muted
                font.pixelSize: 9
                font.family: "JetBrainsMono Nerd Font"
            }
        }


    Item {
        width: parent.width
        height: 180

        ListView {
            id: themeList

            anchors.fill: parent
            z: 1

            orientation: ListView.Horizontal
            spacing: 6
            clip: false

            model: root.filteredThemeOptions
            currentIndex: root.selectedVisibleIndex

            preferredHighlightBegin: (width - 190) / 2
            preferredHighlightEnd: (width + 190) / 2

            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 300
            highlightMoveVelocity: -1

           

            delegate: FocusScope {
                id: themeRow

                required property int index
                required property var modelData

                width: 190
                height: 180
                activeFocusOnTab: true

                readonly property int themeIndex: modelData.index
                readonly property var themeData: modelData.theme
                readonly property var previewColors:
                    themeData.slug === "dynamic"
                        ? themeData.colors
                        : (themeData.colors.dark || themeData.colors)

                readonly property bool isSelected:
                    themeIndex === root.selectedIndex

                property real lift: isSelected ? -8 : 0

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

                Keys.onReturnPressed: root.activate(themeIndex)
                Keys.onEnterPressed: root.activate(themeIndex)
                Keys.onSpacePressed: root.activate(themeIndex)
                Keys.onLeftPressed: root.focusTheme(index - 1)
                Keys.onRightPressed: root.focusTheme(index + 1)

                onActiveFocusChanged: {
                    if (activeFocus)
                        root.selectedIndex = themeIndex;
                }

                Item {
                    anchors.fill: parent

                    transform: Translate {
                        y: themeRow.lift
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 100
                        radius: Theme.radius
                        color: themeRow.previewColors.bg0
                        border.width: 1
                        border.color: Theme.bg2
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6

                            Repeater {
                                model: [
                                    themeRow.previewColors.primary,
                                    themeRow.previewColors.blue,
                                    themeRow.previewColors.purple,
                                    themeRow.previewColors.aqua
                                        || themeRow.previewColors.blue,
                                    themeRow.previewColors.green
                                        || themeRow.previewColors.primary
                                ]

                                Rectangle {
                                    required property var modelData

                                    width: 20
                                    height: 10
                                    radius: 4
                                    color: modelData
                                }
                            }
                        }

                        ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 96
                            horizontalAlignment: Text.AlignHCenter
                            text: themeRow.themeData.name
                            elide: Text.ElideRight
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onEntered: root.selectedIndex = themeRow.themeIndex
                    onClicked: root.activate(themeRow.themeIndex)
                }
            }
        }

        Rectangle {
            id: selectionOutline

            width: 190
            height: 100
            radius: Theme.radius
            color: "transparent"
            border.width: 2
            border.color: Theme.aqua

            z: 2

            x: themeList.x + (themeList.width - width) / 2

            y: themeList.y
                + (themeList.height - height) / 2
                - 8

                
        }
    }
         
        Row {
            width: parent.width
            height: -26

            ShellText {
                
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.themeOptions[root.selectedIndex]
                    ? root.themeOptions[root.selectedIndex].name
                    : ""
                color: Theme.aqua
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.family: "JetBrainsMono Nerd"
                
            }

            ShellText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                text: themeList.count > 0
                    ? (themeList.currentIndex + 1) + "/" + themeList.count
                    : "0/0"

                color: Theme.muted
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd"
            }
        }
    }

}
