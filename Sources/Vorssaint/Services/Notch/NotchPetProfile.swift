// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

/// Every Notch Eyes appearance shares preferences and the existing Companion runtime.
/// Selecting an appearance preserves the independent classic Companion choice.
enum NotchPetProfile {
    static func isActive(in defaults: UserDefaults = .standard) -> Bool {
        guard AppFeature.notchEyes.isAvailable(in: defaults), NotchSupport.isEnabled(in: defaults),
              defaults.bool(forKey: DefaultsKey.notchEyesEnabled) else { return false }
        switch defaults.string(forKey: DefaultsKey.notchEyesStyle) ?? "round" {
        case "round", "slim": return true
        case "ghost": return !(defaults.string(forKey: DefaultsKey.notchPetAssetRevision) ?? "").isEmpty
        default: return false
        }
    }
    static func dimension(in defaults: UserDefaults = .standard, sideRoom: CGFloat? = nil) -> CGFloat {
        let requested = defaults.string(forKey: DefaultsKey.notchEyesStyle) == "ghost"
            ? defaults.double(forKey: DefaultsKey.notchPetSize)
            : NotchEyesSupport.eyeSize(defaults.double(forKey: DefaultsKey.notchEyesSize)) * 2.8
        return NotchGhostSupport.dimension(requested, sideRoom: sideRoom)
    }

    static func key(_ pet: String, _ classic: String, in defaults: UserDefaults) -> String {
        isActive(in: defaults) ? pet : classic
    }
    static func action(for reaction: NotchMascotReaction) -> NotchGhostAction {
        switch reaction {
        case .celebrate, .wakeUp, .bounce, .surprised: return .jump
        case .confused: return .failed
        case .flash, .hush, .yawn: return .waiting
        default: return .wave
        }
    }
    static func action(for mood: NotchMascotMood) -> NotchGhostAction {
        switch mood {
        case .sleepy: return .waiting
        case .confused: return .failed
        case .searching, .thinking, .determined: return .review
        case .happy, .love, .wink: return .wave
        case .surprised, .alert: return .jump
        default: return .idle
        }
    }
}
