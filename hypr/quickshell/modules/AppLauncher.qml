import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: appLauncher

    property bool isOpen: false
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0
    property string searchText: ""

    function toggle() {
        isOpen = !isOpen;
    }

    function filterApps(query) {
        if (query === "") {
            filteredApps = allApps.slice(0, 64);
        } else {
            var q = query.toLowerCase();
            var results = [];
            for (var i = 0; i < allApps.length; i++) {
                var app = allApps[i];
                if (app.name.toLowerCase().indexOf(q) !== -1)
                    results.push(app);

            }
            filteredApps = results.slice(0, 64);
        }
        selectedIndex = 0;
    }

    function launchSelected() {
        if (filteredApps.length === 0)
            return ;

        var app = filteredApps[selectedIndex];
        // Strip field codes like %F %u %U etc
        var cmd = app.exec.replace(/%[a-zA-Z]/g, "").trim();
        execProc.command = ["sh", "-c", cmd];
        execProc.running = true;
        isOpen = false;
    }

    visible: overlayRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"
    onIsOpenChanged: {
        if (isOpen) {
            searchText = "";
            selectedIndex = 0;
            filterApps("");
            searchInput.forceActiveFocus();
        }
    }
    Component.onCompleted: {
        scanProc.running = true;
    }

    // Click outside to close
    Rectangle {
        id: overlayRect

        anchors.fill: parent
        color: "transparent"
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: appLauncher.isOpen = false
        }

        // Panel
        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 560
            height: panelCol.implicitHeight + 32
            radius: 16
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            ColumnLayout {
                id: panelCol

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                // Header
                Text {
                    text: "APP LAUNCHER"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                    topPadding: 4
                }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 10
                    color: "#22ffffff"
                    border.width: 1
                    border.color: searchInput.activeFocus ? Colors.accent : "#33ffffff"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: "\uf002"
                            color: Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            text: searchText
                            color: Colors.text
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            selectionColor: Colors.accent
                            clip: true
                            onTextChanged: {
                                searchText = text;
                                appLauncher.filterApps(text);
                            }
                            Keys.onUpPressed: {
                                if (selectedIndex > 0)
                                    selectedIndex--;

                                appList.positionViewAtIndex(selectedIndex, ListView.Contain);
                            }
                            Keys.onDownPressed: {
                                if (selectedIndex < filteredApps.length - 1)
                                    selectedIndex++;

                                appList.positionViewAtIndex(selectedIndex, ListView.Contain);
                            }
                            Keys.onReturnPressed: appLauncher.launchSelected()
                            Keys.onEscapePressed: appLauncher.isOpen = false
                        }

                        // Clear button
                        Text {
                            visible: searchText !== ""
                            text: "\uf00d"
                            color: clearInputArea.containsMouse ? Colors.text : Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"

                            MouseArea {
                                id: clearInputArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                // Results count
                Text {
                    visible: searchText !== ""
                    text: filteredApps.length + " result" + (filteredApps.length !== 1 ? "s" : "")
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1
                }

                // Empty state
                Item {
                    visible: filteredApps.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf059"
                            color: Colors.overlay
                            font.pixelSize: 28
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No apps found"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                // App list
                ListView {
                    id: appList

                    visible: filteredApps.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(filteredApps.length * 52, 52 * 7)
                    model: filteredApps
                    clip: true
                    spacing: 4
                    currentIndex: selectedIndex

                    delegate: Rectangle {
                        width: appList.width
                        height: 48
                        radius: 10
                        color: (index === selectedIndex) ? "#33ffffff" : (itemArea.containsMouse ? "#22ffffff" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Item {
                                width: 28
                                height: 28

                                Image {
                                    id: appIcon

                                    anchors.fill: parent
                                    source: modelData.icon !== "" ? ("file://" + modelData.icon) : ""
                                    visible: modelData.icon !== "" && status === Image.Ready
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.icon === "" || appIcon.status !== Image.Ready
                                    text: "\uf17c"
                                    color: Colors.accent
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.exec.replace(/%[a-zA-Z]/g, "").trim()
                                    color: Colors.subtle
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                }

                            }

                        }

                        MouseArea {
                            id: itemArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                selectedIndex = index;
                                appLauncher.launchSelected();
                            }
                            onEntered: selectedIndex = index
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }

                        }

                    }

                }

                Item {
                    implicitHeight: 4
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

    // Scan .desktop files
    Process {
        id: scanProc

        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/list_apps.py"]
        running: false
        onRunningChanged: {
            if (!running) {
                var raw = scanProc.stdout.buf;
                scanProc.stdout.buf = "";
                var apps = [];
                var lines = raw.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim() === "")
                        continue;

                    var parts = line.split("\t");
                    if (parts.length < 2)
                        continue;

                    var name = parts[0].trim();
                    var exec = parts[1].trim();
                    var iconpath = parts.length >= 3 ? parts[2].trim() : "";
                    if (name === "" || exec === "")
                        continue;

                    apps.push({
                        "name": name,
                        "exec": exec,
                        "icon": iconpath
                    });
                }
                apps.sort(function(a, b) {
                    return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
                });
                allApps = apps;
                filterApps(searchText);
                searchInput.forceActiveFocus();
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

    Process {
        id: execProc

        running: false
    }

}
