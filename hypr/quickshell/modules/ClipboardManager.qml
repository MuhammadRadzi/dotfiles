import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: clipboardManager

    property bool isOpen: false
    property var items: []
    property string searchText: ""
    property var filteredItems: []

    function toggle() {
        isOpen = !isOpen;
    }

    function filterItems(query) {
        if (query === "") {
            filteredItems = items.slice(0, 100);
        } else {
            var q = query.toLowerCase();
            var results = [];
            for (var i = 0; i < items.length; i++) {
                if (items[i].preview.toLowerCase().indexOf(q) !== -1)
                    results.push(items[i]);

            }
            filteredItems = results.slice(0, 100);
        }
    }

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
            listProc.running = true;
            searchText = "";
            searchInput.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: clipboardManager.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 41 + 8
            width: 360
            height: Math.min(panelCol.implicitHeight + 32, 600)
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
                id: panelCol

                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "CLIPBOARD"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Clear all"
                        color: clearAllArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: clearAllArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clearProc.running = true
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 10
                    color: "#22ffffff"
                    border.width: 1
                    border.color: searchInput.activeFocus ? Colors.accent : "#33ffffff"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "\uf002"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            text: searchText
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            selectionColor: Colors.accent
                            clip: true
                            onTextChanged: {
                                searchText = text;
                                clipboardManager.filterItems(text);
                            }
                            Keys.onEscapePressed: clipboardManager.isOpen = false
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                // Empty state
                Item {
                    visible: filteredItems.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf0ea"
                            color: Colors.overlay
                            font.pixelSize: 28
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Clipboard is empty"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                // List
                Flickable {
                    visible: filteredItems.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(clipList.implicitHeight, 480)
                    contentHeight: clipList.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: clipList

                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: filteredItems

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: itemCol.implicitHeight + 20
                                radius: 10
                                color: itemArea.containsMouse ? "#22ffffff" : "#11ffffff"

                                ColumnLayout {
                                    id: itemCol

                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 36
                                    anchors.topMargin: 10
                                    anchors.bottomMargin: 10
                                    spacing: 4

                                    // Index badge + preview
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 4
                                            color: "#22ffffff"

                                            Text {
                                                anchors.centerIn: parent
                                                text: (index + 1).toString()
                                                color: Colors.subtle
                                                font.pixelSize: 9
                                                font.family: "JetBrainsMono Nerd Font"
                                            }

                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.preview
                                            color: Colors.text
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                        }

                                    }

                                }

                                // Copy button
                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 10
                                    text: "\uf0c5"
                                    color: copyArea.containsMouse ? Colors.accent : Colors.subtle
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"

                                    MouseArea {
                                        id: copyArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            decodeProc.entryId = modelData.id;
                                            decodeProc.running = true;
                                            clipboardManager.isOpen = false;
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
                                    onClicked: {
                                        decodeProc.entryId = modelData.id;
                                        decodeProc.running = true;
                                        clipboardManager.isOpen = false;
                                    }
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

    // Fetch clipboard list
    Process {
        id: listProc

        command: ["sh", "-c", "cliphist list 2>/dev/null"]
        running: false
        onRunningChanged: {
            if (!running) {
                var raw = listProc.stdout.buf;
                listProc.stdout.buf = "";
                var lines = raw.split("\n");
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim() === "")
                        continue;

                    // cliphist format: "<id>\t<content>"
                    var tabIdx = line.indexOf("\t");
                    if (tabIdx === -1)
                        continue;

                    var id = line.substring(0, tabIdx).trim();
                    var content = line.substring(tabIdx + 1).trim();
                    // Skip binary
                    if (content.indexOf("[[ binary data") !== -1)
                        continue;

                    result.push({
                        "id": id,
                        "preview": content
                    });
                }
                items = result;
                filterItems(searchText);
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

    // Decode and copy selected entry
    Process {
        id: decodeProc

        property string entryId: ""

        running: false
        command: ["sh", "-c", `cliphist decode ${entryId} | wl-copy`]
    }

    // Clear all
    Process {
        id: clearProc

        command: ["sh", "-c", "cliphist wipe"]
        running: false
        onRunningChanged: {
            if (!running) {
                items = [];
                filteredItems = [];
            }
        }
    }

}
