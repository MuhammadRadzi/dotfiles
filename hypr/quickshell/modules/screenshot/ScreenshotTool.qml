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

    function toggle() {
        isOpen = !isOpen;
    }

    function resetRegion() {
        hasSelection = false;
        isSelecting = false;
        startX = 0; startY = 0;
        endX = 0; endY = 0;
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
        captureProc.command = ["bash", scriptPath, "geometry", geometryString];
        captureProc.running = true;
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

    onIsOpenChanged: {
        initialized = true;
    }

    onIsSelectingRegionChanged: {
        initialized = true;
    }

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
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                // Mode buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Region",     icon: "\uf065", mode: "region" },
                            { label: "Fullscreen", icon: "\uf0c8", mode: "full"   },
                            { label: "Window",     icon: "\uf2d0", mode: "window" }
                        ]

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
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: modeArea.containsMouse ? Colors.text : Colors.subtle
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: modeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.capture(modelData.mode)
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // ─────────────────────────────────────────────
    // REGION SELECTION OVERLAY
    // ─────────────────────────────────────────────
    Item {
        id: regionOverlay
        anchors.fill: parent
        visible: isSelectingRegion
        z: 10

        // Dim when no selection yet
        Rectangle {
            anchors.fill: parent
            color: "#55000000"
            opacity: (!isSelecting && !hasSelection) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "Drag to select a region"
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
        }

        // Dim outside selection
        Item {
            anchors.fill: parent
            opacity: (isSelecting || hasSelection) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Rectangle { x: 0;           y: 0;         width: parent.width;              height: selY;                        color: "#55000000" }
            Rectangle { x: 0;           y: selY+selH; width: parent.width;              height: parent.height - selY - selH; color: "#55000000" }
            Rectangle { x: 0;           y: selY;      width: selX;                      height: selH;                        color: "#55000000" }
            Rectangle { x: selX + selW; y: selY;      width: parent.width - selX - selW; height: selH;                       color: "#55000000" }
        }

        // Selection rect
        Rectangle {
            visible: isSelecting || hasSelection
            x: selX; y: selY; width: selW; height: selH
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.08)
            border.color: Colors.accent
            border.width: 2
            z: 5
        }

        // Corner handles
        component Handle: Rectangle {
            width: 10; height: 10; radius: 5
            color: Colors.text
            border.color: Colors.accent
            border.width: 2
            visible: hasSelection && !isSelecting
            z: 10
        }
        Handle { x: selX - 5;        y: selY - 5        }
        Handle { x: selX + selW - 5; y: selY - 5        }
        Handle { x: selX - 5;        y: selY + selH - 5 }
        Handle { x: selX + selW - 5; y: selY + selH - 5 }

        // Size label while dragging
        Rectangle {
            visible: isSelecting && selW > 60 && selH > 30
            x: selX + selW / 2 - width / 2
            y: selY + selH / 2 - height / 2
            width: sizeLabel.implicitWidth + 16
            height: 24
            radius: 6
            color: "#cc000000"
            z: 6

            Text {
                id: sizeLabel
                anchors.centerIn: parent
                text: Math.round(selW) + " × " + Math.round(selH)
                color: Colors.subtle
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }
        }

        // Capture toolbar
        Rectangle {
            id: selToolbar
            visible: hasSelection && !isSelecting
            z: 20

            width: toolbarRow.implicitWidth + 12
            height: 48
            radius: 24
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"

            property bool fitsBelow: (selY + selH + 64) <= parent.height
            x: Math.max(8, Math.min(parent.width - width - 8, selX + selW / 2 - width / 2))
            y: fitsBelow ? selY + selH + 12 : selY - height - 12

            Row {
                id: toolbarRow
                anchors.centerIn: parent
                spacing: 10

                // Capture button
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: captureHover.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf030"
                        color: captureHover.containsMouse ? Colors.base : Colors.text
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: captureHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.captureRegion()
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Cancel button
                Rectangle {
                    width: 36; height: 36; radius: 18
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

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Mouse interaction
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: 15

            function getInteractionMode(mx, my) {
                if (!hasSelection) return 1;
                var margin = 14;
                var onL = Math.abs(mx - selX) <= margin;
                var onR = Math.abs(mx - (selX + selW)) <= margin;
                var onT = Math.abs(my - selY) <= margin;
                var onB = Math.abs(my - (selY + selH)) <= margin;
                var inX = mx >= (selX - margin) && mx <= (selX + selW + margin);
                var inY = my >= (selY - margin) && my <= (selY + selH + margin);

                if (onT && onL) return 3;
                if (onT && onR) return 5;
                if (onB && onL) return 8;
                if (onB && onR) return 10;
                if (onT && inX) return 4;
                if (onB && inX) return 9;
                if (onL && inY) return 6;
                if (onR && inY) return 7;
                if (mx >= selX && mx <= selX + selW && my >= selY && my <= selY + selH) return 2;
                return 1;
            }

            onPositionChanged: (mouse) => {
                if (!isSelecting) {
                    var m = getInteractionMode(mouse.x, mouse.y);
                    switch(m) {
                        case 2:       cursorShape = Qt.SizeAllCursor;    break;
                        case 3: case 10: cursorShape = Qt.SizeFDiagCursor; break;
                        case 5: case 8:  cursorShape = Qt.SizeBDiagCursor; break;
                        case 4: case 9:  cursorShape = Qt.SizeVerCursor;   break;
                        case 6: case 7:  cursorShape = Qt.SizeHorCursor;   break;
                        default: cursorShape = Qt.CrossCursor; break;
                    }
                    return;
                }

                var dx = mouse.x - anchorX;
                var dy = mouse.y - anchorY;
                var clamp = function(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); };

                if (interactionMode === 1) {
                    endX = clamp(mouse.x, 0, width);
                    endY = clamp(mouse.y, 0, height);
                } else if (interactionMode === 2) {
                    var nx = clamp(initX + dx, 0, width - initW);
                    var ny = clamp(initY + dy, 0, height - initH);
                    startX = nx; startY = ny;
                    endX = nx + initW; endY = ny + initH;
                } else {
                    var nx2 = initX, ny2 = initY, nw = initW, nh = initH;
                    if ([3, 6, 8].indexOf(interactionMode) !== -1) {
                        nx2 = clamp(initX + dx, 0, initX + initW - 10);
                        nw = initW + (initX - nx2);
                    }
                    if ([5, 7, 10].indexOf(interactionMode) !== -1) {
                        nw = clamp(initW + dx, 10, width - initX);
                    }
                    if ([3, 4, 5].indexOf(interactionMode) !== -1) {
                        ny2 = clamp(initY + dy, 0, initY + initH - 10);
                        nh = initH + (initY - ny2);
                    }
                    if ([8, 9, 10].indexOf(interactionMode) !== -1) {
                        nh = clamp(initH + dy, 10, height - initY);
                    }
                    startX = nx2; startY = ny2;
                    endX = nx2 + nw; endY = ny2 + nh;
                }
            }

            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.isSelectingRegion = false;
                    root.isOpen = true;
                    return;
                }
                interactionMode = getInteractionMode(mouse.x, mouse.y);
                isSelecting = true;
                anchorX = mouse.x; anchorY = mouse.y;
                initX = selX; initY = selY;
                initW = selW; initH = selH;

                if (interactionMode === 1) {
                    startX = mouse.x; startY = mouse.y;
                    endX = mouse.x; endY = mouse.y;
                    hasSelection = false;
                }
            }

            onReleased: {
                isSelecting = false;
                if (selW > 10 && selH > 10) {
                    hasSelection = true;
                } else {
                    hasSelection = false;
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // PROCESSES
    // ─────────────────────────────────────────────
    Process {
        id: captureProc
        running: false

        stdout: SplitParser {
            property string buf: ""
            splitMarker: ""
            onRead: (data) => { buf += data; }
        }

        onRunningChanged: {
            if (!running) {
                captureProc.stdout.buf = "";
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
            if (isSelectingRegion && hasSelection) {
                captureRegion();
            }
        }
    }
}