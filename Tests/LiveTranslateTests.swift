// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

enum LiveTranslateTests {
    static func run(_ suite: TestSuite) {
        suite.expect(LiveTranslateDirection.englishIndonesian.locale == "en-US"
            && LiveTranslateDirection.englishIndonesian.pair == "en|id"
            && LiveTranslateDirection.indonesianEnglish.locale == "id-ID"
            && LiveTranslateDirection.indonesianEnglish.pair == "id|en", "both translation directions map speech and translation languages")
        suite.expect(LiveTranslateSupport.request(text: "  \n", direction: .englishIndonesian) == nil,
                     "empty recognition does not generate network requests")
        let text = "hello & selamat? + 😀"
        if let request = LiveTranslateSupport.request(text: text, direction: .englishIndonesian),
           let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
            suite.expect(components.scheme == "https" && components.host == "api.mymemory.translated.net",
                         "translation requests go only to the disclosed HTTPS provider")
            suite.expect(components.queryItems?.first(where: { $0.name == "q" })?.value == text,
                         "speech query safely encodes Unicode and URL punctuation")
        } else { suite.expect(false, "valid speech creates a translation request") }
        for input in [String(repeating: "word ", count: 200), String(repeating: "😀é中文", count: 100)] {
            let clipped = LiveTranslateSupport.excerpt(input)
            suite.expect(clipped.utf8.count <= 450 && input.trimmingCharacters(in: .whitespaces).hasSuffix(clipped),
                         "long recognition keeps the latest complete Unicode characters within API quota")
        }
        let valid = Data(#"{"responseData":{"translatedText":"Halo dunia"},"responseStatus":200,"responseDetails":""}"#.utf8)
        suite.expect((try? LiveTranslateSupport.decode(valid)) == "Halo dunia", "provider responses decode the translated subtitle")
        for invalid in [Data("invalid".utf8), Data(#"{"responseData":{"translatedText":"quota exceeded"},"responseStatus":429,"responseDetails":"Daily limit"}"#.utf8)] {
            do { _ = try LiveTranslateSupport.decode(invalid); suite.expect(false, "invalid/quota response must fail") }
            catch { suite.expect(true, "provider failures remain errors rather than fake translations") }
        }
        suite.expect(!AppFeature.liveTranslate.installedByDefault && !AppFeature.liveTranslate.monitorsPermissionChanges,
                     "translation is optional and does not add idle permission polling")
        suite.expect(AppFeature.liveTranslate.permissions.contains(.microphone)
            && AppFeature.liveTranslate.permissions.contains(.screenRecording), "selected capture permissions are declared")
        suite.expect(!SettingsBackupSupport.exportKeys().contains(DefaultsKey.liveTranslateConsent)
            && SettingsBackupSupport.exportKeys().contains(DefaultsKey.liveTranslateDirection),
            "direction persists in backups but network consent must be renewed on another installation")
        let domain = "com.onedesk.tests.live-translate"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        defer { defaults.removePersistentDomain(forName: domain) }
        AppFeature.liveTranslate.enableOnFirstInstall(in: defaults, savedValues: [:])
        suite.expect(!defaults.bool(forKey: DefaultsKey.liveTranslateEnabled), "installing translation never starts recording or networking")
        defaults.set(true, forKey: AppFeature.liveTranslate.availabilityKey)
        defaults.set(true, forKey: DefaultsKey.liveTranslateEnabled)
        defaults.set(true, forKey: DefaultsKey.liveTranslateNotch)
        defaults.set(true, forKey: DefaultsKey.notchEnabled)
        defaults.set(true, forKey: AppFeature.notch.availabilityKey)
        suite.expect(NotchSupport.routes(.translation, in: defaults), "enabled translation can present through the existing island notice router")
        suite.expect(NotchSupport.modules(in: defaults).contains(.translate)
            && NotchModule.translate.shortcutKey == "l",
            "installed Live Translate has its own island section and direct navigation key")
        defaults.set(false, forKey: AppFeature.liveTranslate.availabilityKey)
        suite.expect(!NotchSupport.modules(in: defaults).contains(.translate)
            && !NotchSupport.routes(.translation, in: defaults), "uninstalled translation cannot present island notices")
        for event in NotchEvent.allCases where event != .translation {
            suite.expect(event.priority > NotchEvent.translation.priority, "translation yields to every existing island notice")
        }
    }
}
