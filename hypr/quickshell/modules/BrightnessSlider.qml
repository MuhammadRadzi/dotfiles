import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property int brightness: 0

    implicitWidth: parent.width
    implicitHeight: 40
    Component.onCompleted: brightProc.running = true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: brightness > 50 ? "\uf186" : "\uf185"
            color: Colors.text
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Colors.overlay

            Rectangle {
                width: parent.width * (brightness / 100)
                height: parent.height
                radius: 2
                color: Colors.accent

                Behavior on width {
                    NumberAnimation {
                        duration: 100
                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onClicked: (mouse) => {
                    var newBright = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)));
                    setBrightProc.command = ["brightnessctl", "set", newBright + "%"];
                    setBrightProc.running = true;
                }
                onPositionChanged: (mouse) => {
                    if (!pressed)
                        return ;

                    var newBright = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)));
                    setBrightProc.command = ["brightnessctl", "set", newBright + "%"];
                    setBrightProc.running = true;
                }
                cursorShape: Qt.PointingHandCursor
            }

        }

        Text {
            text: brightness + "%"
            color: Colors.subtle
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.minimumWidth: 36
        }

    }

    Process {
        id: brightProc

        command: ["sh", "-c", "brightnessctl get && brightnessctl max"]

        stdout: SplitParser {
            property var lines: []

            onRead: (data) => {
                lines.push(data.trim());
                if (lines.length >= 2) {
                    brightness = Math.round(100 * parseInt(lines[0]) / parseInt(lines[1]));
                    lines = [];
                }
            }
        }

    }

    Process {
        id: setBrightProc

        running: false
        onRunningChanged: {
            if (!running)
                brightProc.running = true;

        }
    }

}
