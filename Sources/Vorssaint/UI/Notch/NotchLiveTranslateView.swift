// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import SwiftUI

/// Caption-first island page. Setup is available without leaving the island.
struct NotchLiveTranslateView: View {
    @ObservedObject private var service = LiveTranslateService.shared
    @AppStorage(DefaultsKey.liveTranslateEnabled) private var enabled = false
    @AppStorage(DefaultsKey.liveTranslateConsent) private var consent = false
    @State private var setup = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(service.running ? "Listening" : service.starting ? "Starting…" : "Live Translate",
                      systemImage: "character.bubble")
                Spacer()
                Button(service.running || service.starting ? "Stop" : "Start") {
                    if service.running || service.starting { service.stop() }
                    else if enabled && consent { service.start() }
                    else { setup = true }
                }
            }
            Text(service.translation.isEmpty ? "Translated speech will appear here." : service.translation)
                .font(.system(size: 20, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .textSelection(.enabled)
            if !service.transcript.isEmpty {
                Text(service.transcript).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            }
            if let error = service.error { Text(error).font(.caption).foregroundStyle(.red) }
            DisclosureGroup("Language, audio & permissions", isExpanded: $setup) {
                LiveTranslateSettings().padding(.top, 8)
            }
        }
        .padding(12)
        .onAppear { if !enabled || !consent { setup = true } }
    }
}
