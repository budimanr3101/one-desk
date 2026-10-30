// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import AppKit
import AVFoundation
import Speech
import ScreenCaptureKit
import SwiftUI

private final class TranslationAudioOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    let request: SFSpeechAudioBufferRecognitionRequest
    var failed: ((Error) -> Void)?
    init(request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, CMSampleBufferIsValid(sampleBuffer) else { return }
        request.appendAudioSampleBuffer(sampleBuffer)
    }
    func stream(_ stream: SCStream, didStopWithError error: Error) { failed?(error) }
}

/// Main-thread service. Audio callbacks only append to the recognition request.
/// No audio capture, permission prompt or network traffic occurs at startup.
final class LiveTranslateService: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = LiveTranslateService()
    @Published private(set) var running = false
    @Published private(set) var starting = false
    @Published private(set) var transcript = ""
    @Published private(set) var translation = ""
    @Published private(set) var error: String?
    @Published private(set) var shortcutFailed = false
    private var session: UUID?
    private var recognitionID = UUID()
    private var startTask: Task<Void, Never>?
    private var rotateTask: Task<Void, Never>?
    private var speechTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var engine: AVAudioEngine?
    private var stream: SCStream?
    private var output: TranslationAudioOutput?
    private var submittedWordCount = 0
    private var latestRecognizedWords: [String] = []
    private var speechPauseTask: Task<Void, Never>?
    private var translationQueue: [String] = []
    private var translationWorker: Task<Void, Never>?
    private var translatedPhrases: [String] = []
    private var sessionObservers: [NSObjectProtocol] = []
    private var lockObserver: NSObjectProtocol?
    private var direction = LiveTranslateDirection.englishIndonesian
    private var input = LiveTranslateInput.microphone
    private let hotkey = QuickToolHotkey(id: 82)
    private var controls: NSPanel?
    private let network = URLSession(configuration: .ephemeral)
    override private init() {
        super.init()
        hotkey.onPress = { [weak self] in
            guard let self else { return }
            if self.running || self.starting { self.stop() }
            else if UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateConsent) { self.start() }
            else { self.show() }
        }
    }
    func syncWithPreferences() {
        let enabled = AppFeature.liveTranslate.isAvailable && UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateEnabled)
        shortcutFailed = !hotkey.sync(enabled: enabled && UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateShortcutEnabled),
            shortcut: GlobalShortcut(keyCode: 17, modifiers: [.control, .option, .shift]),
            storageKey: DefaultsKey.liveTranslateShortcut)
        if !enabled || !UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateConsent) { stop() }
        if !AppFeature.liveTranslate.isAvailable { controls?.close(); controls = nil }
    }
    func show() {
        guard AppFeature.liveTranslate.isAvailable else { return }
        if NotchSupport.isEnabled() {
            NotchService.shared.open(.translate)
            return
        }
        if controls == nil {
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 580),
                styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            panel.title = "ONE DESK · Live Translate"; panel.isReleasedWhenClosed = false; panel.delegate = self
            panel.contentView = NSHostingView(rootView: LiveTranslateSettings().padding(20))
            panel.center(); controls = panel
        }
        controls?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func start() {
        guard !running, !starting, AppFeature.liveTranslate.isAvailable,
              UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateEnabled),
              UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateConsent) else { return }
        direction = LiveTranslateDirection(rawValue: UserDefaults.standard.string(forKey: DefaultsKey.liveTranslateDirection) ?? "") ?? .englishIndonesian
        input = LiveTranslateInput(rawValue: UserDefaults.standard.string(forKey: DefaultsKey.liveTranslateInput) ?? "") ?? .microphone
        if NotchSupport.isEnabled() { NotchService.shared.open(.translate) }
        let token = UUID(); session = token; starting = true; error = nil
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            sessionObservers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.stop() })
        }
        lockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in self?.stop() }
        transcript = ""; translation = ""
        submittedWordCount = 0; latestRecognizedWords = []
        translationQueue.removeAll(); translatedPhrases.removeAll()
        startTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let speech = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
                }
                guard self.session == token, !Task.isCancelled else { return }
                guard speech == .authorized else { throw Self.failure("Allow Speech Recognition for ONE DESK in System Settings → Privacy & Security.") }
                if self.input == .microphone {
                    let allowed = await AVCaptureDevice.requestAccess(for: .audio)
                    guard self.session == token, !Task.isCancelled else { return }
                    guard allowed else { throw Self.failure("Allow Microphone access for ONE DESK in System Settings.") }
                }
                try await self.capture(token: token)
                guard self.session == token, !Task.isCancelled else { return }
                self.starting = false; self.running = true
            } catch {
                guard self.session == token else { return }
                self.stop(); self.error = error.localizedDescription
            }
        }
    }
    @MainActor private func capture(token: UUID) async throws {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: direction.locale)), recognizer.isAvailable else {
            throw Self.failure("Speech recognition for \(direction.locale) is currently unavailable. Check network access and installed speech languages.")
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        submittedWordCount = 0
        latestRecognizedWords = []
        speechPauseTask?.cancel(); speechPauseTask = nil
        self.request = request
        let epoch = UUID(); recognitionID = epoch
        speechTask = recognizer.recognitionTask(with: request) { [weak self] result, failure in
            DispatchQueue.main.async {
                guard let self, self.session == token, self.recognitionID == epoch else { return }
                if let result {
                    self.transcript = String(result.bestTranscription.formattedString.suffix(2000))
                    self.submit(self.transcript, final: result.isFinal)
                    if result.isFinal { self.rotate(token: token, after: 0.3) }
                } else if let failure {
                    self.stop(); self.error = failure.localizedDescription
                }
            }
        }
        if input == .microphone {
            let engine = AVAudioEngine()
            let node = engine.inputNode
            let format = node.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { throw Self.failure("No microphone is available.") }
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            self.engine = engine
            engine.prepare(); try engine.start()
        } else {
            // macOS 14 ScreenCaptureKit is the system-audio path; no microphone tap.
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard session == token, recognitionID == epoch, !Task.isCancelled else { return }
            guard let display = content.displays.first else { throw Self.failure("No display is available for system audio capture.") }
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.capturesAudio = true; config.excludesCurrentProcessAudio = true
            config.sampleRate = 16000; config.channelCount = 1
            // Only audio output is attached; no video frames are retained.
            config.width = 16; config.height = 16
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
            let output = TranslationAudioOutput(request: request)
            output.failed = { [weak self] failure in
                DispatchQueue.main.async {
                    guard let self, self.session == token, self.recognitionID == epoch else { return }
                    self.stop(); self.error = failure.localizedDescription
                }
            }
            let stream = SCStream(filter: filter, configuration: config, delegate: output)
            try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.onedesk.live-translate.audio"))
            self.stream = stream; self.output = output
            try await stream.startCapture()
            guard session == token, !Task.isCancelled else { try? await stream.stopCapture(); return }
        }
        rotate(token: token, after: 45)
    }
    private func rotate(token: UUID, after delay: TimeInterval) {
        rotateTask?.cancel()
        rotateTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { return }
            guard let self, self.session == token else { return }
            let previous = self.clearCapture()
            if let previous { try? await previous.stopCapture() }
            guard self.session == token, !Task.isCancelled else { return }
            do { try await self.capture(token: token) }
            catch { if self.session == token { self.stop(); self.error = error.localizedDescription } }
        }
    }
    private func submit(_ text: String, final: Bool) {
        let words = LiveTranslateSupport.words(text)
        latestRecognizedWords = words

        // Send full five-word phrases during continuous speech instead of
        // waiting for a complete sentence or a long recognition pause.
        while words.count - submittedWordCount >= 5 {
            enqueueTranslation(LiveTranslateSupport.phrase(words, from: submittedWordCount, count: 5))
            submittedWordCount += 5
        }

        speechPauseTask?.cancel(); speechPauseTask = nil
        let remaining = words.count - submittedWordCount
        guard remaining > 0 else { return }
        if final {
            flushRecognizedTail(minimumWords: 1)
        } else if remaining >= 2 {
            // Speech recognition revises partial words frequently. A short
            // pause lets those settle, while keeping captions responsive.
            speechPauseTask = Task { @MainActor [weak self] in
                do { try await Task.sleep(nanoseconds: 450_000_000) } catch { return }
                guard let self, self.session != nil else { return }
                self.flushRecognizedTail(minimumWords: 2)
            }
        }
    }

    private func flushRecognizedTail(minimumWords: Int) {
        let remaining = latestRecognizedWords.count - submittedWordCount
        guard remaining >= minimumWords else { return }
        enqueueTranslation(LiveTranslateSupport.phrase(latestRecognizedWords,
                                                        from: submittedWordCount,
                                                        count: min(5, remaining)))
        submittedWordCount += min(5, remaining)
    }

    private func enqueueTranslation(_ phrase: String) {
        guard !phrase.isEmpty else { return }
        translationQueue.append(phrase)
        guard translationWorker == nil, let token = session else { return }
        let direction = self.direction
        translationWorker = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.session == token, !self.translationQueue.isEmpty {
                let phrase = self.translationQueue.removeFirst()
                guard let request = LiveTranslateSupport.request(text: phrase, direction: direction) else { continue }
                do {
                    let (data, response) = try await self.network.data(for: request)
                    guard !Task.isCancelled, self.session == token else { return }
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count <= 131072 else {
                        throw Self.failure("Translation service rejected the request. Try again later.")
                    }
                    self.translatedPhrases.append(try LiveTranslateSupport.decode(data))
                    self.translation = String(self.translatedPhrases.joined(separator: " ").suffix(2000))
                    self.error = nil
                    self.presentTranslation()
                } catch is CancellationError { return }
                catch {
                    guard !Task.isCancelled, self.session == token else { return }
                    self.error = error.localizedDescription
                }
            }
            self.translationWorker = nil
        }
    }
    private func clearCapture() -> SCStream? {
        recognitionID = UUID()
        engine?.stop(); engine?.inputNode.removeTap(onBus: 0); engine = nil
        request?.endAudio(); speechTask?.cancel(); speechTask = nil; request = nil
        let previous = stream
        if let output { try? previous?.removeStreamOutput(output, type: .audio) }
        output?.failed = nil; output = nil; stream = nil
        return previous
    }
    func stop() {
        session = nil; recognitionID = UUID()
        for observer in sessionObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        sessionObservers.removeAll()
        if let lockObserver { DistributedNotificationCenter.default().removeObserver(lockObserver) }
        lockObserver = nil
        startTask?.cancel(); startTask = nil
        rotateTask?.cancel(); rotateTask = nil
        speechPauseTask?.cancel(); speechPauseTask = nil
        translationWorker?.cancel(); translationWorker = nil
        translationQueue.removeAll()
        let previous = clearCapture()
        if let previous { Task { try? await previous.stopCapture() } }
        starting = false; running = false
        NotchService.shared.dismissTranslationNotice()
    }
    func clearText() {
        speechPauseTask?.cancel(); speechPauseTask = nil
        translationWorker?.cancel(); translationWorker = nil
        translationQueue.removeAll()
        transcript = ""; translation = ""; error = nil
        submittedWordCount = latestRecognizedWords.count
        translatedPhrases.removeAll()
        NotchService.shared.dismissTranslationNotice()
    }
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window === controls { stop() }
    }
    func suspend() { hotkey.unregister(); stop(); controls?.close() }
    private func presentTranslation() {
        if UserDefaults.standard.bool(forKey: DefaultsKey.liveTranslateNotch),
           NotchService.shared.notice == nil || NotchService.shared.notice?.event == .translation {
            NotchService.shared.show(NotchNotice(event: .translation, title: "Live Translate", detail: translation, symbol: "character.bubble"))
        }
    }
    private static func failure(_ message: String) -> NSError {
        NSError(domain: "LiveTranslate", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
