import "../theme"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
    WlrLayershell.exclusiveZone: 40

    anchors {
        top: true
        left: true
        right: true
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: barPath

            property real r: 18
            property real w: root.width
            property real h: root.height

            strokeWidth: -1
            fillColor: "#d916181c"
            startX: 0
            startY: 0

            PathLine {
                x: barPath.w
                y: 0
            }

            PathLine {
                x: barPath.w
                y: barPath.h
            }

            PathArc {
                x: barPath.w - barPath.r
                y: barPath.h - barPath.r
                radiusX: barPath.r
                radiusY: barPath.r
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: barPath.r
                y: barPath.h - barPath.r
            }

            PathArc {
                x: 0
                y: barPath.h
                radiusX: barPath.r
                radiusY: barPath.r
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: 0
                y: 0
            }

        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        // anchors.topMargin: 4
        anchors.bottomMargin: 18

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
                    text: "\u23fb"
                    color: powerArea.containsMouse ? Colors.text : Colors.subtle
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        id: powerArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePower()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.overlay
                }

                Workspaces {
                }

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

                Rectangle {
                    implicitWidth: clockText.implicitWidth + 16
                    implicitHeight: clockText.implicitHeight + 8
                    radius: 8
                    color: clockArea.containsMouse ? "#22ffffff" : "transparent"

                    Text {
                        id: clockText

                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
                        color: Colors.text
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

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                SysTray {
                    barWindow: root
                }

                Rectangle {
                    id: rightPill

                    implicitWidth: rightRow.implicitWidth + 18
                    implicitHeight: rightRow.implicitHeight - 5
                    radius: 8
                    color: ccMouseArea.containsMouse ? "#22ffffff" : "transparent"

                    RowLayout {
                        id: rightRow

                        anchors.centerIn: parent
                        spacing: 10

                        SystemGraph {
                        }

                        Weather {
                        }

                        Network {
                        }

                        Volume {
                        }

                        Battery {
                        }

                    }

                    MouseArea {
                        id: ccMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleCC()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Text {
                    text: "\uf03e"
                    color: wpArea.containsMouse ? Colors.text : Colors.subtle
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        id: wpArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleWallpaper()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Text {
                    text: "\uf0f3"
                    color: notifBellArea.containsMouse ? Colors.text : Colors.subtle
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        id: notifBellArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleNotif()
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
