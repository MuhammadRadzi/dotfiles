import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: notifCenter

    required property ListModel historyModel
    signal clearAll()
    signal removeItem(int uid)

    property bool isOpen: false
    property bool initialized: false
    property string searchText: ""

    visible: initialized && (isOpen || panelRect.opacity > 0)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true
    color: "transparent"

    onIsOpenChanged: {
        initialized = true;
        if (isOpen) searchInput.forceActiveFocus();
        else searchText = "";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: notifCenter.isOpen = false
        enabled: isOpen
        visible: isOpen
    }

    Rectangle {
        id: panelRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 64
        width: 360
        implicitHeight: notifCol.implicitHeight + 32
        height: Math.min(implicitHeight, 600)
        radius: 10
        color: "#d916181c"
        border.width: 1
        border.color: "#22ffffff"
        clip: true
        opacity: isOpen ? 1 : 0

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: notifCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "NOTIFICATIONS"
                    color: Colors.subtle
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.letterSpacing: 1.5
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Clear all"
                    color: clearArea.containsMouse ? Colors.text : Colors.subtle
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifCenter.clearAll()
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // Search
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 8
                color: searchInput.activeFocus ? "#22ffffff" : "#11ffffff"
                border.width: 1
                border.color: searchInput.activeFocus ? Colors.accent : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "\uf002"
                        color: searchInput.activeFocus ? Colors.accent : Colors.overlay
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Colors.text
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
                        selectedTextColor: Colors.text
                        clip: true
                        onTextChanged: notifCenter.searchText = text

                        Keys.onEscapePressed: {
                            if (text !== "") text = "";
                            else notifCenter.isOpen = false;
                        }

                        Text {
                            anchors.fill: parent
                            text: "Search..."
                            color: Colors.overlay
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            visible: searchInput.text === ""
                        }
                    }

                    Text {
                        visible: searchInput.text !== ""
                        text: "\uf00d"
                        color: clearSearchArea.containsMouse ? Colors.text : Colors.overlay
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            id: clearSearchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            // Empty state
            Item {
                visible: historyModel.count === 0
                Layout.fillWidth: true
                implicitHeight: 80

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf0f3"
                        color: Colors.overlay
                        font.pixelSize: 32
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: searchText !== "" ? "No results" : "No notifications"
                        color: Colors.subtle
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            // List
            Flickable {
                visible: historyModel.count > 0
                Layout.fillWidth: true
                implicitHeight: Math.min(notifList.implicitHeight, 460)
                contentHeight: notifList.implicitHeight
                clip: true

                ColumnLayout {
                    id: notifList
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: historyModel

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: itemCol.implicitHeight + 20
                            radius: 10
                            color: itemArea.containsMouse ? "#22ffffff" : "#11ffffff"

                            // Filter search
                            visible: {
                                if (searchText === "") return true;
                                var q = searchText.toLowerCase();
                                return (model.summary && model.summary.toLowerCase().indexOf(q) !== -1)
                                    || (model.body    && model.body.toLowerCase().indexOf(q)    !== -1)
                                    || (model.appName && model.appName.toLowerCase().indexOf(q) !== -1);
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 4
                                width: 3; radius: 2
                                color: {
                                    if (model.urgency === 2) return Colors.red;
                                    if (model.urgency === 0) return Colors.subtle;
                                    return Colors.accent;
                                }
                            }

                            ColumnLayout {
                                id: itemCol
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 36
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: model.appName || "system"
                                        color: Colors.subtle
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.letterSpacing: 1
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.summary || ""
                                    color: Colors.text
                                    font.pixelSize: 13
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: (model.body || "") !== ""
                                    Layout.fillWidth: true
                                    text: model.body || ""
                                    color: Colors.subtle
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                text: "\uf00d"
                                color: closeItemArea.containsMouse ? Colors.text : Colors.subtle
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"

                                MouseArea {
                                    id: closeItemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifCenter.removeItem(model.uid)
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            x: isOpen ? 0 : 24
            Behavior on x {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }
    }
}