import "."
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: mixerPanel

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
        if (isOpen)
            streamsProc.running = true;
    }

    // State
    QtObject {
        id: mixerData

        property var streams: []
        property int activeScrubs: 0
    }

    Timer {
        interval: 1200
        repeat: true
        running: mixerPanel.isOpen && mixerData.activeScrubs === 0
        onTriggered: streamsProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: mixerPanel.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 49
        width: 360
        radius: 10
        color: Qt.alpha(Colors.base, 0.85)
        border.width: 1
        border.color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.13)
        clip: true
        implicitHeight: Math.min(contentCol.implicitHeight + 32, mixerPanel.height - 61)
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
        }

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
                                mixerPanel.isOpen = false;
                                backPressed();
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }

                        }

                    }

                    Text {
                        text: "App Volume Mixer"
                        color: Colors.text
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        leftPadding: 6
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: refreshArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\udb81\udc53"
                            color: Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: refreshArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: streamsProc.running = true
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }

                        }

                    }

                }

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

                // ── Per-app stream list ─────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: mixerData.streams.length > 0

                    Repeater {
                        model: mixerData.streams

                        delegate: AppMixerTile {
                            required property var modelData

                            Layout.fillWidth: true
                            appName: modelData.name
                            iconName: modelData.iconName
                            volume: modelData.volume
                            muted: {
                                return modelData.muted;
                            }
                            onMuteToggled: {
                                muteStreamProc.command = ["pactl", "set-sink-input-mute", String(modelData.id), "toggle"];
                                muteStreamProc.running = true;
                            }
                            onScrubStarted: mixerData.activeScrubs += 1
                                onScrubEnded: {
                                    mixerData.activeScrubs = Math.max(0, mixerData.activeScrubs - 1);
                                    if (mixerData.activeScrubs === 0 && !setStreamVolProc.running)
                                        streamsProc.running = true;

                                }
                            onVolumeScrubbed: (ratio) => {
                                var pct = Math.round(ratio * 100) + "%";
                                if (setStreamVolProc.running) {
                                    setStreamVolProc.pendingId = String(modelData.id);
                                    setStreamVolProc.pendingPct = pct;
                                } else {
                                    setStreamVolProc.command = ["pactl", "set-sink-input-volume", String(modelData.id), pct];
                                    setStreamVolProc.running = true;
                                }

                            }

                        }

                    }

                }

                // Empty state
                Item {
                    Layout.fillWidth: true
                    implicitHeight: emptyCol.implicitHeight
                    visible: mixerData.streams.length === 0

                    ColumnLayout {
                        id: emptyCol

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Item {
                            implicitHeight: 20
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\udb80\udece"
                            color: Colors.subtle
                            font.pixelSize: 26
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No apps playing audio"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Item {
                            implicitHeight: 20
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
        onActivated: mixerPanel.isOpen = false
    }

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: streamsProc

        command: ["pactl", "-f", "json", "list", "sink-inputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                var list = [];
                try {
                    var data = JSON.parse(text);
                    for (var i = 0; i < data.length; i++) {
                        var item = data[i];
                        var props = item.properties || {};
                        var name = props["application.name"] || props["media.name"] || "Unknown";
                        var iconName = props["application.icon_name"] || (props["application.process.binary"] || "").toLowerCase();
                        var vol = 0;
                        if (item.volume) {
                            var keys = Object.keys(item.volume);
                            if (keys.length > 0)
                                vol = Math.round(parseFloat(item.volume[keys[0]].value_percent.replace("%", "")));

                        }
                        list.push({
                            "id": item.index,
                            "name": name,
                            "iconName": iconName,
                            "volume": vol,
                            "muted": !!item.mute
                        });
                    }
                } catch (e) {
                }
                mixerData.streams = list;
            }
        }
    }

    Process {
        id: muteStreamProc

        running: false
        onRunningChanged: {
            if (!running && mixerData.activeScrubs === 0)
                streamsProc.running = true;

        }
    }

    Process {
        id: setStreamVolProc

        property string pendingId: ""
        property string pendingPct: ""

        running: false
        onRunningChanged: {
            if (!running) {
                if (pendingId !== "") {
                    var id = pendingId;
                    var pct = pendingPct;
                    pendingId = "";
                    pendingPct = "";
                    command = ["pactl", "set-sink-input-volume", id, pct];
                    running = true;
                } else if (mixerData.activeScrubs === 0) {
                    streamsProc.running = true;
                }
            }
        }
    }
}