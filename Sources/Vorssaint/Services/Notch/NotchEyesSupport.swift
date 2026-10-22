// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

/// AppKit desktop coordinates, including displays left of/below the primary.
enum NotchEyesSupport {
    static func gaze(cursor: CGPoint, screen: CGRect, sensitivity: Double) -> CGPoint {
        guard screen.width > 0, screen.height > 0, screen.width.isFinite, screen.height.isFinite,
              screen.minX.isFinite, screen.maxY.isFinite,
              cursor.x.isFinite, cursor.y.isFinite else { return .zero }
        let gain = sensitivity.isFinite ? min(2, max(0.2, sensitivity)) : 1
        var x = (cursor.x - screen.midX) / (screen.width / 2) * gain
        var y = (cursor.y - screen.maxY) / (screen.height / 2) * gain
        let length = hypot(x, y)
        if length > 1 { x /= length; y /= length }
        return CGPoint(x: x, y: y)
    }
    static func visible(enabled: Bool, available: Bool, expanded: Bool,
                        activity: Bool, companion: Bool, idleEmpty: Bool) -> Bool {
        enabled && available && !expanded && !activity && !companion && idleEmpty
    }
    static func blinkDelay(unit: Double) -> Double { 3 + min(1, max(0, unit)) * 5 }
    static func eyeSize(_ value: Double) -> Double {
        value.isFinite ? min(20, max(8, value)) : 14
    }
}

/// Owns event subscriptions as a single resource. Installation is lazy and
/// idempotent; disabling, hiding or destroying the view releases it exactly once.
final class NotchEyesLifecycle {
    private var cleanup: (() -> Void)?
    var isActive: Bool { cleanup != nil }
    func activate(install: () -> (() -> Void)) {
        guard cleanup == nil else { return }
        cleanup = install()
    }
    func stop() {
        let release = cleanup
        cleanup = nil
        release?()
    }
    deinit { stop() }
}
