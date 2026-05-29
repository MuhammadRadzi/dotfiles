import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PopupWindow {
    id: osd

    property var bar: null
    property string type: ""
    property int value: 0
    property bool muted: false

    anchor.window: bar
    anchor.rect.x: bar ? (bar.width - 280) / 2 : 0
    anchor.rect.y: bar ? bar.implicitHeight + 8 : 64

    function showVolume(val, isMuted) {
        type = "volume"
        value = val
        muted = isMuted
        visible = true
        hideTimer.restart()
    }

    function showBrightness(val) {
        type = "brightness"
        value = val
        visible = true
        hideTimer.restart()
    }

    visible: false
    implicitWidth: 280
    implicitHeight: 52

    color: "transparent"

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osd.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: {
                    if (type === "volume") {
                        return muted ? "\udb81\udf5f" : value >= 50 ? "\uf028" : "\uf027"
                    } else {
                        return value > 50 ? "\uf185" : "\uf186"
                    }
                }
                color: type === "volume" ? (muted ? Colors.subtle : Colors.text) : Colors.yellow
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Colors.overlay

                Rectangle {
                    width: parent.width * (value / 100)
                    height: parent.height
                    radius: 2
                    color: {
                        if (type === "brightness") return Colors.yellow
                        if (muted) return Colors.subtle
                        return Colors.accent
                    }
                    Behavior on width { NumberAnimation { duration: 100 } }
                }
            }

            Text {
                text: muted ? "mute" : value + "%"
                color: Colors.subtle
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                Layout.minimumWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}