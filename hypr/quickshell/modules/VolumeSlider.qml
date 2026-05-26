import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: parent.width
    implicitHeight: 40

    property int vol: 0
    property bool muted: false

    Component.onCompleted: volProc.running = true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: muted ? "󰝟" : vol >= 50 ? "󰕾" : "󰖀"
            color: Colors.text
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
            MouseArea {
                anchors.fill: parent
                onClicked: muteProc.running = true
                cursorShape: Qt.PointingHandCursor
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Colors.overlay

            Rectangle {
                width: parent.width * (vol / 100)
                height: parent.height
                radius: 2
                color: muted ? Colors.subtle : Colors.accent

                Behavior on width { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onClicked: mouse => {
                    var newVol = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)))
                    setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol + "%"]
                    setVolProc.running = true
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    var newVol = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)))
                    setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol + "%"]
                    setVolProc.running = true
                }
                cursorShape: Qt.PointingHandCursor
            }
        }

        Text {
            text: vol + "%"
            color: Colors.subtle
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.minimumWidth: 36
        }
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                muted = data.includes("MUTED")
                var match = data.match(/[\d.]+/)
                if (match) vol = Math.round(parseFloat(match[0]) * 100)
            }
        }
    }
    Process { id: muteProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; running: false; onRunningChanged: if (!running) volProc.running = true }
    Process { id: setVolProc; running: false; onRunningChanged: if (!running) volProc.running = true }
}