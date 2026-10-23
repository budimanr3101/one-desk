// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation
import CryptoKit
import ImageIO

/// User-requested asset, kept outside the app and settings backups. No third-party
/// artwork is redistributed with ONE DESK. Never downloads at application startup.
enum NotchGhostAssets {
    static let source = URL(string: "https://assets.petdex.dev/pets/ghost-a4500caeb64e/sprite.webp")!
    static let checksum = "f150d794d1c33caabca0d32d213904efaac86afb215fa33f6fcee7ab444f9602"
    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.onedesk.app")
            .appendingPathComponent("Pets/Ghost/spritesheet.webp")
    }
    static var isInstalled: Bool { FileManager.default.fileExists(atPath: fileURL.path) }
    enum Failure: LocalizedError {
        case invalid, network
        var errorDescription: String? {
            switch self {
            case .invalid: return "This is not the supported Ghost sprite sheet. Import the original spritesheet.webp from Petdex."
            case .network: return "Ghost could not be downloaded. Try again or import its original sprite sheet."
            }
        }
    }
    static func install(_ data: Data) throws {
        guard data.count <= 4_000_000,
              SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == checksum,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              props[kCGImagePropertyPixelWidth] as? Int == 1536,
              props[kCGImagePropertyPixelHeight] as? Int == 1872 else { throw Failure.invalid }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
    /// Runs on the generic async executor, keeping disk I/O and checksum/image
    /// validation out of the Settings view and off the main UI thread.
    static func importSprite(from url: URL) async throws {
        try Task.checkCancellation()
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard bytes > 0, bytes <= 4_000_000 else { throw Failure.invalid }
        let data = try Data(contentsOf: url)
        try Task.checkCancellation()
        try install(data)
    }

    static func download() async throws {
        var request = URLRequest(url: source)
        request.timeoutInterval = 30
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 45
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Failure.network }
        try Task.checkCancellation()
        try install(data)
    }
    static func frames() -> [NotchGhostAction: [CGImage]] {
        guard let data = try? Data(contentsOf: fileURL), data.count <= 4_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary),
              image.width == 1536, image.height == 1872 else { return [:] }
        return Dictionary(uniqueKeysWithValues: NotchGhostAction.allCases.map { action in
            (action, (0..<action.frameCount).compactMap { image.cropping(to: action.frameRect($0)) })
        })
    }
}
