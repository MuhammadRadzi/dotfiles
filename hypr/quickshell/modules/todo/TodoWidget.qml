import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: todoWidget

    property bool isOpen: false
    property bool initialized: false
    property var todos: []
    property int activeCount: todos.filter(function(t) { return !t.done; }).length
    property string todoPath: Quickshell.env("HOME") + "/.local/share/hypr/todos.json"
    property string currentFilter: "all"

    property var filteredTodos: {
        if (currentFilter === "active") return todos.filter(function(t) { return !t.done; });
        if (currentFilter === "done")   return todos.filter(function(t) { return t.done;  });
        return todos;
    }

    function toggle() {
        isOpen = !isOpen;
    }

    function addTodo(text) {
        if (text.trim() === "") return;
        var updated = todos.slice();
        updated.unshift({ id: Date.now(), text: text.trim(), done: false });
        todos = updated;
        save();
    }

    function toggleDone(id) {
        var updated = todos.map(function(t) {
            return t.id === id ? { id: t.id, text: t.text, done: !t.done } : t;
        });
        todos = updated;
        save();
    }

    function removeTodo(id) {
        todos = todos.filter(function(t) { return t.id !== id; });
        save();
    }

    function save() {
        var encoded = Qt.btoa(unescape(encodeURIComponent(JSON.stringify(todos))));
        saveProc.command = ["python3", "-c",
            "import base64, os, sys\n" +
            "path = sys.argv[1]\n" +
            "content = base64.b64decode(sys.argv[2]).decode('utf-8')\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "open(path, 'w').write(content)",
            todoPath, encoded
        ];
        saveProc.running = true;
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
            loadProc.running = true;
            todoInput.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: todoWidget.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.verticalCenter: parent.verticalCenter
        x: isOpen ? 10 : -width - 20
        width: 320
        height: Math.min(panelCol.implicitHeight + 32, 560)
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: panelCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "\uf0ae"
                    color: Colors.accent
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                }

                Text {
                    text: "Todo"
                    color: Colors.text
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                    leftPadding: 6
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: activeCount > 0
                    text: activeCount + " left"
                    color: Colors.overlay
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            // Input field
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: todoInput.activeFocus ? "#22ffffff" : "#11ffffff"
                border.width: 1
                border.color: todoInput.activeFocus ? Colors.accent : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "\uf067"
                        color: todoInput.activeFocus ? Colors.accent : Colors.overlay
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: todoInput
                        Layout.fillWidth: true
                        color: Colors.text
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
                        selectedTextColor: Colors.text
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Add a task..."
                            color: Colors.overlay
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            visible: todoInput.text === ""
                        }

                        Keys.onReturnPressed: {
                            todoWidget.addTodo(text);
                            text = "";
                        }

                        Keys.onEscapePressed: {
                            if (text !== "") {
                                text = "";
                            } else {
                                todoWidget.isOpen = false;
                            }
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#22ffffff"
            }

            // Filter tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: [
                        { label: "All",    value: "all"    },
                        { label: "Active", value: "active" },
                        { label: "Done",   value: "done"   }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: currentFilter === modelData.value ? "#33ffffff" : "transparent"
                        border.width: 1
                        border.color: currentFilter === modelData.value ? Colors.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: currentFilter === modelData.value ? Colors.text : Colors.overlay
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentFilter = modelData.value
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Empty state
            Item {
                visible: filteredTodos.length === 0
                Layout.fillWidth: true
                implicitHeight: 60

                Text {
                    anchors.centerIn: parent
                    text: currentFilter === "done" ? "Nothing done yet" : "No tasks"
                    color: Colors.overlay
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            // Todo list
            Flickable {
                visible: filteredTodos.length > 0
                Layout.fillWidth: true
                implicitHeight: Math.min(todoList.implicitHeight, 360)
                contentHeight: todoList.implicitHeight
                clip: true

                ColumnLayout {
                    id: todoList
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: filteredTodos

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: itemHover.containsMouse ? "#22ffffff" : "#11ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 10

                                // Checkbox
                                Rectangle {
                                    width: 18; height: 18; radius: 4
                                    color: modelData.done ? Colors.accent : "transparent"
                                    border.width: 1.5
                                    border.color: modelData.done ? Colors.accent : Colors.overlay

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00c"
                                        color: Colors.base
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                        visible: modelData.done
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: todoWidget.toggleDone(modelData.id)
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                }

                                // Text
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    color: modelData.done ? Colors.overlay : Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.strikeout: modelData.done
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                // Delete button
                                Text {
                                    text: "\uf00d"
                                    color: delHover.containsMouse ? Colors.red : "transparent"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"

                                    MouseArea {
                                        id: delHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: todoWidget.removeTodo(modelData.id)
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // Clear completed — di luar Flickable
            Rectangle {
                visible: todos.filter(function(t) { return t.done; }).length > 0
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: clearDoneHover.containsMouse ? "#22ffffff" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Clear completed"
                    color: Colors.overlay
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: clearDoneHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        todos = todos.filter(function(t) { return !t.done; });
                        save();
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Behavior on x {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
    }

    Process {
        id: loadProc
        command: ["sh", "-c", "cat '" + todoPath + "' 2>/dev/null || echo '[]'"]
        running: false

        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }

        onRunningChanged: {
            if (!running) {
                var content = loadProc.stdout.buf.trim();
                loadProc.stdout.buf = "";
                try {
                    todos = JSON.parse(content);
                } catch(e) {
                    todos = [];
                }
            }
        }
    }

    Process {
        id: saveProc
        running: false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: todoWidget.isOpen = false
    }
}