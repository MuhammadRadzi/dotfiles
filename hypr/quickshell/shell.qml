import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "modules"
import "modules/ruleseditor"
import "modules/screenshot"
import "modules/quicknote"
import "modules/wallpaper"
import "modules/processmanager"
import "modules/notifications"

ShellRoot {
    id: root

    property bool isRecording: false
    property int recordSeconds: 0

    ListModel { id: popupModel }
    ListModel { id: historyModel }

    function makeNotifEntry(notif) {
        return {
            uid:     notif.id,
            summary: notif.summary  || "",
            body:    notif.body     || "",
            appName: notif.appName  || "",
            appIcon: notif.appIcon  || "",
            urgency: notif.urgency
        };
    }

    NotificationServer {
        id: notifService
        keepOnReload: true
        onNotification: (notif) => {
            var entry = makeNotifEntry(notif);
            if (!cc.dndActive) popupModel.append(entry);
            historyModel.insert(0, entry);
        }
    }

    Timer {
        id: recordTimer
        interval: 1000
        repeat: true
        running: root.isRecording
        onTriggered: root.recordSeconds++
    }

    Bar {
        id: bar
        todoCount: notepadWidget.activeCount
        isRecording: root.isRecording
        recordSeconds: root.recordSeconds
        onTogglePower:     pm.toggle()
        onToggleWallpaper: ws.toggle()
        onToggleNotif:     nc.toggle()
        onToggleCal:       cal.toggle()
        onToggleCC:        cc.toggle()
        onToggleTodo:      notepadWidget.toggle()
        onStopRecording:   screenshotTool.stopRecording()
    }

    MusicPlayer { id: mp }
    PowerMenu { id: pm }
    WallpaperSelector { id: ws }

    NotificationPopups {
        id: notifPopups
        popupModel: popupModel
        onRemoveRequested: (uid) => {
            for (var i = 0; i < popupModel.count; i++) {
                if (popupModel.get(i).uid === uid) {
                    popupModel.remove(i);
                    break;
                }
            }
        }
    }

    NotificationCenter {
        id: nc
        historyModel: historyModel
        onClearAll:   historyModel.clear()
        onRemoveItem: (uid) => {
            for (var i = 0; i < historyModel.count; i++) {
                if (historyModel.get(i).uid === uid) {
                    historyModel.remove(i);
                    break;
                }
            }
        }
    }

    ControlCenter {
        id: cc
        onOpenWifiPanel: {
            cc.isOpen = false
            wifiPanel.isOpen = true
        }
        onOpenBtPanel: {
            cc.isOpen = false
            btPanel.isOpen = true
        }
    }

    WifiPanel {
        id: wifiPanel
        onBackPressed: {
            wifiPanel.isOpen = false
            cc.isOpen = true
        }
    }

    BluetoothPanel {
        id: btPanel
        onBackPressed: {
            btPanel.isOpen = false
            cc.isOpen = true
        }
    }

    KeybindCheatsheet { id: ks }
    AppLauncher       { id: al }
    ClipboardManager  { id: cm }
    FileBrowser       { id: fb }
    RulesEditor       { id: rulesEditorPanel }

    ScreenshotTool {
        id: screenshotTool
        onRecordingStarted: {
            root.isRecording = true
            root.recordSeconds = screenshotTool.recordSeconds
        }
        onRecordingStopped: {
            root.isRecording = false
        }
    }

    NotepadWidget     { id: notepadWidget }
    ProcessManager    { id: procMgr }
    CalendarPopup     { id: cal }
    OSD               { id: osd; bar: bar }

    IpcHandler { target: "toggle-process";    function handle(): void { procMgr.toggle() } }
    IpcHandler { target: "toggle-notepad";    function handle(): void { notepadWidget.toggle() } }
    IpcHandler { target: "toggle-screenshot"; function handle(): void { screenshotTool.toggle() } }
    IpcHandler { target: "toggle-rules";      function handle(): void { rulesEditorPanel.toggle() } }
    IpcHandler { target: "toggle-filebrowser";function handle(): void { fb.toggle() } }
    IpcHandler { target: "toggle-clipboard";  function handle(): void { cm.toggle() } }
    IpcHandler { target: "toggle-launcher";   function handle(): void { al.toggle() } }
    IpcHandler { target: "toggle-wallpaper";  function handle(): void { ws.toggle() } }
    IpcHandler { target: "toggle-notif";      function handle(): void { nc.toggle() } }
    IpcHandler { target: "toggle-power";      function handle(): void { pm.toggle() } }
    IpcHandler { target: "toggle-cheatsheet"; function handle(): void { ks.toggle() } }
    IpcHandler {
        target: "reload-shell"
        function handle(hard: bool): void { Quickshell.reload(hard) }
    }
    IpcHandler {
        target: "show-volume-osd"
        function handle(val: int, muted: bool): void { osd.showVolume(val, muted) }
    }
    IpcHandler {
        target: "show-brightness-osd"
        function handle(val: int): void { osd.showBrightness(val) }
    }
}