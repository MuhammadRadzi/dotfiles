//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    Bar {
        id: bar
        onTogglePower: pm.isOpen = !pm.isOpen
        onToggleWallpaper: ws.isOpen = !ws.isOpen
        onToggleNotif: nc.isOpen = !nc.isOpen
        onToggleCal: cal.toggle()
        onToggleCC: cc.toggle()
    }

    MusicPlayer { id: mp }

    PowerMenu { id: pm }
    WallpaperSelector { id: ws }
    NotificationCenter { id: nc }
    KeybindCheatsheet { id: ks }
    AppLauncher { id: al }

    OSD {
        id: osd
        bar: bar
    }

    CalendarPopup { id: cal }
    ControlCenter { id: cc }

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