// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

enum NotchEyesTests {
    static func run(_ suite: TestSuite) {
        NotchGhostTests.run(suite)
        var installations = 0, removals = 0
        var lifecycle: NotchEyesLifecycle? = NotchEyesLifecycle()
        let install: () -> (() -> Void) = { installations += 1; return { removals += 1 } }
        suite.expect(lifecycle?.isActive == false && installations == 0, "inactive feature installs no monitors")
        lifecycle?.activate(install: install); lifecycle?.activate(install: install)
        suite.expect(installations == 1 && lifecycle?.isActive == true, "repeated view updates keep one subscription")
        lifecycle?.stop(); lifecycle?.stop()
        suite.expect(removals == 1 && lifecycle?.isActive == false, "disable cancels monitoring exactly once")
        lifecycle?.activate(install: install); lifecycle = nil
        suite.expect(installations == 2 && removals == 2, "view destruction also releases monitors")
        let domain = "com.onedesk.tests.notch-eyes"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(18.0, forKey: DefaultsKey.notchEyesSize)
        defaults.set(true, forKey: DefaultsKey.notchEyesEnabled)
        suite.expect(defaults.double(forKey: DefaultsKey.notchEyesSize) == 18
                     && defaults.bool(forKey: DefaultsKey.notchEyesEnabled), "eye choices persist in the preferences domain")
        suite.expect(SettingsBackupSupport.exportKeys().isSuperset(of: [DefaultsKey.notchEyesEnabled,
            DefaultsKey.notchEyesSize, DefaultsKey.notchEyesStyle, DefaultsKey.notchEyesSensitivity,
            DefaultsKey.notchEyesBlink, DefaultsKey.notchEyesIdle]), "every eye setting participates in backups")
        let display = CGRect(x: -1920, y: -1080, width: 1920, height: 1080)
        let center = CGPoint(x: display.midX, y: display.maxY)
        suite.expect(NotchEyesSupport.gaze(cursor: center, screen: display, sensitivity: 1) == .zero, "camera origin has neutral gaze")
        for offset in [CGPoint(x: -100, y: 0), CGPoint(x: 100, y: 0), CGPoint(x: 0, y: -100), CGPoint(x: 0, y: 100)] {
            let gaze = NotchEyesSupport.gaze(cursor: CGPoint(x: center.x + offset.x, y: center.y + offset.y), screen: display, sensitivity: 1)
            suite.expect(gaze.x * offset.x + gaze.y * offset.y > 0, "gaze follows each desktop direction")
        }
        for cursor in [CGPoint(x: -10000, y: 10000), CGPoint(x: 10000, y: -10000)] {
            let gaze = NotchEyesSupport.gaze(cursor: cursor, screen: display, sensitivity: 2)
            suite.expect(hypot(gaze.x, gaze.y) <= 1.000001, "off-display diagonal movement stays bounded")
        }
        suite.expect(NotchEyesSupport.gaze(cursor: center, screen: .zero, sensitivity: 1) == .zero, "display removal is safe")
        suite.expect(NotchEyesSupport.eyeSize(100) == 20 && NotchEyesSupport.eyeSize(-1) == 8, "eye geometry clamps corrupt preferences")
        suite.expect(NotchEyesSupport.blinkDelay(unit: 0) == 3 && NotchEyesSupport.blinkDelay(unit: 1) == 8, "blink scheduling is bounded")
        for blocked in 0..<5 {
            suite.expect(!NotchEyesSupport.visible(enabled: blocked != 0, available: blocked != 1, expanded: blocked == 2, activity: blocked == 3, companion: blocked == 4, idleEmpty: true), "disable, uninstall, interaction, activity and Companion suppress eyes")
        }
        suite.expect(NotchEyesSupport.visible(enabled: true, available: true, expanded: false, activity: false, companion: false, idleEmpty: true), "empty resting island allows eyes")
        suite.expect(!AppFeature.notchEyes.installedByDefault && AppFeature.notchEyes.permissions.isEmpty, "eyes are opt in and need no permissions")
        suite.expect(Defaults.registeredDefaults[DefaultsKey.notchEyesSize] as? Double == 14, "eye settings participate in registered defaults and backup")
    }
}
