//@ pragma UseQApplication
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
    ListModel { id: popupModel }

    ListModel { id: historyModel }

    NotificationServer {
        id: notifService
        keepOnReload: true

        onNotification: (notif) => {
    console.log("=== NOTIF ===")
    console.log("id:", notif.id)
    console.log("summary:", notif.summary)
    console.log("body:", notif.body)
    console.log("appName:", notif.appName)
    console.log("applicationName:", notif.applicationName)
    console.log("app_name:", notif.app_name)
    console.log("title:", notif.title)
    console.log("message:", notif.message)
    console.log("urgency:", notif.urgency)
    console.log("icon:", notif.appIcon)
    console.log("image:", notif.image)
    console.log(JSON.stringify(notif))

    popupModel.append({
        uid:      notif.id,
        summary:  notif.summary  || "",
        body:     notif.body     || "",
        appName:  notif.appName  || "",
        appIcon:  notif.appIcon  || "",
        urgency:  notif.urgency
    });

    historyModel.insert(0, {
        uid:      notif.id,
        summary:  notif.summary  || "",
        body:     notif.body     || "",
        appName:  notif.appName  || "",
        appIcon:  notif.appIcon  || "",
        urgency:  notif.urgency
    });
}
    }

    Bar {
        id: bar
        todoCount: notepadWidget.activeCount
        onTogglePower: pm.isOpen = !pm.isOpen
        onToggleWallpaper: ws.isOpen = !ws.isOpen
        onToggleNotif: nc.isOpen = !nc.isOpen
        onToggleCal: cal.toggle()
        onToggleCC: cc.toggle()
        onToggleTodo: notepadWidget.toggle()
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
        onClearAll: historyModel.clear()
        onRemoveItem: (uid) => {
            for (var i = 0; i < historyModel.count; i++) {
                if (historyModel.get(i).uid === uid) {
                    historyModel.remove(i);
                    break;
                }
            }
        }
    }

    KeybindCheatsheet { id: ks }
    AppLauncher { id: al }
    ClipboardManager { id: cm }
    FileBrowser { id: fb }
    RulesEditor { id: rulesEditorPanel }
    ScreenshotTool { id: screenshotTool }
    NotepadWidget { id: notepadWidget }
    ProcessManager { id: procMgr }
    CalendarPopup { id: cal }
    ControlCenter { id: cc }
    OSD { id: osd; bar: bar }

    IpcHandler {
        target: "toggle-process"
        function handle(): void { procMgr.toggle() }
    }
    IpcHandler {
        target: "toggle-notepad"
        function handle(): void { notepadWidget.toggle() }
    }
    IpcHandler {
        target: "toggle-screenshot"
        function handle(): void { screenshotTool.toggle() }
    }
    IpcHandler {
        target: "toggle-rules"
        function handle() { rulesEditorPanel.isOpen = !rulesEditorPanel.isOpen; }
    }
    IpcHandler {
        target: "toggle-filebrowser"
        function handle(): void { fb.toggle() }
    }
    IpcHandler {
        target: "toggle-clipboard"
        function handle(): void { cm.toggle() }
    }
    IpcHandler {
        target: "toggle-launcher"
        function handle(): void { al.toggle() }
    }
    IpcHandler {
        target: "toggle-wallpaper"
        function handle(): void { ws.isOpen = !ws.isOpen }
    }
    IpcHandler {
        target: "toggle-notif"
        function handle(): void { nc.isOpen = !nc.isOpen }
    }
    IpcHandler {
        target: "toggle-power"
        function handle(): void { pm.isOpen = !pm.isOpen }
    }
    IpcHandler {
        target: "toggle-cheatsheet"
        function handle(): void { ks.isOpen = !ks.isOpen }
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