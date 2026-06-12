import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: cheatsheet

    property bool isOpen: false

    function toggle() { isOpen = !isOpen }

    visible: overlayRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"
    

    Rectangle {
        id: overlayRect

        anchors.fill: parent
        color: "#cc000000"
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: cheatsheet.isOpen = false
        }

        Rectangle {
            id: panelRect

            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 800
            height: contentCol.implicitHeight + 48
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
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

                    Item {
                        Layout.fillWidth: true
                    }

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

                // Keybinds Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 0
                    columnSpacing: 32

                    // Left Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [{
                                "category": "APPS"
                            }, {
                                "key": "Super + T",
                                "desc": "Terminal"
                            }, {
                                "key": "Super + E",
                                "desc": "File Manager"
                            }, {
                                "key": "Super + D",
                                "desc": "App Launcher"
                            }, {
                                "key": "Super + F",
                                "desc": "Browser"
                            }, {
                                "key": "",
                                "desc": ""
                            }, {
                                "category": "WINDOWS"
                            }, {
                                "key": "Super + Q",
                                "desc": "Close window"
                            }, {
                                "key": "Super + X",
                                "desc": "Toggle float"
                            }, {
                                "key": "Super + Shift + F",
                                "desc": "Fullscreen"
                            }, {
                                "key": "Super + J",
                                "desc": "Toggle split"
                            }, {
                                "key": "Super + Arrows",
                                "desc": "Move focus"
                            }, {
                                "key": "Super + Shift + Arrows",
                                "desc": "Move window"
                            }, {
                                "key": "Super + Alt + Arrows",
                                "desc": "Resize window"
                            }, {
                                "key": "Super + Left Click",
                                "desc": "Move window"
                            }, {
                                "key": "Super + Right Click",
                                "desc": "Resize window"
                            }]

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
                                        color: "#22ffffff"

                                        Text {
                                            id: keyText

                                            anchors.centerIn: parent
                                            text: modelData.key || ""
                                            color: Colors.text
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

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

                    // Right Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [{
                                "category": "WORKSPACES"
                            }, {
                                "key": "Super + 1-9",
                                "desc": "Switch workspace"
                            }, {
                                "key": "Super + Shift + 1-9",
                                "desc": "Move to workspace"
                            }, {
                                "key": "Super + scroll",
                                "desc": "Scroll workspace"
                            }, {
                                "key": "",
                                "desc": ""
                            }, {
                                "category": "QUICKSHELL"
                            }, {
                                "key": "Super + W",
                                "desc": "Wallpaper selector"
                            }, {
                                "key": "Super + V",
                                "desc": "Clipboard"
                            }, {
                                "key": "Super + N",
                                "desc": "Notifications"
                            }, {
                                "key": "Super + Esc",
                                "desc": "Power menu"
                            }, {
                                "key": "Super + F1",
                                "desc": "This Cheatsheet"
                            }, {
                                "key": "SUPER + R",
                                "desc": "Reload Quickshell"
                            }, {
                                "key": "",
                                "desc": ""
                            }, {
                                "category": "SYSTEM"
                            }, {
                                "key": "Super + L",
                                "desc": "Lock screen"
                            }, {
                                "key": "Print",
                                "desc": "Screenshot"
                            }]

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
                                        color: "#22ffffff"

                                        Text {
                                            id: keyText2

                                            anchors.centerIn: parent
                                            text: modelData.key || ""
                                            color: Colors.text
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

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

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

}
