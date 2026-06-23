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
    WlrLayershell.exclusiveZone: 38

    anchors {
        top: true
        left: true
        right: true
    }

    // =========================
    // PILL BACKGROUND (3 separate shapes)
    // =========================
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // ---- LEFT PILL ----
        ShapePath {
            id: leftPath

            property real r: 18
            property real w: leftContent.width + 32
            property real h: root.height

            strokeWidth: -1
            fillColor: Qt.alpha(Colors.base, 0.85)
            startX: 0
            startY: 0

            PathLine { x: leftPath.w + leftPath.r; y: 0 }
            PathArc {
                x: leftPath.w
                y: leftPath.r
                radiusX: leftPath.r
                radiusY: leftPath.r
                direction: PathArc.Counterclockwise
            }
            PathLine { x: leftPath.w; y: leftPath.h - 2 * leftPath.r }
            PathArc {
                x: leftPath.w - leftPath.r
                y: leftPath.h - leftPath.r
                radiusX: leftPath.r
                radiusY: leftPath.r
                direction: PathArc.Clockwise
            }
            PathLine { x: leftPath.r; y: leftPath.h - leftPath.r }
            PathArc {
                x: 0
                y: leftPath.h
                radiusX: leftPath.r
                radiusY: leftPath.r
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: 0 }
        }

        // ---- CENTER PILL ----
        ShapePath {
            id: centerPath

            property real r: 18
            property real w: centerContent.width + 32
            property real h: root.height
            property real startXPos: (root.width - w) / 2

            strokeWidth: -1
            fillColor: Qt.alpha(Colors.base, 0.85)
            startX: centerPath.startXPos - centerPath.r
            startY: 0

            PathLine { x: centerPath.startXPos + centerPath.w + centerPath.r; y: 0 }
            PathArc {
                x: centerPath.startXPos + centerPath.w
                y: centerPath.r
                radiusX: centerPath.r
                radiusY: centerPath.r
                direction: PathArc.Counterclockwise
            }
            PathLine { x: centerPath.startXPos + centerPath.w; y: centerPath.h - 2 * centerPath.r }
            PathArc {
                x: centerPath.startXPos + centerPath.w - centerPath.r
                y: centerPath.h - centerPath.r
                radiusX: centerPath.r
                radiusY: centerPath.r
                direction: PathArc.Clockwise
            }
            PathLine { x: centerPath.startXPos + centerPath.r; y: centerPath.h - centerPath.r }
            PathArc {
                x: centerPath.startXPos
                y: centerPath.h - 2 * centerPath.r
                radiusX: centerPath.r
                radiusY: centerPath.r
                direction: PathArc.Clockwise
            }
            PathLine { x: centerPath.startXPos; y: centerPath.r }
            PathArc {
                x: centerPath.startXPos - centerPath.r
                y: 0
                radiusX: centerPath.r
                radiusY: centerPath.r
                direction: PathArc.Counterclockwise
            }
        }

        // ---- RIGHT PILL ----
        ShapePath {
            id: rightPath

            property real r: 18
            property real w: rightContent.width + 32
            property real h: root.height
            property real startXPos: root.width - w

            strokeWidth: -1
            fillColor: Qt.alpha(Colors.base, 0.85)
            startX: rightPath.startXPos - rightPath.r
            startY: 0

            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: rightPath.h }
            PathArc {
                x: root.width - rightPath.r
                y: rightPath.h - rightPath.r
                radiusX: rightPath.r
                radiusY: rightPath.r
                direction: PathArc.Counterclockwise
            }
            PathLine { x: rightPath.startXPos + rightPath.r; y: rightPath.h - rightPath.r }
            PathArc {
                x: rightPath.startXPos
                y: rightPath.h - 2 * rightPath.r
                radiusX: rightPath.r
                radiusY: rightPath.r
                direction: PathArc.Clockwise
            }
            PathLine { x: rightPath.startXPos; y: rightPath.r }
            PathArc {
                x: rightPath.startXPos - rightPath.r
                y: 0
                radiusX: rightPath.r
                radiusY: rightPath.r
                direction: PathArc.Counterclockwise
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
                id: leftContent

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                BarButton {
                    icon: "\udb82\udcc7"
                    onClicked: root.togglePower()
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.overlay
                }

                Workspaces {
                }

                Item {
                    id: todoContainer

                    property bool showTodo: todoCount > 0

                    visible: opacity > 0
                    implicitWidth: showTodo ? todoContentRow.implicitWidth : 0
                    implicitHeight: todoContentRow.implicitHeight
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    opacity: showTodo ? 1.0 : 0.0
                    clip: true

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    RowLayout {
                        id: todoContentRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 1
                            height: 14
                            color: Colors.overlay
                        }

                        Item {
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

            }

        }

        // =========================
        // CENTER
        // =========================
        Item {
            Layout.fillWidth: true

            RowLayout {
                id: centerContent

                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: clockText

                    text: Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
                    color: Colors.text
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleCal()
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
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
                id: rightContent

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
                    color: Qt.alpha(Colors.red, 0.2)
                    border.color: Colors.red
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
                            color: Colors.red
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
                            color: Colors.red
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