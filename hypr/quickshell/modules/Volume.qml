import "../theme"
import QtQuick
import Quickshell.Io

Item {
    property int vol: 0
    property bool muted: false

    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    Text {
        id: label

        anchors.centerIn: parent
        text: muted ? "\ueb24 mute" : (vol >= 50 ? "\uf028  " : "\uf027 ") + vol + "%"
        color: muted ? Colors.subtle : Colors.text
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
    }

    Process {
        id: volProc

        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                muted = data.includes("MUTED");
                var match = data.match(/[\d.]+/);
                if (match)
                    vol = Math.round(parseFloat(match[0]) * 100);

            }
        }

    }

    Process {
        id: muteProc

        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onRunningChanged: {
            if (!running)
                volProc.running = true;

        }
    }

    Process {
        id: volUpProc

        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
        running: false
        onRunningChanged: {
            if (!running)
                volProc.running = true;

        }
    }

    Process {
        id: volDownProc

        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        running: false
        onRunningChanged: {
            if (!running)
                volProc.running = true;

        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: muteProc.running = true
        scrollGestureEnabled: true
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                volUpProc.running = true;
            else
                volDownProc.running = true;
        }
    }

}
