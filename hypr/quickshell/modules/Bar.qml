import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    height: 40
    color: Colors.base

    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 0

            // === KIRI ===
            Workspaces {}

            // === TENGAH ===
            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 12
                MediaPlayer {}
                Clock {}
            }

            Item { Layout.fillWidth: true }

            // === KANAN ===
            RowLayout {
                spacing: 0

                Weather {}

                Rectangle { width: 1; height: 14; color: Colors.overlay; Layout.leftMargin: 8; Layout.rightMargin: 8 }

                ResourceMonitor {}

                Rectangle { width: 1; height: 14; color: Colors.overlay; Layout.leftMargin: 8; Layout.rightMargin: 8 }

                Network {}
                Item { Layout.preferredWidth: 10 }
                Volume {}
                Item { Layout.preferredWidth: 10 }
                Battery {}

                Rectangle { width: 1; height: 14; color: Colors.overlay; Layout.leftMargin: 8; Layout.rightMargin: 8 }

                SysTray {}
            }
        }
    }
}