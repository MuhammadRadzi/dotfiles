import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: wallpaperSelector

    property bool isOpen: false

    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true

    color: "transparent"

    property var wallpapers: []
    property string wallpaperDir: Quickshell.env("HOME") + "/.config/hypr/assets/wallpapers"
    property string thumbDir: Quickshell.env("HOME") + "/.config/hypr/assets/thumbnails"

    onIsOpenChanged: if (isOpen) scanProc.running = true

    // Background overlay
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: wallpaperSelector.isOpen = false
        }

        // Panel tengah
        Rectangle {
            anchors.centerIn: parent
            width: 600
            height: Math.min(wallpaperGrid.implicitHeight + 80, 500)
            radius: 16
            color: "#e6161920"
            border.width: 1
            border.color: "#22ffffff"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "WALLPAPER"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: wallpapers.length + " files"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                // Grid
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: wallpaperGrid.implicitHeight
                    clip: true

                    Grid {
                        id: wallpaperGrid
                        width: parent.width
                        columns: 3
                        spacing: 8

                        Repeater {
                            model: wallpapers

                            Rectangle {
                                width: (wallpaperGrid.width - 16) / 3
                                height: width * 0.6
                                radius: 8
                                clip: true
                                border.width: 2
                                border.color: thumbArea.containsMouse ? Colors.accent : "transparent"
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + thumbDir + "/" + modelData.split("/").pop()
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.surface
                                    visible: parent.children[0].status !== Image.Ready
                                    radius: 8
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰋯"
                                        color: Colors.subtle
                                        font.pixelSize: 20
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }

                                MouseArea {
                                    id: thumbArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        setWallProc.command = ["awww", "img", modelData,
                                            "--transition-type", "fade",
                                            "--transition-duration", "2"]
                                        setWallProc.running = true
                                        wallpaperSelector.isOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "find " + wallpaperDir + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        stdout: SplitParser {
            property var list: []
            onRead: data => {
                if (data.trim()) list.push(data.trim())
            }
        }
        onRunningChanged: {
            if (!running) {
                wallpapers = scanProc.stdout.list.slice()
                scanProc.stdout.list = []
            }
        }
    }

    Process {
        id: setWallProc
        running: false
    }
}