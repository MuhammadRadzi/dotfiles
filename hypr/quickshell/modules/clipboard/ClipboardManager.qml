import "../../theme"
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
    property var imagePreviews: ({
    })
    property string homePath: Quickshell.env("HOME")
    property bool initialized: false

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
                var item = items[i];
                if (item.type === "image" || item.type === "image-uri")
                    results.push(item);
                else if (item.preview.toLowerCase().indexOf(q) !== -1)
                    results.push(item);
            }
            filteredItems = results.slice(0, 100);
        }
    }

    function requestImagePreview(entryId, entryType, entryPreview) {
        if (imagePreviews[entryId] !== undefined)
            return ;

        var updated = Object.assign({
        }, imagePreviews);
        updated[entryId] = "loading";
        imagePreviews = updated;
        var cmd;
        if (entryType === "image-uri")
            cmd = ["python3", Quickshell.env("HOME") + "/.config/hypr/quickshell/modules/clipboard/decode_preview.py", entryId, entryPreview];
        else
            cmd = ["python3", Quickshell.env("HOME") + "/.config/hypr/quickshell/modules/clipboard/decode_preview.py", entryId];
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process { property string eid: ""; running: false }
        `, clipboardManager);
        proc.eid = entryId;
        proc.command = cmd;
        proc.stdout = Qt.createQmlObject(`
            import Quickshell.Io
            SplitParser { property string buf: ""; splitMarker: ""; onRead: (data) => { buf += data; } }
        `, proc);
        proc.onRunningChanged.connect(function() {
            if (!proc.running) {
                var path = proc.stdout.buf.trim();
                if (path !== "") {
                    var up = Object.assign({
                    }, imagePreviews);
                    up[entryId] = path;
                    imagePreviews = up;
                }
                proc.destroy();
            }
        });
        proc.running = true;
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
        console.log("ClipboardManager isOpen:", isOpen, "keyboardFocus:", WlrLayershell.keyboardFocus);
        if (isOpen) {
            listProc.running = true;
            searchText = "";
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
            });
        }
        initialized = true;
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            visible: isOpen
            onClicked: clipboardManager.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 39 + 8
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
                onClicked: searchInput.forceActiveFocus()
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
                        text: items.length + " item" + (items.length !== 1 ? "s" : "")
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Item {
                        implicitWidth: 12
                    }

                    Text {
                        text: "\uf2ed"
                        color: clearAllArea.containsMouse ? Colors.red : Colors.subtle
                        font.pixelSize: 13
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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: searchInput.forceActiveFocus()
                    }

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
                            focus: true
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
                ListView {
                    id: clipList

                    visible: filteredItems.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 480)
                    model: filteredItems
                    clip: true
                    spacing: 6
                    focus: false

                    delegate: Rectangle {
                        id: clipItem

                        property bool isImage: modelData.type === "image" || modelData.type === "image-uri"
                        property string imgPath: clipboardManager.imagePreviews[modelData.id] || ""
                        property bool imgReady: imgPath !== "" && imgPath !== "loading"

                        width: clipList.width
                        implicitHeight: isImage ? imageContent.implicitHeight + 20 : textContent.implicitHeight + 20
                        radius: 10
                        color: itemArea.containsMouse ? "#22ffffff" : "#11ffffff"
                        Component.onCompleted: {
                            if (isImage)
                                clipboardManager.requestImagePreview(modelData.id, modelData.type, modelData.preview);

                        }

                        // Image entry
                        Item {
                            id: imageContent

                            visible: isImage
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 36
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            implicitHeight: 120

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: "#22ffffff"
                                visible: !imgReady

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: "\uf03e"
                                        color: Colors.subtle
                                        font.pixelSize: 20
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                    Text {
                                        text: "Loading preview..."
                                        color: Colors.subtle
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                    }

                                }

                            }

                            Image {
                                anchors.fill: parent
                                source: imgReady ? ("file://" + imgPath) : ""
                                visible: imgReady && status === Image.Ready
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                clip: true
                            }

                        }

                        // Text entry
                        Item {
                            id: textContent

                            visible: !isImage
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 36
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            implicitHeight: textPreview.implicitHeight

                            Text {
                                id: textPreview

                                width: parent.width
                                text: modelData.preview
                                color: Colors.text
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                maximumLineCount: 3
                                wrapMode: Text.WordWrap
                            }

                        }

                        // Copy button
                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 10
                            anchors.topMargin: 10
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
                                    decodeProc.entryId = "";
                                    decodeProc.entryPath = "";
                                    decodeProc.entryId = modelData.id;
                                    decodeProc.entryPath = modelData.type === "image-uri" ? modelData.preview : "";
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
                                decodeProc.entryId = "";
                                decodeProc.entryPath = "";
                                decodeProc.entryId = modelData.id;
                                decodeProc.entryPath = modelData.type === "image-uri" ? modelData.preview : "";
                                decodeProc.running = true;
                                clipboardManager.isOpen = false;
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
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

        command: ["python3", homePath + "/.config/hypr/quickshell/modules/clipboard/list_clips.py"]
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

                    var parts = line.split("\t");
                    if (parts.length < 3)
                        continue;

                    var id = parts[0].trim();
                    var type = parts[1].trim();
                    var preview = parts.slice(2).join("\t").trim();
                    result.push({
                        "id": id,
                        "type": type,
                        "preview": preview
                    });
                }
                items = result;
                imagePreviews = {
                };
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

    // Decode and copy
    Process {
        id: decodeProc

        property string entryId: ""
        property string entryPath: ""

        running: false
        command: entryPath !== "" ? ["python3", homePath + "/.config/hypr/quickshell/modules/clipboard/decode_clip.py", entryId, entryPath] : ["python3", homePath + "/.config/hypr/quickshell/modules/clipboard/decode_clip.py", entryId]
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
                imagePreviews = {
                };
            }
        }
    }

}
