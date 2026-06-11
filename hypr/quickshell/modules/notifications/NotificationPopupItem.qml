import "../../theme"
import QtQuick
import QtQuick.Layouts

Item {
    id: popupItem

    required property int uid
    required property string summary
    required property string body
    required property string appName
    required property string appIcon
    required property var urgency

    signal dismissed(int uid)

    width: 340
    implicitHeight: card.height

    Timer {
        id: dismissTimer
        interval: 5000
        running: true
        repeat: false
        onTriggered: popupItem.dismissed(uid)
    }

    Rectangle {
        id: card
        width: parent.width
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
                if (urgency === 2) return Colors.red;      // Critical
                if (urgency === 0) return Colors.overlay;  // Low
                return Colors.accent;                      // Normal
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
                    visible: appIcon !== ""
                    source: appIcon !== "" ? ("image://icon/" + appIcon) : ""
                    width: 14; height: 14
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: appName || "system"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                // Countdown bar
                Rectangle {
                    width: 48; height: 3; radius: 2
                    color: "#22ffffff"
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Colors.accent
                        NumberAnimation on width {
                            from: 48; to: 0
                            duration: 5000
                            running: true
                            easing.type: Easing.Linear
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: summary
                color: Colors.text
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                visible: body !== ""
                Layout.fillWidth: true
                text: body
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
                onClicked: popupItem.dismissed(uid)
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            onEntered: dismissTimer.stop()
            onExited: dismissTimer.start()
            onClicked: popupItem.dismissed(uid)
        }
    }
}