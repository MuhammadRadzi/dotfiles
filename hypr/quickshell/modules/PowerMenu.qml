import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powerMenu

    property bool isOpen: false

    visible: overlayRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"

    Rectangle {
        id: overlayRect

        anchors.fill: parent
        color: "#88000000"
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: powerMenu.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 360
            height: contentCol.implicitHeight + 48
            radius: 20
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            ColumnLayout {
                id: contentCol

                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 24

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: [{
                            "icon": "\uf023",
                            "label": "Lock",
                            "cmd": "hyprlock",
                            "color": "#85B7EB"
                        }, {
                            "icon": "\uf186",
                            "label": "Suspend",
                            "cmd": "systemctl suspend",
                            "color": "#AFA9EC"
                        }, {
                            "icon": "\udb81\udf17",
                            "label": "Hibernate",
                            "cmd": "systemctl hibernate",
                            "color": "#5DCAA5"
                        }, {
                            "icon": "\uf021",
                            "label": "Reboot",
                            "cmd": "systemctl reboot",
                            "color": "#EF9F27"
                        }, {
                            "icon": "\uf011",
                            "label": "Shutdown",
                            "cmd": "systemctl poweroff",
                            "color": "#F09595"
                        }, {
                            "icon": "\udb80\udf43",
                            "label": "Logout",
                            "cmd": "loginctl terminate-user $USER",
                            "color": "#ED93B1"
                        }]

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 80
                            radius: 12
                            color: btnArea.containsMouse ? "#22ffffff" : "#11ffffff"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: modelData.color
                                    font.pixelSize: 28
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                            }

                            MouseArea {
                                id: btnArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    powerMenu.isOpen = false;
                                    execProc.command = ["sh", "-c", modelData.cmd];
                                    execProc.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 10
                    color: cancelArea.containsMouse ? "#22ffffff" : "#11ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: cancelArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerMenu.isOpen = false
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

    Process {
        id: execProc

        running: false
    }

}
