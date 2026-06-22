//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    QtObject {
        id: lockUI
        property bool failed: false
        property bool authenticating: false
        property string statusText: "locked"
    }

    Timer {
        id: pamTimer
        interval: 50
        onTriggered: pam.start()
    }

    PamContext {
        id: pam
        Component.onCompleted: pamTimer.start()
        onCompleted: (result) => {
            lockUI.authenticating = false
            if (result === PamResult.Success) {
                rootLock.locked = false
                Qt.quit()
            } else {
                lockUI.failed = true
                lockUI.statusText = "wrong password"
                pamTimer.start()
            }
        }
    }

    Process { id: suspendProc;  command: ["systemctl", "suspend"] }
    Process { id: rebootProc;   command: ["systemctl", "reboot"] }
    Process { id: poweroffProc; command: ["systemctl", "poweroff"] }

    WlSessionLock {
        id: rootLock
        locked: true

        WlSessionLockSurface {
            Item {
                id: screen
                anchors.fill: parent

                // --- Data ---
                property string wallpaperPath: ""
                property string currentUser: "user"
                property string faceIconPath: ""
                property string batPct: "100"
                property string batStatus: "Full"
                property bool   isDesktop: false
                property string kbLayout: "US"
                property string mpTrack: ""
                property string mpArtist: ""
                property string mpStatus: "Stopped"
                property string mpArtUrl: ""
                property int    mpPosition: 0
                property int    mpDuration: 0
                property bool   mpHasPlayer: mpStatus === "Playing" || mpStatus === "Paused"
                function mpFormatTime(secs) {
                    var m = Math.floor(secs / 60)
                    var s = secs % 60
                    return m + ":" + (s < 10 ? "0" + s : s)
                }

                // --- UI state ---
                property bool ready: false        // after intro fade
                property bool inputActive: false  // clock → auth transition
                property bool powerOpen: false

                Process {
                    command: ["bash", "-c", "cat ~/.config/hypr/.last_wallpaper 2>/dev/null"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let p = this.text.trim()
                            if (p) screen.wallpaperPath = "file://" + p
                        }
                    }
                    Component.onCompleted: running = true
                }

                Process {
                    command: ["bash", "-c",
                        "echo $(whoami);" +
                        "if [ -f ~/.face.icon ]; then readlink -f ~/.face.icon;" +
                        "elif [ -f ~/.face ]; then readlink -f ~/.face; else echo ''; fi"
                    ]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n")
                            if (lines[0]) screen.currentUser = lines[0]
                            if (lines[1] && lines[1].trim()) {
                                let p = lines[1].trim()
                                screen.faceIconPath = p.startsWith("file://") ? p : "file://" + p
                            }
                        }
                    }
                    Component.onCompleted: running = true
                }

                Process {
                    id: chassisCheck
                    command: ["bash", "-c", "ls /sys/class/power_supply/BAT* &>/dev/null && echo laptop || echo desktop"]
                    stdout: StdioCollector {
                        onStreamFinished: screen.isDesktop = this.text.trim() === "desktop"
                    }
                    Component.onCompleted: running = true
                }

                Process {
                    id: batProc
                    running: false
                    command: ["bash", "-c",
                        "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1;" +
                        "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"
                    ]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let l = this.text.trim().split("\n")
                            if (l[0]) screen.batPct = l[0]
                            if (l[1]) screen.batStatus = l[1]
                        }
                    }
                }
                Timer {
                    interval: 10000; repeat: true; triggeredOnStart: true
                    running: !screen.isDesktop
                    onTriggered: batProc.running = true
                }

                Process {
                    id: kbProc
                    running: false
                    command: ["bash", "-c",
                        "hyprctl devices -j | jq -r '[.keyboards[]|select(.main==true)|.active_keymap][0]'" +
                        " | cut -c1-2 | tr '[:lower:]' '[:upper:]'"
                    ]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let l = this.text.trim()
                            if (l && l !== "nu") screen.kbLayout = l
                        }
                    }
                }
                Timer {
                    interval: 3000; repeat: true; triggeredOnStart: true; running: true
                    onTriggered: kbProc.running = true
                }

                // Auto-hide input when idle & empty
                Timer {
                    interval: 15000; repeat: false
                    running: screen.inputActive && inputField.text.length === 0
                    onTriggered: screen.inputActive = false
                }

                // -----------------------------------------------
                // BACKGROUND
                // -----------------------------------------------

                Rectangle {
                    anchors.fill: parent
                    color: Colors.base
                }

                Image {
                    id: wallImg
                    anchors.fill: parent
                    source: screen.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    cache: false
                }

                MultiEffect {
                    anchors.fill: wallImg
                    source: wallImg
                    blurEnabled: true
                    blurMax: 48
                    blur: 1.0
                }

                // Dark overlay — slightly stronger so text is readable
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.45
                }

                // -----------------------------------------------
                // CLICK CATCHER
                // -----------------------------------------------

                MouseArea {
                    anchors.fill: parent
                    enabled: screen.ready
                    onClicked: {
                        if (screen.powerOpen) {
                            screen.powerOpen = false
                        } else if (!screen.inputActive) {
                            screen.inputActive = true
                        }
                        inputField.forceActiveFocus()
                    }

                // Key catcher — any keypress activates input
                Item {
                    anchors.fill: parent
                    focus: screen.ready && !screen.inputActive
                    Keys.onPressed: (event) => {
                        if (!screen.inputActive && !screen.powerOpen) {
                            screen.inputActive = true
                            inputField.forceActiveFocus()
                        }
                    }
                }
                }

                // -----------------------------------------------
                // CLOCK  (center, visible when !inputActive)
                // -----------------------------------------------

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    opacity: screen.ready && !screen.inputActive ? 1.0 : 0.0
                    scale:   screen.ready && !screen.inputActive ? 1.0 : 0.96

                    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    // Time
                    Text {
                        id: clockTime
                        Layout.alignment: Qt.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 128
                        font.weight: Font.Bold
                        color: Colors.text
                        font.letterSpacing: -4
                    }

                    // Date
                    Text {
                        id: clockDate
                        Layout.alignment: Qt.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        font.weight: Font.Normal
                        color: Colors.subtle
                        font.letterSpacing: 3
                        text: ""
                    }

                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: {
                            let d = new Date()
                            clockTime.text = Qt.formatDateTime(d, "HH:mm")
                            clockDate.text = Qt.formatDateTime(d, "dddd, d MMMM yyyy").toUpperCase()
                        }
                    }
                }

                // -----------------------------------------------
                // AUTH CARD  (center, visible when inputActive)
                // -----------------------------------------------

                Item {
                    anchors.centerIn: parent
                    width: 340
                    height: authCol.implicitHeight + 64
                    visible: true

                    opacity: screen.ready && screen.inputActive ? 1.0 : 0.0
                    scale:   screen.ready && screen.inputActive ? 1.0 : 0.97

                    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    // Frosted card background
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: Qt.rgba(
                            Qt.darker(Colors.base, 1.0).r,
                            Qt.darker(Colors.base, 1.0).g,
                            Qt.darker(Colors.base, 1.0).b,
                            0.55
                        )
                        border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.08)
                        border.width: 1
                    }

                    ColumnLayout {
                        id: authCol
                        anchors {
                            top: parent.top; left: parent.left; right: parent.right
                            margins: 32
                        }
                        spacing: 20

                        // Avatar + username
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            // Avatar circle
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                width: 72; height: 72

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Qt.rgba(0, 0, 0, 0.4)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰄽"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 30
                                        color: Colors.subtle
                                        visible: avatarImg.status !== Image.Ready
                                    }
                                }

                                Image {
                                    id: avatarImgMask
                                    anchors.fill: parent
                                    source: ""
                                    visible: false
                                    layer.enabled: true
                                }

                                Rectangle {
                                    id: avatarClipMask
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "black"
                                    visible: false
                                    layer.enabled: true
                                }

                                Image {
                                    id: avatarImg
                                    anchors.fill: parent
                                    source: screen.faceIconPath
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: false
                                    cache: false
                                }

                                MultiEffect {
                                    source: avatarImg
                                    anchors.fill: avatarImg
                                    maskEnabled: true
                                    maskSource: avatarClipMask
                                    visible: avatarImg.status === Image.Ready
                                }

                                // Ring — changes color on fail/auth
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "transparent"
                                    border.width: 2
                                    border.color: lockUI.failed
                                        ? "#FB4934"
                                        : lockUI.authenticating
                                            ? Colors.yellow
                                            : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.25)
                                    Behavior on border.color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Username
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: screen.currentUser
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: Colors.text
                                font.letterSpacing: 1
                            }
                        }

                        // Password input pill
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            // Hidden TextInput
                            TextInput {
                                id: inputField
                                anchors.fill: parent
                                opacity: 0
                                echoMode: TextInput.Password
                                enabled: screen.ready

                                Component.onCompleted: forceActiveFocus()
                                onActiveFocusChanged: {
                                    if (!activeFocus && screen.ready && !screen.powerOpen)
                                        forceActiveFocus()
                                }
                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Escape) {
                                        screen.inputActive = false
                                        text = ""
                                        dotsModel.clear()
                                        lockUI.failed = false
                                        lockUI.statusText = "locked"
                                        event.accepted = true
                                    } else if (!screen.inputActive && !screen.powerOpen) {
                                        screen.inputActive = true
                                    }
                                }

                                onAccepted: {
                                    if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                        lockUI.authenticating = true
                                        lockUI.failed = false
                                        lockUI.statusText = "verifying..."
                                        pam.respond(text)
                                        text = ""
                                        dotsModel.clear()
                                    }
                                }

                                onTextChanged: {
                                    let n = text.length
                                    while (dotsModel.count > n) dotsModel.remove(dotsModel.count - 1)
                                    while (dotsModel.count < n) dotsModel.append({})
                                    if (lockUI.failed) {
                                        lockUI.failed = false
                                        lockUI.statusText = "locked"
                                    }
                                }
                            }

                            // Pill background
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Qt.rgba(0, 0, 0, 0.25)
                                border.width: 1
                                border.color: {
                                    if (lockUI.failed)         return "#FB4934"
                                    if (lockUI.authenticating) return Colors.yellow
                                    if (inputField.text.length > 0)
                                        return Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.5)
                                    return Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.12)
                                }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                // Shake on fail
                                transform: Translate { id: shakeTx; x: 0 }
                                SequentialAnimation {
                                    id: shakeAnim
                                    NumberAnimation { target: shakeTx; property: "x"; from: 0;  to: -7; duration: 80; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTx; property: "x"; from: -7; to: 7;  duration: 80; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTx; property: "x"; from: 7;  to: -4; duration: 60; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTx; property: "x"; from: -4; to: 0;  duration: 60; easing.type: Easing.InOutSine }
                                }
                                Connections {
                                    target: lockUI
                                    function onFailedChanged() { if (lockUI.failed) shakeAnim.restart() }
                                }

                                // Dots / placeholder
                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    clip: true

                                    // Placeholder
                                    Text {
                                        anchors.centerIn: parent
                                        visible: inputField.text.length === 0 && !lockUI.authenticating
                                        text: lockUI.failed ? lockUI.statusText : "password"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.letterSpacing: 1
                                        color: lockUI.failed
                                            ? "#FB4934"
                                            : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.3)
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }

                                    // Authenticating indicator
                                    Text {
                                        anchors.centerIn: parent
                                        visible: lockUI.authenticating
                                        text: "..."
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 18
                                        color: Colors.yellow
                                    }

                                    // Password dots
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        visible: inputField.text.length > 0 && !lockUI.authenticating

                                        Repeater {
                                            model: ListModel { id: dotsModel }
                                            delegate: Rectangle {
                                                width: 7; height: 7; radius: 4
                                                color: Colors.text
                                                opacity: 0.9
                                                scale: 0

                                                NumberAnimation on scale {
                                                    from: 0.0; to: 1.0
                                                    duration: 150
                                                    easing.type: Easing.OutBack
                                                    running: true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -----------------------------------------------
                // INFO STRIP — bottom left
                // -----------------------------------------------

                Row {
                    anchors {
                        left: parent.left; bottom: parent.bottom
                        margins: 28
                    }
                    spacing: 20
                    opacity: screen.ready ? 0.55 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 600 } }

                    // Battery
                    Text {
                        visible: !screen.isDesktop
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Colors.subtle
                        text: {
                            let icon = screen.batStatus === "Charging" ? "󰂄"
                                     : parseInt(screen.batPct) > 20 ? "󰁹" : "󰃂"
                            return icon + "  " + screen.batPct + "%"
                        }
                    }

                    // Keyboard layout
                    Text {
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Colors.subtle
                        text: "󰌌  " + screen.kbLayout
                    }
                }

                // -----------------------------------------------
                // POWER BUTTON — bottom right
                // -----------------------------------------------

                Column {
                    anchors {
                        right: parent.right; bottom: parent.bottom
                        margins: 28
                    }
                    spacing: 8

                    opacity: screen.ready ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 600 } }

                    // Power menu items
                    Column {
                        spacing: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: screen.powerOpen ? 1.0 : 0.0
                        scale: screen.powerOpen ? 1.0 : 0.85
                        transformOrigin: Item.Bottom
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        Repeater {
                            model: [
                                { icon: "\udb81\udcb2", label: "Suspend",  proc: suspendProc  },
                                { icon: "\udb81\udc53", label: "Reboot",   proc: rebootProc   },
                                { icon: "\udb81\udc25", label: "Power off", proc: poweroffProc }
                            ]
                            delegate: Rectangle {
                                width: 130; height: 36; radius: 8
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                color: menuMa.containsMouse
                                    ? Qt.rgba(0, 0, 0, 0.6)
                                    : Qt.rgba(0, 0, 0, 0.7)
                                border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: Colors.text
                                    }
                                    Text {
                                        text: modelData.label
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Colors.text
                                    }
                                }
                                MouseArea {
                                    id: menuMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    pressAndHoldInterval: 800
                                    onPressAndHold: modelData.proc.running = true
                                    onPressed: parent.scale = 0.95
                                    onReleased: parent.scale = 1.0
                                }
                            }
                        }
                    }

                    // Power icon button
                    Rectangle {
                        width: 36; height: 36; radius: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: screen.powerOpen
                            ? Qt.rgba(0, 0, 0, 0.7)
                            : powerMa.containsMouse
                                ? Qt.rgba(0, 0, 0, 0.5)
                                : Qt.rgba(0, 0, 0, 0.25)
                        border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: powerMa.pressed ? 0.88 : (powerMa.containsMouse ? 1.1 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: screen.powerOpen ? "#FB4934" : Colors.subtle
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                screen.powerOpen = !screen.powerOpen
                                if (!screen.powerOpen) inputField.forceActiveFocus()
                            }
                        }
                    }
                }

                // -----------------------------------------------
                // MUSIC PLAYER — bottom center
                // -----------------------------------------------
                Item {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 28
                    
                    width: 360
                    height: mpCard.height 
                    opacity: screen.ready && screen.mpHasPlayer ? 1.0 : 0.0
                    scale: screen.ready && screen.mpHasPlayer ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    Rectangle {
                        id: mpCard
                        width: parent.width
                        height: mpRow.implicitHeight + 24
                    
                        
                        radius: 10
                        color: Qt.rgba(0, 0, 0, 0.45)
                        border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.08)
                        border.width: 1

                        Row {
                            id: mpRow
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 15 }
                            spacing: 14

                            // Artwork
                            Rectangle {
                                width: 80; height: 80; radius: 10
                                color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.08)
                                clip: true

                                Image {
                                    id: mpArt
                                    anchors.fill: parent
                                    source: screen.mpArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: mpArt.status !== Image.Ready
                                    text: "\uf001"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 26
                                    color: Colors.subtle
                                }
                            }

                            // Info + controls
                            Column {
                                width: parent.width - 72 - 14
                                spacing: 6

                                Text {
                                    width: parent.width
                                    text: screen.mpTrack
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Colors.text
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: screen.mpArtist
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: Colors.subtle
                                    elide: Text.ElideRight
                                }

                                // Progress bar
                                Item {
                                    width: parent.width; height: 10
                                    Rectangle {
                                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                        height: 3; radius: 2
                                        color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.15)
                                        Rectangle {
                                            width: screen.mpDuration > 0 ? parent.width * (screen.mpPosition / screen.mpDuration) : 0
                                            height: parent.height; radius: 2
                                            color: Colors.accent
                                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.Linear } }
                                        }
                                    }
                                }

                                // Controls + time
                                RowLayout {
                                    width: parent.width
                                    spacing: 4
                                    Text {
                                        text: "\udb81\udcae"
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                                        color: mpPrevMa.containsMouse ? Colors.text : Colors.subtle
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        MouseArea { id: mpPrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mpPrevProc.running = true }
                                    }
                                    Text {
                                        text: screen.mpStatus === "Playing" ? "\udb80\udfe4" : "\udb81\udc0a"
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22
                                        color: Colors.text
                                        Layout.leftMargin: 8; Layout.rightMargin: 8
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mpPlayProc.running = true }
                                    }
                                    Text {
                                        text: "\udb81\udcad"
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                                        color: mpNextMa.containsMouse ? Colors.text : Colors.subtle
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        MouseArea { id: mpNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mpNextProc.running = true }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: screen.mpFormatTime(screen.mpPosition) + " / " + screen.mpFormatTime(screen.mpDuration)
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                                        color: Colors.subtle
                                    }
                                }
                            }
                        }
                    }
                }

                // Processes — music
                Process {
                    id: mpMetaProc
                    command: ["sh", "-c", "playerctl metadata --format '{{title}}|{{artist}}|{{status}}|{{mpris:artUrl}}|{{mpris:length}}' 2>/dev/null || echo '||||0'"]
                    Component.onCompleted: running = true
                    stdout: SplitParser {
                        onRead: (data) => {
                            if (!data.trim()) return
                            var p = data.trim().split("|")
                            screen.mpTrack    = p[0] || ""
                            screen.mpArtist   = p[1] || ""
                            screen.mpStatus   = p[2] || "Stopped"
                            screen.mpArtUrl   = p[3] || ""
                            screen.mpDuration = Math.floor((parseInt(p[4]) || 0) / 1e6)
                        }
                    }
                }
                Process {
                    id: mpPosProc
                    running: false
                    command: ["sh", "-c", "playerctl position 2>/dev/null || echo 0"]
                    stdout: SplitParser {
                        onRead: (data) => { screen.mpPosition = Math.floor(parseFloat(data.trim()) || 0) }
                    }
                }
                Timer { interval: 2000; running: true; repeat: true; onTriggered: mpMetaProc.running = true }
                Timer { interval: 1000; running: true; repeat: true; onTriggered: { if (screen.mpStatus === "Playing") mpPosProc.running = true } }
                Process { id: mpPrevProc; command: ["playerctl", "previous"]; running: false; onRunningChanged: { if (!running) mpMetaProc.running = true } }
                Process { id: mpPlayProc; command: ["playerctl", "play-pause"]; running: false; onRunningChanged: { if (!running) mpMetaProc.running = true } }
                Process { id: mpNextProc; command: ["playerctl", "next"]; running: false; onRunningChanged: { if (!running) mpMetaProc.running = true } }

                // INTRO — simple fade in
                // -----------------------------------------------

                Rectangle {
                    id: introVeil
                    anchors.fill: parent
                    color: Colors.base
                    opacity: 1.0
                    z: 999

                    NumberAnimation on opacity {
                        id: introFade
                        from: 1.0; to: 0.0
                        duration: 600
                        easing.type: Easing.OutCubic
                        running: false
                        onFinished: {
                            introVeil.visible = false
                            screen.ready = true
                            inputField.forceActiveFocus()
                        }
                    }
                }

                Timer {
                    interval: 120; running: true; repeat: false
                    onTriggered: introFade.running = true
                }
            }
        }
    }
}
