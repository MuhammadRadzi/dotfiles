import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    Bar {}

    IpcHandler {
        target: "toggle-wallpaper"
        function handle(): void {
            wallpaperWin.isOpen = !wallpaperWin.isOpen
        }
    }

    WallpaperSelector {
        id: wallpaperWin
    }
}