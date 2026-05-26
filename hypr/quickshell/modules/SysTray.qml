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

            Item {
                width: 18
                height: 18

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}