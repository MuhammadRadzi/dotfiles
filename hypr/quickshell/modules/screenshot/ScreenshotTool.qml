import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    // --- State ---
    property bool isOpen: false
    property bool initialized: false
    property bool isSelectingRegion: false
    property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/quickshell/modules/screenshot/take_screenshot.sh"
    property bool isRecording: false
    property string activeTab: "screenshot"
    property string recordOutputPath: Quickshell.env("HOME") + "/Videos/Recordings"
    // --- Region selection geometry ---
    property real startX: 0
    property real startY: 0
    property real endX: 0
    property real endY: 0
    property bool hasSelection: false
    property bool isSelecting: false
    property real selX: Math.min(startX, endX)
    property real selY: Math.min(startY, endY)
    property real selW: Math.abs(endX - startX)
    property real selH: Math.abs(endY - startY)
    property string geometryString: Math.round(selX) + "," + Math.round(selY) + " " + Math.round(selW) + "x" + Math.round(selH)
    // --- Resize handle interaction ---
    property int interactionMode: 0
    property real anchorX: 0
    property real anchorY: 0
    property real initX: 0
    property real initY: 0
    property real initW: 0
    property real initH: 0
    // --- Record pending state ---
    property bool pendingRecord: false
    property string pendingRecordFile: ""
    property string recordStateFile: Quickshell.env("HOME") + "/.cache/hypr/.recording_state"
    property int recordSeconds: 0
    property int recordPid: 0

    // --- Signal ---
    signal recordingStarted()
    signal recordingStopped()

    Component.onCompleted: recoverProc.running = true

    Process {
        id: recoverProc
        running: false
        command: ["bash", "-c", "cat '" + root.recordStateFile + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n").filter(l => l.length > 0);
                if (lines.length < 2) {
                    return;
                }
                var startedAt = parseInt(lines[0], 10);
                var pid = parseInt(lines[1], 10);
                if (isNaN(startedAt) || isNaN(pid)) {
                    cleanupStateProc.running = true;
                    return;
                }
                checkPidProc.targetPid = pid;
                checkPidProc.startedAt = startedAt;
                checkPidProc.command = ["bash", "-c", "kill -0 " + pid + " 2>/dev/null && echo ALIVE"];
                checkPidProc.running = true;
            }
        }
    }

    Process {
        id: checkPidProc
        property int targetPid: 0
        property int startedAt: 0
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "ALIVE") {
                    root.recordPid = checkPidProc.targetPid;
                    root.isRecording = true;
                    root.recordSeconds = Math.max(0, Math.floor(Date.now() / 1000) - checkPidProc.startedAt);
                    root.recordingStarted();
                    watchPidTimer.start();
                } else {
                    // Stale state file; the process is gone
                    cleanupStateProc.running = true;
                }
            }
        }
    }

    Process {
        id: cleanupStateProc
        running: false
        command: ["rm", "-f", root.recordStateFile]
    }

    function toggle() {
        isOpen = !isOpen;
    }

    function resetRegion() {
        hasSelection = false;
        isSelecting = false;
        startX = 0;
        startY = 0;
        endX = 0;
        endY = 0;
    }

    function openRegionSelect() {
        isOpen = false;
        resetRegion();
        isSelectingRegion = true;
    }

    function capture(mode) {
        if (mode === "region") {
            openRegionSelect();
        } else {
            isOpen = false;
            delayTimer.mode = mode;
            delayTimer.start();
        }
    }

    function captureRegion() {
        isSelectingRegion = false;
        if (pendingRecord) {
            pendingRecord = false;
            startRecordProc.outFile = pendingRecordFile;
            startRecordProc.command = ["bash", "-c", "setsid wf-recorder -g '" + geometryString + "' -f '" + pendingRecordFile + "' >/dev/null 2>&1 < /dev/null & echo $!"];
            startRecordProc.running = true;
        } else {
            captureDelayTimer.geometryStr = geometryString
            captureDelayTimer.start()
        }
    }

    function startRecording(mode) {
        let ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        let outFile = root.recordOutputPath + "/rec_" + ts + ".mp4";
        ensureDirProc.running = true;
        if (mode === "record-region") {
            openRegionSelect();
            pendingRecordFile = outFile;
            pendingRecord = true;
        } else {
            startRecordProc.outFile = outFile;
            startRecordProc.command = ["bash", "-c", "setsid wf-recorder -f '" + outFile + "' >/dev/null 2>&1 < /dev/null & echo $!"];
            startRecordProc.running = true;
            root.isOpen = false;
        }
    }

    function stopRecording() {
        if (root.recordPid > 0) {
            stopRecordProc.command = ["bash", "-c", "kill -INT " + root.recordPid];
            stopRecordProc.running = true;
        }
    }

    // --- Window setup ---
    visible: initialized && (isOpen || isSelectingRegion || overlayBg.opacity > 0)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    WlrLayershell.keyboardFocus: (isOpen || isSelectingRegion) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onIsOpenChanged: initialized = true
    onIsSelectingRegionChanged: initialized = true

    // ─────────────────────────────────────────────
    // MODE PANEL
    // ─────────────────────────────────────────────
    Rectangle {
        id: overlayBg

        anchors.fill: parent
        color: "#55000000"
        opacity: isOpen ? 1 : 0
        visible: !isSelectingRegion

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            visible: isOpen
            onClicked: root.isOpen = false
        }

        Rectangle {
            id: panelCard

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: 340
            height: contentCol.implicitHeight + 32
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
                id: contentCol

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                // Tab switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [{
                            "label": "Screenshot",
                            "tab": "screenshot"
                        }, {
                            "label": "Record",
                            "tab": "record"
                        }]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: root.activeTab === modelData.tab ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2) : "transparent"
                            border.color: root.activeTab === modelData.tab ? Colors.accent : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: root.activeTab === modelData.tab ? Colors.accent : Colors.subtle

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = modelData.tab
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                }

                // Screenshot modes
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.activeTab === "screenshot"

                    Repeater {
                        model: [{
                            "label": "Region",
                            "icon": "\uf065",
                            "mode": "region"
                        }, {
                            "label": "Fullscreen",
                            "icon": "\uf0c8",
                            "mode": "full"
                        }, {
                            "label": "Window",
                            "icon": "\uf2d0",
                            "mode": "window"
                        }]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            radius: 10
                            color: modeArea.containsMouse ? "#33ffffff" : "#1affffff"
                            border.width: 1
                            border.color: modeArea.containsMouse ? Colors.accent : "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: modeArea.containsMouse ? Colors.accent : Colors.text
                                    font.pixelSize: 22
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: modeArea.containsMouse ? Colors.text : Colors.subtle
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: modeArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.capture(modelData.mode)
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                }

                // Record modes
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.activeTab === "record"

                    Repeater {
                        model: [{
                            "label": "Region",
                            "icon": "\uf065",
                            "mode": "record-region"
                        }, {
                            "label": "Fullscreen",
                            "icon": "\uf0c8",
                            "mode": "record-full"
                        }]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            radius: 10
                            color: recArea.containsMouse ? "#33FB4934" : "#1affffff"
                            border.width: 1
                            border.color: recArea.containsMouse ? "#FB4934" : "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: recArea.containsMouse ? "#FB4934" : Colors.text
                                    font.pixelSize: 22
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: recArea.containsMouse ? Colors.text : Colors.subtle
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: recArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startRecording(modelData.mode)
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                            Behavior on border.color {
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
                duration: 200
            }

        }

    }

    // ─────────────────────────────────────────────
    // REGION SELECTION OVERLAY
    // ─────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: isSelectingRegion

        // Dim outside selection
        Item {
            anchors.fill: parent
            visible: hasSelection

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: selY
                color: "#88000000"
            }

            Rectangle {
                x: 0
                y: selY
                width: selX
                height: selH
                color: "#88000000"
            }

            Rectangle {
                x: selX + selW
                y: selY
                width: parent.width - (selX + selW)
                height: selH
                color: "#88000000"
            }

            Rectangle {
                x: 0
                y: selY + selH
                width: parent.width
                height: parent.height - (selY + selH)
                color: "#88000000"
            }

        }

        // Selection rectangle
        Rectangle {
            x: selX
            y: selY
            width: selW
            height: selH
            color: "transparent"
            border.color: Colors.accent
            border.width: 2
            visible: hasSelection || isSelecting

            // Resize handles
            Repeater {
                model: [{
                    "hx": 0,
                    "hy": 0
                }, {
                    "hx": 0.5,
                    "hy": 0
                }, {
                    "hx": 1,
                    "hy": 0
                }, {
                    "hx": 0,
                    "hy": 0.5
                }, {
                    "hx": 1,
                    "hy": 0.5
                }, {
                    "hx": 0,
                    "hy": 1
                }, {
                    "hx": 0.5,
                    "hy": 1
                }, {
                    "hx": 1,
                    "hy": 1
                }]

                delegate: Rectangle {
                    x: modelData.hx * (selW - 8)
                    y: modelData.hy * (selH - 8)
                    width: 8
                    height: 8
                    radius: 2
                    color: Colors.accent
                }

            }

            // Size label
            Rectangle {
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: sizeText.implicitWidth + 12
                height: 22
                radius: 6
                color: "#cc000000"
                visible: hasSelection

                Text {
                    id: sizeText

                    anchors.centerIn: parent
                    text: Math.round(selW) + " × " + Math.round(selH)
                    color: Colors.text
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                }

            }

        }

        // Capture toolbar
        Rectangle {
            z: 20
            visible: hasSelection
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 40
            width: toolRow.implicitWidth + 10
            height: 48
            radius: 24
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"

            Row {
                id: toolRow

                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 80
                    height: 35
                    radius: 16
                    color: captureHover.containsMouse ? Colors.accent : "#33ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "Capture"
                        color: Colors.text
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: captureHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: captureRegion()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: cancelHover.containsMouse ? Colors.red : "#22ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Colors.text
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: cancelHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isSelectingRegion = false;
                            root.isOpen = true;
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

        // Mouse interaction
        MouseArea {
            function getInteractionMode(mx, my) {
                if (!hasSelection)
                    return 1;

                var margin = 14;
                var onL = Math.abs(mx - selX) <= margin;
                var onR = Math.abs(mx - (selX + selW)) <= margin;
                var onT = Math.abs(my - selY) <= margin;
                var onB = Math.abs(my - (selY + selH)) <= margin;
                var inX = mx >= (selX - margin) && mx <= (selX + selW + margin);
                var inY = my >= (selY - margin) && my <= (selY + selH + margin);
                if (onT && onL)
                    return 3;

                if (onT && onR)
                    return 5;

                if (onB && onL)
                    return 8;

                if (onB && onR)
                    return 10;

                if (onT && inX)
                    return 4;

                if (onB && inX)
                    return 9;

                if (onL && inY)
                    return 6;

                if (onR && inY)
                    return 7;

                if (mx >= selX && mx <= selX + selW && my >= selY && my <= selY + selH)
                    return 2;

                return 1;
            }

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: 15
            onPositionChanged: (mouse) => {
                if (!isSelecting) {
                    var m = getInteractionMode(mouse.x, mouse.y);
                    switch (m) {
                    case 2:
                        cursorShape = Qt.SizeAllCursor;
                        break;
                    case 3:
                    case 10:
                        cursorShape = Qt.SizeFDiagCursor;
                        break;
                    case 5:
                    case 8:
                        cursorShape = Qt.SizeBDiagCursor;
                        break;
                    case 4:
                    case 9:
                        cursorShape = Qt.SizeVerCursor;
                        break;
                    case 6:
                    case 7:
                        cursorShape = Qt.SizeHorCursor;
                        break;
                    default:
                        cursorShape = Qt.CrossCursor;
                        break;
                    }
                    return ;
                }
                var dx = mouse.x - anchorX;
                var dy = mouse.y - anchorY;
                var clamp = function clamp(v, lo, hi) {
                    return Math.max(lo, Math.min(hi, v));
                };
                if (interactionMode === 1) {
                    endX = clamp(mouse.x, 0, width);
                    endY = clamp(mouse.y, 0, height);
                } else if (interactionMode === 2) {
                    var nx = clamp(initX + dx, 0, width - initW);
                    var ny = clamp(initY + dy, 0, height - initH);
                    startX = nx;
                    startY = ny;
                    endX = nx + initW;
                    endY = ny + initH;
                } else {
                    var nx2 = initX, ny2 = initY, nw = initW, nh = initH;
                    if ([3, 6, 8].indexOf(interactionMode) !== -1) {
                        nx2 = clamp(initX + dx, 0, initX + initW - 10);
                        nw = initW + (initX - nx2);
                    }
                    if ([5, 7, 10].indexOf(interactionMode) !== -1)
                        nw = clamp(initW + dx, 10, width - initX);

                    if ([3, 4, 5].indexOf(interactionMode) !== -1) {
                        ny2 = clamp(initY + dy, 0, initY + initH - 10);
                        nh = initH + (initY - ny2);
                    }
                    if ([8, 9, 10].indexOf(interactionMode) !== -1)
                        nh = clamp(initH + dy, 10, height - initY);

                    startX = nx2;
                    startY = ny2;
                    endX = nx2 + nw;
                    endY = ny2 + nh;
                }
            }
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.isSelectingRegion = false;
                    root.isOpen = true;
                    return ;
                }
                interactionMode = getInteractionMode(mouse.x, mouse.y);
                isSelecting = true;
                anchorX = mouse.x;
                anchorY = mouse.y;
                initX = selX;
                initY = selY;
                initW = selW;
                initH = selH;
                if (interactionMode === 1) {
                    startX = mouse.x;
                    startY = mouse.y;
                    endX = mouse.x;
                    endY = mouse.y;
                    hasSelection = false;
                }
            }
            onReleased: {
                isSelecting = false;
                if (selW > 10 && selH > 10)
                    hasSelection = true;
                else
                    hasSelection = false;
            }
        }

    }

    // ─────────────────────────────────────────────
    // PROCESSES
    // ─────────────────────────────────────────────
    Process {
        id: captureProc

        running: false
        onRunningChanged: {
            if (!running)
                captureProc.stdout.buf = "";

        }

        stdout: SplitParser {
            property string buf: ""

            splitMarker: ""
            onRead: (data) => {
                buf += data;
            }
        }

    }

    Timer {
        id: delayTimer

        property string mode: ""

        interval: 300
        repeat: false
        onTriggered: {
            captureProc.command = ["bash", scriptPath, mode, ""];
            captureProc.running = true;
        }
    }

    Timer {
        id: captureDelayTimer
        property string geometryStr: ""
        interval: 400
        repeat: false
        onTriggered: {
            captureProc.command = ["bash", scriptPath, "geometry", geometryStr]
            captureProc.running = true
        }
    }

    Process {
        id: startRecordProc

        property string outFile: ""
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                var pid = parseInt(text.trim(), 10);
                if (isNaN(pid) || pid <= 0) {
                    return;
                }
                root.recordPid = pid;
                root.isRecording = true;
                root.recordSeconds = 0;
                root.recordingStarted();
                notifyStartProc.running = true;
                writeStateProc.command = ["bash", "-c", "mkdir -p '" + Quickshell.env("HOME") + "/.cache/hypr' && printf '%s\\n%s\\n' \"$(date +%s)\" \"" + pid + "\" > '" + root.recordStateFile + "'"];
                writeStateProc.running = true;
                watchPidTimer.start();
            }
        }
    }

    Process {
        id: writeStateProc

        running: false
        command: []
    }

    // Polls whether the detached wf-recorder PID is still alive, since it is
    // no longer a direct Quickshell child and won't emit onRunningChanged.
    Timer {
        id: watchPidTimer

        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.recordPid <= 0) {
                stop();
                return;
            }
            watchPidProc.running = true;
        }
    }

    Process {
        id: watchPidProc

        running: false
        command: ["bash", "-c", "kill -0 " + root.recordPid + " 2>/dev/null && echo ALIVE"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ALIVE") {
                    watchPidTimer.stop();
                    root.recordPid = 0;
                    root.isRecording = false;
                    root.recordingStopped();
                    notifyStopProc.running = true;
                    cleanupStateProc.running = true;
                }
            }
        }
    }

    Process {
        id: ensureDirProc

        running: false
        command: ["bash", "-c", "mkdir -p " + root.recordOutputPath]
    }

    Process {
        id: stopRecordProc

        running: false
        command: []
    }

    Process {
        id: notifyStartProc

        running: false
        command: ["notify-send", "-i", "media-record", "-t", "3000", "Recording Started", "Screen recording is now active"]
    }

    Process {
        id: notifyStopProc

        running: false
        command: ["notify-send", "-i", "media-record-stop", "-t", "3000", "Recording Saved", "Saved to ~/Videos/Recordings"]
    }

    // ─────────────────────────────────────────────
    // KEYBOARD
    // ─────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (isSelectingRegion) {
                isSelectingRegion = false;
                isOpen = true;
            } else {
                isOpen = false;
            }
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (isSelectingRegion && hasSelection)
                captureRegion();

        }
    }

}