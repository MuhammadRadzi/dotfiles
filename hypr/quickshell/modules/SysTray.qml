import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property bool expanded: false
    property var barWindow: null

    implicitWidth: layout.implicitWidth
    implicitHeight: parent ? parent.height : 24

    RowLayout {
        id: layout

        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            id: toggleBtn

            text: root.expanded ? "󰅁" : "󰅀"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: mouseArea.containsMouse ? "#ffffff" : "#888888"

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.expanded = !root.expanded
                cursorShape: Qt.PointingHandCursor
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }

            }

        }

        Item {
            id: trayContainer

            Layout.preferredWidth: root.expanded ? trayRow.implicitWidth : 0
            Layout.preferredHeight: 18
            clip: true
            opacity: root.expanded ? 1 : 0

            RowLayout {
                id: trayRow

                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: SystemTray.items

                    Item {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 18
                        height: 18

                        Image {
                            anchors.fill: parent
                            source: trayItem.modelData.icon
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        QsMenuAnchor {
                            id: menuAnchor

                            anchor.window: root.barWindow
                            anchor.item: trayItem
                            menu: trayItem.modelData.menu
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    console.log("barWindow:", root.barWindow);
                                    console.log("menu:", trayItem.modelData.menu);
                                    menuAnchor.open();
                                }
                            }
                        }

                    }

                }

            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }

            }

        }

    }

}
