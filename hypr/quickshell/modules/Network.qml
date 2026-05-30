import "../theme"
import QtQuick
import Quickshell.Io

Item {
    property string netInfo: "..."

    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    Text {
        id: label

        anchors.centerIn: parent
        text: netInfo
        color: Colors.text
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
    }

    Process {
        id: netProc

        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                netInfo = data.trim() !== "" ? "󰤨 " + data.trim() : "󰤭 offline";
            }
        }

    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

}
