pragma Singleton
import QtQuick
QtObject {
    // Base — mapping dari MD3 surface roles
    readonly property color base:    "{{colors.surface.default.hex}}"
    readonly property color surface: "{{colors.surface_container.default.hex}}"
    readonly property color overlay: "{{colors.outline.default.hex}}"
    // Text — mapping dari MD3 on-surface roles
    readonly property color text:    "{{colors.on_surface.default.hex}}"
    readonly property color subtle:  "{{colors.on_surface_variant.default.hex}}"
    // Accent — mapping dari MD3 primary role
    readonly property color accent:  "{{colors.primary.default.hex}}"
    // Status colors
    readonly property color red:     "{{colors.error.default.hex}}"
    readonly property color green:   "{{colors.success.default.hex | harmonize: {{colors.primary.default.hex}} }}"
    readonly property color yellow:  "{{colors.warning.default.hex | harmonize: {{colors.primary.default.hex}} }}"
}
