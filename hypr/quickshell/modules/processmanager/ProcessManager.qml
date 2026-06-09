import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: processManager

    property bool isOpen: false
    property bool initialized: false
    property var processes: []
    property string sortBy: "cpu"  // cpu | ram

    function toggle() {
        isOpen = !isOpen;
    }

    function refresh() {
        fetchProc.running = true;
    }

    function killProcess(pid) {
        killProc.command = ["kill", "-9", pid.toString()];
        killProc.running = true;
    }

    visible: initialized && (isOpen || overlayRect.opacity > 0)
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
            refresh();
            pollTimer.running = true;
        } else {
            pollTimer.running = false;
        }
    }

    // Overlay background
    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "transparent"
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            visible: isOpen
            onClicked: processManager.isOpen = false
        }

        // Panel
        Rectangle {
            id: panelRect
            anchors.centerIn: parent
            width: 480
            height: Math.min(panelCol.implicitHeight + 48, 560)
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: panelCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "\uf085"
                        color: Colors.accent
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        text: "Processes"
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.DemiBold
                        leftPadding: 6
                    }

                    Item { Layout.fillWidth: true }

                    // Sort toggle
                    Rectangle {
                        height: 28
                        width: sortRow.implicitWidth + 16
                        radius: 8
                        color: sortArea.containsMouse ? "#33ffffff" : "#22ffffff"

                        RowLayout {
                            id: sortRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "\uf160"
                                color: Colors.accent
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                text: sortBy === "cpu" ? "CPU" : "RAM"
                                color: Colors.text
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        MouseArea {
                            id: sortArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sortBy = sortBy === "cpu" ? "ram" : "cpu";
                                refresh();
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Column headers
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4

                    Text {
                        Layout.fillWidth: true
                        text: "NAME"
                        color: Colors.overlay
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Text {
                        width: 56
                        text: "CPU"
                        color: sortBy === "cpu" ? Colors.accent : Colors.overlay
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                        horizontalAlignment: Text.AlignRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        width: 72
                        text: "RAM"
                        color: sortBy === "ram" ? Colors.accent : Colors.overlay
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                        horizontalAlignment: Text.AlignRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Space for kill button
                    Item { width: 28 }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#22ffffff"
                }

                // Process list
                Flickable {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(procList.implicitHeight, 420)
                    contentHeight: procList.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: procList
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: processes

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 8
                                color: rowHover.containsMouse ? "#22ffffff" : "#11ffffff"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 0

                                    // Process name + pid
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: Colors.text
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "PID " + modelData.pid
                                            color: Colors.overlay
                                            font.pixelSize: 9
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }

                                    // CPU bar + value
                                    ColumnLayout {
                                        width: 56
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: modelData.cpu + "%"
                                            color: modelData.cpu > 50 ? Colors.red : modelData.cpu > 20 ? Colors.yellow : Colors.subtle
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                            horizontalAlignment: Text.AlignRight
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        Rectangle {
                                            width: 56
                                            height: 3
                                            radius: 2
                                            color: "#22ffffff"

                                            Rectangle {
                                                width: Math.min(parent.width * modelData.cpu / 100, parent.width)
                                                height: parent.height
                                                radius: 2
                                                color: modelData.cpu > 50 ? Colors.red : modelData.cpu > 20 ? Colors.yellow : Colors.accent
                                                Behavior on width { NumberAnimation { duration: 300 } }
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                    }

                                    // RAM
                                    Text {
                                        width: 72
                                        text: modelData.ram
                                        color: Colors.subtle
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                        horizontalAlignment: Text.AlignRight
                                        leftPadding: 8
                                    }

                                    // Kill button
                                    Rectangle {
                                        width: 28; height: 28; radius: 6
                                        color: killHover.containsMouse ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.3) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf00d"
                                            color: killHover.containsMouse ? Colors.red : "transparent"
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            id: killHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                processManager.killProcess(modelData.pid);
                                            }
                                        }

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: rowHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }
            }

            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // Fetch processes
    Process {
        id: fetchProc
        running: false

        command: ["python3", "-c", "
import subprocess, json, sys

sort = sys.argv[1]
result = subprocess.run(
    ['ps', 'aux', '--no-headers', '--sort=-' + ('%cpu' if sort == 'cpu' else '%mem')],
    capture_output=True, text=True
)

procs = []
for line in result.stdout.strip().split('\\n')[:15]:
    parts = line.split(None, 10)
    if len(parts) < 11:
        continue
    pid  = parts[1]
    cpu  = float(parts[2])
    mem  = float(parts[3])
    rss  = int(parts[5])
    name = parts[10].split('/')[-1].split()[0][:24]
    # Format RAM
    if rss >= 1024*1024:
        ram = f'{rss/1024/1024:.1f} GB'
    elif rss >= 1024:
        ram = f'{rss/1024:.0f} MB'
    else:
        ram = f'{rss} KB'
    procs.append({'pid': pid, 'name': name, 'cpu': cpu, 'ram': ram})

print(json.dumps(procs))
", sortBy]

        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }

        onRunningChanged: {
            if (!running) {
                var raw = fetchProc.stdout.buf.trim();
                fetchProc.stdout.buf = "";
                try {
                    processes = JSON.parse(raw);
                } catch(e) {
                    processes = [];
                }
            }
        }
    }

    // Kill process
    Process {
        id: killProc
        running: false
        onRunningChanged: {
            if (!running) refresh();
        }
    }

    // Auto-refresh
    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: false
        onTriggered: refresh()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: processManager.isOpen = false
    }
}