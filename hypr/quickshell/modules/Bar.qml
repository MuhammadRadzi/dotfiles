import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

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

                WallpaperSelector {
                    id: ws
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: leftRow.implicitWidth + 20
                    color: "transparent"

                    RowLayout {
                        id: leftRow

                        anchors.centerIn: parent
                        spacing: 6

                        Workspaces {
                        }
                    }

                }

            }

            // =========================
            // CENTER
            // =========================
            Item {
                Layout.fillWidth: true

                CalendarPopup {
                    id: cal
                }

                RowLayout {
                    id: centerRow

                    anchors.centerIn: parent
                    spacing: 10

                    MediaPlayer {
                    }

                    Rectangle {
                        implicitWidth: clockText.implicitWidth + 16
                        implicitHeight: clockText.implicitHeight + 8
                        radius: 8
                        color: clockArea.containsMouse ? "#22ffffff" : "transparent"

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
                            onClicked: cal.toggle()
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

            }

            // =========================
            // RIGHT
            // =========================
            Item {
                Layout.fillWidth: true

                ControlCenter {
                    id: cc
                }

                Rectangle {
                    id: rightPill

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: rightRow.implicitWidth + 20
                    implicitHeight: rightRow.implicitHeight + 25
                    radius: 8
                    color: ccMouseArea.containsMouse ? "#22ffffff" : "transparent"

                    RowLayout {
                        id: rightRow

                        anchors.centerIn: parent
                        spacing: 10

                        Weather {
                        }

                        Network {
                        }

                        Volume {
                        }

                        Battery {
                        }

                        SysTray {
                        }

                    }

                    MouseArea {
                        id: ccMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cc.toggle()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

        }

    }

}
