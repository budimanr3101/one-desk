# ONE DESK validation

Status: **source implementation delivered; macOS development build blocked**.
Do not interpret source parsing or upstream CI as proof that ONE DESK compiles,
passes unit tests, renders smoothly, or works on physical hardware.

## Environment

- Date: 2026-10-22 (UTC).
- Workspace: `/workspace/onedesk`, Codex Cloud Linux 6.18.55, x86_64.
- Swift compiler version: unavailable (`swiftc` is not installed).
- macOS SDK / Xcode / AppKit: unavailable; baseline `./build.sh` exits at
  `xcrun: command not found` (status 127).
- Shell: zsh for the upstream build scripts; Python 3.12 for test generation.
- Destination: not configured. Upstream is read-only remote `upstream`.
- Branch: `feat/onedesk-foundation`. Git history retains the upstream ancestor.

## Baseline established before implementation

Exact upstream commit: `02a13224062342f289753733487f6da85db4e332`.
Read the completed [upstream CI run](https://github.com/vorssaint/vorssaint-utils/actions/runs/39688240264)
and job results through GitHub's API. Both jobs concluded `success`:

- Swift 6.0.3 compatibility: macos-15, Xcode 16.2, SDK 15.2 as configured
  upstream; build, self-test and unit-test steps succeeded.
- Build & selftest: macos-26 as configured upstream; build, self-test, DMG and
  unit-test steps succeeded.

This is **upstream evidence only**. Runner labels/toolchain configuration above
come from the exact upstream workflow; physical machine characteristics were not
independently measured. A small API result snapshot is saved under
`docs/validation/upstream-baseline.json`.

## ONE DESK results

| Validation | Result |
| --- | --- |
| Source changes and branch | Implemented locally |
| Git diff whitespace/errors (`git diff --check`) | Passed |
| zsh syntax: build, packaging, signing, uninstall, install test | Passed |
| `python3 Tests/generate_sources.py` | Passed |
| `.github/workflows/*.yml` parsing | Passed |
| `actionlint` 1.7.12 | Passed, no workflow diagnostics |
| Resource plist XML parsing | Passed |
| Swift static parser | No new parser errors across 208 changed/new Swift files; six files have parser limitations also present upstream |
| `Tests/PreferenceCleanupTests.sh` | Passed (`PREFERENCE CLEANUP TESTS OK`) |
| `Tests/UninstallSpacesTests.sh` | Attempted; failed because macOS `plutil`/preference tooling is absent in Linux. Not disabled or represented as passing |
| macOS compilation | Not run: no macOS SDK and no writable destination |
| App self-test | Not run for ONE DESK |
| Swift unit tests | Implemented/extended, not executed; compiler unavailable |
| CI integration tests | Not run for ONE DESK |
| `.app`, ZIP, DMG packaging and signing | Workflow prepared, not executed |
| Downloadable compiled artifact links | None; no successful ONE DESK CI run |
| Physical Mac / visual / camera / notch testing | Not performed |

Static Swift parsing used tree-sitter-swift, **not a Swift compiler/type checker**.
The known upstream parser limitations include NotchService, AgentCodexServer,
AirPlayRouteManager, QuickTogglesService, RecorderExporter and NotchMascotTests.
Parsing does not validate API availability, overload resolution or actor isolation.
The parser and actionlint were installed as temporary cloud validation tools;
neither is a runtime dependency of ONE DESK.

## Tests added and retained

`NotchEyesTests` runs from the existing Notch test suite and covers directional
mapping, negative display origins, off-display diagonals, normalization bounds,
invalid display geometry, size limits, blink-delay bounds, lazy subscription
installation, idempotent enable/disable and cleanup, destruction cleanup, settings
persistence, backup inclusion, opt-in availability, and presentation priority.

Existing production-method extraction hosts for music/resting layout and mirrored
displays include the eyes reservation case. Feature catalog expected identities
and count are updated from 77 to 78. The Settings tab layout test now includes both
Companion and Notch Eyes. Installation isolation checks both ONE DESK variants
leave all upstream bundles unchanged. Existing tests remain enabled.

Tests for actual mouse delivery, AppKit display changes, pupil animation timing,
Retina output and blink appearance still require macOS execution and/or visual
inspection. The pure lifecycle test exercises the production subscription owner;
it does not prove every OS/session visibility callback tears down the host.

## GitHub blocker and resumption

`gh auth status` identifies `budimanr3101`. Creating a fork with
`gh repo fork vorssaint/vorssaint-utils --clone=false --remote=false` returned:

> HTTP 403: Resource not accessible by integration

No source was pushed to the official repository. No repository outside this
checkout was modified. A user-created fork or repository access grant is required;
see [cloud build instructions](docs/CLOUD-BUILDS.md). Once connected, push this
branch and inspect the actual workflow logs. Populate this document with the
ONE DESK run URL, measured runner architecture, Swift/Xcode/SDK versions, build,
self-test, unit-test, packaging results and artifact URLs. Fix any failures before
calling the build usable.

## Known limitations

- Native source is uncompiled; compiler and runtime issues may remain.
- New eye-settings labels are English in all existing locales.
- Eyes deliberately require idle content None, adequate wing space, and Companion
  disabled. They do not expand into scarce menu-bar space or draw in the cutout.
- Verify hidden-window teardown during lock/Space/Mission Control changes; the
  upstream host can retain an attached hidden view. Hidden cursor events are
  ignored, but real-Mac profiling must establish the idle resource cost.
- App self-update is disabled. Repository metadata is unconfigured. Original
  author support/donation destinations remain upstream links.
- Upload/feedback endpoints are `.invalid` until independent hosting exists;
  local screenshot, recording and file export remain available.
- No independent Developer ID/notarization or privileged fan-helper trust is
  configured. CI artifacts will be ad-hoc signed; grants can change on rebuild.
  The M2 MacBook Air target is fanless. Do not weaken helper peer verification.
- Build version remains upstream's base version for compatibility; these are
  explicitly independent development distributions, not production releases.

## Physical-Mac validation checklist (pending)

On the M2 Air and at least one external display:

1. Install alongside Vorssaint; confirm independent preferences, login items,
   permissions, file shelf, clipboard data, caches and uninstall behavior.
2. Test island hover, expansion/collapse, cancellation/reversal, menus, activity
   changes, notification previews, drag/drop, Companion, Command Bar and capture.
3. Enable eyes with idle None and Companion off; move left/right/up/down and
   diagonally across all displays. Check pupil bounds, eye alignment outside the
   camera cutout, Retina scaling and absence of clipping/flicker.
4. Rearrange displays (including negative coordinates), change resolution/scaling,
   connect/disconnect monitors, and test the mirrored-island setting.
5. Test fullscreen, Spaces, Mission Control, lock/unlock, sleep/wake and menu-bar
   interactions; confirm the eyes never steal clicks or overlay important content.
6. Toggle/install/uninstall eyes and the parent island repeatedly. Confirm settings
   backup/restore and subscription/scheduler teardown. Enable Reduce Motion before
   and during presentation; check that decorative animation stops and resumes.
7. Use Instruments Time Profiler, Allocations and Energy Log: compare eyes disabled,
   visible idle, active cursor movement, hidden and Companion/activity precedence.
   Look for retained monitors/work items, growing memory, main-thread blocking,
   animation stalls and unexpected wakeups. No performance measurement is claimed.
8. Repeat key clipboard, shelf, window management, switcher, screenshot/recording,
   metrics, mixer, brightness and existing self-test/regression paths with their
   normal permissions. CI success would not substitute for this checklist.
