import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popupRoot

    required property ListModel popupModel

    signal removeRequested(int uid)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.right: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: popupModel.count > 0
    implicitWidth: 364
    implicitHeight: popupColumn.implicitHeight + 10

    Column {
        id: popupColumn

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 11
        anchors.rightMargin: 12
        spacing: 8

        Repeater {
            model: popupRoot.popupModel

            delegate: Item {
                id: delegateItem

                required property int index
                required property int uid
                required property string summary
                required property string body
                required property string appName
                required property string appIcon
                required property var urgency

                width: 340
                implicitHeight: visible ? card.height + 8 : 0
                opacity: 1
                clip: true
                // Slide in from right on appear
                Component.onCompleted: {
                    card.x = 380;
                    slideInAnim.start();
                }

                Timer {
                    id: dismissTimer

                    interval: 5000
                    running: true
                    repeat: false
                    onTriggered: dismissAnim.start()
                }

                // Slide out to right + fade, then remove
                SequentialAnimation {
                    id: dismissAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: card
                            property: "x"
                            to: 380
                            duration: 280
                            easing.type: Easing.InCubic
                        }

                        NumberAnimation {
                            target: delegateItem
                            property: "opacity"
                            to: 0
                            duration: 280
                            easing.type: Easing.InCubic
                        }

                    }

                    ScriptAction {
                        script: popupRoot.removeRequested(delegateItem.uid)
                    }

                }

                NumberAnimation {
                    id: slideInAnim

                    target: card
                    property: "x"
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                Rectangle {
                    id: card

                    width: 340
                    height: cardCol.implicitHeight + 20
                    radius: 10
                    color: "#ee16181c"
                    border.width: 1
                    border.color: "#33ffffff"

                    // Urgency bar
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        width: 3
                        radius: 2
                        color: {
                            if (delegateItem.urgency === 2)
                                return Colors.red;

                            if (delegateItem.urgency === 0)
                                return Colors.overlay;

                            return Colors.accent;
                        }
                    }

                    ColumnLayout {
                        id: cardCol

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 36
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Image {
                                visible: delegateItem.appIcon !== ""
                                source: delegateItem.appIcon !== "" ? ("image://icon/" + delegateItem.appIcon) : ""
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: delegateItem.appName || "system"
                                color: Colors.subtle
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                font.letterSpacing: 1
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // Countdown bar
                            Rectangle {
                                width: 48
                                height: 3
                                radius: 2
                                color: "#22ffffff"

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    color: Colors.accent

                                    NumberAnimation on width {
                                        from: 48
                                        to: 0
                                        duration: 5000
                                        running: true
                                        easing.type: Easing.Linear
                                    }

                                }

                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            text: delegateItem.summary
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: delegateItem.body !== ""
                            Layout.fillWidth: true
                            text: delegateItem.body
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                    }

                    // Close button
                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        text: "\uf00d"
                        color: closeArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: closeArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dismissAnim.start()
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        onEntered: dismissTimer.stop()
                        onExited: {
                            if (!dismissAnim.running)
                                dismissTimer.start();

                        }
                        onClicked: dismissAnim.start()
                    }

                }

                // Animate implicitHeight collapse after slide out
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
