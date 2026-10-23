// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import AppKit
import SwiftUI
import QuartzCore

struct NotchGhostView: NSViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(DefaultsKey.notchPetAnimations) private var animations = true
    func makeNSView(context: Context) -> NotchGhostHost { NotchGhostHost(frame: .zero) }
    func updateNSView(_ host: NotchGhostHost, context: Context) { host.configure(animated: animations && !reduceMotion) }
    static func dismantleNSView(_ host: NotchGhostHost, coordinator: ()) { host.stop() }
}

final class NotchGhostHost: NSView {
    private let sprite = CALayer()
    private var frames: [NotchGhostAction: [CGImage]] = [:]
    private var work: DispatchWorkItem?
    private var loading: Task<Void, Never>?
    private var animated = true
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        sprite.contentsGravity = .resizeAspect
        sprite.magnificationFilter = .nearest
        sprite.minificationFilter = .nearest
        layer?.addSublayer(sprite)
    }
    required init?(coder: NSCoder) { return nil }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsLayout = true
    }
    override func layout() {
        super.layout()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        sprite.frame = bounds; sprite.contentsScale = window?.backingScaleFactor ?? 2
        CATransaction.commit()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { stop() } else { start() }
    }
    func configure(animated: Bool) {
        guard self.animated != animated else { return }
        self.animated = animated
        play(.idle)
    }
    private func start() {
        guard loading == nil else { return }
        if !frames.isEmpty { play(.idle); return }
        loading = Task { [weak self] in
            let decoded = await Task.detached(priority: .utility) { NotchGhostAssets.frames() }.value
            guard !Task.isCancelled, let self, self.window != nil else { return }
            self.frames = decoded
            self.loading = nil
            self.play(.idle)
        }
    }
    private func play(_ action: NotchGhostAction) {
        work?.cancel(); work = nil
        sprite.removeAllAnimations()
        guard window != nil, let images = frames[action], !images.isEmpty else { return }
        CATransaction.begin(); CATransaction.setDisableActions(true)
        sprite.contents = images[0]
        CATransaction.commit()
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        let motion = CAKeyframeAnimation(keyPath: "contents")
        motion.values = images
        motion.duration = action.duration
        motion.calculationMode = .discrete
        motion.repeatCount = action == .idle ? .infinity : 1
        sprite.add(motion, forKey: "ghost.frames")
        let next = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.play(action == .idle ? (NotchGhostAction.visits.randomElement() ?? .wave) : .idle)
        }
        work = next
        DispatchQueue.main.asyncAfter(deadline: .now() + (action == .idle ? Double.random(in: 3...6) : action.duration), execute: next)
    }
    func stop() {
        loading?.cancel(); loading = nil
        work?.cancel(); work = nil
        sprite.removeAllAnimations()
        frames.removeAll()
        sprite.contents = nil
    }
    deinit { stop() }
}
