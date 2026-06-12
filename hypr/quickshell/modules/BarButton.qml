// modules/BarButton.qml — NEW FILE

import "../theme"
import QtQuick

Item {
    id: root

    property string icon: ""
    property int iconSize: 14
    signal clicked()

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.fill: parent
        text: root.icon
        color: hover.containsMouse ? Colors.text : Colors.subtle
        font.pixelSize: root.iconSize
        font.family: "JetBrainsMono Nerd Font"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}