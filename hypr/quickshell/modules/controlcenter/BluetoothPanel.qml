import "."
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: btPanel

    signal backPressed()

    property bool isOpen: false
    property bool initialized: false

    function toggle() {
        isOpen = !isOpen;
    }

    visible: initialized && (isOpen || panelRect.opacity > 0)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"
    onIsOpenChanged: {
        initialized = true;
        if (isOpen) {
            btPowerProc.running = true;
            btListProc.running = true;
        } else {
            btData.scanning = false;
            scanTimer.running = false;
        }
    }

    QtObject {
        id: btData

        property bool powered: false
        property bool scanning: false
        property var devices: []
    }

    // Scan timeout — stop after 15s
    Timer {
        id: scanTimer

        interval: 15000
        repeat: false
        running: false
        onTriggered: {
            btData.scanning = false;
            btScanOffProc.running = true;
        }
    }

    // Poll devices every 3s while open
    Timer {
        interval: 3000
        repeat: true
        running: isOpen && btData.powered
        onTriggered: btListProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: btPanel.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 49
        width: 360
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true
        implicitHeight: Math.min(btContentCol.implicitHeight + 32, btPanel.height - 61)
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: btContentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: btContentCol

                width: parent.width
                spacing: 0

                // ── Header ────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 44

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: btBackArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf053"
                            color: Colors.subtle
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: btBackArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btPanel.isOpen = false
                                backPressed()
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }

                        }

                    }

                    Text {
                        text: "Bluetooth"
                        color: Colors.text
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        leftPadding: 6
                    }

                    // Scan button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        visible: btData.powered
                        color: scanBtnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: btData.scanning ? "\uf110" : "\udb81\udc53"
                            color: btData.scanning ? Colors.accent : Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"

                            RotationAnimator on rotation {
                                running: btData.scanning
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }

                        }

                        MouseArea {
                            id: scanBtnArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (btData.scanning) {
                                    btData.scanning = false;
                                    scanTimer.running = false;
                                    btScanOffProc.running = true;
                                } else {
                                    btData.scanning = true;
                                    btScanOnProc.running = true;
                                    scanTimer.restart();
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }

                        }

                    }

                    // Power toggle
                    Rectangle {
                        implicitWidth: btPowerRow.implicitWidth + 20
                        height: 30
                        radius: 15
                        color: btData.powered ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85) : Qt.rgba(1, 1, 1, 0.07)

                        RowLayout {
                            id: btPowerRow

                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "\udb80\udcaf"
                                color: btData.powered ? Colors.base : Colors.subtle
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 160
                                    }

                                }

                            }

                            Text {
                                text: btData.powered ? "On" : "Off"
                                color: btData.powered ? Colors.base : Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 160
                                    }

                                }

                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btPowerToggleProc.command = ["sh", "-c", btData.powered ? "bluetoothctl power off" : "bluetoothctl power on"];
                                btPowerToggleProc.running = true;
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                            }

                        }

                    }

                }

                // ── Divider ───────────────────────────────────────
                Item {
                    implicitHeight: 10
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)
                }

                Item {
                    implicitHeight: 10
                }

                // ── Power off state ───────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: btOffCol.implicitHeight
                    visible: !btData.powered

                    ColumnLayout {
                        id: btOffCol

                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Item {
                            implicitHeight: 24
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\udb80\udcb2"
                            color: Colors.subtle
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Bluetooth is turned off"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Item {
                            implicitHeight: 24
                        }

                    }

                }

                // ── Device list ───────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: btData.powered

                    // Connected devices
                    Text {
                        visible: btData.devices.some((d) => {
                            return d.connected;
                        })
                        text: "CONNECTED"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                        bottomPadding: 4
                    }

                    Repeater {
                        model: btData.devices.filter((d) => {
                            return d.connected;
                        })

                        delegate: BtDeviceTile {
                            required property var modelData

                            Layout.fillWidth: true
                            deviceName: modelData.name
                            deviceMac: modelData.mac
                            connected: modelData.connected
                            paired: modelData.paired
                            deviceType: modelData.type
                        }

                    }

                    // Spacing between sections
                    Item {
                        implicitHeight: 8
                        visible: btData.devices.some((d) => {
                            return d.connected;
                        }) && btData.devices.some((d) => {
                            return !d.connected;
                        })
                    }

                    // Available devices
                    Text {
                        visible: btData.devices.some((d) => {
                            return !d.connected;
                        })
                        text: btData.scanning ? "SCANNING..." : "AVAILABLE"
                        color: btData.scanning ? Colors.accent : Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                        bottomPadding: 4
                    }

                    Repeater {
                        model: btData.devices.filter((d) => {
                            return !d.connected;
                        })

                        delegate: BtDeviceTile {
                            required property var modelData

                            Layout.fillWidth: true
                            deviceName: modelData.name
                            deviceMac: modelData.mac
                            connected: modelData.connected
                            paired: modelData.paired
                            deviceType: modelData.type
                        }

                    }

                    // Empty + scanning
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 60
                        visible: btData.devices.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: btData.scanning ? "Scanning for devices..." : "No devices found"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                Item {
                    implicitHeight: 4
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
            y: isOpen ? 0 : -20

            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Shortcut {
        sequence: "Escape"
        onActivated: btPanel.isOpen = false
    }

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: btPowerProc

        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]

        stdout: SplitParser {
            onRead: (data) => {
                btData.powered = data.trim().startsWith("yes");
            }
        }

    }

    Process {
        id: btPowerToggleProc

        running: false
        onRunningChanged: {
            if (!running)
                btPowerProc.running = true;

        }
    }

    Process {
        id: btListProc

        // List paired + recently seen devices with connection status
        command: ["sh", "-c", "bluetoothctl devices | while read _ mac name; do " + "info=$(bluetoothctl info $mac 2>/dev/null); " + "connected=$(echo \"$info\" | grep 'Connected:' | awk '{print $2}'); " + "paired=$(echo \"$info\" | grep 'Paired:' | awk '{print $2}'); " + "class=$(echo \"$info\" | grep 'Class:' | awk '{print $2}'); " + "echo \"$mac|$connected|$paired|$class|$name\"; " + "done"]
        onRunningChanged: {
            if (running) {
                btListProc.stdout.list = [];
            } else {
                btData.devices = btListProc.stdout.list.slice();
                btListProc.stdout.list = [];
            }
        }

        stdout: SplitParser {
            property var list: []

            onRead: (data) => {
                if (!data.trim())
                    return ;

                var parts = data.trim().split("|");
                if (parts.length >= 5) {
                    var classHex = parseInt(parts[3], 16) || 0;
                    var majorClass = (classHex >> 8) & 31;
                    var deviceType = "generic";
                    if (majorClass === 1)
                        deviceType = "computer";
                    else if (majorClass === 2)
                        deviceType = "phone";
                    else if (majorClass === 4)
                        deviceType = "audio";
                    else if (majorClass === 5)
                        deviceType = "peripheral";
                    list.push({
                        "mac": parts[0].trim(),
                        "connected": parts[1].trim() === "yes",
                        "paired": parts[2].trim() === "yes",
                        "type": deviceType,
                        "name": parts.slice(4).join("|").trim()
                    });
                }
            }
        }

    }

    Process {
        id: btScanOnProc

        command: ["sh", "-c", "bluetoothctl scan on &"]
        running: false
    }

    Process {
        id: btScanOffProc

        command: ["sh", "-c", "bluetoothctl scan off"]
        running: false
        onRunningChanged: {
            if (!running)
                btListProc.running = true;

        }
    }

}
