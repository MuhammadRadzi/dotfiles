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
                return "\udb80\udc84 " + batLevel + "%";

            if (batLevel > 80)
                return "\udb80\udc79 " + batLevel + "%";

            if (batLevel > 50)
                return "\udb80\udc7e " + batLevel + "%";

            if (batLevel > 20)
                return "\udb80\udc7b " + batLevel + "%";

            return "\udb80\udc7a " + batLevel + "%";
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
