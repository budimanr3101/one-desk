# Ghost pet in the notch

Ghost is an optional appearance of the existing Notch Eyes feature. Select
Settings → Features → Notch Eyes, open its settings tab, choose **Ghost · Petdex**,
and click **Download Ghost from Petdex**. Alternatively, import the original
`spritesheet.webp` from the Ghost package. Keep the island enabled, choose **None**
as idle content to see its resting pose. Selecting an installed Ghost automatically
uses it in the original Companion runtime instead of the purple character. Classic
Companion settings are preserved and resume when Ghost is disabled. No desktop
mouse tracking is installed in Ghost mode.

Ghost now has independent Companion-style settings: camera side, hide after idle,
periodic visits with three frequencies, reactions to real island activities, and
Command Bar with Drop/Open island presentation. The shared interactive stage
provides Say Hi and the same reaction preview buttons. The actual activity events,
visits, idle hiding, transitions and Command Bar routing use the upstream engine.
Ghost maps the available sprite rows to those moods/reactions; it does not invent
additional artwork. Its default resting size is 52 points (32–72 configurable),
limited by available menu space. Activity and Command Bar faces use their existing
compact geometry.

`NotchPetProfile` selects pet preferences without overwriting classic preferences.
`NotchGhostRig` attaches a sprite layer inside the original Companion rig, retaining
its hopper, squasher, visit paths, clipping and native window host. Original window
animation timings are unchanged. Frame sequences run in Core Animation, decode off
the UI thread, respect Reduce Motion, and stop while invisible. Scheduled reaction
resets and loading are cancelled on teardown. No rendering timer is added.

## Asset provenance and distribution

- Page: https://petdex.dev/pets/ghost
- Petdex manifest submitter: `huigegood`.
- Description in the package: “A tiny retro pixel ghost companion.”
- Official asset: https://assets.petdex.dev/pets/ghost-a4500caeb64e/sprite.webp
- Package: https://assets.petdex.dev/pets/ghost-a4500caeb64e/zip.zip
- SHA-256: `f150d794d1c33caabca0d32d213904efaac86afb215fa33f6fcee7ab444f9602`
- Image: 1536×1872 RGBA WebP, 8×9 grid, 192×208 per cell.

The package inspected on 2026-10-23 contains `pet.json` and `spritesheet.webp`,
with **no redistribution license**. Petdex's MIT license covers its software;
its README says asset licensing is determined by individual submitters. ONE DESK
therefore does not bundle or redistribute this artwork, and does not claim it is
GPL licensed. The application provides an explicit download/import action for the
user; neither startup nor feature installation contacts Petdex automatically.
Creator/underlying-IP permissions still govern asset use and redistribution.

The installed image lives under this app's Application Support/Pets/Ghost path.
Only the pinned asset hash and exact atlas dimensions are accepted. Preferences
(size, animation, appearance) participate in backups; image data and installation
revision do not. Source/test artifacts contain no Ghost image, and CI tests need
no network access to Petdex.

## Validation

Static Swift parsing, test-source generation, build-script syntax and workflow
linting are run in Linux. New tests cover atlas bounds, valid frame counts,
size/space constraints, larger native surface reservation, backup policy and
rejection of unverified image data. Added profile tests cover independent preferences,
classic restoration, feature disable/removal, Command Bar opt-out, reaction/mood
mapping and larger Companion tracks. Native compilation, these new tests, actual
web-download behavior on macOS and visual/hardware appearance require the new CI
run and subsequent real-Mac testing. The previous successful foundation CI does
not validate this new Ghost implementation.

## Round and Slim parity

The same Companion behavior settings and interactive stage now apply to Round
and Slim eyes. They need no downloaded asset. NotchEyesRig draws a native pair
inside the existing Companion motion hierarchy, with bounded pupil gaze from
local/global mouse events and the original eye size/sensitivity/blink/idle
preferences. Ghost, Round and Slim share the pet behavior preferences; switching
appearance preserves them. Classic Companion preferences remain separate.
