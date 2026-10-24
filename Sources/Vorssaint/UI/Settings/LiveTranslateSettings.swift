// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import SwiftUI

struct LiveTranslateSettings: View {
    @ObservedObject private var service = LiveTranslateService.shared
    @AppStorage(DefaultsKey.liveTranslateEnabled) private var enabled = false
    @AppStorage(DefaultsKey.liveTranslateConsent) private var consent = false
    @AppStorage(DefaultsKey.liveTranslateDirection) private var direction = "englishIndonesian"
    @AppStorage(DefaultsKey.liveTranslateInput) private var input = "microphone"
    @AppStorage(DefaultsKey.liveTranslateNotch) private var notch = true
    @AppStorage(DefaultsKey.liveTranslateShortcutEnabled) private var shortcut = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Live Translate", isOn: $enabled)
            Picker("Direction", selection: $direction) {
                ForEach(LiveTranslateDirection.allCases) { Text($0.label).tag($0.rawValue) }
            }.disabled(service.running || service.starting)
            Picker("Audio source", selection: $input) {
                ForEach(LiveTranslateInput.allCases) { Text($0.label).tag($0.rawValue) }
            }.disabled(service.running || service.starting)
            Text("Start requests Speech Recognition and your selected audio permission. Apple transcribes speech (on device when supported; otherwise using Apple's service). The latest recognized text is sent to MyMemory for English ↔ Indonesian translation. Internet and provider quota apply; crowd-sourced matches can be inaccurate. Audio/text are not saved by ONE DESK.")
                .font(.callout).foregroundStyle(.secondary)
            Link("MyMemory service and privacy", destination: URL(string: "https://mymemory.translated.net/doc/en/tos.php")!)
            Toggle("I agree to send recognized text to MyMemory when I press Start", isOn: $consent)
            Toggle("Show translations in Dynamic Island", isOn: $notch)
            Text("Live subtitles appear in the island. Open its Live Translate section for full text and Start/Stop controls. Existing notices take priority.").font(.caption).foregroundStyle(.secondary)
            Toggle("Global start/stop shortcut: ⌃⌥⇧T", isOn: $shortcut)
            if service.shortcutFailed { Text("Shortcut is already in use. Choose another app's shortcut or disable it there.").foregroundStyle(.red) }
            HStack {
                Button(service.running || service.starting ? "Stop" : "Start translating") {
                    if service.running || service.starting { service.stop() } else { service.start() }
                }.disabled(!enabled || !consent)
                if service.starting { ProgressView().controlSize(.small) }
                if service.running { Label("Listening", systemImage: "waveform").foregroundStyle(.green) }
                Spacer()
                Button("Clear text") { service.clearText() }
            }
            if let error = service.error { Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled) }
            GroupBox("Recognized speech") {
                Text(service.transcript.isEmpty ? "Speech will appear here." : service.transcript)
                    .frame(maxWidth: .infinity, minHeight: 45, alignment: .leading).textSelection(.enabled)
            }
            GroupBox("Translation") {
                Text(service.translation.isEmpty ? "Translation will appear here." : service.translation)
                    .frame(maxWidth: .infinity, minHeight: 65, alignment: .leading).textSelection(.enabled)
            }
        }
        .onChange(of: enabled) { _, _ in service.syncWithPreferences() }
        .onChange(of: consent) { _, _ in service.syncWithPreferences() }
        .onChange(of: shortcut) { _, _ in service.syncWithPreferences() }
        .onChange(of: notch) { _, value in if !value { NotchService.shared.dismissTranslationNotice() } }
    }
}
