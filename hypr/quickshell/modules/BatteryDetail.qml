import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property int level: 0
    property string status: ""
    property string timeLeft: ""

    implicitWidth: parent.width
    implicitHeight: 40
    Component.onCompleted: batProc.running = true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: status === "Charging" ? "󰂄" : level > 80 ? "󰁹" : level > 50 ? "󰁾" : level > 20 ? "󰁻" : "󰁺"
            color: status === "Charging" ? Colors.green : level < 20 ? Colors.red : Colors.text
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Colors.overlay

                Rectangle {
                    width: parent.width * (level / 100)
                    height: parent.height
                    radius: 2
                    color: status === "Charging" ? Colors.green : level < 20 ? Colors.red : Colors.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                        }

                    }

                }

            }

            Text {
                text: status + (timeLeft !== "" ? "  •  " + timeLeft : "")
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

        }

        Text {
            text: level + "%"
            color: Colors.text
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.minimumWidth: 36
        }

    }

    Process {
        id: batProc

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status"]

        stdout: SplitParser {
            property var lines: []

            onRead: (data) => {
                lines.push(data.trim());
                if (lines.length >= 2) {
                    level = parseInt(lines[0]) || 0;
                    status = lines[1];
                    lines = [];
                }
            }
        }

    }

}
