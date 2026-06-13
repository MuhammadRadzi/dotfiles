import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    property string deviceName: ""
    property string deviceMac: ""
    property bool connected: false
    property bool paired: false
    property string deviceType: "generic"

    implicitHeight: 52
    radius: 10
    color: connected ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : (tileHover.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        // Device type icon
        Text {
            text: deviceType === "audio" ? "\udb80\udece" : deviceType === "phone" ? "\uf10b" : deviceType === "computer" ? "\uf109" : deviceType === "peripheral" ? "\uf11c" : "\udb80\udcaf"
            color: connected ? Colors.accent : Colors.subtle
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }

            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: deviceName !== "" ? deviceName : deviceMac
                color: Colors.text
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                font.weight: connected ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: connected ? "Connected" : paired ? "Paired" : "Available"
                color: connected ? Colors.accent : paired ? Colors.subtle : Colors.subtle
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
            }

        }

        // Action button
        Rectangle {
            implicitWidth: actionLabel.implicitWidth + 20
            height: 28
            radius: 6
            color: actionHover.containsMouse ? (connected ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.3) : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)) : (connected ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.15) : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15))

            Text {
                id: actionLabel

                anchors.centerIn: parent
                text: connected ? "Disconnect" : paired ? "Connect" : "Pair"
                color: connected ? Colors.red : Colors.accent
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: actionHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (connected)
                        actionProc.command = ["bluetoothctl", "disconnect", deviceMac];
                    else if (paired)
                        actionProc.command = ["bluetoothctl", "connect", deviceMac];
                    else
                        actionProc.command = ["bluetoothctl", "pair", deviceMac];
                    actionProc.running = true;
                }
            }

            Process {
                id: actionProc

                running: false
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }

            }

        }

    }

    MouseArea {
        id: tileHover

        anchors.fill: parent
        hoverEnabled: true
        enabled: false // just for hover effect
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }

    }

}
