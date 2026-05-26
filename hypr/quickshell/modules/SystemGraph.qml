import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    implicitWidth: 180
    implicitHeight: 34

    color: "transparent"


    property var ramHistory: [20,24,22,28,32,25,23,35,42,38,30,28]
    property int ramUsage: 73
    property var gpuHistory: [10,12,14,20,28,18,12,25,35,30,22,16]
    property int gpuUsage: 0

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

                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
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

                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }

                ctx.stroke()
            }
        }
    }
}

    Timer {
    interval: 1000
    running: true
    repeat: true

    onTriggered: {
        ramUsage = Math.floor(Math.random() * 40) + 40
        gpuUsage = Math.floor(Math.random() * 50) + 10

        ramHistory.shift()
        gpuHistory.shift()

        ramHistory.push(ramUsage)
        gpuHistory.push(gpuUsage)

        ramGraph.requestPaint()
        gpuGraph.requestPaint()
    }
}

    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }
}