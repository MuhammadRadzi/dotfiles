import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: cheatsheet

    property bool isOpen: false

    visible: isOpen
    implicitWidth: 1920
    implicitHeight: 1080

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "#cc000000"

        MouseArea {
            anchors.fill: parent
            onClicked: cheatsheet.isOpen = false
        }

        Rectangle {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 800
            height: contentCol.implicitHeight + 48
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "KEYBINDS"
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 2
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Super + F1 to close"
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.overlay
                }

                // Grid keybinds
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 0
                    columnSpacing: 32

                    // Kolom kiri
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [
                                { category: "APPS" },
                                { key: "Super + Q",       desc: "Terminal (kitty)" },
                                { key: "Super + E",       desc: "File manager" },
                                { key: "Super + R",       desc: "App launcher" },
                                { key: "Super + B",       desc: "Browser" },
                                { key: "",                desc: "" },
                                { category: "WINDOWS" },
                                { key: "Super + C",       desc: "Close window" },
                                { key: "Super + V",       desc: "Toggle float" },
                                { key: "Super + F",       desc: "Fullscreen" },
                                { key: "Super + J",       desc: "Toggle split" },
                                { key: "Super + arrows",  desc: "Move focus" },
                                { key: "Super+Shift+↕↔",  desc: "Move window" },
                                { key: "Super+Alt+↕↔",    desc: "Resize window" },
                                { key: "Super + click",   desc: "Move window" },
                                { key: "Super + RClick",  desc: "Resize window" },
                            ]

                            delegate: Item {
                                Layout.fillWidth: true
                                implicitHeight: modelData.category ? 32 : 28

                                Text {
                                    visible: modelData.category !== undefined
                                    text: modelData.category || ""
                                    color: Colors.accent
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.letterSpacing: 1.5
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                }

                                RowLayout {
                                    visible: modelData.key !== undefined
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        visible: modelData.key !== ""
                                        implicitWidth: keyText.implicitWidth + 12
                                        implicitHeight: 20
                                        radius: 4
                                        color: Colors.overlay

                                        Text {
                                            id: keyText
                                            anchors.centerIn: parent
                                            text: modelData.key || ""
                                            color: Colors.text
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: modelData.desc || ""
                                        color: Colors.subtle
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }
                        }
                    }

                    // Kolom kanan
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [
                                { category: "WORKSPACES" },
                                { key: "Super + 1-9",     desc: "Switch workspace" },
                                { key: "Super+Shift+1-9", desc: "Move to workspace" },
                                { key: "Super + scroll",  desc: "Scroll workspace" },
                                { key: "",                desc: "" },
                                { category: "QUICKSHELL" },
                                { key: "Super + W",       desc: "Wallpaper selector" },
                                { key: "Super + N",       desc: "Notifications" },
                                { key: "Super + Esc",     desc: "Power menu" },
                                { key: "Super + F1",      desc: "This cheatsheet" },
                                { key: "",                desc: "" },
                                { category: "SYSTEM" },
                                { key: "Super + L",       desc: "Lock screen" },
                                { key: "Print",           desc: "Screenshot area" },
                                { key: "Super + Print",   desc: "Screenshot full" },
                                { key: "Super+Shift+S",   desc: "Screenshot area" },
                            ]

                            delegate: Item {
                                Layout.fillWidth: true
                                implicitHeight: modelData.category ? 32 : 28

                                Text {
                                    visible: modelData.category !== undefined
                                    text: modelData.category || ""
                                    color: Colors.accent
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.letterSpacing: 1.5
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                }

                                RowLayout {
                                    visible: modelData.key !== undefined
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        visible: modelData.key !== ""
                                        implicitWidth: keyText2.implicitWidth + 12
                                        implicitHeight: 20
                                        radius: 4
                                        color: Colors.overlay

                                        Text {
                                            id: keyText2
                                            anchors.centerIn: parent
                                            text: modelData.key || ""
                                            color: Colors.text
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: modelData.desc || ""
                                        color: Colors.subtle
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}