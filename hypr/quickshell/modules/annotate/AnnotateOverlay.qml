import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Screenshot annotation overlay.
// Opened by ScreenshotTool after a capture finishes. Lets the user draw
// rectangles, lines, text labels, or pixelate a region before committing
// the result via Save (overwrite + clipboard) or Copy (clipboard only).
PanelWindow {
    id: root

    // --- Public API ---
    // Call open(path) after a screenshot has been written to disk.
    function open(path) {
        imagePath = "";
        // Force the Image source to reload even if the same path is reused
        // (e.g. consecutive captures before the user saves/cancels).
        shapes = [];
        redoStack = [];
        activeTool = "rect";
        imagePath = "file://" + path;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        shapes = [];
        redoStack = [];
        imagePath = "";
    }

    // --- State ---
    property bool isOpen: false
    property bool initialized: false
    property string imagePath: ""
    property string sourceFile: imagePath.replace("file://", "")
    property string activeTool: "rect" // rect | line | text | pixelate
    readonly property var toolColors: ["#e74c3c", "#f1c40f", "#2ecc71", "#3498db", "#ffffff"]
    property string drawColor: toolColors[0]
    property int strokeWidth: 3
    property var shapes: []
    property var redoStack: []
    property bool isDrawing: false
    property real curX: 0
    property real curY: 0
    property real startX: 0
    property real startY: 0
    property bool textPromptOpen: false
    property real textPromptX: 0
    property real textPromptY: 0

    visible: initialized && isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onIsOpenChanged: initialized = true

    // ─────────────────────────────────────────────
    // IMAGE + CANVAS STAGE
    // ─────────────────────────────────────────────
    Item {
        id: stage

        anchors.centerIn: parent
        width: shotImage.implicitWidth > 0 ? shotImage.implicitWidth : 1
        height: shotImage.implicitHeight > 0 ? shotImage.implicitHeight : 1
        scale: Math.min(1, Math.min((parent.width - 80) / Math.max(1, width), (parent.height - 160) / Math.max(1, height)))

        Image {
            id: shotImage

            anchors.fill: parent
            source: root.imagePath
            fillMode: Image.PreserveAspectFit
            asynchronous: false
            cache: false
        }

        Canvas {
            id: canvas

            anchors.fill: parent
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Immediate
            property bool forFlatten: false

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                for (var i = 0; i < root.shapes.length; i++) {
                    drawShape(ctx, root.shapes[i]);
                }
                if (!forFlatten && root.isDrawing && (root.activeTool === "rect" || root.activeTool === "line" || root.activeTool === "pixelate")) {
                    drawShape(ctx, {
                        "type": root.activeTool,
                        "x1": root.startX,
                        "y1": root.startY,
                        "x2": root.curX,
                        "y2": root.curY,
                        "color": root.drawColor,
                        "width": root.strokeWidth,
                        "preview": true
                    });
                }
            }

            function drawShape(ctx, s) {
                if (s.type === "rect") {
                    ctx.strokeStyle = s.color;
                    ctx.lineWidth = s.width;
                    ctx.strokeRect(Math.min(s.x1, s.x2), Math.min(s.y1, s.y2), Math.abs(s.x2 - s.x1), Math.abs(s.y2 - s.y1));
                } else if (s.type === "line") {
                    ctx.strokeStyle = s.color;
                    ctx.lineWidth = s.width;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(s.x1, s.y1);
                    ctx.lineTo(s.x2, s.y2);
                    ctx.stroke();
                } else if (s.type === "text") {
                    ctx.fillStyle = s.color;
                    ctx.font = "bold " + s.size + "px sans-serif";
                    ctx.textBaseline = "top";
                    ctx.fillText(s.text, s.x1, s.y1);
                } else if (s.type === "pixelate") {
                    // The real pixelation is applied by pixelate.py on the
                    // saved PNG after grabToImage finishes (see commit()).
                    // Skip drawing anything here when flattening for output,
                    // so no placeholder box leaks into the saved file.
                    if (forFlatten)
                        return;

                    ctx.save();
                    ctx.strokeStyle = s.color;
                    ctx.lineWidth = 1;
                    ctx.setLineDash([4, 4]);
                    ctx.strokeRect(Math.min(s.x1, s.x2), Math.min(s.y1, s.y2), Math.abs(s.x2 - s.x1), Math.abs(s.y2 - s.y1));
                    ctx.restore();
                }
            }

        }

        MouseArea {
            id: drawArea

            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            enabled: !root.textPromptOpen
            onPressed: (mouse) => {
                if (root.activeTool === "text") {
                    root.textPromptX = mouse.x;
                    root.textPromptY = mouse.y;
                    root.textPromptOpen = true;
                    return;
                }
                root.isDrawing = true;
                root.startX = mouse.x;
                root.startY = mouse.y;
                root.curX = mouse.x;
                root.curY = mouse.y;
            }
            onPositionChanged: (mouse) => {
                if (!root.isDrawing)
                    return;

                root.curX = mouse.x;
                root.curY = mouse.y;
                canvas.requestPaint();
            }
            onReleased: (mouse) => {
                if (!root.isDrawing)
                    return;

                root.isDrawing = false;
                var dx = Math.abs(mouse.x - root.startX);
                var dy = Math.abs(mouse.y - root.startY);
                if (dx < 3 && dy < 3) {
                    canvas.requestPaint();
                    return;
                }
                var shape = {
                    "type": root.activeTool,
                    "x1": root.startX,
                    "y1": root.startY,
                    "x2": mouse.x,
                    "y2": mouse.y,
                    "color": root.drawColor,
                    "width": root.strokeWidth
                };
                root.shapes = root.shapes.concat([shape]);
                root.redoStack = [];
                canvas.requestPaint();
            }
        }

        // Inline text input prompt, appears where the user clicked
        Rectangle {
            visible: root.textPromptOpen
            x: Math.min(root.textPromptX, stage.width - width)
            y: Math.min(root.textPromptY, stage.height - height)
            width: Math.max(140, textInput.implicitWidth + 16)
            height: 32
            radius: 6
            color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.85)
            border.width: 1
            border.color: root.drawColor
            z: 30

            TextInput {
                id: textInput

                anchors.fill: parent
                anchors.margins: 6
                color: root.drawColor
                font.pixelSize: 16
                font.bold: true
                focus: root.textPromptOpen

                Keys.onReturnPressed: commitText()
                Keys.onEnterPressed: commitText()
                Keys.onEscapePressed: {
                    root.textPromptOpen = false;
                    text = "";
                }

                function commitText() {
                    if (text.length > 0) {
                        var shape = {
                            "type": "text",
                            "x1": root.textPromptX,
                            "y1": root.textPromptY,
                            "text": text,
                            "color": root.drawColor,
                            "size": 18
                        };
                        root.shapes = root.shapes.concat([shape]);
                        root.redoStack = [];
                        canvas.requestPaint();
                    }
                    text = "";
                    root.textPromptOpen = false;
                }

            }

        }

    }

    // Decorative frame, kept as a sibling of `stage` (not a child) so it
    // is never included when `stage` is grabbed for the final output.
    Rectangle {
        x: stage.x - 2
        y: stage.y - 2
        width: stage.width * stage.scale + 4
        height: stage.height * stage.scale + 4
        color: "transparent"
        border.width: 2
        border.color: "#33ffffff"
        z: -1
    }

    onShapesChanged: canvas.requestPaint()

    // ─────────────────────────────────────────────
    // TOOLBAR
    // ─────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 32
        width: toolbarRow.implicitWidth + 24
        height: 56
        radius: 10
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.85)
        border.width: 1
        border.color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.13)

        RowLayout {
            id: toolbarRow

            anchors.centerIn: parent
            spacing: 10

            // Tool buttons
            Repeater {
                model: [{
                    "tool": "rect",
                    "icon": "\uf096"
                }, {
                    "tool": "line",
                    "icon": "\uf07e"
                }, {
                    "tool": "text",
                    "icon": "\uf031"
                }, {
                    "tool": "pixelate",
                    "icon": "\uf00a"
                }]

                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: root.activeTool === modelData.tool ? Colors.accent : (toolHover.containsMouse ? "#33ffffff" : "#1affffff")

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.activeTool === modelData.tool ? Colors.base : Colors.text
                    }

                    MouseArea {
                        id: toolHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTool = modelData.tool
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 28
                color: "#22ffffff"
            }

            // Color swatches
            Repeater {
                model: root.toolColors

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: modelData
                    border.width: root.drawColor === modelData ? 2 : 0
                    border.color: Colors.text

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.drawColor = modelData
                    }

                }

            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 28
                color: "#22ffffff"
            }

            // Undo
            Rectangle {
                width: 38
                height: 38
                radius: 12
                color: undoHover.containsMouse ? "#33ffffff" : "#1affffff"
                opacity: root.shapes.length > 0 ? 1 : 0.35

                Text {
                    anchors.centerIn: parent
                    text: "\uf0e2"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colors.text
                }

                MouseArea {
                    id: undoHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.shapes.length > 0
                    onClicked: {
                        var s = root.shapes.slice();
                        var last = s.pop();
                        root.shapes = s;
                        root.redoStack = root.redoStack.concat([last]);
                    }
                }

            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 28
                color: "#22ffffff"
            }

            // Cancel
            Rectangle {
                width: 80
                height: 38
                radius: 14
                color: cancelHover.containsMouse ? Colors.red : "#22ffffff"

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Colors.text
                }

                MouseArea {
                    id: cancelHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        cleanupTempProc.running = true;
                        root.close();
                    }
                }

            }

            // Copy
            Rectangle {
                width: 80
                height: 38
                radius: 14
                color: copyHover.containsMouse ? "#33ffffff" : "#1affffff"

                Text {
                    anchors.centerIn: parent
                    text: "Copy"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Colors.text
                }

                MouseArea {
                    id: copyHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.commit(false)
                }

            }

            // Save
            Rectangle {
                width: 90
                height: 38
                radius: 14
                color: saveHover.containsMouse ? Colors.accent : Qt.darker(Colors.accent, 1.15)

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    color: Colors.base
                }

                MouseArea {
                    id: saveHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.commit(true)
                }

            }

        }

    }

    // ─────────────────────────────────────────────
    // COMMIT (grab the stage as a flat image, save/copy)
    // ─────────────────────────────────────────────
    property bool pendingToFile: true

    function commit(toFile) {
        pendingToFile = toFile;
        // Repaint without the dashed preview shape or pixelate placeholders,
        // then grab the whole stage (Image + Canvas overlay) as a single
        // flattened image. grabToImage natively rasterizes child items
        // together, which sidesteps Canvas.drawImage()'s unreliable
        // handling of Image items as a source.
        canvas.forFlatten = true;
        canvas.requestPaint();
        stage.grabToImage(function(result) {
            canvas.forFlatten = false;
            canvas.requestPaint();

            var ok = result.saveToFile(root.sourceFile);
            if (!ok) {
                notifyFailProc.running = true;
                return;
            }

            // Convert each pixelate shape's coordinates from the on-screen
            // stage size to the original image's pixel size, then run them
            // through pixelate.py on the just-saved file.
            var scaleX = shotImage.implicitWidth / Math.max(1, stage.width);
            var scaleY = shotImage.implicitHeight / Math.max(1, stage.height);
            var regions = [];
            for (var i = 0; i < root.shapes.length; i++) {
                var s = root.shapes[i];
                if (s.type !== "pixelate")
                    continue;

                var rx = Math.min(s.x1, s.x2) * scaleX;
                var ry = Math.min(s.y1, s.y2) * scaleY;
                var rw = Math.abs(s.x2 - s.x1) * scaleX;
                var rh = Math.abs(s.y2 - s.y1) * scaleY;
                regions.push(rx.toFixed(0) + "," + ry.toFixed(0) + "," + rw.toFixed(0) + "," + rh.toFixed(0));
            }

            if (regions.length > 0) {
                pixelateProc.command = ["python3", root.pixelateScriptPath, root.sourceFile].concat(regions);
                pixelateProc.runThenFinish = true;
                pixelateProc.running = true;
            } else {
                root.finishCommit();
            }
        }, Qt.size(shotImage.implicitWidth, shotImage.implicitHeight));
    }

    readonly property string pixelateScriptPath: Quickshell.env("HOME") + "/.config/hypr/quickshell/modules/annotate/pixelate.py"

    function finishCommit() {
        if (root.pendingToFile) {
            postSaveProc.command = ["bash", "-c", "wl-copy < '" + root.sourceFile + "' && notify-send 'Screenshot' 'Saved & copied to clipboard' -i '" + root.sourceFile + "' -t 3000"];
        } else {
            postSaveProc.command = ["bash", "-c", "wl-copy < '" + root.sourceFile + "' && notify-send 'Screenshot' 'Copied to clipboard' -t 3000 && rm -f '" + root.sourceFile + "'"];
        }
        postSaveProc.running = true;
    }

    Process {
        id: pixelateProc
        running: false
        property bool runThenFinish: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                notifyFailProc.running = true;
                return;
            }
            if (runThenFinish) {
                runThenFinish = false;
                root.finishCommit();
            }
        }
    }

    Process {
        id: postSaveProc
        running: false
        command: []
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.close();
            } else {
                notifyFailProc.running = true;
            }
        }
    }

    Process {
        id: notifyFailProc
        running: false
        command: ["notify-send", "Screenshot", "Failed to save annotated image", "-t", "3000"]
    }

    Process {
        id: cleanupTempProc

        running: false
        command: ["rm", "-f", root.sourceFile]
    }

    // ─────────────────────────────────────────────
    // KEYBOARD
    // ─────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen && !root.textPromptOpen
        onActivated: {
            cleanupTempProc.running = true;
            root.close();
        }
    }

    Shortcut {
        sequence: "Ctrl+Z"
        enabled: root.isOpen && !root.textPromptOpen
        onActivated: {
            if (root.shapes.length > 0) {
                var s = root.shapes.slice();
                var last = s.pop();
                root.shapes = s;
                root.redoStack = root.redoStack.concat([last]);
            }
        }
    }

}
