// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import AppKit
import SwiftUI
import QuartzCore

private struct NotchGhostOverride: EnvironmentKey { static let defaultValue: Bool? = nil }
extension EnvironmentValues {
    var notchGhostOverride: Bool? {
        get { self[NotchGhostOverride.self] }
        set { self[NotchGhostOverride.self] = newValue }
    }
}

/// Sprite skin attached INSIDE the original Companion rig. The original hopper,
/// squasher, path timelines, clipping, window host and cancellation remain owners.
final class NotchGhostRig {
    let root = CALayer()
    private var frames: [NotchGhostAction: [CGImage]] = [:]
    private var loading: Task<Void, Never>?
    private var reset: DispatchWorkItem?
    private var generation = 0
    private var active = false
    private var visible = false
    private var animates = true
    private var current = NotchGhostAction.idle
    init() {
        root.contentsGravity = .resizeAspect
        root.magnificationFilter = .nearest
        root.minificationFilter = .nearest
        root.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull(), "hidden": NSNull()]
    }
    func configure(active: Bool, size: CGFloat, scale: CGFloat, reduceMotion: Bool) {
        let animationChanged = animates != (!reduceMotion && UserDefaults.standard.bool(forKey: DefaultsKey.notchPetAnimations))
        animates = !reduceMotion && UserDefaults.standard.bool(forKey: DefaultsKey.notchPetAnimations)
        let changed = self.active != active
        self.active = active
        root.isHidden = !active
        root.frame = CGRect(x: 0, y: 0, width: size, height: size)
        root.contentsScale = scale
        guard active else { stop(); return }
        if frames.isEmpty, loading == nil {
            let generation = self.generation
            loading = Task { [weak self] in
                let decoded = await Task.detached(priority: .utility) { NotchGhostAssets.frames() }.value
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.active, self.generation == generation else { return }
                    self.frames = decoded; self.loading = nil
                    self.play(self.current)
                }
            }
        } else if changed || animationChanged { play(current) }
    }
    func setVisible(_ visible: Bool) {
        guard self.visible != visible else { return }
        self.visible = visible
        if visible { play(current) }
        else { reset?.cancel(); reset = nil; root.removeAllAnimations() }
    }
    func play(_ action: NotchGhostAction, hold: TimeInterval? = nil, then nextAction: NotchGhostAction = .idle) {
        current = action
        reset?.cancel(); reset = nil
        root.removeAllAnimations()
        guard active, let images = frames[action], !images.isEmpty else { return }
        root.contents = images[0]
        guard visible, animates else { return }
        let motion = CAKeyframeAnimation(keyPath: "contents")
        motion.values = images; motion.duration = action.duration
        motion.calculationMode = .discrete
        motion.repeatCount = action == .idle || hold != nil ? .infinity : 1
        root.add(motion, forKey: "ghost.frames")
        if action != .idle {
            let next = DispatchWorkItem { [weak self] in self?.play(nextAction) }
            reset = next
            DispatchQueue.main.asyncAfter(deadline: .now() + (hold ?? action.duration), execute: next)
        }
    }
    private func stop() {
        generation += 1
        loading?.cancel(); loading = nil
        reset?.cancel(); reset = nil
        root.removeAllAnimations(); root.contents = nil
        frames.removeAll(); current = .idle
    }
    deinit { stop() }
}
