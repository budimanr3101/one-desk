// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

enum NotchGhostTests {
    static func run(_ suite: TestSuite) {
        let domain = "com.onedesk.tests.ghost-profile"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        defer { defaults.removePersistentDomain(forName: domain) }
        for feature in [AppFeature.notch, .notchEyes, .notchMascot, .commandBar] {
            defaults.set(true, forKey: feature.availabilityKey)
        }
        defaults.set(true, forKey: DefaultsKey.notchEnabled)
        defaults.set(true, forKey: DefaultsKey.notchEyesEnabled)
        defaults.set("ghost", forKey: DefaultsKey.notchEyesStyle)
        defaults.set("fixture", forKey: DefaultsKey.notchPetAssetRevision)
        defaults.set(false, forKey: DefaultsKey.notchMascotEnabled)
        defaults.set("left", forKey: DefaultsKey.notchMascotSide)
        defaults.set("right", forKey: DefaultsKey.notchPetSide)
        defaults.set(true, forKey: DefaultsKey.notchPetVisits)
        defaults.set(true, forKey: DefaultsKey.notchPetReactions)
        defaults.set(true, forKey: DefaultsKey.notchPetHidesWhenIdle)
        defaults.set("frequent", forKey: DefaultsKey.notchPetVisitFrequency)
        defaults.set(true, forKey: DefaultsKey.notchPetCommandBar)
        defaults.set("island", forKey: DefaultsKey.notchPetCommandBarStyle)
        suite.expect(NotchMascotSupport.isEnabled(in: defaults), "Ghost activates the shared lifecycle independently of classic Companion")
        suite.expect(NotchMascotSupport.side(in: defaults) == .right
            && NotchMascotSupport.visits(in: defaults) && NotchMascotSupport.reacts(in: defaults)
            && NotchMascotSupport.hidesWhenIdle(in: defaults)
            && NotchMascotSupport.visitFrequency(in: defaults) == .frequent,
            "Ghost routes independent side, visits, reactions and hiding preferences")
        suite.expect(NotchMascotSupport.commandBarStyle(in: defaults) == .island,
                     "Ghost uses its own Command Bar presentation")
        defaults.set(false, forKey: DefaultsKey.notchPetCommandBar)
        suite.expect(NotchMascotSupport.commandBarStyle(in: defaults) == nil, "Ghost can opt out of Command Bar")
        defaults.set(false, forKey: DefaultsKey.notchEyesEnabled)
        suite.expect(!NotchMascotSupport.isEnabled(in: defaults), "disabling Ghost stops the shared runtime when classic Companion is off")
        defaults.set(true, forKey: DefaultsKey.notchMascotEnabled)
        suite.expect(NotchMascotSupport.side(in: defaults) == .left, "disabling Ghost restores preserved classic preferences")
        defaults.set(true, forKey: DefaultsKey.notchEyesEnabled)
        defaults.set(false, forKey: AppFeature.notchEyes.availabilityKey)
        suite.expect(!NotchPetProfile.isActive(in: defaults), "removing the Ghost feature releases its presentation")
        defaults.set(true, forKey: AppFeature.notchEyes.availabilityKey)
        defaults.set("", forKey: DefaultsKey.notchPetAssetRevision)
        suite.expect(!NotchPetProfile.isActive(in: defaults), "an undownloaded Ghost never replaces Companion")
        for reaction in NotchMascotReaction.allCases {
            suite.expect(NotchPetProfile.action(for: reaction).frameCount > 0, "every Companion reaction has a Ghost animation")
        }
        for mood in NotchMascotMood.allCases {
            suite.expect(NotchPetProfile.action(for: mood).frameCount > 0, "every Companion mood has a Ghost animation")
        }
        let track = NotchMascotSupport.track(stripWidth: 300, stripHeight: 60, wing: 60,
            cameraWidth: 180, floats: false, bodyHeight: 60, side: .right, sizeOverride: 52)
        suite.expect(track.size == 52, "resting Ghost retains its larger size in the Companion track")
        for requested in [32.0, 52.0, 72.0] {
            let dimension = NotchGhostSupport.dimension(requested, sideRoom: nil)
            // A tall pre-existing island must not determine the character's size.
            let surface = NotchGhostSupport.surface(base: CGSize(width: 400, height: 100),
                cameraWidth: 180, screenWidth: 1440, dimension: dimension)
            let sized = NotchMascotSupport.track(stripWidth: surface.width, stripHeight: surface.height,
                wing: (surface.width - 180) / 2, cameraWidth: 180, floats: false,
                bodyHeight: surface.height, side: .left, sizeOverride: dimension)
            suite.expect(sized.size == CGFloat(requested),
                         "pet size follows the requested dimension independently of the island height")
        }
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
