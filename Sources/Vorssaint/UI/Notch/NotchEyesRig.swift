// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import AppKit
import QuartzCore

/// A pair of eyes inside the Companion's existing moving/visiting layer hierarchy.
/// Mouse events update only pupil layers; no SwiftUI state or display timer.
final class NotchEyesRig {
    let root = CALayer()
    private let eyes = [CAShapeLayer(), CAShapeLayer()]
    private let pupils = [CAShapeLayer(), CAShapeLayer()]
    private let tracking = NotchEyesLifecycle()
    private var scheduled: DispatchWorkItem?
    private var active = false
    private var visible = false
    private var reduceMotion = false
    private var slim = false
    private var lastMovement = Date.distantPast
    init() {
        root.actions = ["bounds": NSNull(), "position": NSNull(), "hidden": NSNull()]
        for i in eyes.indices {
            eyes[i].fillColor = NSColor.white.cgColor
            pupils[i].fillColor = NSColor.black.cgColor
            eyes[i].actions = root.actions; pupils[i].actions = root.actions
            eyes[i].addSublayer(pupils[i]); root.addSublayer(eyes[i])
        }
    }
    func configure(active: Bool, size: CGFloat, scale: CGFloat, reduceMotion: Bool, separation: CGFloat) {
        self.active = active; self.reduceMotion = reduceMotion
        slim = UserDefaults.standard.string(forKey: DefaultsKey.notchEyesStyle) == "slim"
        CATransaction.begin(); CATransaction.setDisableActions(true)
        root.isHidden = !active
        root.frame = CGRect(x: 0, y: 0, width: size, height: size)
        let diameter = CGFloat(NotchEyesSupport.eyeSize(UserDefaults.standard.double(forKey: DefaultsKey.notchEyesSize)))
        for i in eyes.indices {
            eyes[i].bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            eyes[i].position = CGPoint(x: size / 2 + (i == 0 ? -1 : 1) * (separation > 0 ? separation : diameter * 0.65), y: size / 2)
            let height = slim ? diameter * 0.6 : diameter
            eyes[i].path = CGPath(ellipseIn: CGRect(x: 0, y: (diameter - height) / 2,
                                                   width: diameter, height: height), transform: nil)
            pupils[i].path = CGPath(ellipseIn: CGRect(x: -diameter * 0.16, y: -diameter * 0.16,
                width: diameter * 0.32, height: diameter * 0.32), transform: nil)
            eyes[i].contentsScale = scale; pupils[i].contentsScale = scale
        }
        CATransaction.commit()
        if !active { stop() } else { sync() }
    }
    func setVisible(_ visible: Bool) {
        guard self.visible != visible else { return }
        self.visible = visible; sync()
    }
    private func sync() {
        guard active, visible else { stop(); return }
        tracking.activate { [weak self] in
            let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
            let global = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in self?.follow() }
            let local = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in self?.follow(); return event }
            return {
                if let global { NSEvent.removeMonitor(global) }
                if let local { NSEvent.removeMonitor(local) }
            }
        }
        if reduceMotion { for layer in eyes + pupils { layer.removeAllAnimations() } }
        if scheduled == nil { schedule() }
        follow()
    }
    private func follow() {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else { return }
        lastMovement = Date()
        move(NotchEyesSupport.gaze(cursor: point, screen: screen.frame,
            sensitivity: UserDefaults.standard.double(forKey: DefaultsKey.notchEyesSensitivity)))
    }
    private func move(_ gaze: CGPoint) {
        for i in pupils.indices {
            let d = eyes[i].bounds.width
            let target = CGPoint(x: d / 2 + gaze.x * d * 0.18, y: d / 2 + gaze.y * d * (slim ? 0.08 : 0.18))
            let from = pupils[i].presentation()?.position ?? pupils[i].position
            CATransaction.begin(); CATransaction.setDisableActions(true)
            pupils[i].position = target; CATransaction.commit()
            if !reduceMotion {
                let animation = CABasicAnimation(keyPath: "position")
                animation.fromValue = NSValue(point: from); animation.toValue = NSValue(point: target)
                animation.duration = 0.16; animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                pupils[i].add(animation, forKey: "gaze")
            }
        }
    }
    func react() {
        guard active, visible, !reduceMotion else { return }
        for eye in eyes {
            let blink = CAKeyframeAnimation(keyPath: "transform.scale.y")
            blink.values = [1, 0.08, 1]; blink.duration = 0.22
            eye.add(blink, forKey: "expression")
        }
    }
    private func schedule() {
        guard active, visible, !reduceMotion,
              UserDefaults.standard.bool(forKey: DefaultsKey.notchEyesBlink)
                || UserDefaults.standard.bool(forKey: DefaultsKey.notchEyesIdle) else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.scheduled = nil
            if UserDefaults.standard.bool(forKey: DefaultsKey.notchEyesBlink) { self.react() }
            if UserDefaults.standard.bool(forKey: DefaultsKey.notchEyesIdle), Date().timeIntervalSince(self.lastMovement) > 4 {
                self.move(CGPoint(x: Double.random(in: -0.2...0.2), y: Double.random(in: -0.12...0.12)))
            }
            self.schedule()
        }
        scheduled = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotchEyesSupport.blinkDelay(unit: Double.random(in: 0...1)), execute: work)
    }
    private func stop() {
        tracking.stop(); scheduled?.cancel(); scheduled = nil
        for layer in eyes + pupils { layer.removeAllAnimations() }
    }
    deinit { stop() }
}
