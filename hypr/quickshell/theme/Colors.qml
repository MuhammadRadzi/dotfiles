pragma Singleton
import QtQuick
QtObject {
    // Base — mapping dari MD3 surface roles
    readonly property color base:    "#12140d"
    readonly property color surface: "#1e2019"
    readonly property color overlay: "#8f9284"
    // Text — mapping dari MD3 on-surface roles
    readonly property color text:    "#e3e3d8"
    readonly property color subtle:  "#c6c8b9"
    // Accent — mapping dari MD3 primary role
    readonly property color accent:  "#b7d085"
    // Status colors
    readonly property color red:     "#ffb4ab"
    readonly property color green:   "#acd18f"
    readonly property color yellow:  "#cbcb77"
}
