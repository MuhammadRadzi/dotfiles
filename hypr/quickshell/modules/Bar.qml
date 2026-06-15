import "../theme"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property int todoCount: 0
    property bool isRecording: false
    property int recordSeconds: 0

    signal togglePower()
    signal toggleWallpaper()
    signal toggleNotif()
    signal toggleCal()
    signal toggleCC()
    signal toggleTodo()
    signal stopRecording()

    implicitHeight: 56
    color: "transparent"
    WlrLayershell.exclusiveZone: 37

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

                BarButton {
                    icon: "\u23fb"
                    onClicked: root.togglePower()
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.overlay
                }

                Workspaces {
                }

                Rectangle {
                    visible: todoCount > 0
                    width: 1
                    height: 14
                    color: Colors.overlay
                }

                Item {
                    visible: todoCount > 0
                    width: todoRow.implicitWidth
                    height: todoRow.implicitHeight

                    RowLayout {
                        id: todoRow

                        spacing: 4

                        Text {
                            text: "\uf0ae"
                            color: todoArea.containsMouse ? Colors.text : Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        Rectangle {
                            width: badgeText.implicitWidth + 6
                            height: 16
                            radius: 8
                            color: Colors.accent

                            Text {
                                id: badgeText

                                anchors.centerIn: parent
                                text: todoCount
                                color: Colors.base
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                            }

                        }

                    }

                    MouseArea {
                        id: todoArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTodo()
                    }

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

                    implicitWidth: rightRow.implicitWidth
                    implicitHeight: rightRow.implicitHeight
                    radius: 8
                    color: "transparent"

                    RowLayout {
                        id: rightRow

                        anchors.centerIn: parent
                        spacing: 0

                        SystemGraph {
                            Layout.rightMargin: 10
                        }

                        Weather {
                            Layout.rightMargin: 10
                        }

                        Network {
                            Layout.rightMargin: 10
                        }

                        Volume {
                            Layout.rightMargin: 10
                        }

                        Battery {
                            Layout.rightMargin: 4
                        }

                    }

                }

                BarButton {
                    icon: "\udb85\udd42"
                    onClicked: root.toggleCC()
                }

                BarButton {
                    icon: "\uf0f3"
                    onClicked: root.toggleNotif()
                }

                // Recording indicator pill
                Rectangle {
                    id: recordPill

                    property real blinkOpacity: 1

                    visible: root.isRecording
                    width: recordPillRow.implicitWidth + 16
                    height: 26
                    radius: 13
                    color: "#33FB4934"
                    border.color: "#FB4934"
                    border.width: 1
                    opacity: blinkOpacity

                    Row {
                        id: recordPillRow

                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 4
                            color: "#FB4934"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: {
                                let m = Math.floor(root.recordSeconds / 60);
                                let s = root.recordSeconds % 60;
                                return m + ":" + (s < 10 ? "0" + s : s);
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: "#FB4934"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stopRecording()
                    }

                    SequentialAnimation on blinkOpacity {
                        running: root.isRecording
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.35
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                    }

                }

            }

        }

    }

}
