# Cloud-only development

The workspace was empty. Preparation used:

```sh
git clone https://github.com/vorssaint/vorssaint-utils.git /workspace/onedesk
cd /workspace/onedesk
git remote rename origin upstream
git switch -c feat/onedesk-foundation
```

Upstream history is preserved. The initial integration could not create a fork
(HTTP 403). On 2026-10-23 the user supplied the independent fork
`https://github.com/budimanr3101/one-desk`; this checkout now uses it as `origin`.
The feature branch has been pushed successfully. The upstream push URL is
`DISABLED` to prevent accidental publication there.

```sh
git remote add origin https://github.com/budimanr3101/one-desk.git
git push -u origin feat/onedesk-foundation
```

The first ONE DESK Actions run is
https://github.com/budimanr3101/one-desk/actions/runs/39882559587.
See VALIDATION.md for the final native results and subsequent corrective runs.

Never set the writable origin to `vorssaint/vorssaint-utils`. The archived upstream
release workflow is not executable. Enable Actions in the fork if GitHub asks;
new forks may require this before workflows run. Pushes to `main`, `feat/**`,
`fix/**`, `dev/**` and `develop`, plus pull requests/manual runs, trigger CI.

The workflow has five jobs: build, self-test, unit-tests, package, upload. Native
jobs use `macos-15`, assert `uname -m == arm64`, record OS/Xcode/Swift/SDK versions,
and verify the executable's ARM64 slice. If the label yields Intel for an account,
select an available GitHub-hosted ARM64 label; do not remove the architecture check.
The SDK/toolchain must support the macOS 14 deployment target. Actual versions are
recorded in `ONE-DESK-build-logs/environment.txt`, not assumed from the label.

The self-test runs the new executable inside the built app bundle. Tests compile
with the existing source-extraction harness. Packaging is gated on all three
validation jobs, verifies signatures and generates DMG, ZIP, SHA256 sums and the
exact Git source archive. Downloads appear on the successful Actions run page:

- `ONE-DESK-dev-macos-arm64`: app ZIP, source ZIP and checksums.
- `ONE-DESK-dev-DMG`: development DMG.
- `ONE-DESK-test-results`, self-test/build/packaging logs: diagnostics.

ZIP transport via `ditto` preserves bundle permissions and signature metadata
between macOS jobs. CI uses no Developer ID, upstream certificate, signing secrets,
protected environment, notarization credentials or release publication. Signature
verification remains enabled. Keep source available with redistributed GPL builds.

After connecting the fork, update `OneDeskRepositoryURL` bundle metadata and
VALIDATION.md with actual workflow run URLs, environment details, results and
artifact links. A queued workflow or prepared YAML is not a successful build.

## Source handoff without repository-write access

The local checkout contains the actual commits and upstream history. A source ZIP
and incremental Git bundle can be delivered separately from any compiled artifact.
The bundle needs the upstream ancestor, so apply it to an upstream clone:

```sh
git clone https://github.com/vorssaint/vorssaint-utils.git onedesk
cd onedesk
git remote rename origin upstream
git remote set-url --push upstream DISABLED
git fetch /path/to/ONE-DESK-development.bundle feat/onedesk-foundation:feat/onedesk-foundation
git switch feat/onedesk-foundation
```

Connect your own writable origin as above. The source ZIP/bundle is **not a macOS
application**, and its presence does not demonstrate a successful development build.
