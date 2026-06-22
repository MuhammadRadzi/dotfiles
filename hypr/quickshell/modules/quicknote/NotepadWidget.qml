import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: notepadWidget

    // ── State ────────────────────────────────────────────────
    property bool isOpen: false
    property bool initialized: false

    property string activeTab: "note"

    property string notePath: Quickshell.env("HOME") + "/.local/share/hypr/quicknote.txt"
    property string todoPath: Quickshell.env("HOME") + "/.local/share/hypr/todos.json"
    property string tabPath:  Quickshell.env("HOME") + "/.local/share/hypr/notepad_tab.txt"

    property var todos: []
    property int activeCount: todos.filter(function(t) { return !t.done; }).length
    property string currentFilter: "all"
    property var filteredTodos: {
        if (currentFilter === "active") return todos.filter(function(t) { return !t.done; });
        if (currentFilter === "done")   return todos.filter(function(t) { return t.done;  });
        return todos;
    }

    function toggle() { isOpen = !isOpen; }

    function addTodo(text) {
        if (text.trim() === "") return;
        var updated = todos.slice();
        updated.unshift({ id: Date.now(), text: text.trim(), done: false });
        todos = updated;
        saveTodo();
    }

    function toggleDone(id) {
        todos = todos.map(function(t) {
            return t.id === id ? { id: t.id, text: t.text, done: !t.done } : t;
        });
        saveTodo();
    }

    function removeTodo(id) {
        todos = todos.filter(function(t) { return t.id !== id; });
        saveTodo();
    }

    function saveTodo() {
        var encoded = Qt.btoa(unescape(encodeURIComponent(JSON.stringify(todos))));
        todoSaveProc.command = ["python3", "-c",
            "import base64, os, sys\n" +
            "path = sys.argv[1]\n" +
            "content = base64.b64decode(sys.argv[2]).decode('utf-8')\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "open(path, 'w').write(content)",
            todoPath, encoded
        ];
        todoSaveProc.running = true;
    }

    function saveNote() {
        var encoded = Qt.btoa(unescape(encodeURIComponent(noteArea.text)));
        noteSaveProc.command = ["python3", "-c",
            "import base64, os, sys\n" +
            "path = sys.argv[1]\n" +
            "content = base64.b64decode(sys.argv[2]).decode('utf-8')\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "open(path, 'w').write(content)",
            notePath, encoded
        ];
        noteSaveProc.running = true;
    }

    function saveTab() {
        var encoded = Qt.btoa(unescape(encodeURIComponent(activeTab)));
        tabSaveProc.command = ["python3", "-c",
            "import base64, os, sys\n" +
            "path = sys.argv[1]\n" +
            "content = base64.b64decode(sys.argv[2]).decode('utf-8')\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "open(path, 'w').write(content)",
            tabPath, encoded
        ];
        tabSaveProc.running = true;
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
            tabLoadProc.running = true;
            noteLoadProc.running = true;
            todoLoadProc.running = true;
        }
    }

    onActiveTabChanged: {
        saveTab();
        if (activeTab === "note") noteArea.forceActiveFocus();
        else todoInput.forceActiveFocus();
    }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        visible: isOpen
        onClicked: notepadWidget.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.verticalCenter: parent.verticalCenter
        x: isOpen ? 10 : -width - 20
        width: 320
        height: 540
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // ── Header / Tab bar ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                // Tab: Note
                Rectangle {
                    height: 30
                    width: noteTabRow.implicitWidth + 20
                    radius: 7
                    color: activeTab === "note" ? "#33ffffff" : "transparent"
                    border.width: 1
                    border.color: activeTab === "note" ? Colors.accent : "transparent"

                    RowLayout {
                        id: noteTabRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "\uf249"
                            color: Colors.accent
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Note"
                            color: Colors.accent
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: activeTab === "note" ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: activeTab = "note"
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                // Tab: Todo
                Rectangle {
                    height: 30
                    width: todoTabRow.implicitWidth + 20
                    radius: 7
                    color: activeTab === "todo" ? "#33ffffff" : "transparent"
                    border.width: 1
                    border.color: activeTab === "todo" ? Colors.accent : "transparent"

                    RowLayout {
                        id: todoTabRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "\uf0ae"
                            color: Colors.accent
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Todo"
                            color: Colors.accent
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: activeTab === "todo" ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            visible: activeCount > 0
                            width: badgeText.implicitWidth + 8
                            height: 16
                            radius: 8
                            color: Colors.accent

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: activeCount
                                color: Colors.base
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: activeTab = "todo"
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Clear button (Note tab only)
                Rectangle {
                    visible: activeTab === "note"
                    width: 28
                    height: 28
                    radius: 8
                    color: clearNoteArea.containsMouse ? "#33ffffff" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf12d"
                        color: Colors.subtle
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: clearNoteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            noteArea.text = "";
                            saveDebounce.restart();
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // ── Divider ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#22ffffff"
            }

            // ── Tab content area ──────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // NOTE TAB
                ColumnLayout {
                    visible: activeTab === "note"
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: "#11ffffff"

                        Flickable {
                            id: noteFlickable
                            anchors.fill: parent
                            anchors.margins: 10
                            contentHeight: noteArea.implicitHeight
                            clip: true

                            TextEdit {
                                id: noteArea
                                width: noteFlickable.width
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

                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: noteArea.text.length + " chars"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                // TODO TAB
                ColumnLayout {
                    visible: activeTab === "todo"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 8

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
                                    color: Colors.subtle
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    visible: todoInput.text === ""
                                }

                                Keys.onReturnPressed: {
                                    notepadWidget.addTodo(text);
                                    text = "";
                                }

                                Keys.onEscapePressed: {
                                    if (text !== "") text = "";
                                    else notepadWidget.isOpen = false;
                                }
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
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
                                height: 26
                                radius: 6
                                color: currentFilter === modelData.value ? "#33ffffff" : "transparent"
                                border.width: 1
                                border.color: currentFilter === modelData.value ? Colors.accent : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Colors.subtle 
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

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#22ffffff"
                    }

                    // Empty state
                    Item {
                        visible: filteredTodos.length === 0
                        Layout.fillWidth: true
                        implicitHeight: 50

                        Text {
                            anchors.centerIn: parent
                            text: currentFilter === "done" ? "Nothing done yet" : "No tasks"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    // Todo list
                    Flickable {
                        visible: filteredTodos.length > 0
                        Layout.fillWidth: true
                        implicitHeight: Math.min(todoList.implicitHeight, 340)
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

                                        Rectangle {
                                            width: 18; height: 18; radius: 4
                                            color: modelData.done ? Colors.accent : "transparent"
                                            border.width: 1.5
                                            border.color: Colors.accent

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
                                                onClicked: notepadWidget.toggleDone(modelData.id)
                                            }

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.text
                                            color: Colors.accent
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.strikeout: modelData.done
                                            elide: Text.ElideRight
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

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
                                                onClicked: notepadWidget.removeTodo(modelData.id)
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

                    // Clear completed
                    Rectangle {
                        visible: todos.filter(function(t) { return t.done; }).length > 0
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: clearDoneHover.containsMouse ? "#22ffffff" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Clear completed"
                            color: Colors.accent
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
                                saveTodo();
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }

        Behavior on x {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
    }

    // ── Timers & Processes ───────────────────────────────────

    Timer {
        id: saveDebounce
        interval: 800
        repeat: false
        onTriggered: saveNote()
    }

    Process {
        id: noteLoadProc
        command: ["sh", "-c", "cat '" + notePath + "' 2>/dev/null || echo ''"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }
        onRunningChanged: {
            if (!running) {
                var content = noteLoadProc.stdout.buf;
                noteLoadProc.stdout.buf = "";
                if (noteArea.text !== content) noteArea.text = content;
            }
        }
    }

    Process { id: noteSaveProc; running: false }

    Process {
        id: todoLoadProc
        command: ["sh", "-c", "cat '" + todoPath + "' 2>/dev/null || echo '[]'"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }
        onRunningChanged: {
            if (!running) {
                var content = todoLoadProc.stdout.buf.trim();
                todoLoadProc.stdout.buf = "";
                try { todos = JSON.parse(content); } catch(e) { todos = []; }
            }
        }
    }

    Process { id: todoSaveProc; running: false }

    Process {
        id: tabLoadProc
        command: ["sh", "-c", "cat '" + tabPath + "' 2>/dev/null || echo 'note'"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }
        onRunningChanged: {
            if (!running) {
                var t = tabLoadProc.stdout.buf.trim();
                tabLoadProc.stdout.buf = "";
                if (t === "note" || t === "todo") activeTab = t;
                if (activeTab === "note") noteArea.forceActiveFocus();
                else todoInput.forceActiveFocus();
            }
        }
    }

    Process { id: tabSaveProc; running: false }

    Shortcut {
        sequence: "Escape"
        onActivated: notepadWidget.isOpen = false
    }
}