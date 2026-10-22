// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import AppKit
import SwiftUI
import QuartzCore

/// Lives inside the existing resting strip, never creates a window.
struct NotchEyesView: NSViewRepresentable {
    var cameraWidth: CGFloat
    var wingWidth: CGFloat
    @AppStorage(DefaultsKey.notchEyesSize) private var size = 14.0
    @AppStorage(DefaultsKey.notchEyesSensitivity) private var sensitivity = 1.0
    @AppStorage(DefaultsKey.notchEyesBlink) private var blink = true
    @AppStorage(DefaultsKey.notchEyesIdle) private var idle = true
    @AppStorage(DefaultsKey.notchEyesStyle) private var style = "round"
    func makeNSView(context: Context) -> NotchEyesHost { NotchEyesHost(frame: .zero) }
    func updateNSView(_ view: NotchEyesHost, context: Context) {
        view.configure(camera: cameraWidth, wing: wingWidth, size: size,
                       sensitivity: sensitivity, blink: blink, idle: idle, style: style)
    }
    static func dismantleNSView(_ view: NotchEyesHost, coordinator: ()) { view.stop() }
}

final class NotchEyesHost: NSView {
    private let eyes = [CAShapeLayer(), CAShapeLayer()]
    private let pupils = [CAShapeLayer(), CAShapeLayer()]
    private let tracking = NotchEyesLifecycle()
    private var scheduled: DispatchWorkItem?
    private var camera: CGFloat = 0
    private var wing: CGFloat = 0
    private var size: CGFloat = 14
    private var sensitivity = 1.0
    private var blinks = true
    private var idles = true
    private var style = "round"
    private var lastMovement = Date.distantPast
    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        for i in eyes.indices {
            eyes[i].fillColor = NSColor.white.cgColor
            pupils[i].fillColor = NSColor.black.cgColor
            eyes[i].addSublayer(pupils[i]); layer?.addSublayer(eyes[i])
        }
    }
    required init?(coder: NSCoder) { return nil }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { stop() } else { start() }
    }
    func configure(camera: CGFloat, wing: CGFloat, size: Double, sensitivity: Double,
                   blink: Bool, idle: Bool, style: String) {
        self.camera = camera; self.wing = wing
        self.size = NotchEyesSupport.eyeSize(size); self.sensitivity = sensitivity
        blinks = blink; idles = idle; self.style = style
        needsLayout = true
        if window != nil { schedule() }
    }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsLayout = true
    }
    override func layout() {
        super.layout()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        let diameter = min(size, max(4, bounds.height - 6), max(4, wing - 8))
        for i in eyes.indices {
            let sign: CGFloat = i == 0 ? -1 : 1
            eyes[i].bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            eyes[i].position = CGPoint(x: bounds.midX + sign * (camera / 2 + wing / 2), y: bounds.midY)
            let height = style == "slim" ? diameter * 0.6 : diameter
            eyes[i].path = CGPath(ellipseIn: CGRect(x: 0, y: (diameter-height)/2, width: diameter, height: height), transform: nil)
            pupils[i].path = CGPath(ellipseIn: CGRect(x: -diameter*0.16, y: -diameter*0.16, width: diameter*0.32, height: diameter*0.32), transform: nil)
            for item in [eyes[i], pupils[i]] { item.contentsScale = window?.backingScaleFactor ?? 2 }
        }
        CATransaction.commit()
        followCursor()
    }
    private func start() {
        tracking.activate { [weak self] in
            let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
            let global = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in self?.followCursor() }
            let local = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
                self?.followCursor(); return event
            }
            return {
                if let global { NSEvent.removeMonitor(global) }
                if let local { NSEvent.removeMonitor(local) }
            }
        }
        schedule()
    }
    private func followCursor() {
        guard window?.isVisible == true, let screen = window?.screen else { return }
        lastMovement = Date()
        move(NotchEyesSupport.gaze(cursor: NSEvent.mouseLocation, screen: screen.frame, sensitivity: sensitivity))
    }
    private func move(_ gaze: CGPoint) {
        for i in eyes.indices {
            let d = eyes[i].bounds.width
            let target = CGPoint(x: d/2 + gaze.x*d*0.18, y: d/2 + gaze.y*d*(style == "slim" ? 0.08 : 0.18))
            let from = pupils[i].presentation()?.position ?? pupils[i].position
            CATransaction.begin(); CATransaction.setDisableActions(true)
            pupils[i].position = target
            CATransaction.commit()
            if !reduceMotion {
                let animation = CABasicAnimation(keyPath: "position")
                animation.fromValue = NSValue(point: from); animation.toValue = NSValue(point: target)
                animation.duration = 0.16; animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                pupils[i].add(animation, forKey: "gaze")
            } else { pupils[i].removeAnimation(forKey: "gaze") }
        }
    }
    private func schedule() {
        scheduled?.cancel(); scheduled = nil
        guard (blinks || idles), !reduceMotion, window != nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.window != nil else { return }
            if self.blinks && !self.reduceMotion {
                for eye in self.eyes {
                    let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
                    let twice = Int.random(in: 0..<8) == 0
                    animation.values = twice ? [1, 0.08, 1, 1, 0.08, 1] : [1, 0.08, 1]
                    animation.duration = twice ? 0.48 : 0.20
                    eye.add(animation, forKey: "blink")
                }
            }
            if self.idles && !self.reduceMotion && Date().timeIntervalSince(self.lastMovement) > 4 {
                self.move(CGPoint(x: Double.random(in: -0.2...0.2), y: Double.random(in: -0.12...0.12)))
            }
            self.schedule()
        }
        scheduled = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotchEyesSupport.blinkDelay(unit: Double.random(in: 0...1)), execute: work)
    }
    func stop() {
        tracking.stop()
        scheduled?.cancel(); scheduled = nil
        for item in eyes + pupils { item.removeAllAnimations() }
    }
    deinit { stop() }
}
