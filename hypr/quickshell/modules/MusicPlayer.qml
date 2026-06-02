import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
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
    WlrLayershell.anchors.right: true
    implicitWidth: 240
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

    // Poll posisi cursor tiap 100ms
    Process {
        id: cursorProc

        command: ["sh", "-c", "hyprctl cursorpos"]

        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split(", ");
                var x = parseInt(parts[0]);
                var y = parseInt(parts[1]);
                // zona pojok kanan bawah — x >= 1070, y >= 1070 (1920x1080)
                root.cursorInZone = (x >= 1070 && y >= 1070);
            }
        }

    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (root.hasPlayer) {
                cursorProc.running = true;
            }
        }
    }

    Rectangle {
        id: card

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        width: 200
        height: cardCol.implicitHeight + 32
        radius: 10
        color: "#dd16181c"
        border.width: 1
        border.color: "#22ffffff"
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
                if (!root.cursorInZone && !root.autoShow) {
                    autoHideTimer.interval = 1500;
                    autoHideTimer.restart();
                }
            }
        }

        ColumnLayout {
            id: cardCol

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            width: parent.width - 32
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 152
                height: 152
                radius: 12
                color: Colors.surface
                clip: true

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
                    font.pixelSize: 40
                    font.family: "JetBrainsMono Nerd Font"
                }

            }

            Text {
                Layout.fillWidth: true
                text: root.track
                color: Colors.text
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

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

                Text {
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

            }

            Rectangle {
                Layout.fillWidth: true
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

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: formatTime(root.position) + " / " + formatTime(root.duration)
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

            Item {
                height: 4
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

        transform: Translate {
            x: root.isVisible ? 0 : card.width + 20

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

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
            if (!running) {
                metaProc.running = true;
            }
        }
    }

    Process {
        id: playProc

        command: ["playerctl", "play-pause"]
        running: false
        onRunningChanged: {
            if (!running) {
                metaProc.running = true;
            }
        }
    }

    Process {
        id: nextProc

        command: ["playerctl", "next"]
        running: false
        onRunningChanged: {
            if (!running) {
                metaProc.running = true;
            }
        }
    }

}
