# ONE DESK architecture

## Foundation audit

Upstream `02a13224062342f289753733487f6da85db4e332` is retained as the Git ancestor.
`Sources/Vorssaint` and internal symbols keep their names to reduce merge churn.
The package targets macOS 14; `build.sh` is authoritative, invoking `swiftc` for
arm64 with SDK compatibility flags. No third-party Swift dependencies are added.
`Package.swift` is for indexing, not full app assembly. Resources include localized
permission prompts, agent prices, helper configuration, and app entitlements.
`Tests/generate_sources.py` extracts production methods into isolated test hosts;
`build.sh --test` compiles the existing custom test harness and runs shell tests.

Application startup/teardown and permissions live in `App/`, shared preferences,
catalogs and backup policy in `Core/`, platform behavior in `Services/`, and native
views in `UI/`. System libraries bridge HID and VM statistics. Existing services
cover clipboard, shelf, window layouts/switching, capture/recording, Command Bar,
radial menu, CPU/GPU/memory/battery/network metrics, mixer and brightness.

## Preserved animation engine

`NotchWindowHost.swift`, `NotchMascotView.swift` and `NotchMascotSupport.swift` are
unchanged. The host animates silhouette paths using `CAKeyframeAnimation`, keeps
presentation-layer state when retargeting, and reserves window bounds for motion.
Generation counters prevent stale completion/cancellation from settling a newer
animation. Core Animation timelines coordinate shape, content opacity, border and
mascot bridges. Pixel alignment, geometry, positioning, clipping, event routing,
fullscreen/Spaces/Mission Control behavior remain with the upstream implementation.

`NotchView.swift` only adds a decorative native view to the existing resting strip.
`NotchService.swift` adds an eligibility predicate and includes eyes when asking
existing geometry for resting wing space on the primary and mirrored displays.
No timing curves, animation cleanup, window host, gesture handling, display-link
or native masking implementation is replaced. Relevant layout regression hosts
and assertions were extended for the new resting-content case. CI must still
compile and run them; this document does not assert visual smoothness.

## Notch Eyes

`AppFeature.notchEyes` uses the existing availability, opt-in installation, enabled
key, settings destination, permission reporting and runtime synchronization. It is
not installed with the default island extensions. All six preference keys are
registered in `Defaults`, so the existing backup exporter includes them.

`NotchEyesSupport` contains coordinate normalization, presentation arbitration,
size clamping and blink delay bounds. Coordinates use the hosting window's
`NSScreen.frame`, not a hardcoded primary display or a union that loses display
origins. Cursor-to-camera direction is normalized in that display's coordinates,
with sensitivity and a unit-disk bound. Other monitors and negative coordinates
therefore remain meaningful. Existing screen-change handling rebuilds layout;
each event reads the current screen, and backing-property changes update scale.

`NotchEyesView` is an `NSViewRepresentable`; its host owns two `CAShapeLayer` eyes
and pupil layers. AppKit local/global movement and drag monitors update only the
pupil layers, not observable SwiftUI state. New gaze animations start at current
presentation positions and ease to the target over 160 ms. Small pupil travel
and size bounds keep the pupils inside round and slim eyes.

One cancellable work item schedules the next random blink (3–8 seconds), with a
1-in-8 double blink and small idle gaze only after cursor inactivity. No rendering
timer or polling loop is added. Both behaviors off means no scheduled blink work.
Reduce Motion removes animated gaze, blinking and idle scheduling. Native eye
tracking does not capture clicks; `hitTest` returns nil, and the SwiftUI overlay
also disables hit testing. The existing island remains the sole window owner.

`NotchEyesLifecycle` lazily installs subscriptions and tears them down exactly
once on disable/view removal/destruction. Tests exercise that resource owner.
The host cancels its pending work and layer animations when dismantled. Eyes
removed by presentation arbitration perform no monitoring. Hidden-window events
are ignored; confirm teardown/idle behavior during Space and session changes on a
real Mac, especially where the upstream host keeps hidden views attached.

Presentation priority, highest first:

1. Existing window visibility policy, fullscreen hiding, system UI and native menus.
2. Interaction, capture controls, dragging, expansion and peeking.
3. Existing activities and notifications.
4. Enabled Companion (even if its idle-hiding preference currently hides it).
5. Notch Eyes, only in an otherwise empty resting strip with sufficient wing room.

This conservative policy avoids overlapping Companion or replacing selected idle
content. Uninstalling the island hides the eyes without discarding their choices.

## Independent identity

Bundle IDs are `com.onedesk.app` and `.dev`; helper IDs, storage fallbacks, queue
identifiers and privileged rule paths use ONE DESK namespaces. Existing preference
key names and backup-format keys remain stable inside the independent domain.
Old-bundle migration is disabled for these development distributions. Installer
cleanup no longer removes upstream applications; shell uninstallation targets
ONE DESK paths. Original author/SPDX notices and LICENSE remain intact.

`Tools/MakeIcon.swift` draws the original desk design programmatically. No official
brand asset is bundled. Build signing only selects `ONEDESK_SIGNING_IDENTITY` if
explicitly configured, otherwise an independent local identity or ad-hoc signature.
No upstream Team ID is trusted. The privileged fan helper's placeholder requirement
fails closed until independent signing is designed; do not weaken peer verification.

The original release and issue automation are archived as `.disabled` documentation
under `docs/upstream/`. Active workflows cannot publish releases, access the upstream
protected signing environment or send issue notifications. App self-update entry
points are gated off. Upstream-hosted uploads/feedback are not used.
