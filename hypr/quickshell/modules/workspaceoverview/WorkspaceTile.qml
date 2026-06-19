import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Rectangle {
    id: tile

    required property int wsId

    signal clicked()

    readonly property var wsObj: Hyprland.workspaces.values.find((w) => {
        return w.id === wsId;
    })

    readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
    readonly property var windowList: wsObj ? wsObj.toplevels.values : []
    readonly property bool hasWindows: windowList.length > 0

    Layout.preferredWidth: 240
    Layout.preferredHeight: 150
    radius: 10
    color: isActive ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : Qt.rgba(1, 1, 1, 0.04)
    border.width: isActive ? 2 : 1
    border.color: isActive ? Colors.accent : Qt.rgba(1, 1, 1, 0.08)

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ── Header: nomor workspace + jumlah window ────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: tile.wsId
                color: tile.isActive ? Colors.accent : Colors.text
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "JetBrainsMono Nerd Font"
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: tile.hasWindows
                text: tile.windowList.length
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

        }

        // ── Daftar window (ikon + judul singkat) ────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Repeater {
                model: tile.hasWindows ? tile.windowList.slice(0, 4) : []

                delegate: RowLayout {
                    required property var modelData

                    readonly property string appId: modelData.wayland ? (modelData.wayland.appId || "") : ""
                    readonly property string winTitle: modelData.wayland ? (modelData.wayland.title || appId || "—") : "—"
                    readonly property string iconSrc: appId !== "" ? Quickshell.iconPath(appId.toLowerCase(), true) : ""

                    Layout.fillWidth: true
                    spacing: 6

                    IconImage {
                        visible: iconSrc !== ""
                        implicitSize: 13
                        source: iconSrc
                    }

                    Text {
                        visible: iconSrc === ""
                        text: "·"
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: winTitle
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                    }

                }

            }

            Text {
                visible: !tile.hasWindows
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Empty"
                color: Qt.rgba(Colors.subtle.r, Colors.subtle.g, Colors.subtle.b, 0.5)
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                font.italic: true
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: tile.hasWindows && tile.windowList.length > 4
                text: "+" + (tile.windowList.length - 4) + " more"
                color: Qt.rgba(Colors.subtle.r, Colors.subtle.g, Colors.subtle.b, 0.6)
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                font.italic: true
            }

        }

    }

}