import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: fileBrowser

    property bool isOpen: false
    property bool initialized: false
    property bool showHidden: false
    property string currentPath: ""
    property var entries: []
    property var filteredEntries: []
    property string searchText: ""
    property var pathHistory: []
    property string homePath: Quickshell.env("HOME")

    function toggle() {
        isOpen = !isOpen;
    }

    function navigateTo(path) {
        if (currentPath !== "") {
            pathHistory.push(currentPath);
            pathHistory = pathHistory.slice();
        }
        currentPath = path;
        searchText = "";
        searchInput.text = "";
        listProc.command = ["python3", homePath + "/.config/hypr/quickshell/modules/file-browser/list_files.py", path];
        listProc.running = true;
    }

    function navigateBack() {
        if (pathHistory.length === 0) return;
        var prev = pathHistory.pop();
        pathHistory = pathHistory.slice();
        currentPath = prev;
        searchText = "";
        searchInput.text = "";
        listProc.command = ["python3", homePath + "/.config/hypr/quickshell/modules/file-browser/list_files.py", prev];
        listProc.running = true;
    }

    function filterEntries(query) {
        var source = entries;
        if (!showHidden) {
            source = entries.filter(function(e) {
                return !e.name.startsWith(".");
            });
        }
        if (query === "") {
            filteredEntries = source.slice();
        } else {
            var q = query.toLowerCase();
            filteredEntries = source.filter(function(e) {
                return e.name.toLowerCase().indexOf(q) !== -1;
            });
        }
    }

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB";
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + " GB";
    }

    function getFileIcon(name, isDir) {
        if (isDir) {
            if (name === ".git") return "\ue5fb";
            if (name === "Downloads") return "\uf019";
            if (name === "Pictures" || name === "Images") return "\uf03e";
            if (name === "Music") return "\uf001";
            if (name === "Videos") return "\uf03d";
            if (name === "Documents") return "\uf15c";
            if (name === "Desktop") return "\uf108";
            if (name === ".config") return "\uf013";
            if (name === "node_modules") return "\ue718";
            return "\uf07b";
        }
        var ext = name.lastIndexOf(".") !== -1 ? name.substring(name.lastIndexOf(".") + 1).toLowerCase() : "";
        if (ext === "py") return "\ue606";
        if (ext === "js" || ext === "ts" || ext === "jsx" || ext === "tsx") return "\ue74e";
        if (ext === "html" || ext === "htm") return "\uf13b";
        if (ext === "css" || ext === "scss") return "\uf13c";
        if (ext === "json") return "\ue60b";
        if (ext === "md") return "\uf48a";
        if (ext === "sh" || ext === "bash" || ext === "zsh" || ext === "fish") return "\uf489";
        if (ext === "png" || ext === "jpg" || ext === "jpeg" || ext === "gif" || ext === "webp" || ext === "svg") return "\uf03e";
        if (ext === "mp3" || ext === "flac" || ext === "wav" || ext === "ogg") return "\uf001";
        if (ext === "mp4" || ext === "mkv" || ext === "avi" || ext === "mov") return "\uf03d";
        if (ext === "pdf") return "\uf1c1";
        if (ext === "zip" || ext === "tar" || ext === "gz" || ext === "bz2" || ext === "xz" || ext === "7z") return "\uf1c6";
        if (ext === "php") return "\ue73d";
        if (ext === "sql") return "\uf1c0";
        if (ext === "txt") return "\uf15c";
        if (ext === "xml" || ext === "yaml" || ext === "yml" || ext === "toml" || ext === "ini" || ext === "conf") return "\uf17a";
        if (name.startsWith(".")) return "\uf023";
        return "\uf15b";
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
        if (isOpen) {
            if (currentPath === "") {
                navigateTo(homePath);
            }
            searchText = "";
            searchInput.text = "";
            Qt.callLater(function() {
                searchInput.forceActiveFocus();
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            visible: isOpen
            onClicked: fileBrowser.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 600
            height: Math.min(panelCol.implicitHeight + 32, 680)
            radius: 10
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            clip: true
            opacity: isOpen ? 1 : 0
            scale: isOpen ? 1 : 0.95

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
                    spacing: 8

                    // Back button
                    Text {
                        text: "\uf060"
                        color: pathHistory.length > 0
                            ? (backArea.containsMouse ? Colors.text : Colors.subtle)
                            : Colors.overlay
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pathHistory.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: pathHistory.length > 0
                            onClicked: fileBrowser.navigateBack()
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    // Home button
                    Text {
                        text: "\uf015"
                        color: homeArea.containsMouse ? Colors.text : Colors.subtle
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: homeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pathHistory = [];
                                fileBrowser.navigateTo(homePath);
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    // Toggle hidden files button
                    Text {
                        text: "\uf023"
                        color: showHidden
                            ? Colors.accent
                            : (hiddenArea.containsMouse ? Colors.text : Colors.subtle)
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: hiddenArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                fileBrowser.showHidden = !fileBrowser.showHidden;
                                fileBrowser.filterEntries(searchText);
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    // Current path
                    Text {
                        Layout.fillWidth: true
                        text: currentPath.replace(homePath, "~")
                        color: Colors.subtle
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideLeft
                    }

                    // Entry count
                    Text {
                        text: filteredEntries.length + " item" + (filteredEntries.length !== 1 ? "s" : "")
                        color: Colors.overlay
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
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

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

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
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            selectionColor: Colors.accent
                            clip: true
                            focus: true

                            onTextChanged: {
                                searchText = text;
                                fileBrowser.filterEntries(text);
                            }

                            Keys.onEscapePressed: fileBrowser.isOpen = false
                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
                                    fileBrowser.showHidden = !fileBrowser.showHidden;
                                    fileBrowser.filterEntries(searchText);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    visible: filteredEntries.length === 0 && !listProc.running
                    Layout.fillWidth: true
                    implicitHeight: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf07b"
                            color: Colors.overlay
                            font.pixelSize: 28
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Empty folder"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                // File list
                ListView {
                    id: fileList

                    visible: filteredEntries.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 560)
                    model: filteredEntries
                    clip: true
                    spacing: 4
                    focus: false

                    delegate: Rectangle {
                        width: fileList.width
                        height: 44
                        radius: 10
                        color: itemArea.containsMouse ? "#22ffffff" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Icon
                            Text {
                                text: fileBrowser.getFileIcon(modelData.name, modelData.isDir)
                                color: modelData.isDir ? Colors.accent : Colors.subtle
                                font.pixelSize: 16
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            // Name
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Colors.text
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                opacity: modelData.name.startsWith(".") ? 0.6 : 1.0
                            }

                            // Size (files only)
                            Text {
                                visible: !modelData.isDir && modelData.size !== ""
                                text: fileBrowser.formatSize(parseInt(modelData.size))
                                color: Colors.overlay
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            // Arrow for dirs
                            Text {
                                visible: modelData.isDir
                                text: "\uf054"
                                color: Colors.overlay
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.isDir) {
                                    fileBrowser.navigateTo(modelData.path);
                                } else {
                                    openProc.command = ["xdg-open", modelData.path];
                                    openProc.running = true;
                                    fileBrowser.isOpen = false;
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 100 }
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

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Process {
        id: listProc

        running: false

        onRunningChanged: {
            if (!running) {
                var raw = listProc.stdout.buf;
                listProc.stdout.buf = "";
                var lines = raw.split("\n");
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim() === "") continue;
                    var parts = line.split("\t");
                    if (parts.length < 3) continue;
                    var type = parts[0].trim();
                    var name = parts[1].trim();
                    var path = parts[2].trim();
                    var size = parts.length >= 4 ? parts[3].trim() : "";
                    result.push({
                        "isDir": type === "d",
                        "name": name,
                        "path": path,
                        "size": size
                    });
                }
                entries = result;
                filterEntries(searchText);
            }
        }

        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }
    }

    Process {
        id: openProc
        running: false
    }
}