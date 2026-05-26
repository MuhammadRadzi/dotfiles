import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 56

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8

        radius: 18

        color: "#d916181c"

        border.width: 1
        border.color: "#22ffffff"

        RowLayout {
            anchors.fill: parent

            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            // =========================
            // LEFT
            // =========================

            Item {
                Layout.fillWidth: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    implicitWidth: leftRow.implicitWidth + 20

                    RowLayout {
                        id: leftRow

                        anchors.centerIn: parent
                        spacing: 6

                        Workspaces {}
                    }
                }
            }

            // =========================
            // CENTER
            // =========================

            Item {
                Layout.fillWidth: true

                RowLayout {
                    id: centerRow

                    anchors.centerIn: parent
                    spacing: 10

                    MediaPlayer {}
                    Clock {}
                    
                }
            }

            // =========================
            // RIGHT
            // =========================

            Item {
                Layout.fillWidth: true

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    implicitWidth: rightRow.implicitWidth + 20

                    RowLayout {
                        id: rightRow

                        anchors.centerIn: parent
                        spacing: 10

                        Weather {}
                        Network {}
                        Volume {}
                        Battery {}
                        SysTray {}
                    }
                }
            }
        }
    }
}