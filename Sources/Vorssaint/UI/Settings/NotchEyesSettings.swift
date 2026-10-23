// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import SwiftUI
import AppKit

struct NotchEyesSettings: View {
    @AppStorage(DefaultsKey.notchEyesEnabled) private var enabled = false
    @AppStorage(DefaultsKey.notchEyesSize) private var size = 14.0
    @AppStorage(DefaultsKey.notchEyesSensitivity) private var sensitivity = 1.0
    @AppStorage(DefaultsKey.notchEyesBlink) private var blink = true
    @AppStorage(DefaultsKey.notchEyesIdle) private var idle = true
    @AppStorage(DefaultsKey.notchEyesStyle) private var style = "round"
    @AppStorage(DefaultsKey.notchPetSize) private var petSize = 52.0
    @AppStorage(DefaultsKey.notchPetAnimations) private var petAnimations = true
    @AppStorage(DefaultsKey.notchPetAssetRevision) private var revision = ""
    @State private var installed = NotchGhostAssets.isInstalled
    @State private var downloading = false
    @State private var failure: String?
    @State private var downloadTask: Task<Void, Never>?
    var body: some View {
        GroupBox("Notch Eyes & Pet") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Notch Eyes / Pet", isOn: $enabled)
                Picker("Appearance", selection: $style) {
                    Text("Ghost · Petdex").tag("ghost")
                    Text("Round eyes").tag("round")
                    Text("Slim eyes").tag("slim")
                }
                if style == "ghost" {
                    Text("A larger animated Ghost that idles, waves, jumps and changes expression. No cursor tracking.")
                        .font(.callout).foregroundStyle(.secondary)
                    if installed {
                        NotchGhostView().frame(width: 96, height: 96)
                            .padding(12).background(.black, in: RoundedRectangle(cornerRadius: 14))
                        Text("Pet size"); Slider(value: $petSize, in: 32...72, step: 2)
                        Toggle("Animate pet actions", isOn: $petAnimations)
                    }
                    HStack {
                        Button(downloading ? "Downloading…" : (installed ? "Download Ghost again" : "Download Ghost from Petdex")) {
                            downloadTask?.cancel()
                            downloading = true; failure = nil
                            downloadTask = Task {
                                defer { downloading = false }
                                do {
                                    try await NotchGhostAssets.download()
                                    try Task.checkCancellation()
                                    didInstall()
                                } catch is CancellationError { }
                                  catch { failure = error.localizedDescription }
                            }
                        }.disabled(downloading)
                        Button("Import Ghost sprite…", action: importGhost).disabled(downloading)
                    }
                    Link("Ghost by huigegood · View on Petdex", destination: URL(string: "https://petdex.dev/pets/ghost")!)
                    Text("Downloaded only when requested and stored on this Mac. Pet artwork is supplied by its creator; it is not included in ONE DESK's GPL source or settings backups.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let failure { Text(failure).font(.caption).foregroundStyle(.red) }
                } else {
                    Text("Eye size"); Slider(value: $size, in: 8...20, step: 1)
                    Text("Cursor-follow sensitivity"); Slider(value: $sensitivity, in: 0.2...2)
                    Toggle("Natural blinking", isOn: $blink)
                    Toggle("Idle gaze", isOn: $idle)
                }
                Text("Select None for island idle content and turn Companion off. The pet yields to activities, notifications and interaction. Crowded menu bars can limit its size.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(8)
                .onChange(of: enabled) { _, _ in sync() }
                .onChange(of: style) { _, _ in sync() }
                .onChange(of: petSize) { _, _ in sync() }
                .onDisappear { downloadTask?.cancel(); downloadTask = nil }
        }
    }
    private func sync() { NotchService.shared.syncWithPreferences() }
    private func didInstall() {
        installed = true; revision = UUID().uuidString; enabled = true
        sync()
    }
    private func importGhost() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.message = "Choose the original spritesheet.webp from the Ghost Petdex package."
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard bytes <= 4_000_000 else { throw NotchGhostAssets.Failure.invalid }
                try NotchGhostAssets.install(Data(contentsOf: url))
                failure = nil; didInstall()
            } catch { failure = error.localizedDescription }
        }
    }
}
