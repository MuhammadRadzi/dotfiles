import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    property string appName: ""
    property string iconName: ""
    property int volume: 0
    property bool muted: false
    property int displayVolume: volume
    property bool scrubbing: false
    property bool displayMuted: muted

    signal muteToggled()
    signal volumeScrubbed(real ratio)
    signal scrubStarted()
    signal scrubEnded()

    onVolumeChanged: {
        if (!scrubbing)
            displayVolume = volume;

    }
    onMutedChanged: displayMuted = muted

    implicitWidth: parent ? parent.width : 0
    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: tileHover.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

        MouseArea {
            id: tileHover

            anchors.fill: parent
            hoverEnabled: true
            enabled: false
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        // App icon (best-effort, falls back to a generic speaker glyph)
        IconImage {
            id: appIcon

            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            source: iconName !== "" ? Quickshell.iconPath(iconName, true) : ""
            asynchronous: true
            visible: status === Image.Ready

            Text {
                anchors.fill: parent
                visible: appIcon.status !== Image.Ready
                text: "\udb80\udece"
                color: Colors.subtle
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: appName
                color: Colors.text
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Track
            Rectangle {
                Layout.fillWidth: true
                height: 5
                radius: 2.5
                color: Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.6)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, displayVolume / 100))
                    height: parent.height
                    radius: 2.5
                    color: displayMuted ? Colors.subtle : Colors.accent

                    Behavior on width {
                        enabled: !scrubbing
                        NumberAnimation { duration: 80 }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Rectangle {
                    x: parent.width * Math.max(0, Math.min(1, displayVolume / 100)) - width / 2
                    y: (parent.height - height) / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: Colors.text
                    Behavior on x {
                        enabled: !scrubbing
                        NumberAnimation { duration: 80 }
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        scrubbing = true;
                        scrubStarted();
                        var r = Math.max(0, Math.min(1, mouse.x / width));
                        displayVolume = Math.round(r * 100);
                        volumeScrubbed(r);
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            var r = Math.max(0, Math.min(1, mouse.x / width));
                            displayVolume = Math.round(r * 100);
                            volumeScrubbed(r);
                        }
                    }
                    onReleased: {
                        scrubbing = false;
                        scrubEnded();
                    }
                    
                }

            }

        }

        Text {
            text: displayMuted ? "\ueee8" : displayVolume >= 50 ? "\uf028" : displayVolume > 0 ? "\uf027" : "\uf026"
            color: displayMuted ? Colors.subtle : Colors.text
            font.pixelSize: 15
            font.family: "JetBrainsMono Nerd Font"
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    displayMuted = !displayMuted;
                    muteToggled();
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }

            }

        }

        Text {
            text: displayVolume + "%"
            color: Colors.subtle
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            Layout.minimumWidth: 32
            horizontalAlignment: Text.AlignRight
        }

    }

}