// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

enum NotchGhostTests {
    static func run(_ suite: TestSuite) {
        for action in NotchGhostAction.allCases {
            suite.expect(action.duration > 0 && action.duration < 2, "Ghost actions have bounded timing")
            for frame in 0..<action.frameCount {
                let rect = action.frameRect(frame)
                suite.expect(CGRect(x: 0, y: 0, width: 1536, height: 1872).contains(rect),
                             "Ghost frame stays inside the source atlas")
                suite.expect(rect.minY == CGFloat(action.rawValue * 208), "actions use distinct animation rows")
            }
            suite.expect(action.frameRect(-1) == action.frameRect(0)
                         && action.frameRect(100) == action.frameRect(action.frameCount - 1),
                         "frame indexing never reaches blank trailing cells")
        }
        suite.expect(NotchGhostAction.idle.frameCount == 6 && NotchGhostAction.wave.frameCount == 4,
                     "short Ghost animations exclude transparent cells")
        suite.expect(NotchGhostSupport.dimension(.nan, sideRoom: nil) == 52,
                     "invalid size restores the larger default")
        suite.expect(NotchGhostSupport.dimension(72, sideRoom: 44) == 36,
                     "crowded menus limit pet width")
        let surface = NotchGhostSupport.surface(base: CGSize(width: 268, height: 32),
                                                cameraWidth: 180, screenWidth: 1440, dimension: 52)
        suite.expect(surface.width >= 300 && surface.height == 60,
                     "Ghost reserves a visibly larger native resting surface")
        suite.expect(!SettingsBackupSupport.exportKeys().contains(DefaultsKey.notchPetAssetRevision)
                     && SettingsBackupSupport.exportKeys().contains(DefaultsKey.notchPetSize)
                     && SettingsBackupSupport.exportKeys().contains(DefaultsKey.notchPetAnimations),
                     "pet preferences travel in backups while asset-install state stays local")
        do {
            try NotchGhostAssets.install(Data("not a Ghost sprite".utf8))
            suite.expect(false, "an unverified sprite must be rejected")
        } catch {
            suite.expect(true, "the pinned Ghost asset rejects unverified image data before installation")
        }
    }
}
