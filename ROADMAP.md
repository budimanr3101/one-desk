# ONE DESK roadmap

## Finish the development build

The independent fork is connected; native build, self-test, tests and development
packaging passed in run 39884700825. Download and preserve the development artifacts,
then complete the physical-Mac checklist in
VALIDATION.md. Translate the new settings labels, profile idle work, configure
repository metadata and independent support links, then choose a final bundle ID.
Design an independent Developer ID/notarization process separately; no public
release is enabled in this phase. Privileged helper trust and remote upload/feedback
hosting must be configured independently before those functions are advertised.

## Live Translate (development MVP implemented; validation pending)

The optional module now includes EN ↔ ID speech translation, microphone/system
input, native subtitles, island notices and a global start/stop shortcut. See
[usage, provider/privacy and limitations](docs/LIVE-TRANSLATE.md). Validate real
Apple Speech language support, permissions, latency and audio session rotation.
Future additions: offline/native translation when language/OS support permits,
provider selection, per-app audio input, configurable shortcut, caption history
and export behind explicit user action. No audio/transcripts are persisted now.

## Universal File Actions (not implemented)

Extend existing shelf/notch file drag handling and `NotchFileToolsService`, keeping
security-scoped access and temporary-file cleanup with current owners. Use a pure
content-type action registry for supported actions and existing progress/activity
presentation. JSON formatting can use Foundation; investigate a maintained,
GPL-compatible YAML parser before YAML formatting/conversion. Image conversion,
compression and metadata removal should reuse ImageIO and existing media tools.

Do not modify originals implicitly: generate a preview/output file and require an
explicit destination/replacement action. Test malformed/large files, cancellation,
file promises, encoding, metadata removal and sandbox-scoped URLs.

## Developer and Cloud Toolkit (not implemented)

Add independent catalog entries for JSON/YAML tools, Kubernetes validation/resource
extraction, AWS profiles and EKS context selection. Reuse Command Bar, settings and
on-demand service patterns. Parse local AWS/kubeconfig metadata only when invoked;
never load credentials at startup or include them in backup/logs. Use credential
and executable selectors without exposing tokens. Do not run arbitrary shell text
from imported configuration. Confirm a chosen account/context before changes that
affect external infrastructure; editing a local context and mutating a cluster are
separate operations. Test subprocess cancellation, path handling, redaction,
conflicting contexts, malformed YAML and absent CLIs without live cloud mutations.

No placeholder service, timer, capture session or cloud client is started for any
of these future modules.
