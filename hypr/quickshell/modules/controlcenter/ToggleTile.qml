import "../../theme"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property string iconText: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property color accentColor: Colors.accent
    property bool showArrow: false

    signal toggled()
    signal arrowClicked()

    implicitHeight: 62
    radius: 12
    color: active ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.85) : Qt.rgba(1, 1, 1, 0.07)
    clip: true

    // Main label area — toggles on click
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: showArrow ? arrowBtn.left : parent.right
        cursorShape: Qt.PointingHandCursor
        onClicked: toggled()
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.right: showArrow ? arrowBtn.left : parent.right
        anchors.rightMargin: showArrow ? 4 : 14
        spacing: 2

        Text {
            text: iconText
            color: active ? Colors.base : Colors.text
            font.pixelSize: 17
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }

            }

        }

        Text {
            text: label
            color: active ? Colors.base : Colors.text
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }

            }

        }

        Text {
            text: sublabel
            color: active ? Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.65) : Colors.subtle
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }

            }

        }

    }

    // Arrow button — opens panel
    Rectangle {
        id: arrowBtn

        visible: showArrow
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: showArrow ? 32 : 0
        color: "transparent"

        // Subtle divider
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            width: 1
            color: active ? Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.25) : Qt.rgba(1, 1, 1, 0.12)
        }

        Text {
            anchors.centerIn: parent
            text: "\uf054" // nf-fa-chevron_right
            color: active ? Colors.base : Colors.subtle
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }

            }

        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: arrowClicked()
        }

    }

    Behavior on color {
        ColorAnimation {
            duration: 160
        }

    }

}
