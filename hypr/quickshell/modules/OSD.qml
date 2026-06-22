import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd

    property var bar: null
    property string type: ""
    property int value: 0
    property bool muted: false
    property bool shown: false

    function showVolume(val, isMuted) {
        type = "volume";
        value = val;
        muted = isMuted;
        visible = true;
        shown = true;
        hideTimer.restart();
    }

    function showBrightness(val) {
        type = "brightness";
        value = val;
        visible = true;
        shown = true;
        hideTimer.restart();
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.top: true
    margins.top: 49
    implicitWidth: 280
    implicitHeight: 52
    color: "transparent"

    Timer {
        id: hideTimer

        interval: 2000
        repeat: false
        onTriggered: osd.shown = false
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"
        opacity: osd.shown ? 1 : 0
        scale: osd.shown ? 1 : 0.85
        y: osd.shown ? 0 : -12
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack }
        }
        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onOpacityChanged: {
            if (opacity === 0 && !osd.shown)
                osd.visible = false;
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: {
                    if (type === "volume")
                        return muted ? "\ueee8" : value >= 50 ? "\uf028" : "\uf027";
                    else
                        return value > 50 ? "\uf185" : "\uf186";
                }
                color: Colors.accent
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Colors.overlay

                Rectangle {
                    width: parent.width * (value / 100)
                    height: parent.height
                    radius: 2
                    color: {
                        if (type === "brightness")
                            return Colors.accent;

                        if (muted)
                            return Colors.accent;

                        return Colors.accent;
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

            }

            Text {
                text: muted ? "mute" : value + "%"
                color: Colors.subtle
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                Layout.minimumWidth: 36
                horizontalAlignment: Text.AlignRight
            }

        }

    }

}
