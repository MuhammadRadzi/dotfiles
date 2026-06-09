import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: calendarPopup

    property bool isOpen: false
    property var now: new Date()

    function toggle() {
        isOpen = !isOpen;
    }

    visible: panelRect.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: calendarPopup.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: isOpen
            onClicked: calendarPopup.isOpen = false
        }

        Rectangle {
            id: panelRect

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50
            width: 320
            height: calCol.implicitHeight + 32
            radius: 10
            color: "#d916181c"
            border.width: 1
            border.color: "#22ffffff"
            clip: true
            opacity: isOpen ? 1 : 0

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            ColumnLayout {
                id: calCol

                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // =====================
                // CLOCK & DATE
                // =====================
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(now, "HH:mm:ss")
                    color: Colors.text
                    font.pixelSize: 48
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(now, "dddd, dd MMMM yyyy")
                    color: Colors.subtle
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.overlay
                }

                // =====================
                // CALENDAR
                // =====================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Month & Year Navigation
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "\uf060"
                            color: Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calGrid.viewMonth -= 1;
                                    if (calGrid.viewMonth < 0) {
                                        calGrid.viewMonth = 11;
                                        calGrid.viewYear -= 1;
                                    }
                                }
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][calGrid.viewMonth] + " " + calGrid.viewYear
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "\uf061"
                            color: Colors.subtle
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calGrid.viewMonth += 1;
                                    if (calGrid.viewMonth > 11) {
                                        calGrid.viewMonth = 0;
                                        calGrid.viewYear += 1;
                                    }
                                }
                            }

                        }

                    }

                    // Day Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Colors.subtle
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                        }

                    }

                    // Date Grid
                    Grid {
                        id: calGrid

                        property int viewMonth: now.getMonth()
                        property int viewYear: now.getFullYear()
                        property int todayDate: now.getDate()
                        property int todayMonth: now.getMonth()
                        property int todayYear: now.getFullYear()
                        property int firstDay: {
                            var d = new Date(viewYear, viewMonth, 1).getDay();
                            return d === 0 ? 6 : d - 1;
                        }
                        property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()
                        property int totalCells: firstDay + daysInMonth

                        Layout.fillWidth: true
                        columns: 7
                        spacing: 2

                        Repeater {
                            model: calGrid.firstDay + calGrid.daysInMonth + (7 - ((calGrid.firstDay + calGrid.daysInMonth) % 7 || 7))

                            Rectangle {
                                property int day: index - calGrid.firstDay + 1
                                property bool isValid: index >= calGrid.firstDay && day <= calGrid.daysInMonth
                                property bool isToday: isValid && day === calGrid.todayDate && calGrid.viewMonth === calGrid.todayMonth && calGrid.viewYear === calGrid.todayYear

                                width: (calGrid.width - calGrid.spacing * 6) / 7
                                height: width
                                radius: width / 2
                                color: isToday ? Colors.accent : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: isValid ? day : ""
                                    color: isToday ? "#0d0d0d" : Colors.text
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: isToday
                                }

                            }

                        }

                    }

                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.overlay
                }

                // =====================
                // WORLD CLOCK
                // =====================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "WORLD CLOCK"
                        color: Colors.subtle
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.letterSpacing: 1.5
                    }

                    Repeater {
                        model: [{
                            "label": "Jakarta",
                            "tz": "Asia/Jakarta"
                        }, {
                            "label": "WITA",
                            "tz": "Asia/Makassar"
                        }, {
                            "label": "UTC",
                            "tz": "UTC"
                        }, {
                            "label": "Tokyo",
                            "tz": "Asia/Tokyo"
                        }, {
                            "label": "London",
                            "tz": "Europe/London"
                        }]

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: modelData.label
                                color: modelData.label === "WITA" ? Colors.accent : Colors.subtle
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                Layout.minimumWidth: 60
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                id: tzLabel

                                property string tz: modelData.tz

                                text: "--:--"
                                color: modelData.label === "WITA" ? Colors.text : Colors.subtle
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"

                                Connections {
                                    function onNowChanged() {
                                        tzProc.running = true;
                                    }

                                    target: calendarPopup
                                }

                                Process {
                                    id: tzProc

                                    command: ["sh", "-c", "TZ=" + tzLabel.tz + " date +'%H:%M'"]
                                    Component.onCompleted: running = true

                                    stdout: SplitParser {
                                        onRead: (data) => {
                                            if (data.trim())
                                                tzLabel.text = data.trim();

                                        }
                                    }

                                }

                            }

                        }

                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

            transform: Translate {
                y: isOpen ? 0 : -10

                Behavior on y {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
