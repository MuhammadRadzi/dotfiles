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

    PowerMenu { id: pm }
    WallpaperSelector { id: ws }
    NotificationCenter { id: nc }

    CalendarPopup {
        id: cal
        barWindow: bar
    }

    ControlCenter {
        id: cc
        barWindow: bar
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
}