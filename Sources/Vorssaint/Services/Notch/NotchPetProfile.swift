// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

/// Ghost owns its preferences but participates in the existing Companion runtime.
/// Selecting Ghost takes precedence without erasing the classic Companion choice.
enum NotchPetProfile {
    static func isActive(in defaults: UserDefaults = .standard) -> Bool {
        AppFeature.notchEyes.isAvailable(in: defaults) && NotchSupport.isEnabled(in: defaults)
            && defaults.bool(forKey: DefaultsKey.notchEyesEnabled)
            && defaults.string(forKey: DefaultsKey.notchEyesStyle) == "ghost"
            && !(defaults.string(forKey: DefaultsKey.notchPetAssetRevision) ?? "").isEmpty
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
