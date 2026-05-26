import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: parent.height

    property int cpuUsage: 0
    property int memUsage: 0
    property int lastCpuTotal: 0
    property int lastCpuIdle: 0

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: " " + cpuUsage + "%"
            color: cpuUsage > 80 ? Colors.red : Colors.text
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            text: " " + memUsage + "%"
            color: memUsage > 80 ? Colors.red : Colors.text
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (lastCpuTotal > 0)
                    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                lastCpuTotal = total
                lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                memUsage = Math.round(100 * parseInt(parts[2]) / parseInt(parts[1]))
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }
}