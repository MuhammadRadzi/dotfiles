import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."
import "../theme"

PopupWindow {
    id: controlCenter
    
    property bool isOpen: false

    function toggle() { isOpen = !isOpen }

    visible: isOpen
    anchor.window: root
    anchor.rect.x: root.width - 320 - 16
    anchor.rect.y: root.implicitHeight + 8

    width: 320
    height: ccCol.implicitHeight + 32
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#e6161920"
        border.width: 1
        border.color: "#22ffffff"

        ColumnLayout {
            id: ccCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // Header
            Text {
                text: "Control Center"
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                font.letterSpacing: 1.5
            }

            // Volume
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "VOLUME"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                }
                VolumeSlider { Layout.fillWidth: true }
            }

            // Brightness
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "BRIGHTNESS"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                }
                BrightnessSlider { Layout.fillWidth: true }
            }

            // Battery
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "BATTERY"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                }
                BatteryDetail { Layout.fillWidth: true }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.overlay
            }

            // Network
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "NETWORK"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                }
                NetworkList { Layout.fillWidth: true }
            }
        }
    }

    // Tutup kalau klik di luar
    MouseArea {
        anchors.fill: parent
        onClicked: controlCenter.isOpen = false
        z: -1
    }
}