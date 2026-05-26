import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: parent.height
    visible: title.text !== "" && title.text !== "No player"

    property string artist: ""
    property string track: ""
    property string status: "Stopped"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Prev
        Text {
            text: "󰒮"
            color: Colors.subtle
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            MouseArea {
                anchors.fill: parent
                onClicked: prevProc.running = true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Play/Pause
        Text {
            text: status === "Playing" ? "󰏤" : "󰐊"
            color: Colors.text
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            MouseArea {
                anchors.fill: parent
                onClicked: playProc.running = true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Next
        Text {
            text: "󰒭"
            color: Colors.subtle
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            MouseArea {
                anchors.fill: parent
                onClicked: nextProc.running = true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Separator
        Rectangle {
            width: 1; height: 14
            color: Colors.overlay
        }

        // Track info
        Text {
            id: title
            text: track !== "" ? track + "  —  " + artist : ""
            color: Colors.text
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            elide: Text.ElideRight
            Layout.maximumWidth: 200
        }
    }

    // Fetch metadata
    Process {
        id: metaProc
        command: ["sh", "-c", "playerctl metadata --format '{{title}}|{{artist}}|{{status}}' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var parts = data.trim().split("|")
                track  = parts[0] || ""
                artist = parts[1] || ""
                status = parts[2] || "Stopped"
            }
        }
        Component.onCompleted: running = true
    }

    // Controls
    Process { id: prevProc;  command: ["playerctl", "previous"]; running: false; onRunningChanged: if (!running) metaProc.running = true }
    Process { id: playProc;  command: ["playerctl", "play-pause"]; running: false; onRunningChanged: if (!running) metaProc.running = true }
    Process { id: nextProc;  command: ["playerctl", "next"]; running: false; onRunningChanged: if (!running) metaProc.running = true }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: metaProc.running = true
    }
}