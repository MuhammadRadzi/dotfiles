import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PopupWindow {
    id: calendarPopup

    property bool isOpen: false
    function toggle() { isOpen = !isOpen }

    visible: isOpen
    anchor.window: root
    anchor.rect.x: (root.width / 2) - 160
    anchor.rect.y: root.implicitHeight + 8

    width: 320
    height: calCol.implicitHeight + 32
    color: "transparent"

    // Update setiap menit
    property var now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: calendarPopup.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#e6161920"
        border.width: 1
        border.color: "#22ffffff"

        ColumnLayout {
            id: calCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // =====================
            // JAM BESAR
            // =====================
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(now, "HH:mm:ss")
                color: Colors.text
                font.pixelSize: 48
                font.family: "JetBrainsMono Nerd Font Bold"
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
            // KALENDER
            // =====================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // Header bulan + navigasi
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰔠"
                        color: Colors.subtle
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calGrid.viewMonth -= 1
                                if (calGrid.viewMonth < 0) {
                                    calGrid.viewMonth = 11
                                    calGrid.viewYear -= 1
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: ["January","February","March","April","May","June",
                               "July","August","September","October","November","December"][calGrid.viewMonth]
                               + " " + calGrid.viewYear
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "󰔟"
                        color: Colors.subtle
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calGrid.viewMonth += 1
                                if (calGrid.viewMonth > 11) {
                                    calGrid.viewMonth = 0
                                    calGrid.viewYear += 1
                                }
                            }
                        }
                    }
                }

                // Hari header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
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

                // Grid tanggal
                Grid {
                    id: calGrid
                    Layout.fillWidth: true
                    columns: 7
                    spacing: 2

                    property int viewMonth: now.getMonth()
                    property int viewYear: now.getFullYear()
                    property int todayDate: now.getDate()
                    property int todayMonth: now.getMonth()
                    property int todayYear: now.getFullYear()

                    // Hitung hari pertama bulan (0=Sun, convert ke Mon-based)
                    property int firstDay: {
                        var d = new Date(viewYear, viewMonth, 1).getDay()
                        return d === 0 ? 6 : d - 1
                    }
                    property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()
                    property int totalCells: firstDay + daysInMonth

                    Repeater {
                        model: calGrid.firstDay + calGrid.daysInMonth + (7 - ((calGrid.firstDay + calGrid.daysInMonth) % 7 || 7))

                        Rectangle {
                            width: (calGrid.width - calGrid.spacing * 6) / 7
                            height: width
                            radius: width / 2
                        
                            property int day: index - calGrid.firstDay + 1
                            property bool isValid: index >= calGrid.firstDay && day <= calGrid.daysInMonth
                            property bool isToday: isValid && day === calGrid.todayDate
                                && calGrid.viewMonth === calGrid.todayMonth
                                && calGrid.viewYear === calGrid.todayYear
                        
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
                    model: [
                        { label: "WIB",   offset: 7  },
                        { label: "WITA",  offset: 8  },
                        { label: "WIT",   offset: 9  },
                        { label: "UTC",   offset: 0  },
                        { label: "Tokyo", offset: 9  },
                        { label: "London",offset: 1  },
                    ]

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: modelData.label
                            color: modelData.label === "WITA" ? Colors.accent : Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.minimumWidth: 60
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            property var tzTime: {
                                var utc = now.getTime() + now.getTimezoneOffset() * 60000
                                return new Date(utc + modelData.offset * 3600000)
                            }
                            text: Qt.formatTime(tzTime, "HH:mm")
                            color: modelData.label === "WITA" ? Colors.text : Colors.subtle
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: calendarPopup.isOpen = false
        z: -1
    }
}