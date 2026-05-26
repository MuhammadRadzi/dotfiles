import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: parent.height

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: 9

            Rectangle {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                property bool hasWindows: ws !== undefined

                width: isActive ? 28 : 10
                height: 10
                radius: 5

                color: isActive    ? Colors.accent
                     : hasWindows  ? "#555555"
                     :               "#2a2a2a"

                Behavior on width {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}