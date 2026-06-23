import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Shapes
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool cardHovered: false
    property bool cursorInZone: false
    property string track: ""
    property string artist: ""
    property string status: "Stopped"
    property string artUrl: ""
    property int position: 0
    property int duration: 0
    property bool hasPlayer: status === "Playing" || status === "Paused"
    property bool autoShow: false
    property bool isVisible: (autoShow || cursorInZone || cardHovered) && hasPlayer
    property string lastTrack: ""

    function formatTime(secs) {
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    implicitHeight: card.height + 20
    color: "transparent"
    visible: card.opacity > 0
    onTrackChanged: {
        if (track !== "" && track !== lastTrack) {
            lastTrack = track;
            autoShow = true;
            autoHideTimer.interval = 3000;
            autoHideTimer.restart();
        }
    }

    Timer {
        id: autoHideTimer

        interval: 3000
        running: false
        repeat: false
        onTriggered: root.autoShow = false
    }

    // Poll cursor position
    Process {
        id: cursorProc

        command: ["sh", "-c", "hyprctl cursorpos"]

        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split(", ");
                var x = parseInt(parts[0]);
                var y = parseInt(parts[1]);
                // zone: bottom center ~360px wide
                var cx = Screen.width / 2;
                root.cursorInZone = (Math.abs(x - cx) < 180 && y >= Screen.height - 10);
            }
        }

    }

    Timer {
        interval: 250
        running: root.hasPlayer
        repeat: true
        onTriggered: {
            if (!cursorProc.running)
                cursorProc.running = true;

        }
    }

    // Card — centered horizontally
    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: 380
        height: cardRow.implicitHeight + 24
        radius: 10
        color: Qt.alpha(Colors.base, 0.85)
        border.width: 1
        border.color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.13)
        clip: true
        opacity: root.isVisible ? 1 : 0

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.cardHovered = true;
                autoHideTimer.stop();
            }
            onExited: {
                root.cardHovered = false;
                if (!root.cursorInZone) {
                    autoHideTimer.interval = 1500;
                    autoHideTimer.restart();
                }
            }
        }

        RowLayout {
            id: cardRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 14

            // ── Artwork ───────────────────────────────────────────
            Rectangle {
                width: 80
                height: 80
                radius: 10
                color: "#33ffffff"
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: artImg

                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    text: "\uf001"
                    color: Colors.subtle
                    font.pixelSize: 28
                    font.family: "JetBrainsMono Nerd Font"
                }

            }

            // ── Info + controls ───────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                // Track + artist
                Text {
                    Layout.fillWidth: true
                    text: root.track
                    color: Colors.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.artist
                    color: Colors.subtle
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }

                // Progress bar
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 12

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3
                        radius: 2
                        color: "#22ffffff"

                        Rectangle {
                            width: root.duration > 0 ? parent.width * (root.position / root.duration) : 0
                            height: parent.height
                            radius: 2
                            color: Colors.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 800
                                    easing.type: Easing.Linear
                                }

                            }

                        }

                    }

                }

                // Controls + time
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // Prev
                    Text {
                        text: "\udb81\udcae"
                        color: prevArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: prevArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: prevProc.running = true
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                    // Play/Pause
                    Text {
                        leftPadding: 14
                        rightPadding: 14
                        text: root.status === "Playing" ? "\udb80\udfe4" : "\udb81\udc0a"
                        color: Colors.text
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playProc.running = true
                        }

                    }

                    // Next
                    Text {
                        text: "\udb81\udcad"
                        color: nextArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: nextArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: nextProc.running = true
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Time
                    Text {
                        text: formatTime(root.position) + " / " + formatTime(root.duration)
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }

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
            y: root.isVisible ? 0 : 20

            Behavior on y {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: metaProc

        command: ["sh", "-c", "playerctl metadata --format '{{title}}|{{artist}}|{{status}}|{{mpris:artUrl}}|{{mpris:length}}' 2>/dev/null || echo '||||0'"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data.trim())
                    return ;

                var p = data.trim().split("|");
                root.track = p[0] || "";
                root.artist = p[1] || "";
                root.status = p[2] || "Stopped";
                root.artUrl = p[3] || "";
                root.duration = Math.floor((parseInt(p[4]) || 0) / 1e+06);
            }
        }

    }

    Process {
        id: posProc

        command: ["sh", "-c", "playerctl position 2>/dev/null || echo 0"]

        stdout: SplitParser {
            onRead: (data) => {
                root.position = Math.floor(parseFloat(data.trim()) || 0);
            }
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: metaProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.status === "Playing")
                posProc.running = true;

        }
    }

    Process {
        id: prevProc

        command: ["playerctl", "previous"]
        running: false
        onRunningChanged: {
            if (!running)
                metaProc.running = true;

        }
    }

    Process {
        id: playProc

        command: ["playerctl", "play-pause"]
        running: false
        onRunningChanged: {
            if (!running)
                metaProc.running = true;

        }
    }

    Process {
        id: nextProc

        command: ["playerctl", "next"]
        running: false
        onRunningChanged: {
            if (!running)
                metaProc.running = true;

        }
    }

}
