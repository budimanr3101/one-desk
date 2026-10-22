// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import SwiftUI

struct NotchEyesSettings: View {
    @AppStorage(DefaultsKey.notchEyesEnabled) private var enabled = false
    @AppStorage(DefaultsKey.notchEyesSize) private var size = 14.0
    @AppStorage(DefaultsKey.notchEyesSensitivity) private var sensitivity = 1.0
    @AppStorage(DefaultsKey.notchEyesBlink) private var blink = true
    @AppStorage(DefaultsKey.notchEyesIdle) private var idle = true
    @AppStorage(DefaultsKey.notchEyesStyle) private var style = "round"
    var body: some View {
        GroupBox("Notch Eyes") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Notch Eyes", isOn: $enabled)
                Picker("Eye style", selection: $style) {
                    Text("Round").tag("round"); Text("Slim").tag("slim")
                }
                Text("Eye size"); Slider(value: $size, in: 8...20, step: 1)
                Text("Cursor-follow sensitivity"); Slider(value: $sensitivity, in: 0.2...2)
                Toggle("Natural blinking", isOn: $blink)
                Toggle("Idle gaze", isOn: $idle)
                Text("Appears in an empty resting island. Companion, activities, notifications and interaction take priority. Select None for the island’s idle content.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(8)
                .onChange(of: enabled) { _, _ in NotchService.shared.syncWithPreferences() }
        }
    }
}
