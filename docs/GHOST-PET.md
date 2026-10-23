# Ghost pet in the notch

Ghost is an optional appearance of the existing Notch Eyes feature. Select
Settings → Features → Notch Eyes, open its settings tab, choose **Ghost · Petdex**,
and click **Download Ghost from Petdex**. Alternatively, import the original
`spritesheet.webp` from the Ghost package. Keep the island enabled, choose **None**
as idle content and disable Companion. No mouse tracking is installed in Ghost mode.

The default size is 52 points, configurable from 32–72. Available menu-bar space
can cap it. The existing island host reserves a taller resting surface for the
whole pet, positioned beside the physical camera. On a floating capsule it is
centered. Existing notifications, activities, Companion and interaction retain
priority. This is decorative animation: actions do not claim to report actual
coding-agent or shell activity.

Idle animation is followed periodically by a wave, jump, walk or expression, using
Ghost's actual frame counts. Blank trailing cells are excluded. Core Animation
plays the image sequence; a single cancellable delayed task selects the next
activity. No frame-rendering timer, cursor monitor or SwiftUI per-frame state is
used. Disable animations or enable Reduce Motion for a static idle frame. Removal
of the view cancels loading, scheduled actions and layer animations.

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
rejection of unverified image data. Native compilation, these new tests, actual
web-download behavior on macOS and visual/hardware appearance require the new CI
run and subsequent real-Mac testing. The previous successful foundation CI does
not validate this new Ghost implementation.
