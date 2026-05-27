import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: osd

    property string type: ""   // "volume" atau "brightness"
    property int value: 0
    property bool muted: false

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
    implicitWidth: 1920
    implicitHeight: 1080

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true

    color: "transparent"

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osd.visible = false
    }

    Rectangle {
        x: (parent.width - width) / 2
        y: 64
        width: 280
        height: 52
        radius: 14
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            // Icon
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

            // Bar
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

            // Value
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