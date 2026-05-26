import QtQuick
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    property string netInfo: "..."

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
        stdout: SplitParser {
            onRead: data => {
                netInfo = data.trim() !== "" ? "󰤨 " + data.trim() : "󰤭 offline"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }
}