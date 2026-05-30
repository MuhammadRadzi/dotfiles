import "../theme"
import QtQuick

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    Text {
        id: label

        anchors.centerIn: parent
        text: Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
        color: Colors.text
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: label.text = Qt.formatDateTime(new Date(), "ddd, dd MMM  HH:mm")
        }

    }

}
