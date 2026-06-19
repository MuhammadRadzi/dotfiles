import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: overview

    property bool isOpen: false
    property bool initialized: false

    // How many workspaces are displayed in the grid (1..workspaceCount)
    readonly property int workspaceCount: 10
    readonly property int columns: 5

    function toggle() {
        isOpen = !isOpen;
    }

    function goTo(wsId) {
        Hyprland.dispatch("workspace " + wsId);
        overview.isOpen = false;
    }

    visible: initialized && (isOpen || panelRect.opacity > 0)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"

    onIsOpenChanged: {
        initialized = true;
        if (isOpen)
            Hyprland.refreshWorkspaces();
    }

    Shortcut {
        sequence: "Escape"
        enabled: overview.isOpen
        onActivated: overview.isOpen = false
    }

    MouseArea {
        anchors.fill: parent
        enabled: overview.isOpen
        visible: overview.isOpen
        onClicked: overview.isOpen = false
    }

    Rectangle {
        id: panelRect

        anchors.centerIn: parent
        width: columns * 240 + (columns - 1) * 14 + 40
        implicitHeight: grid.implicitHeight + 40
        radius: 14
        color: "#d916181c"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true
        opacity: overview.isOpen ? 1 : 0
        scale: overview.isOpen ? 1 : 0.94

        MouseArea {
            anchors.fill: parent
        }

        GridLayout {
            id: grid

            anchors.centerIn: parent
            columns: overview.columns
            rowSpacing: 14
            columnSpacing: 14

            Repeater {
                model: overview.workspaceCount

                delegate: WorkspaceTile {
                    required property int index

                    wsId: index + 1
                    onClicked: overview.goTo(wsId)
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

}