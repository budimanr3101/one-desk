// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

/// Layout of Ghost's v1 Petdex atlas. Blank trailing cells are never animated.
enum NotchGhostAction: Int, CaseIterable, Hashable {
    case idle, right, left, wave, jump, failed, waiting, running, review
    var frameCount: Int { [6, 8, 8, 4, 5, 8, 6, 6, 6][rawValue] }
    var duration: Double { Double(frameCount) / 7 }
    func frameRect(_ frame: Int) -> CGRect {
        CGRect(x: min(max(0, frame), frameCount - 1) * 192, y: rawValue * 208, width: 192, height: 208)
    }
    static let visits: [Self] = [.wave, .jump, .right, .left, .running, .review]
}

enum NotchGhostSupport {
    static func dimension(_ requested: Double, sideRoom: CGFloat?) -> CGFloat {
        let size = requested.isFinite ? min(72, max(32, requested)) : 52
        return min(CGFloat(size), max(24, (sideRoom ?? CGFloat(size + 8)) - 8))
    }
    static func surface(base: CGSize, cameraWidth: CGFloat, screenWidth: CGFloat, dimension: CGFloat) -> CGSize {
        CGSize(width: min(max(0, screenWidth - 24), max(base.width, cameraWidth + (dimension + 8) * 2)),
               height: max(base.height, dimension + 8))
    }
}
