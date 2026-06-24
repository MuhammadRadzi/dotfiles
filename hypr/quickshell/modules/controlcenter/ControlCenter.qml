import "."
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: controlCenter

    property bool isOpen: false
    property bool initialized: false
    property bool dndActive: dndState.active

    signal openWifiPanel()
    signal openBtPanel()
    signal openMixerPanel()

    function toggle() {
        isOpen = !isOpen;
    }

    function updateClock() {
        var d = new Date();
        clockLabel.text = Qt.formatTime(d, "HH:mm");
        dateLabel.text = Qt.formatDate(d, "dddd, d MMM yyyy");
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
            wifiStatusProc.running = true;
            btStatusProc.running = true;
            updateClock();
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: isOpen
        onTriggered: controlCenter.updateClock()
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: controlCenter.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 49
        width: 340
        radius: 10
        color: Qt.alpha(Colors.base, 0.85)
        border.width: 1
        border.color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.13)
        clip: true
        implicitHeight: mainCol.implicitHeight + 32
        opacity: isOpen ? 1 : 0

        // Consume clicks so backdrop mousearea doesn't fire
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: mainCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 0

            // ── Header ────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 56

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        id: clockLabel

                        text: "00:00"
                        color: Colors.text
                        font.pixelSize: 28
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                    }

                    Text {
                        id: dateLabel

                        text: ""
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }

                }

            }

            // ── Divider ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)
            }

            Item {
                implicitHeight: 14
            }

            // ── Volume ────────────────────────────────────────────
            SliderRow {
                Layout.fillWidth: true
                iconText: volState.muted ? "\ueee8" : volState.vol >= 50 ? "\uf028" : "\uf027"
                iconColor: volState.muted ? Colors.subtle : Colors.text
                valueText: volState.vol + "%"
                sliderValue: volState.vol / 100
                accentColor: volState.muted ? Colors.subtle : Colors.accent
                showArrow: true
                onIconClicked: muteVolProc.running = true
                onSliderScrubbed: (r) => {
                    setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(r * 100) + "%"];
                    setVolProc.running = true;
                }
                onArrowClicked: {
                    openMixerPanel();
                }
            }

            Item {
                implicitHeight: 10
            }

            // ── Brightness ────────────────────────────────────────
            SliderRow {
                Layout.fillWidth: true
                iconText: "\uf0eb"
                iconColor: Colors.subtle
                valueText: Math.round(brightState.value * 100) + "%"
                sliderValue: brightState.value
                accentColor: Colors.accent
                onSliderScrubbed: (r) => {
                    setBrightProc.command = ["brightnessctl", "set", Math.round(r * 100) + "%"];
                    setBrightProc.running = true;
                }
            }

            Item {
                implicitHeight: 14
            }

            // ── Divider ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)
            }

            Item {
                implicitHeight: 14
            }

            // ── Battery ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: batState.status === "Charging" ? "󰂄" : batState.level > 80 ? "󰁹" : batState.level > 50 ? "󰁾" : batState.level > 20 ? "󰁻" : "󰁺"
                    color: batState.status === "Charging" ? Colors.green : batState.level < 20 ? Colors.red : Colors.text
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Battery"
                            color: Colors.subtle
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: batState.status === "Charging" ? "\udb85\udc0b Charging" : batState.status
                            color: batState.status === "Charging" ? Colors.green : Colors.subtle
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            text: "  " + batState.level + "%"
                            color: Colors.text
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.6)

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, batState.level / 100))
                            height: parent.height
                            radius: 3
                            color: batState.status === "Charging" ? Colors.green : batState.level < 20 ? Colors.red : Colors.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 400
                                }

                            }

                        }

                    }

                }

            }

            Item {
                implicitHeight: 14
            }

            // ── Divider ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)
            }

            Item {
                implicitHeight: 14
            }

            // ── Toggle grid 2x2 ───────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    iconText: "\udb82\udd28"
                    label: "Wi-Fi"
                    sublabel: wifiState.enabled ? "On" : "Off"
                    active: wifiState.enabled
                    showArrow: true
                    onToggled: {
                        wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiState.enabled ? "off" : "on"];
                        wifiToggleProc.running = true;
                    }
                    onArrowClicked: {
                        openWifiPanel();
                    }
                }

                ToggleTile {
                    Layout.fillWidth: true
                    iconText: "\udb80\udcaf"
                    label: "Bluetooth"
                    sublabel: btState.enabled ? "On" : "Off"
                    active: btState.enabled
                    showArrow: true
                    onToggled: {
                        btToggleProc.command = ["sh", "-c", btState.enabled ? "bluetoothctl power off" : "bluetoothctl power on"];
                        btToggleProc.running = true;
                    }
                    onArrowClicked: {
                        openBtPanel();
                    }
                }

                ToggleTile {
                    Layout.fillWidth: true
                    iconText: "\uf186"
                    label: "Night Light"
                    sublabel: nightLight.active ? "On" : "Off"
                    active: nightLight.active
                    accentColor: Colors.accent
                    onToggled: {
                        nightLight.active = !nightLight.active;
                        if (nightLight.active)
                            nightLightProc.command = ["sh", "-c", "nohup hyprsunset -t 3500 > /dev/null 2>&1 &"];
                        else
                            nightLightProc.command = ["sh", "-c", "pkill -f hyprsunset"];
                        nightLightProc.running = true;
                    }
                }

                ToggleTile {
                    Layout.fillWidth: true
                    iconText: dndState.active ? "\ueab8" : "\uea71"
                    label: "Do Not Disturb"
                    sublabel: dndState.active ? "On" : "Off"
                    active: dndState.active
                    accentColor: Colors.accent
                    onToggled: dndState.active = !dndState.active
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

    // ── State objects ─────────────────────────────────────────────
    QtObject {
        id: volState

        property int vol: 0
        property bool muted: false

        Component.onCompleted: volProc.running = true
    }

    QtObject {
        id: brightState

        property real value: 1

        Component.onCompleted: brightProc.running = true
    }

    QtObject {
        id: batState

        property int level: 0
        property string status: ""

        Component.onCompleted: batProc.running = true
    }

    QtObject {
        id: wifiState

        property bool enabled: false
    }

    QtObject {
        id: btState

        property bool enabled: false
    }

    QtObject {
        id: nightLight

        property bool active: false
        Component.onCompleted: checkNightLightProc.running = true
    }

    QtObject {
    id: dndState
    property bool active: false
    Component.onCompleted: checkDndProc.running = true
    onActiveChanged: {
        saveDndProc.command = ["sh", "-c", "echo " + (active ? "1" : "0") + " > /tmp/qs_dnd"]
        saveDndProc.running = true
    }
}

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: volProc

        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                volState.muted = data.includes("MUTED");
                var m = data.match(/[\d.]+/);
                if (m)
                    volState.vol = Math.round(parseFloat(m[0]) * 100);

            }
        }

    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: volProc.running = true
    }

    Process {
        id: muteVolProc

        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onRunningChanged: {
            if (!running)
                volProc.running = true;

        }
    }

    Process {
        id: setVolProc

        running: false
        onRunningChanged: {
            if (!running)
                volProc.running = true;

        }
    }

    Process {
        id: brightProc

        command: ["sh", "-c", "brightnessctl get && brightnessctl max"]

        stdout: SplitParser {
            property var lines: []

            onRead: (data) => {
                lines.push(data.trim());
                if (lines.length >= 2) {
                    var cur = parseInt(lines[0]);
                    var max = parseInt(lines[1]);
                    if (max > 0)
                        brightState.value = cur / max;

                    lines = [];
                }
            }
        }

    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: brightProc.running = true
    }

    Process {
        id: setBrightProc

        running: false
        onRunningChanged: {
            if (!running)
                brightProc.running = true;

        }
    }

    Process {
        id: batProc

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status"]

        stdout: SplitParser {
            property var lines: []

            onRead: (data) => {
                lines.push(data.trim());
                if (lines.length >= 2) {
                    batState.level = parseInt(lines[0]) || 0;
                    batState.status = lines[1];
                    lines = [];
                }
            }
        }

    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: batProc.running = true
    }

    Process {
        id: wifiStatusProc

        command: ["nmcli", "radio", "wifi"]

        stdout: SplitParser {
            onRead: (data) => {
                wifiState.enabled = data.trim() === "enabled";
            }
        }

    }

    Process {
        id: wifiToggleProc

        running: false
        onRunningChanged: {
            if (!running)
                wifiStatusProc.running = true;

        }
    }

    Process {
        id: btStatusProc

        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]

        stdout: SplitParser {
            onRead: (data) => {
                btState.enabled = data.trim().startsWith("yes");
            }
        }

    }

    Process {
        id: btToggleProc

        running: false
        onRunningChanged: {
            if (!running)
                btStatusProc.running = true;

        }
    }

    Process {
        id: nightLightProc

        running: false
        onRunningChanged: console.log("nightLightProc running:", running, "command:", command)
    }

Process {
    id: checkNightLightProc
    command: ["sh", "-c", "pgrep -x hyprsunset > /dev/null && echo yes || echo no"]
    stdout: SplitParser {
        onRead: (data) => { nightLight.active = data.trim() === "yes" }
    }
}

Process {
    id: checkDndProc
    command: ["sh", "-c", "cat /tmp/qs_dnd 2>/dev/null || echo 0"]
    stdout: SplitParser {
        onRead: (data) => { dndState.active = data.trim() === "1" }
    }
}

Process {
    id: saveDndProc
    running: false
}
}
