import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: notifCenter

    property bool isOpen: false
    property var notifications: []

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
            historyProc.running = true;
            pollTimer.running = true;
        } else {
            pollTimer.running = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: notifCenter.isOpen = false
            enabled: isOpen
        }

        // Panel
        Rectangle {
            id: panelRect

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 39 + 8
            width: 360
            height: Math.min(notifCol.implicitHeight + 32, 600)
            radius: 10
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
                id: notifCol

                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "NOTIFICATIONS"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Clear All
                    Text {
                        text: "Clear all"
                        color: clearArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: clearArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clearProc.running = true;
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

                // Empty State
                Item {
                    visible: notifications.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf0f3"
                            color: Colors.overlay
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No notifications"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                // List
                Flickable {
                    visible: notifications.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(notifList.implicitHeight, 500)
                    contentHeight: notifList.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: notifList

                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: notifications

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: itemCol.implicitHeight + 20
                                radius: 10
                                color: itemArea.containsMouse ? "#22ffffff" : "#11ffffff"

                                // Urgency indicator
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    width: 3
                                    radius: 2
                                    color: modelData.urgency === "CRITICAL" ? Colors.red : modelData.urgency === "LOW" ? Colors.subtle : Colors.accent
                                }

                                ColumnLayout {
                                    id: itemCol

                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 36
                                    anchors.topMargin: 10
                                    anchors.bottomMargin: 10
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.appname
                                            color: Colors.subtle
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.letterSpacing: 1
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.time
                                            color: Colors.subtle
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                        }

                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary
                                        color: Colors.text
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: modelData.body !== ""
                                        Layout.fillWidth: true
                                        text: modelData.body
                                        color: Colors.subtle
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                }

                                // Close Button
                                Text {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    text: "\uf00d"
                                    color: closeArea.containsMouse ? Colors.text : Colors.subtle
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"

                                    MouseArea {
                                        id: closeArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            dismissProc.command = ["dunstctl", "history-rm", modelData.id.toString()];
                                            dismissProc.running = true;
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                                MouseArea {
                                    id: itemArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

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

    // Fetch History
    Process {
        id: historyProc

        command: ["dunstctl", "history"]
        onRunningChanged: {
            if (!running) {
                try {
                    var raw = JSON.parse(historyProc.stdout.buf);
                    var list = [];
                    var items = raw.data[0];
                    for (var i = 0; i < items.length; i++) {
                        var n = items[i];
                        var ts = parseInt(n.timestamp.data);
                        var date = new Date(ts / 1000);
                        var now = new Date();
                        var diff = Math.floor((now - date) / 60000);
                        var timeStr = diff < 1 ? "just now" : diff < 60 ? diff + "m ago" : Math.floor(diff / 60) + "h ago";
                        list.push({
                            "id": n.id.data,
                            "summary": n.summary.data,
                            "body": n.body.data,
                            "appname": n.appname.data || "system",
                            "urgency": n.urgency.data,
                            "time": timeStr
                        });
                    }
                    notifications = list;
                } catch (e) {
                    notifications = [];
                }
                historyProc.stdout.buf = "";
            }
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Timer {
        id: pollTimer

        interval: 3000
        running: false
        repeat: true
        onTriggered: historyProc.running = true
    }

    Process {
        id: dismissProc

        running: false
        onRunningChanged: {
            if (!running)
                historyProc.running = true;

        }
    }

    Process {
        id: clearProc

        command: ["dunstctl", "history-clear"]
        running: false
        onRunningChanged: {
            if (!running)
                notifications = [];

        }
    }

}
