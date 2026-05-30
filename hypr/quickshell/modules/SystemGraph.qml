import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 180
    implicitHeight: 34

    color: "transparent"

    // ── State ──────────────────────────────────────────────────────────────
    property var ramHistory: [0,0,0,0,0,0,0,0,0,0,0,0]
    property var gpuHistory: [0,0,0,0,0,0,0,0,0,0,0,0]

    // RAM
    property int memTotal: 1
    property int memAvail: 0
    property int ramPct:   0

    // GPU
    property int gpuCur: 0
    property int gpuMax: 1
    property int gpuPct: 0

    // ── UI ─────────────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 10

        // GPU
        RowLayout {
            spacing: 4

            Text {
                text: "GPU"
                color: "#f38ba8"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
            }

            Canvas {
                id: gpuGraph
                width: 45
                height: 16

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let step = width / (root.gpuHistory.length - 1)
                    ctx.beginPath()
                    ctx.strokeStyle = "#f38ba8"
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    for (let i = 0; i < root.gpuHistory.length; i++) {
                        let x = i * step
                        let y = height - (root.gpuHistory[i] / 100) * height
                        if (i === 0) ctx.moveTo(x, y)
                        else         ctx.lineTo(x, y)
                    }
                    ctx.stroke()
                }
            }
        }

        // RAM
        RowLayout {
            spacing: 4

            Text {
                text: "RAM"
                color: "#89b4fa"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
            }

            Canvas {
                id: ramGraph
                width: 45
                height: 16

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let step = width / (root.ramHistory.length - 1)
                    ctx.beginPath()
                    ctx.strokeStyle = "#89b4fa"
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    for (let i = 0; i < root.ramHistory.length; i++) {
                        let x = i * step
                        let y = height - (root.ramHistory[i] / 100) * height
                        if (i === 0) ctx.moveTo(x, y)
                        else         ctx.lineTo(x, y)
                    }
                    ctx.stroke()
                }
            }
        }
    }

    // ── Data Sources ───────────────────────────────────────────────────────

    // RAM
    Process {
        id: ramProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: SplitParser {
            property int total: 0
            property int avail: 0
            property int lineCount: 0

            onRead: data => {
                var line = data.trim()
                if (line.startsWith("MemTotal:")) {
                    total = parseInt(line.replace(/[^0-9]/g, "")) || 1
                    lineCount++
                } else if (line.startsWith("MemAvailable:")) {
                    avail = parseInt(line.replace(/[^0-9]/g, "")) || 0
                    lineCount++
                }
                if (lineCount >= 2) {
                    root.memTotal = total
                    root.memAvail = avail
                    root.ramPct = Math.round((total - avail) / total * 100)
                    lineCount = 0

                    var h = root.ramHistory.slice(1)
                    h.push(root.ramPct)
                    root.ramHistory = h
                    ramGraph.requestPaint()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // GPU
    Process {
        id: gpuProc
        command: [
            "sh", "-c",
            "CUR=$(cat /sys/class/drm/card1/gt/gt0/rps_cur_freq_mhz 2>/dev/null || cat /sys/class/drm/card0/gt/gt0/rps_cur_freq_mhz 2>/dev/null || echo 0); " +
            "MAX=$(cat /sys/class/drm/card1/gt/gt0/rps_max_freq_mhz 2>/dev/null || cat /sys/class/drm/card0/gt/gt0/rps_max_freq_mhz 2>/dev/null || echo 1); " +
            "echo $CUR $MAX"
        ]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                var cur = parseInt(parts[0]) || 0
                var max = parseInt(parts[1]) || 1
                root.gpuCur = cur
                root.gpuMax = max
                root.gpuPct = max > 0 ? Math.round(cur / max * 100) : 0

                var h = root.gpuHistory.slice(1)
                h.push(root.gpuPct)
                root.gpuHistory = h
                gpuGraph.requestPaint()
            }
        }
        Component.onCompleted: running = true
    }

    // ── Poll Timer ─────────────────────────────────────────────────────────
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            ramProc.running = true
            gpuProc.running = true
        }
    }

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
}
