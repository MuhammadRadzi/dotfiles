import "../applauncher"
import "../filebrowser"
import "../wallpaper"
import "../../theme"
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: hostWindow

    // "" | "launcher" | "filebrowser" | "wallpaper"
    property string activeMode: ""
    property string lastMode: ""
    property bool isOpen: activeMode !== ""
    property bool initialized: false

    readonly property var modeItem: {
        if (lastMode === "launcher")
            return appLauncherContent;

        if (lastMode === "filebrowser")
            return fileBrowserContent;

        if (lastMode === "wallpaper")
            return wallpaperContent;

        return null;
    }

    function openMode(mode) {
        activeMode = (activeMode === mode) ? "" : mode;
    }

    function toggleLauncher() { openMode("launcher"); }
    function toggleFileBrowser() { openMode("filebrowser"); }
    function toggleWallpaper() { openMode("wallpaper"); }
    function close() { activeMode = ""; }

    onActiveModeChanged: {
        initialized = true;
        if (activeMode !== "")
            lastMode = activeMode;

    }

    visible: initialized && (isOpen || panelRect.opacity > 0)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: hostWindow.isOpen
            visible: hostWindow.isOpen
            onClicked: hostWindow.close()
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: hostWindow.modeItem ? hostWindow.modeItem.implicitWidth : 0
            height: hostWindow.modeItem ? hostWindow.modeItem.implicitHeight : 0
            radius: hostWindow.modeItem ? hostWindow.modeItem.panelRadius : 10
            color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.85)
            border.width: 1
            border.color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.13)
            clip: true
            opacity: hostWindow.isOpen ? 1 : 0
            scale: hostWindow.isOpen ? 1 : 0.95

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            Behavior on height {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            Behavior on radius {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // Eat clicks inside the panel so they don't fall through to the
            // click-outside-to-close MouseArea behind it.
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            AppLauncherContent {
                id: appLauncherContent

                anchors.fill: parent
                active: hostWindow.activeMode === "launcher"
                onRequestClose: hostWindow.close()
            }

            FileBrowserContent {
                id: fileBrowserContent

                anchors.fill: parent
                active: hostWindow.activeMode === "filebrowser"
                onRequestClose: hostWindow.close()
            }

            WallpaperSelectorContent {
                id: wallpaperContent

                anchors.fill: parent
                active: hostWindow.activeMode === "wallpaper"
                onRequestClose: hostWindow.close()
            }

        }

    }

}