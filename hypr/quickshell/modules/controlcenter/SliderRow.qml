import "../../theme"
import QtQuick
import QtQuick.Layouts

Item {
    property string iconText: ""
    property color iconColor: Colors.text
    property string valueText: ""
    property real sliderValue: 0
    property color accentColor: Colors.accent

    signal iconClicked()
    signal sliderScrubbed(real ratio)

    implicitWidth: parent ? parent.width : 0
    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: iconText
            color: iconColor
            font.pixelSize: 17
            font.family: "JetBrainsMono Nerd Font"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: iconClicked()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }

            }

        }

        // Track
        Rectangle {
            Layout.fillWidth: true
            height: 5
            radius: 2.5
            color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.6)

            // Fill
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sliderValue))
                height: parent.height
                radius: 2.5
                color: accentColor

                Behavior on width {
                    NumberAnimation {
                        duration: 80
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }

                }

            }

            // Thumb
            Rectangle {
                x: parent.width * Math.max(0, Math.min(1, sliderValue)) - width / 2
                y: (parent.height - height) / 2
                width: 13
                height: 13
                radius: 6.5
                color: Colors.text

                Behavior on x {
                    NumberAnimation {
                        duration: 80
                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    return sliderScrubbed(Math.max(0, Math.min(1, mouse.x / width)));
                }
                onPositionChanged: (mouse) => {
                    if (pressed)
                        sliderScrubbed(Math.max(0, Math.min(1, mouse.x / width)));

                }
            }

        }

        Text {
            text: valueText
            color: Colors.subtle
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            Layout.minimumWidth: 38
            horizontalAlignment: Text.AlignRight
        }

    }

}
