import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    signal togglePower()
    signal toggleWallpaper()
    signal toggleNotif()
    signal toggleCal()
    signal toggleCC()

    implicitHeight: 56
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: 18
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            // =========================
            // LEFT
            // =========================
            Item {
                Layout.fillWidth: true

                RowLayout {
                    id: leftRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "⏻"
                        color: powerArea.containsMouse ? "#e0e0e0" : "#888888"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: powerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePower()
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 14
                        color: "#333333"
                    }

                    Workspaces {}
                }
            }

            // =========================
            // CENTER
            // =========================
            Item {
                Layout.fillWidth: true

                RowLayout {
                    id: centerRow
                    anchors.centerIn: parent
                    spacing: 10

                    MediaPlayer {}

                    Rectangle {
                        implicitWidth: clockText.implicitWidth + 16
                        implicitHeight: clockText.implicitHeight + 8
                        radius: 8
                        color: clockArea.containsMouse ? "#22ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: clockText
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
                            color: "#e0e0e0"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
                            }
                        }

                        MouseArea {
                            id: clockArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleCal()
                        }
                    }
                }
            }

            // =========================
            // RIGHT
            // =========================
            Item {
                Layout.fillWidth: true

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        id: rightPill
                        implicitWidth: rightRow.implicitWidth + 18
                        implicitHeight: rightRow.implicitHeight - 5
                        radius: 8
                        color: ccMouseArea.containsMouse ? "#22ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: rightRow
                            anchors.centerIn: parent
                            spacing: 10

                            SystemGraph {}
                            Weather {}
                            Network {}
                            Volume {}
                            Battery {}
                            SysTray {}
                        }

                        MouseArea {
                            id: ccMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleCC()
                        }
                    }

                    Text {
                        text: "󰋯"
                        color: wpArea.containsMouse ? "#e0e0e0" : "#888888"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: wpArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWallpaper()
                        }
                    }

                    Text {
                        text: "󰂚"
                        color: notifBellArea.containsMouse ? "#e0e0e0" : "#888888"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: notifBellArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleNotif()
                        }
                    }
                }
            }
        }
    }
}