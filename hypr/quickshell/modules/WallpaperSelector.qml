import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wallpaperSelector

    property bool isOpen: false
    property var wallpapers: []
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string thumbDir: Quickshell.env("HOME") + "/.cache/hypr/thumbnails"
    property string homePath: Quickshell.env("HOME")

    visible: panelRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"
    onIsOpenChanged: {
        if (isOpen)
            scanProc.running = true;

    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: wallpaperSelector.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 600
            height: Math.min(wallpaperGrid.implicitHeight + 80, 500)
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            opacity: isOpen ? 1 : 0
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

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

                    Item {
                        Layout.fillWidth: true
                    }

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

                                Image {
                                    id: thumbImg

                                    anchors.fill: parent
                                    source: "file://" + thumbDir + "/" + modelData.split("/").pop()
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    cache: false
                                    onStatusChanged: {
                                        // If thumbnail missing, generate it via wallpaper.sh convert step
                                        if (status === Image.Error) {
                                            genThumbProc.command = ["convert", modelData, "-resize", "300x180^", "-gravity", "Center", "-extent", "300x180", thumbDir + "/" + modelData.split("/").pop()];
                                            genThumbProc.running = true;
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.surface
                                    visible: thumbImg.status !== Image.Ready
                                    radius: 8

                                    Text {
                                        anchors.centerIn: parent
                                        text: thumbImg.status === Image.Error ? "\uf021" : "\uf03e"
                                        color: Colors.subtle
                                        font.pixelSize: 20
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                }

                                Process {
                                    id: genThumbProc

                                    running: false
                                    onRunningChanged: {
                                        if (!running) {
                                            // Reload image after thumbnail generated
                                            thumbImg.source = "";
                                            thumbImg.source = "file://" + thumbDir + "/" + modelData.split("/").pop();
                                        }
                                    }
                                }

                                MouseArea {
                                    id: thumbArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        setWallProc.command = ["bash", homePath + "/.config/hypr/scripts/wallpaper.sh", modelData];
                                        setWallProc.running = true;
                                        wallpaperSelector.isOpen = false;
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                        }

                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Process {
        id: scanProc

        command: ["sh", "-c", "find " + wallpaperDir + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        onRunningChanged: {
            if (!running) {
                wallpapers = scanProc.stdout.list.slice();
                scanProc.stdout.list = [];
            }
        }

        stdout: SplitParser {
            property var list: []

            onRead: (data) => {
                if (data.trim())
                    list.push(data.trim());

            }
        }

    }

    Process {
        id: setWallProc

        running: false
    }

}
