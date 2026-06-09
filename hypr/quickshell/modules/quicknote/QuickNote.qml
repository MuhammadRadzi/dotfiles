import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: quickNote

    property bool isOpen: false
    property bool initialized: false
    property string notePath: Quickshell.env("HOME") + "/.local/share/hypr/quicknote.txt"

    function toggle() {
        isOpen = !isOpen;
    }

    visible: initialized && (isOpen || panelRect.x > -panelRect.width - 20)
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
            noteArea.forceActiveFocus();
            loadProc.running = true;
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: quickNote.isOpen = false
    }

    // Panel
    Rectangle {
        id: panelRect

        anchors.verticalCenter: parent.verticalCenter
        x: isOpen ? 10 : -width - 20
        width: 320
        height: Math.min(contentCol.implicitHeight + 32, 500)
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        // Swallow clicks
        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }

        ColumnLayout {
            id: contentCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "\uf249"
                    color: Colors.accent
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                }

                Text {
                    text: "Quick Note"
                    color: Colors.text
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                    leftPadding: 6
                }

                Item {
                    Layout.fillWidth: true
                }

                // Clear button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: clearArea.containsMouse ? "#33ffffff" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf12d"
                        color: clearArea.containsMouse ? Colors.red : Colors.overlay
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                    MouseArea {
                        id: clearArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            noteArea.text = "";
                            saveDebounce.restart();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#22ffffff"
            }

            // Text area
            Rectangle {
                Layout.fillWidth: true
                height: 360
                radius: 8
                color: "#11ffffff"

                Flickable {
                    id: flickable

                    anchors.fill: parent
                    anchors.margins: 10
                    contentHeight: noteArea.implicitHeight
                    clip: true

                    TextEdit {
                        id: noteArea

                        width: flickable.width
                        wrapMode: TextEdit.Wrap
                        color: Colors.text
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
                        selectedTextColor: Colors.text
                        onTextChanged: saveDebounce.restart()

                        Text {
                            anchors.fill: parent
                            text: "Start typing..."
                            color: Colors.overlay
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            visible: noteArea.text === ""
                        }

                    }

                }

            }

            // Footer — char count
            Text {
                Layout.alignment: Qt.AlignRight
                text: noteArea.text.length + " chars"
                color: Colors.overlay
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                bottomPadding: 4
            }

        }

        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }

        }

    }

    // Auto-save debounce — 800ms after last keystroke
    Timer {
        id: saveDebounce

        interval: 800
        repeat: false
        onTriggered: {
            var encoded = Qt.btoa(unescape(encodeURIComponent(noteArea.text)));
            saveProc.command = ["python3", "-c", "import base64, os, sys\n" + "path = sys.argv[1]\n" + "content = base64.b64decode(sys.argv[2]).decode('utf-8')\n" + "os.makedirs(os.path.dirname(path), exist_ok=True)\n" + "open(path, 'w').write(content)", notePath, encoded];
            saveProc.running = true;
        }
    }

    // Load note on open
    Process {
        id: loadProc

        command: ["sh", "-c", "cat '" + notePath + "' 2>/dev/null || echo ''"]
        running: false
        onRunningChanged: {
            if (!running) {
                var content = loadProc.stdout.buf;
                loadProc.stdout.buf = "";
                // Only update if different to avoid cursor reset
                if (noteArea.text !== content)
                    noteArea.text = content;

            }
        }

        stdout: SplitParser {
            property string buf: ""

            splitMarker: ""
            onRead: (data) => {
                buf += data;
            }
        }

    }

    // Save process
    Process {
        id: saveProc

        running: false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: quickNote.isOpen = false
    }

}
