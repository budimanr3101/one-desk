# ONE DESK

ONE DESK is an independent, GPL-3.0-or-later development fork of
[Vorssaint](https://github.com/vorssaint/vorssaint-utils), based on upstream
commit `02a13224062342f289753733487f6da85db4e332`. It is not an official Vorssaint
release and is not endorsed by its maintainers. Original authorship, license,
utilities, Companion, and the native Dynamic Island implementation are retained.

Target: Apple Silicon, macOS 14 Sonoma or later. Swift, SwiftUI, AppKit and Core
Animation; no web shell or additional runtime dependencies.

## Development status

The feature branch is published in
[budimanr3101/one-desk](https://github.com/budimanr3101/one-desk/tree/feat/onedesk-foundation).
[Foundation development CI passed](https://github.com/budimanr3101/one-desk/actions/runs/39884700825): native ARM64 build, self-test,
113,340 test checks, packaging and artifact uploads all succeeded.
Download the [development app ZIP](https://github.com/budimanr3101/one-desk/actions/runs/39884700825/artifacts/12471958180) or [DMG](https://github.com/budimanr3101/one-desk/actions/runs/39884700825/artifacts/12472525943).
These builds are ad-hoc signed and are not notarized.
See [VALIDATION.md](VALIDATION.md) for measured results and
[cloud build instructions](docs/CLOUD-BUILDS.md) for the workflow. Real-Mac visual
and hardware verification remains pending.

## Notch Eyes

Install **Notch Eyes** in Settings → Features → Dynamic Island. Open the Dynamic
Island settings → Notch Eyes tab and enable the feature. Enable the island and set its idle content
to **None**. Disable Companion to allow the eyes to appear. The island needs room
for its existing wings; the physical camera cutout cannot display pixels.

Settings: round/slim eyes, size (8–20 points), cursor sensitivity (0.2–2), natural
blinking and idle gaze. Preferences persist and participate in settings backups.
The feature is opt in and requires no additional system permission. Global mouse
movement is handled locally; cursor coordinates are not stored or transmitted.

Eyes yield to activities, notifications, Companion, drag/drop, capture controls,
expanded/peek interactions, and hidden/fullscreen states. Companion remains an
independent feature. New settings currently use English labels in all locales;
existing translated utilities and rebranded permission prompts remain available.

## Ghost pet appearance

The new Ghost update is submitted for macOS CI; the successful foundation build
above predates it. In the Notch Eyes settings choose **Ghost · Petdex**, then
**Download Ghost from Petdex**. Ghost appears as a larger animated pet (default
52 points) with idle, wave, jump, walk and expression actions; no cursor tracking.
A preview, size slider and animation toggle are provided. It yields to existing
island content and Companion. See [Ghost setup and asset provenance](docs/GHOST-PET.md).
The image is fetched only on request and is not bundled with ONE DESK because
its package does not declare redistribution rights.

## Cloud builds

Push `feat/onedesk-foundation` to your fork. The ONE DESK development workflow
builds, self-tests, runs all unit tests, packages the app/DMG and uploads artifacts.
It checks `uname -m` and the executable architecture rather than trusting the
runner label. Artifact names include `ONE-DESK-dev-macos-arm64`,
`ONE-DESK-dev-DMG` and `ONE-DESK-test-results`. Source accompanies the packages.

On a macOS runner the equivalent commands are:

```sh
./build.sh
./build/ONEDESK --selftest
./build.sh --test
./Tools/make-dmg.sh
```

`Package.swift` supports editor indexing; `build.sh` assembles the complete app,
fan helper, Now Playing adapter, icon and resources. Default output:
`build/stage/ONE DESK.app`. `--dev` uses executable `ONEDESKDeveloper`, a separate
`com.onedesk.app.dev` identity and unoptimized compilation.

## Identity and distribution

`com.onedesk.app` is provisional; replace it before public distribution if needed.
Preferences, caches, helper identifiers and privileged rule paths are separated
from Vorssaint. Installation/uninstallation never retires upstream apps. The
original application icon assets are removed; `Tools/MakeIcon.swift` generates an
original vector desk glyph, iconset, ICNS and menu glyph.

CI uses ad-hoc signing with signature verification. These builds are **not
notarized**; Gatekeeper may block downloaded apps, and permissions may need to be
re-granted after rebuilding. Use macOS's explicit Open / Privacy & Security
workflow only for a build you trust. Do not disable Gatekeeper globally.
Developer ID signing/notarization and privileged fan-helper trust are unconfigured.
The fan helper fails closed without an independent signing identity; the target
MacBook Air M2 has no fan.

Self-updates and upstream release media are disabled for this development phase.
Cloud screenshot/recording upload and feedback use a reserved `.invalid` endpoint
until independent hosting is configured; local capture/export remains intact.
Existing support/donation links refer to the **upstream authors**, not ONE DESK.
`OneDeskRepositoryURL` is configured to the independent fork.

## Documentation and license

- [Architecture and animation decisions](ARCHITECTURE.md)
- [Validation and real-Mac checklist](VALIDATION.md)
- [Future module roadmap](ROADMAP.md)
- [Cloud builds and fork connection](docs/CLOUD-BUILDS.md)
- [GPL-3.0-or-later license](LICENSE), [upstream trademark policy](TRADEMARKS.md)

Preserve source headers and copyright notices. Redistribution must include the
corresponding source under GPL-3.0-or-later. The original contributor guide remains
in [CONTRIBUTING.md](CONTRIBUTING.md); its upstream commands and release guidance
are historical context, superseded for this fork by the cloud build instructions.

### Live Translate (development MVP)

Install **Live Translate** from Features, then open **Quick Tools → Live Translate**.
Choose English ↔ Indonesian and microphone/system audio, accept the provider
disclosure, then Start. Includes floating subtitles, optional island notices and
Control–Option–Shift–T start/stop. Uses Apple Speech and online MyMemory translation;
Internet, provider quotas and host speech-language availability apply. No audio or
transcript files are saved. See [setup and limitations](docs/LIVE-TRANSLATE.md).

Round/Slim resting eyes straddle the physical camera again (one per side), while
retaining shared Companion visits, reactions and Command Bar controls.
