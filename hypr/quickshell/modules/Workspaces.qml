import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    spacing: 8

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            readonly property bool active:
                Hyprland.focusedWorkspace?.id === modelData.id

            implicitWidth: active ? 34 : 12
            implicitHeight: 12

            radius: 999

            color: active ? "#f2f2f2" : "#44ffffff"

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    Hyprland.dispatch(
                        "workspace " + modelData.id
                    )
                }
            }
        }
    }
}