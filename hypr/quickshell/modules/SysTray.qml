import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: parent.height

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            Image {
                source: modelData.icon
                width: 16
                height: 16

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                }
            }
        }
    }
}