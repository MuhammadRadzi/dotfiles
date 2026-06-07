import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: rulesEditor

    property bool isOpen: false
    property bool initialized: false
    property var rules: []
    property string homePath: Quickshell.env("HOME")
    // Form state
    property string formRule: ""
    property string formFilter: ""
    property int editIndex: -1 // -1 = add new, >= 0 = editing existing
    property int deleteConfirmIndex: -1 // -1 = none, >= 0 = waiting confirm

    function resetForm() {
        formRule = "";
        formFilter = "";
        editIndex = -1;
        deleteConfirmIndex = -1;
        ruleInput.text = "";
        filterInput.text = "";
    }

    function saveRules() {
        var cmd = ["python3", homePath + "/.config/hypr/quickshell/modules/ruleseditor/save_rules.py"];
        for (var i = 0; i < rules.length; i++) {
            cmd.push(rules[i].rule + "\t" + rules[i].filter);
        }
        saveProc.command = cmd;
        saveProc.running = true;
    }

    function applyFormRule() {
        if (formRule.trim() === "" || formFilter.trim() === "")
            return ;

        var updated = rules.slice();
        if (editIndex >= 0)
            updated[editIndex] = {
            "rule": formRule.trim(),
            "filter": formFilter.trim()
        };
        else
            updated.push({
            "rule": formRule.trim(),
            "filter": formFilter.trim()
        });
        rules = updated;
        saveRules();
        resetForm();
    }

    function deleteRule(index) {
        var updated = rules.slice();
        updated.splice(index, 1);
        rules = updated;
        saveRules();
        if (editIndex === index)
            resetForm();

    }

    function startEdit(index) {
        editIndex = index;
        formRule = rules[index].rule;
        formFilter = rules[index].filter;
        ruleInput.text = formRule;
        filterInput.text = formFilter;
        ruleInput.forceActiveFocus();
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
            listProc.running = true;
            resetForm();
            Qt.callLater(function() {
                ruleInput.forceActiveFocus();
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
            onClicked: rulesEditor.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 640
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
                        text: "WINDOW RULES"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: rules.length + " rule" + (rules.length !== 1 ? "s" : "")
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }

                }

                // Form
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: formCol.implicitHeight + 24
                    radius: 10
                    color: "#22ffffff"
                    border.width: 1
                    border.color: editIndex >= 0 ? Colors.accent : "#33ffffff"

                    ColumnLayout {
                        id: formCol

                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: editIndex >= 0 ? "EDIT RULE" : "ADD RULE"
                            color: editIndex >= 0 ? Colors.accent : Colors.subtle
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"
                            font.letterSpacing: 1.5

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Rule input
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: 8
                                color: "#22ffffff"
                                border.width: 1
                                border.color: ruleInput.activeFocus ? Colors.accent : "#33ffffff"

                                TextInput {
                                    id: ruleInput

                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    selectionColor: Colors.accent
                                    clip: true
                                    onTextChanged: formRule = text
                                    Keys.onReturnPressed: filterInput.forceActiveFocus()
                                    Keys.onEscapePressed: rulesEditor.isOpen = false
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            // Filter input
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: 8
                                color: "#22ffffff"
                                border.width: 1
                                border.color: filterInput.activeFocus ? Colors.accent : "#33ffffff"

                                TextInput {
                                    id: filterInput

                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    selectionColor: Colors.accent
                                    clip: true
                                    onTextChanged: formFilter = text
                                    Keys.onReturnPressed: rulesEditor.applyFormRule()
                                    Keys.onEscapePressed: rulesEditor.isOpen = false
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            // Submit button
                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: 8
                                color: submitArea.containsMouse ? Colors.accent : "#33ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: editIndex >= 0 ? "\uf00c" : "\uf067"
                                    color: Colors.text
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: submitArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rulesEditor.applyFormRule()
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            // Cancel edit button
                            Rectangle {
                                visible: editIndex >= 0
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: 8
                                color: cancelArea.containsMouse ? "#44ffffff" : "#22ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: Colors.subtle
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: cancelArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rulesEditor.resetForm()
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

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

                // Empty state
                Item {
                    visible: rules.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf085"
                            color: Colors.overlay
                            font.pixelSize: 28
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No rules yet"
                            color: Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                    }

                }

                // Rules list
                ListView {
                    id: rulesList

                    visible: rules.length > 0
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 480)
                    model: rules
                    clip: true
                    spacing: 4

                    delegate: Rectangle {
                        width: rulesList.width
                        height: 44
                        radius: 8
                        color: editIndex === index ? "#33ffffff" : itemArea.containsMouse ? "#22ffffff" : "#11ffffff"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8

                            // Rule badge
                            Rectangle {
                                implicitWidth: ruleLabel.implicitWidth + 12
                                implicitHeight: 22
                                radius: 6
                                color: "#22ffffff"

                                Text {
                                    id: ruleLabel

                                    anchors.centerIn: parent
                                    text: modelData.rule
                                    color: Colors.accent
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                            }

                            // Filter
                            Text {
                                Layout.fillWidth: true
                                text: modelData.filter
                                color: Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                            }

                            // Edit button
                            Text {
                                text: "\uf044"
                                color: editBtnArea.containsMouse ? Colors.text : Colors.subtle
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"

                                MouseArea {
                                    id: editBtnArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rulesEditor.startEdit(index)
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            // Delete button
                            // Delete button - first click: confirm, second click: delete
                            Text {
                                text: deleteConfirmIndex === index ? "\uf00c" : "\uf00d"
                                color: deleteBtnArea.containsMouse ? (deleteConfirmIndex === index ? Colors.red : Colors.red) : (deleteConfirmIndex === index ? Colors.red : Colors.subtle)
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"

                                MouseArea {
                                    id: deleteBtnArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (deleteConfirmIndex === index) {
                                            rulesEditor.deleteRule(index);
                                            deleteConfirmIndex = -1;
                                        } else {
                                            deleteConfirmIndex = index;
                                        }
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            // Cancel delete confirmation
                            Text {
                                visible: deleteConfirmIndex === index
                                text: "\uf00d"
                                color: cancelDeleteArea.containsMouse ? Colors.subtle : Colors.overlay
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"

                                MouseArea {
                                    id: cancelDeleteArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: deleteConfirmIndex = -1
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                        }

                        MouseArea {
                            id: itemArea

                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            onDoubleClicked: rulesEditor.startEdit(index)
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

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    // Load rules
    Process {
        id: listProc

        command: ["python3", homePath + "/.config/hypr/quickshell/modules/ruleseditor/list_rules.py"]
        running: false
        onRunningChanged: {
            if (!running) {
                var raw = listProc.stdout.buf;
                listProc.stdout.buf = "";
                var result = [];
                var lines = raw.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line === "")
                        continue;

                    var parts = line.split("\t");
                    if (parts.length < 2)
                        continue;

                    result.push({
                        "rule": parts[0].trim(),
                        "filter": parts[1].trim()
                    });
                }
                rules = result;
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

    // Save rules
    Process {
        id: saveProc

        running: false
        onRunningChanged: {
            if (!running)
                reloadProc.running = true;

        }
    }

    // Reload Hyprland after save
    Process {
        id: reloadProc

        command: ["hyprctl", "reload"]
        running: false
    }

}
