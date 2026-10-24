# Live Translate development MVP

Install **Live Translate** in Settings → Features, then open its settings in
Quick Tools. Enable it, choose English → Indonesian or Indonesian → English,
choose Microphone or System audio, read the disclosure, consent, and press Start.
With Dynamic Island enabled, Start and Open route to its **Live Translate** section
(also available in the island section picker, shortcut letter L). Full captions and
controls live there. There is no bottom-of-screen subtitle panel. A separate
control window remains a fallback only when Dynamic Island is disabled. Stop always cancels pending start,
recognition, capture, translation, scheduled session rotation and island subtitle display.
Closing the separate controls, locking/sleeping the Mac, switching sessions,
disabling or uninstalling the module also stops capture. No automatic resume.

Apple Speech recognizes the selected source language. On-device recognition is
required when the recognizer reports support; otherwise Apple's network service
is used. Language availability depends on the host and service. A missing/denied
speech or audio permission is reported in the UI. macOS 14 system audio uses
ScreenCaptureKit and requires screen/system audio recording permission; microphone
mode uses AVAudioEngine and microphone permission. Only the selected source is
captured. System capture excludes ONE DESK's own audio. No video output is attached.

MyMemory's HTTPS API translates the latest bounded excerpt into the target language.
This is an online development provider with quotas and service availability limits,
not an offline translation engine. Explicit consent is required before Start;
consent is excluded from settings backups. No provider key is embedded. Speech
text is URL-encoded for the provider's GET endpoint and may be retained by that
provider under its own terms. ONE DESK does not log or save audio/transcript files.
Recognition and translation excerpts remain in memory until cleared or quit.

Partial speech updates debounce for 800 ms; stale replies are discarded after a
new request or Stop. Long excerpts keep the latest complete Unicode characters
within 450 UTF-8 bytes. Recognition sessions rotate after 45 seconds, so a small
boundary gap is possible. This is caption translation, not synchronized dubbing;
latency, accuracy and Indonesian speech availability require real-Mac testing.
MyMemory includes public translation-memory matches which can be incorrect (a
synthetic ID→EN greeting check already exposed a bad match). Treat this provider
as an MVP, not authoritative translation; provider replacement is a priority.
Translation errors and provider quota responses are visible and do not masquerade
as successful captions.

Subtitles use the existing island notice host and animation architecture, with a
lowest-priority translation event. Existing notices always take priority. The
island's expanded Live Translate section retains full text and Start/Stop controls;
the compact notice can truncate. The previous floating subtitle preference is
ignored for compatibility: no separate subtitle window is created.

The optional global start/stop shortcut is Control–Option–Shift–T using the existing
QuickToolHotkey lifecycle. Conflicts are reported; it is disabled by default.
This first version exposes a fixed shortcut. More provider choices, offline
translation where supported, configurable shortcut editing, transcript export,
word-level timing and per-app system audio selection remain future work.

Tests cover directions/locales, request encoding, Unicode/byte bounds, provider
success/quota/malformed responses, consent backup exclusion, opt-in lifecycle
policy, feature/notice routing and notice priority. Native audio, permissions,
network translation and caption placement need integration testing on a real Mac.
CI never records audio or calls the provider.
