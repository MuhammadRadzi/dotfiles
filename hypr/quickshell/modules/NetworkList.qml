import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: parent.width
    implicitHeight: networkCol.implicitHeight

    property var networks: []
    property string connectingTo: ""

    Component.onCompleted: netProc.running = true

    ColumnLayout {
        id: networkCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4

        // Reload button
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: reloadArea.containsMouse ? Colors.overlay : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Text {
                    text: "󰑐  Refresh"
                    color: Colors.subtle
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                }
                Item { Layout.fillWidth: true }
            }

            MouseArea {
                id: reloadArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    networks = []
                    netProc.running = true
                }
            }
        }

        // Network list
        Repeater {
            model: networks

            Rectangle {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                height: 36
                radius: 6
                color: modelData.active ? Colors.overlay : (netItemArea.containsMouse ? "#11ffffff" : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: modelData.active ? "󰤨" : "󰤫"
                        color: modelData.active ? Colors.accent : Colors.subtle
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        text: modelData.ssid
                        color: modelData.active ? Colors.text : Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: modelData.active
                        text: "󰄬"
                        color: Colors.green
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        visible: connectingTo === modelData.ssid
                        text: "..."
                        color: Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: netItemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    visible: !modelData.active
                    onClicked: {
                        connectingTo = modelData.ssid
                        askPassProc.command = [
                            "sh", "-c",
                            "pass=$(rofi -dmenu -password -p 'Password: " + modelData.ssid + "' -theme-str 'entry { placeholder: \"\"; }' -config ~/.config/hypr/rofi/config.rasi) && [ -n \"$pass\" ] && nmcli dev wifi connect '" + modelData.ssid + "' password \"$pass\""
                        ]
                        askPassProc.running = true
                    }
                }
            }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | head -10"]
        stdout: SplitParser {
            property var list: []
            onRead: data => {
                if (!data.trim()) return
                var parts = data.trim().split(":")
                if (parts[1] && parts[1].trim() !== "")
                    list.push({ active: parts[0] === "yes", ssid: parts[1].trim() })
            }
        }
        onRunningChanged: {
            if (!running) {
                networks = netProc.stdout.list.slice()
                netProc.stdout.list = []
                connectingTo = ""
            }
        }
    }

    Process {
        id: askPassProc
        running: false
        onRunningChanged: if (!running) netProc.running = true
    }
}