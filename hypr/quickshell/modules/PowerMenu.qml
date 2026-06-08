import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powerMenu

    property bool isOpen: false
    property string sessionUptime: "..."
    property string windowCount: "..."
    property string activeWorkspace: "..."

    onIsOpenChanged: {
        if (isOpen)
            infoProc.running = true;

    }
    visible: overlayRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"

    Rectangle {
        id: overlayRect

        anchors.fill: parent
        color: "#88000000"
        opacity: isOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: powerMenu.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.centerIn: parent
            width: 360
            height: contentCol.implicitHeight + 48
            radius: 20
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            scale: isOpen ? 1 : 0.95

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            ColumnLayout {
                id: contentCol

                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 24

                // Session info strip
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 10
                    color: "#11ffffff"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 0

                        // Uptime
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "\uf017"
                                color: Colors.accent
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                text: sessionUptime
                                color: Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                        }

                        // Divider
                        Rectangle {
                            width: 1
                            height: 24
                            color: "#22ffffff"
                        }

                        // Windows
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            spacing: 6

                            Text {
                                text: "\uf2d0"
                                color: Colors.accent
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                text: windowCount + " windows"
                                color: Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                        }

                        // Divider
                        Rectangle {
                            width: 1
                            height: 24
                            color: "#22ffffff"
                        }

                        // Workspace
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            spacing: 6

                            Text {
                                text: "\udb81\udc06"
                                color: Colors.accent
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                text: "WS " + activeWorkspace
                                color: Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                        }

                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: [{
                            "icon": "\uf023",
                            "label": "Lock",
                            "cmd": "hyprlock",
                            "color": "#85B7EB"
                        }, {
                            "icon": "\uf186",
                            "label": "Suspend",
                            "cmd": "systemctl suspend",
                            "color": "#AFA9EC"
                        }, {
                            "icon": "\udb81\udf17",
                            "label": "Hibernate",
                            "cmd": "systemctl hibernate",
                            "color": "#5DCAA5"
                        }, {
                            "icon": "\uf021",
                            "label": "Reboot",
                            "cmd": "systemctl reboot",
                            "color": "#EF9F27"
                        }, {
                            "icon": "\uf011",
                            "label": "Shutdown",
                            "cmd": "systemctl poweroff",
                            "color": "#F09595"
                        }, {
                            "icon": "\udb80\udf43",
                            "label": "Logout",
                            "cmd": "loginctl terminate-user $USER",
                            "color": "#ED93B1"
                        }]

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 80
                            radius: 12
                            color: btnArea.containsMouse ? "#22ffffff" : "#11ffffff"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: modelData.color
                                    font.pixelSize: 28
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                            }

                            MouseArea {
                                id: btnArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    powerMenu.isOpen = false;
                                    execProc.command = ["sh", "-c", modelData.cmd];
                                    execProc.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 10
                    color: cancelArea.containsMouse ? "#22ffffff" : "#11ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: cancelArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerMenu.isOpen = false
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

    Process {
        id: execProc

        running: false
    }

    Process {
        id: infoProc

        command: ["bash", "-c", "UPTIME=$(uptime -p | sed 's/up //' | sed 's/ hours\\?/h/' | sed 's/ minutes\\?/m/' | sed 's/,//g' | xargs);" + "WINDOWS=$(hyprctl clients -j | python3 -c \"import json,sys; print(len(json.load(sys.stdin)))\");" + "WS=$(hyprctl activeworkspace -j | python3 -c \"import json,sys; print(json.load(sys.stdin)['id'])\");" + "echo \"$UPTIME|$WINDOWS|$WS\""]
        running: false
        onRunningChanged: {
            if (!running) {
                var out = infoProc.stdout.buf.trim();
                infoProc.stdout.buf = "";
                var parts = out.split("|");
                if (parts.length === 3) {
                    powerMenu.sessionUptime = parts[0];
                    powerMenu.windowCount = parts[1];
                    powerMenu.activeWorkspace = parts[2];
                }
            }
        }

        stdout: SplitParser {
            property string buf: ""

            splitMarker: ""
            onRead: (data) => {
                buf += data;
            }
        }

    }

}
