//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "modules"
import "modules/ruleseditor"
import "modules/screenshot"
import "modules/quicknote"
import "modules/wallpaper"
import "modules/todo"
import "modules/processmanager"

ShellRoot {
    Bar {
        id: bar
        todoCount: todoWidget.activeCount
        onTogglePower: pm.isOpen = !pm.isOpen
        onToggleWallpaper: ws.isOpen = !ws.isOpen
        onToggleNotif: nc.isOpen = !nc.isOpen
        onToggleCal: cal.toggle()
        onToggleCC: cc.toggle()
        onToggleTodo: todoWidget.toggle()
    }

    MusicPlayer { id: mp }
    PowerMenu { id: pm }
    WallpaperSelector { id: ws }
    NotificationCenter { id: nc }
    KeybindCheatsheet { id: ks }
    AppLauncher { id: al }
    ClipboardManager { id: cm }
    FileBrowser { id: fb }
    RulesEditor { id: rulesEditorPanel }
    ScreenshotTool { id: screenshotTool }
    QuickNote { id: quickNote }
    TodoWidget { id: todoWidget }    
    ProcessManager { id: procMgr }
    CalendarPopup { id: cal }
    ControlCenter { id: cc }
    OSD {
        id: osd
        bar: bar
    }

    IpcHandler {
        target: "toggle-process"
        function handle(): void { procMgr.toggle() }
    }
    IpcHandler {
        target: "toggle-todo"
        function handle(): void { todoWidget.toggle() }
    }
    IpcHandler {
        target: "toggle-quicknote"
        function handle(): void { quickNote.toggle() }
    }
    IpcHandler {
        target: "toggle-screenshot"
        function handle(): void { screenshotTool.toggle() }
    }
    IpcHandler {
        target: "toggle-rules"
        function handle() {
            rulesEditorPanel.isOpen = !rulesEditorPanel.isOpen;
        }
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
        function handle(val: int, muted: bool): void {
            osd.showVolume(val, muted)
        }
    }
    IpcHandler {
        target: "show-brightness-osd"
        function handle(val: int): void {
            osd.showBrightness(val)
        }
    }
}