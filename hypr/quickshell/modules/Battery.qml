import "../theme"
import QtQuick
import Quickshell.Io

Item {
    property int batLevel: 0
    property bool charging: false

    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    Text {
        id: label

        anchors.centerIn: parent
        text: {
            if (charging)
                return "󰂄 " + batLevel + "%";

            if (batLevel > 80)
                return "󰁹 " + batLevel + "%";

            if (batLevel > 50)
                return "󰁾 " + batLevel + "%";

            if (batLevel > 20)
                return "󰁻 " + batLevel + "%";

            return "󰁺 " + batLevel + "%";
        }
        color: batLevel < 20 && !charging ? Colors.red : Colors.text
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
    }

    Process {
        id: batProc

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            property var lines: []

            onRead: (data) => {
                lines.push(data.trim());
                if (lines.length >= 2) {
                    batLevel = parseInt(lines[0]) || 0;
                    charging = lines[1] === "Charging";
                    lines = [];
                }
            }
        }

    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batProc.running = true
    }

}
