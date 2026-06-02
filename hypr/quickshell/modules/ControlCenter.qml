import "."
import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: controlCenter

    property bool isOpen: false

    function toggle() {
        isOpen = !isOpen;
    }

    visible: panelRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"
    onIsOpenChanged: {
        if (isOpen) {
            wifiStatusProc.running = true;
            btStatusProc.running = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: controlCenter.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 16
            anchors.topMargin: 56 + 8
            width: 320
            height: ccCol.implicitHeight + 32
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            clip: true
            opacity: isOpen ? 1 : 0

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

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

                    VolumeSlider {
                        Layout.fillWidth: true
                    }

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

                    BrightnessSlider {
                        Layout.fillWidth: true
                    }

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

                    BatteryDetail {
                        Layout.fillWidth: true
                    }

                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.overlay
                }

                // Connections
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "CONNECTIONS"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Wi-Fi toggle
                        Rectangle {
                            id: wifiToggle

                            property bool wifiEnabled: false

                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: wifiEnabled ? Colors.accent : "#22ffffff"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "\udb82\udd28"
                                    color: wifiToggle.wifiEnabled ? Colors.base : Colors.subtle
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                                Text {
                                    text: "Wi-Fi"
                                    color: wifiToggle.wifiEnabled ? Colors.base : Colors.subtle
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiToggle.wifiEnabled ? "off" : "on"];
                                    wifiToggleProc.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        // Bluetooth toggle
                        Rectangle {
                            id: btToggle

                            property bool btEnabled: false

                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: btEnabled ? Colors.accent : "#22ffffff"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "\udb80\udcaf"
                                    color: btToggle.btEnabled ? Colors.base : Colors.subtle
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                                Text {
                                    text: "Bluetooth"
                                    color: btToggle.btEnabled ? Colors.base : Colors.subtle
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    btToggleProc.command = ["sh", "-c", btToggle.btEnabled ? "bluetoothctl power off" : "bluetoothctl power on"];
                                    btToggleProc.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

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

                    NetworkList {
                        Layout.fillWidth: true
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

            transform: Translate {
                x: isOpen ? 0 : 24

                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

    // Wi-Fi
    Process {
        id: wifiStatusProc

        command: ["nmcli", "radio", "wifi"]

        stdout: SplitParser {
            onRead: (data) => {
                wifiToggle.wifiEnabled = data.trim() === "enabled";
            }
        }

    }

    Process {
        id: wifiToggleProc

        running: false
        onRunningChanged: {
            if (!running) {
                wifiStatusProc.running = true;
            }
        }
    }

    // Bluetooth
    Process {
        id: btStatusProc

        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]

        stdout: SplitParser {
            onRead: (data) => {
                btToggle.btEnabled = data.trim() === "yes";
            }
        }

    }

    Process {
        id: btToggleProc

        running: false
        onRunningChanged: {
            if (!running) {
                btStatusProc.running = true;
            }
        }
    }

}
