import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: parent ? parent.height : 24

    property bool expanded: false

    RowLayout {
        id: layout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Tombol Toggle (Dropdown/Expander)
        Text {
            id: toggleBtn
            text: root.expanded ? "󰅁" : "󰅀"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: mouseArea.containsMouse ? "#ffffff" : "#888888"
            
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.expanded = !root.expanded
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Container untuk icon tray dengan animasi lebar
        Item {
            id: trayContainer
            Layout.preferredWidth: root.expanded ? trayRow.implicitWidth : 0
            Layout.preferredHeight: 18
            clip: true
            opacity: root.expanded ? 1 : 0

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            RowLayout {
                id: trayRow
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: SystemTray.items

                    Item {
                        width: 18
                        height: 18

                        Image {
                            anchors.fill: parent
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.activate()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}