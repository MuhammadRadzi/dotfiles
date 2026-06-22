import "."
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wifiPanel

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
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onIsOpenChanged: {
        initialized = true;
        if (isOpen) {
            radioStatusProc.running = true;
            scanProc.running = true;
        } else {
            // reset password fields on close
            passwordState.targetSsid = "";
            passwordState.text = "";
            passwordState.visible = false;
        }
    }

    // State
    QtObject {
        id: wifiData

        property bool radioEnabled: true
        property var networks: []
        property bool scanning: false
        property string connectingTo: ""
        property string errorMsg: ""
    }

    QtObject {
        id: passwordState

        property string targetSsid: ""
        property string text: ""
        property bool visible: false
        property bool show: false // toggle show/hide password
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: wifiPanel.isOpen = false
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
        implicitHeight: Math.min(contentCol.implicitHeight + 32, wifiPanel.height - 61)
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
        }

        // Scrollable content
        Flickable {
            id: flickable

            anchors.fill: parent
            anchors.margins: 16
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentCol

                width: flickable.width
                spacing: 0

                // ── Header ────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 44

                    // Back / close
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: backArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf053"
                            color: Colors.subtle
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: backArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPanel.isOpen = false
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
                        text: "Wi-Fi"
                        color: Colors.text
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        leftPadding: 6
                    }

                    // Refresh button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: refreshArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: wifiData.radioEnabled

                        Text {
                            anchors.centerIn: parent
                            text: wifiData.scanning ? "\uf110" : "\udb81\udc53"
                            color: wifiData.scanning ? Colors.accent : Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"

                            RotationAnimator on rotation {
                                running: wifiData.scanning
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }

                        }

                        MouseArea {
                            id: refreshArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !wifiData.scanning
                            onClicked: {
                                wifiData.networks = [];
                                scanProc.running = true;
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }

                        }

                    }

                    // Radio toggle
                    Rectangle {
                        implicitWidth: radioRow.implicitWidth + 20
                        height: 30
                        radius: 15
                        color: wifiData.radioEnabled ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85) : Qt.rgba(1, 1, 1, 0.07)

                        RowLayout {
                            id: radioRow

                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "\udb82\udd28"
                                color: wifiData.radioEnabled ? Colors.base : Colors.subtle
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 160
                                    }

                                }

                            }

                            Text {
                                text: wifiData.radioEnabled ? "On" : "Off"
                                color: wifiData.radioEnabled ? Colors.base : Colors.subtle
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
                                radioToggleProc.command = ["nmcli", "radio", "wifi", wifiData.radioEnabled ? "off" : "on"];
                                radioToggleProc.running = true;
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

                // ── Radio off state ───────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: radioOffCol.implicitHeight
                    visible: !wifiData.radioEnabled

                    ColumnLayout {
                        id: radioOffCol

                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Item {
                            implicitHeight: 24
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\udb82\udd2f"
                            color: Colors.subtle
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Wi-Fi is turned off"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Item {
                            implicitHeight: 24
                        }

                    }

                }

                // ── Network list ──────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: wifiData.radioEnabled

                    Repeater {
                        model: wifiData.networks

                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            spacing: 0

                            // Network tile
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: 10
                                color: modelData.active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : (netHover.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    // Signal strength icon
                                    Text {
                                        text: modelData.signal >= 80 ? "\udb82\udd28"
                                            : modelData.signal >= 60 ? "\udb82\udd25"
                                            : modelData.signal >= 40 ? "\udb82\udd22"
                                            : modelData.signal >= 20 ? "\udb82\udd1f"
                                            : "\udb82\udd2f"
                                        color: modelData.active ? Colors.accent : Colors.subtle
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.ssid
                                            color: modelData.active ? Colors.text : Colors.text
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.weight: modelData.active ? Font.Medium : Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: modelData.active
                                            text: "Connected"
                                            color: Colors.accent
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        Text {
                                            visible: wifiData.connectingTo === modelData.ssid
                                            text: "Connecting..."
                                            color: Colors.subtle
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                    }

                                    // Lock icon
                                    Text {
                                        visible: modelData.secured
                                        text: "\uf023"
                                        color: Colors.subtle
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    // Disconnect button (active only)
                                    Rectangle {
                                        visible: modelData.active
                                        width: 28
                                        height: 28
                                        radius: 6
                                        color: disconnectHover.containsMouse ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.25) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf127"
                                            color: "#FB4934"
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        MouseArea {
                                            id: disconnectHover

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                disconnectProc.command = ["nmcli", "dev", "disconnect", "wlan0"];
                                                disconnectProc.running = true;
                                            }
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }

                                        }

                                    }

                                    // Connect arrow (inactive)
                                    Text {
                                        visible: !modelData.active && wifiData.connectingTo !== modelData.ssid
                                        text: "\uf054"
                                        color: netHover.containsMouse ? Colors.subtle : "transparent"
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }

                                        }

                                    }

                                }

                                MouseArea {
                                    id: netHover

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !modelData.active && wifiData.connectingTo === ""
                                    onClicked: {
                                        if (modelData.secured) {
                                            // Show inline password field
                                            passwordState.targetSsid = modelData.ssid;
                                            passwordState.text = "";
                                            passwordState.show = false;
                                            passwordState.visible = true;
                                        } else {
                                            wifiData.connectingTo = modelData.ssid;
                                            connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                            connectProc.running = true;
                                        }
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }

                                }

                            }

                            // ── Inline password field ─────────────
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: passwordState.visible && passwordState.targetSsid === modelData.ssid ? 56 : 0
                                visible: implicitHeight > 0
                                clip: true
                                color: "transparent"

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.bottomMargin: 6
                                    radius: 10
                                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.12)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.1)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Text {
                                            text: "\uf084"
                                            color: Colors.subtle
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                        TextInput {
                                            id: passInput

                                            Layout.fillWidth: true
                                            text: passwordState.text
                                            echoMode: passwordState.show ? TextInput.Normal : TextInput.Password
                                            color: Colors.text
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
                                            onTextChanged: passwordState.text = text
                                            onAccepted: {
                                                if (passwordState.text.length > 0) {
                                                    wifiData.connectingTo = modelData.ssid;
                                                    passwordState.visible = false;
                                                    connectPassProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", passwordState.text];
                                                    connectPassProc.running = true;
                                                    passwordState.text = "";
                                                }
                                            }
                                            Component.onCompleted: {
                                                if (passwordState.targetSsid === modelData.ssid)
                                                    forceActiveFocus();

                                            }
                                        }

                                        // Show/hide password toggle
                                        Text {
                                            text: passwordState.show ? "\uf070" : "\uf06e"
                                            color: showPassArea.containsMouse ? Colors.text : Colors.subtle
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"

                                            MouseArea {
                                                id: showPassArea

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: passwordState.show = !passwordState.show
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 120
                                                }

                                            }

                                        }

                                        // Cancel
                                        Text {
                                            text: "\uf00d"
                                            color: cancelArea.containsMouse ? Colors.red : Colors.subtle
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"

                                            MouseArea {
                                                id: cancelArea

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    passwordState.visible = false;
                                                    passwordState.targetSsid = "";
                                                    passwordState.text = "";
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 120
                                                }

                                            }

                                        }

                                        // Connect button
                                        Rectangle {
                                            width: 60
                                            height: 28
                                            radius: 6
                                            color: connectBtnArea.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.6)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                color: Colors.base
                                                font.pixelSize: 11
                                                font.family: "JetBrainsMono Nerd Font"
                                            }

                                            MouseArea {
                                                id: connectBtnArea

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (passwordState.text.length > 0) {
                                                        wifiData.connectingTo = modelData.ssid;
                                                        passwordState.visible = false;
                                                        connectPassProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", passwordState.text];
                                                        connectPassProc.running = true;
                                                        passwordState.text = "";
                                                    }
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 120
                                                }

                                            }

                                        }

                                    }

                                }

                                Behavior on implicitHeight {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: emptyCol.implicitHeight
                        visible: wifiData.networks.length === 0 && !wifiData.scanning

                        ColumnLayout {
                            id: emptyCol

                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Item {
                                implicitHeight: 24
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "\udb82\udd2b"
                                color: Colors.subtle
                                font.pixelSize: 28
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No networks found"
                                color: Colors.subtle
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Item {
                                implicitHeight: 24
                            }

                        }

                    }

                    // Scanning state
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 60
                        visible: wifiData.scanning && wifiData.networks.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "Scanning..."
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                // Error message
                Item {
                    Layout.fillWidth: true
                    implicitHeight: errorText.implicitHeight + 12
                    visible: wifiData.errorMsg !== ""

                    Text {
                        id: errorText

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        text: wifiData.errorMsg
                        color: Colors.red
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        wrapMode: Text.Wrap
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
        onActivated: wifiPanel.isOpen = false
    }

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: radioStatusProc

        command: ["nmcli", "radio", "wifi"]

        stdout: SplitParser {
            onRead: (data) => {
                wifiData.radioEnabled = data.trim() === "enabled";
            }
        }

    }

    Process {
        id: radioToggleProc

        running: false
        onRunningChanged: {
            if (!running) {
                radioStatusProc.running = true;
                if (wifiData.radioEnabled)
                    scanProc.running = true;

            }
        }
    }

    Process {
        id: scanProc

        command: ["sh", "-c", "nmcli -t -f active,ssid,signal,security dev wifi 2>/dev/null | head -20"]
        onRunningChanged: {
            if (running) {
                wifiData.scanning = true;
            } else {
                wifiData.scanning = false;
                wifiData.networks = scanProc.stdout.list.slice();
                scanProc.stdout.list = [];
            }
        }

        stdout: SplitParser {
            property var list: []

            onRead: (data) => {
                if (!data.trim())
                    return ;

                var parts = data.trim().split(":");
                if (parts.length >= 4 && parts[1].trim() !== "")
                    list.push({
                    "active": parts[0] === "yes",
                    "ssid": parts[1].trim(),
                    "signal": parseInt(parts[2]) || 0,
                    "secured": parts[3].trim() !== "" && parts[3].trim() !== "--"
                });

            }
        }

    }

    Process {
        id: connectProc

        running: false
        onRunningChanged: {
            if (!running) {
                wifiData.connectingTo = "";
                scanProc.running = true;
            }
        }
    }

    Process {
        id: connectPassProc

        running: false
        onRunningChanged: {
            if (!running) {
                wifiData.connectingTo = "";
                wifiData.errorMsg = "";
                scanProc.running = true;
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data.includes("Error") || data.includes("error")) {
                    wifiData.errorMsg = data.trim();
                    wifiData.connectingTo = "";
                }
            }
        }

    }

    Process {
        id: disconnectProc

        running: false
        onRunningChanged: {
            if (!running)
                scanProc.running = true;

        }
    }

}
