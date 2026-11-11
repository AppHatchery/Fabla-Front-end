# Changelog

## Unreleased (command line only)

- `alive <command> help`, `--help`, `-h` and `alive help <command>` print that command's usage, for every command.
  Before, `alive paws help` and four other commands read `help` as a scene folder and stopped with a file error.
  A test runs every form on every command the help lists.

## Engine 0.7.0: standards: placements, Fabio's size tiers, templates (kit 1.7.1)

**Highlights**

- Placements (page, panel, card, dialog, inline, custom) and Fabio's size tiers, XS 56 to XXL 240 pt.
- `AlivePlacement` lays a scene out by its placement and keeps a phone design from growing on a tablet.
- Templates (beats and patterns) and `alive new`, which writes a moment file from them; `alive catalog` lists them.
- `alive sizes` and two lint rules, placement-box and fabio-size (warnings, errors with `--strict`).
- Scenes load on the web, and seeded pools pick there as on the phone.
- Checked on Flutter 3.44.4: `tools/ci.sh` and `alive preview` stop on any other version.

New animations are assembled from standard pieces instead of being sized and timed by eye each time, and nothing of it
is required: a scene that declares nothing plays and checks as before. docs/standards.md has it in plain words.

### Added

- **Placements** (`standards/placements.json`): page, panel, card, dialog, inline and custom, each with its box, Fabio's
  size, his home spot, its scale (the dialog shows its scene at 110 / 83), fit, alignment, clip, tap pass-through and
  margins. A team adds its own in the same file (or its own copy, `--standards`).
- **Fabio's size tiers**, his body height on screen: XS 56, S 84, M 110, L 136, XL 164, XXL 240 pt, measured from the
  app's 55 scenes (M is the dev team's dialog art). Defaults: page XL, panel XXL, card XL, dialog M, inline XS.
- **Scene fields** `placement` and `fabioSize` (a tier or points), optional, validated by the CLI and parsed by
  `SceneDef` (`placement`, `fabioSize`).
- **`AlivePlacement`** (lib/src/widget/placement.dart): a scene laid out by its placement, a thin layer over
  `AliveStage` (unchanged): the scaling rule (designed at 430 pt wide, scaled evenly by width, never stretched; the
  dialog by height), clip, alignment, taps passing through a page; every stage argument still settable.
  `AlivePlacementSpec`, `AlivePlacements` (the six, `byName`, `all`), `placementSize`.
- **The scaling rule's two limits**, so a tablet does not balloon a phone design: a box grows at most `maxScale` times
  its size on the 430 pt phone (`maxScale` in each placement, 1 by default; `AlivePlacement(maxScale: ...)`,
  `double.infinity` for none), placed in its parent by the placement's alignment; and it is never taller than its
  parent or the screen (it fits the height instead). On an iPad (820 pt) the warning sheet stays 366 pt wide where it
  was 1.9 times that and ran off the bottom. Widget tests at 768 x 1024, 1024 x 1366 and 1024 x 768.
- **Two lint rules**, on scenes that declare a placement or a size: `placement-box` and `fabio-size` (within 6 %, at
  least 4 pt). Warnings, information under `custom`, errors with `--strict`. `alive lint --json <file>` writes every
  problem; `--standards <file>` reads another placements file.
- **`alive sizes`**: Fabio's body in a scene, measured (a kit figure, a body layer, or his body colour in a fabio
  layer; a peek sized from his width).
- **Templates**: `templates/beats/` (enter-left, enter-right, enter-bottom, settle, idle-loop, idle-look, wave-goodbye,
  thumbs-up, small-cheer, react-tap, leave-left, leave-right) and `templates/patterns/` (reaction, page-moment,
  dialog). A moment names a beat (`{"beat": "wave-goodbye", "at": 1200}`) and overrides any of its fields.
- **`alive new <pattern> --placement <p>`**: a moment file assembled from the templates, the same for the same input
  (plain code). `alive catalog` lists placements, tiers, patterns and beats. The alive-author skill starts from it.
- **Moments of several clips** (`clips`, `states`, `pools`, `initial`), as the dialog pattern writes them.

### Changed

- The checks measure in the scene's frame: an art's `offset` is applied as the runtime applies it (the paw check,
  safe-margin, faces and fail drew board cuts where their uncut frame had them).
- safe-margin: the app's 16 pt margin applies on a scene's edges that are the screen's; any other edge is a box in the
  app's layout, measured to its own edge (a declared placement gives its margins; `--safe` sets all four as before).
- `alive preview` and `alive moment --preview` draw at 60 fps and 3x by default (`--draft`: 12 fps, half size).
- `alive moment` lints a kit figure with its parts, so the size rule measures it.
- **A step channel has no value before its first key** (docs/schema.md). The runtime held the first value from 0 ms
  while the tools showed the look's part, so they disagreed about any channel keyed after 0: a `slot:` channel now
  shows the look's own part there, `channel(name)` reads null. A `null` value in a `slot:` channel is the look's part in
  the tools too (the paw check emptied the slot, so a paw the app draws went unmeasured). test/channels_test.dart and
  tools/test/paws.test.mjs pin it. What it changes is under Measured.
- **Kit 1.7.1**: the detached style's `celebrate` and `carry-front` key their items to the holding paw (below).
- **`alive kit lint` checks every paw style's actions** (`pawStyles.<style>.actions`): their parts resolve, and an item
  an action holds is never on the resting paw (held-item, as `alive lint` says it of a scene). On kit 1.7.0 it finds
  the three detached cases below.
- `alive preview` reads a packed folder's `_shared/` art (from the showcase).
- **safe-margin: steam and smoke are bleed names**, as puffs and trails are: they drift and fade past an edge by
  design (the train's steam in hx_v1 to v3, the jetpack's smoke in the update dialog). tools/test/round7.test.mjs.
- **`alive lint` and its switches.** A switch (`--no-pixels`, `--strict`, `--verbose`, any `--no-...`) takes no value: with
  the switch first, `alive lint --no-pixels a b` had taken the folders as its value and linted nothing, silently. Lint
  with no scene folder now stops and says so. Without pixels it warns of no body layer only where there are paws to
  measure against him, as the full lint does (the app's 55 scenes: 37 such warnings before, 9 now, the same 9 as the
  full lint: scenes whose paws have no body layer to be measured against).
- **Flutter 3.44.4, checked.** `pubspec.lock` is made with it and another version rewrites it, so `tools/ci.sh` stops
  (exit 2) and `alive preview` stops on any other, saying which is on PATH and what to do (`FLUTTER`;
  `ALIVE_ANY_FLUTTER=1` goes on anyway). README says so at the top.
- **`tools/ci.sh` checks what a release would carry** (where the release tools are present): every file of the tree is
  copied, made as the release makes it and scanned; a finding fails the suite. The kit's note rewrites apply to every
  copy of `kit.json` in the tree.

### Fixed (found by the showcase)

- **Scenes load on the web.** A scene's colour buffers are a `List<int>`: an `Int64List` on the VM as before, a
  fixed-length list on the web, where every scene failed to load ("Int64List not supported").
- **Seeded pool picks are the same on the web as on the VM.** `fnv1a` and `Mulberry32` work in exact 32-bit arithmetic
  (`mul32` multiplies in 16-bit halves, shifts are integer divisions): on the web an integer is exact only to 2^53, so
  the products went wrong and a seeded pool picked another variant. test/fidelity_test.dart pins known seeds to
  JavaScript's own numbers.
- **Detached paws: a held item shows only on a holding paw** (lint: held-item). The detached actions start and end
  on the resting paw, which put an item on it in two ways:
  - the kit's own items: `celebrate` showed its popper on the resting paw for its first 120 ms and its burst for the
    last 250, `carry-front` its parcel for the last 150. The item now comes with the holding paw and goes with it
    (kit 1.7.1: `slot:held` keyed from 0 ms, `null` where the paw rests). The paws are unchanged, so the detached
    pixel check is unchanged;
  - an item the moment holds: a moment holding an envelope that then does `present` or `hold-up` had the envelope on
    the resting paw for the action's first 100 to 120 ms and its last 220 to 240 (the showcase's "show an item"
    moment). `alive moment` now keeps the paw that holds it wherever an action puts the resting paw in; any other paw
    an action uses (a wave, a thumbs up) is kept, and lint still says it cannot hold the item.
  Touching paws are unchanged (the example moments and `alive new` patterns compile to the same scenes).
- **`alive pack` packs a folder packed before.** Its `_shared/` art is put back into each scene first, as the loader
  does; packed again, with or without `--share`, the loader reads the same art, and the old `_shared/` is not copied.

### Measured

The app's 55 scenes as of 3 Nov (assets/alive_src), `alive lint` at default settings, errors: 51 with 0.6.5 (the four
update dialog scenes against a 16 pt margin inside the dialog's band), 0 with 0.7.0. On the way the offset found
hx_v1, hx_v2 and hx_v3's steam puff `item/steam 10` at x 429.4 of 430 from 3.20 to 3.43 s: a puff of the train's steam
that fades in, grows and drifts up and right past the edge as it fades out (gone by 3.95 s), not an object parked
there, so steam and smoke joined the margin rule's bleed names (above) instead of the scene being changed. Warnings unchanged (11). With the offset alone and the old margin there were 61 (qt_slider 6 and
qt_text 1 against their own box's edge). No scene declares a placement yet, so the two new rules add nothing to them.

What the step channel rule changes: no channel of the app's 55 scenes, of the 71 corpus scenes or of the touching kit's
actions starts after 0 ms, so none of them draws differently. Five clips of examples/kit-vocab do, each only before its
channel's first key (10 of its 235 preview stills differ, all inside these windows): carry-parcel and carry-diary
0 to 150 ms (the item no longer shows on his resting paw before the paw takes it), rain-balloon and umbrella-up 0 to
300 ms and cold-cozy 0 to 1000 ms (his look's own eyes until the eye channel's first key, where they looked up or
blinked from 0). Kit 1.7.0's detached carry-front parcel (0 to 150 ms) is the same case; 1.7.1 keys it from 0.

tools/ci.sh on Flutter 3.44.4 (9 Nov), all green: analyze clean (package and example); 758 Flutter tests, 5 skipped;
124 CLI tests, 1 skipped; the release copy's scan 0 findings; kit 1.7.1's pixel paw check 0 of 79 cases in both styles (touch and detached;
docs/paws/final-1.7.1-*.json); corpus parity 71 scenes, 213 frames, worst 0.0000 % of pixels; the app's 55 scenes
as of 3 Nov packed with `--share` (44 shared fragments, 1481 KB to 696 KB gzipped) and pack parity over 534 frames, worst
0.0000 %; kit-qa parts 221/221, looks 52/52, cards 19/19, 309 tests. `alive lint` on the app's 55 scenes: 0 errors (the
hx steam above is a bleed name now) and 11 warnings.

## Engine 0.6.5: a paw drawn in front of him is measured on what shows (kit 1.7.0 unchanged)

**Highlights**

- paw-contact measures a paw drawn in front of him against the part of him that shows.
- A paw drawn behind him is measured on his full shapes, as before.
- Only the CLI's checks change; the runtime is 0.6.4's.
- The tape moment is drawn for the new rule: the app's 51 scenes lint with 0 errors.

`alive lint` and `alive paws` passed a paw that a viewer sees on its own. The touch rule's paw-contact measured every
paw against his full shapes, including the parts of him that something covers or that lie outside the scene's frame.
For a paw drawn behind him that is right: tucked behind his edge, the part of it that shows meets him where his body
covers the rest. For a paw drawn in front of him it is not. Two cases passed with a gap of 0: a front paw at the
frame's edge as he walks in, his body still outside the frame; and a front paw on a held item (a phone, a tape) that
covers his belly, with none of his body showing beside the paw.

### Changed

- paw-contact (touch, the default): a paw drawn in front of him (after his body in paint order) is measured from its
  pixels that show to the part of his figure that shows: his figure less what is drawn over him after his body (a held
  item, a prop, a desk top, at 60 % opacity or more and not blurred; his own paws excepted) and less what lies outside
  the scene's frame. A paw drawn behind him is measured on full shapes, as before. When nothing covers him and he is
  wholly inside the frame, the measure is 0.6.4's. New messages: "touches him only where he does not show" and "shows
  with none of his figure in sight". tools/lib/paws/check.mjs (`visibleFigure`, `measureFrame`'s `seen`).
- paw-overlap keeps measuring how deep a touching paw sits in his full shapes, front paws too: what covers a front
  paw's junction with him is most often the item it holds, which moves with the paw. The depth into the part of him
  that shows is reported in the JSON output as `shownDepth`. The detached rules measure from his full shapes as before.
- A paw whose figure is wholly cut away by his clips (a dialog) was reported about 2,500,000,000 kit units off him; it
  is now the check's margin, 60, with the message above.
- The paw check's caches key a shape by its clips' places too, so a clip that moves over a still body is measured
  where it is in each frame (they keyed only the number of clips).
- `alive paws --out` draws a failing front paw as it was measured (what shows of the paw and of him) and measures in
  the scene's frame, as the check does.
- tools/test/paws.test.mjs: front paws at the frame's edge and at a dialog clip's edge with his body cut away, on a
  held item over his belly, and meeting him only under an item fail; a paw gripping an item at his edge that meets his
  body below it, a paw on an item's edge and his belly, and paws tucked behind him (also at the frame's edge) pass.
  docs/paws.md, "Front paws are measured on what shows (0.6.5)".

### Measured

The 0.6.4 and 0.6.5 paw checks on the same files, in the touch style: the kit (79 cases, in both styles), the 71
board exports, the app's 51 scenes, the ten Diary Moments engine moments and the encouragement export, and this
repository's examples and test scenes keep their results, but for one scene. The tape moment (the app's `dm-tape`, the
Diary Moments engine folder's `tape`): from 6.29 to 6.33 s (about 40 ms) the tape, flying up into the take paw, passed
over his side between the paw and his body, and the paw showed up to 16 kit units from the part of him that shows;
before and after, it touched him. 0.6.5 reported it as a paw-contact error at 6.3 s. The moment has since been drawn
for it: the tape comes round below his paw and rises into it, and the app's 51 scenes lint with 0 errors.

## Engine 0.6.4: a shape with no area is not filled; checked on Flutter 3.44.4; folders outside the repository from environment variables (26 Oct 2026; kit 1.7.0 unchanged)

**Highlights**

- The renderer leaves out the fill of a shape with no area, so Flutter 3.44 draws no stray hairlines.
- The lock files are made with Flutter 3.44.4.
- Folders and programs outside the repository come from environment variables; a step without them is NOT RUN, never failed.
- A command that needs Chrome says how to install puppeteer-core instead of printing a stack trace.

On Flutter 3.44.4, the app's version, one test failed: the kit card text-spacing, with 8.4% of its drawn pixels
visibly different from Chrome's render against a gate of 1%. Its guide line is a stroked path with SVG's default black
fill. A fill inside a line covers nothing, so SVG and Chrome draw nothing for it; Flutter 3.44's renderer draws it as a
hairline along the line, so the engine drew a dark line where the reference has a light red one. On Flutter 3.41.1 the
same test passed.

### Changed

- The renderer leaves out the fill of a shape with no area (`geometryHasNoArea` in lib/src/render/art_renderer.dart:
  a line; a path or polyline whose points, curve control points too, lie on one straight line; a box or an ellipse
  with no width or no height), on every Flutter version. Strokes are drawn as before. The card on Flutter 3.44.4: 8.4%
  to 0.3% of its drawn pixels, the largest differing patch 600 to 9 pixels. This is a change in lib/: on Flutter 3.44
  an app on 0.6.3 or earlier draws a dark hairline under such lines (a stroked line exported with no fill attribute).
- `pubspec.lock` and `example/pubspec.lock` made with Flutter 3.44.4 (matcher 0.12.19, meta 1.18.0, test_api 0.7.11).
- Folders and programs outside this repository come from environment variables with neutral defaults
  (tools/lib/env.mjs; README.md, "Requirements" and "Environment"): `ALIVE_BOARDS` (the boards folder, by default
  ../fabla-alive beside this one), `ALIVE_APP` (an app checkout with Alive's scenes, by default ../Fabla-Front-end),
  `ALIVE_KIT_SRC`, `FABIO_ENGINE_PLUS` (by default ../fabio-engine-plus), `ALIVE_PUPPETEER` (by default Node's own
  lookup from this repository) and `CHROME`. tools/ci.sh reports a step whose folder or puppeteer-core is not there as
  NOT RUN (exit 2), kit-qa included, and prints the Flutter and Node versions in its summary. `npm run kit-qa` says
  NOT RUN and exits 2 without the kit's source SVGs or puppeteer-core. `alive kit import` records a source folder in
  the boards folder as `<boards>/...`, and kits/fabio records its own that way.
- `alive help` prints the engine's version; it printed the upgrade converter's own (0.2.0).
- examples/kit-vocab: in seven clips the held item showed while the paw was at rest at the clip's start and end (12
  held-item errors); the item now shows only while the paw holds it. `alive lint`: 0 errors and 1 warning in the
  default touch style.
- The Figma readers (tools/figma/read-frames.figma.js, read-nodes.figma.js) say how to run them and where to save what
  they return; docs/authoring.md has "A new Figma frame": the read, the SVG export, the smallest dump
  (`{"frame": "<frame id>"}`) and the command. "One command" holds for the frames the cache has read (41 moments).
- Recorded paths in the examples, the Figma cache's notes and the benchmarks' comments are written relative to the
  boards folder (`<boards>/...`), this repository, or an environment variable.
- `alive figma` and `alive storyboard` take the Figma file's key from the cache (`file` in
  tools/figma/cache/moments.json, or the storyboard's story.json) and write it into the scene's `meta.figma.file` and
  each clip's source; the code names no file, and a cache without a `file` writes none.
- A command that drives Chrome (`alive html`, `alive parity`, `alive kit refs`) without puppeteer-core prints one line
  saying how to install it and exits 2 (could not run); it printed a stack trace (`MissingTool` in tools/lib/env.mjs).
  tools/test/cli.test.mjs checks it.
- tools/lib/paws/check.mjs: the function that lists one measured paw's problems is `pawProblems`, exported by that
  name from tools/lib/paws/cli.mjs too.
- README.md: the Fabio pack has 221 parts of the kit, faces split into features besides (it said 207, the count of
  kit 1.4.0).
- Version 0.6.4 (pubspec, `aliveVersion`, the CLI's `ENGINE_VERSION`, the example's lock); no scene needs it.

### Added

- test/no_area_fill_test.dart (3 tests): which shapes have no area; a stroked line with a fill draws exactly what its
  stroke alone draws (on 3.44.4 without the change this test fails); a shape with area keeps its fill.

## Engine 0.6.3: the flicker rule tells a designed blink and a flip from a flicker (26 Oct 2026; kit 1.7.0 unchanged)

**Highlights**

- The flicker rule reports a designed blink or a flip as info, not as an error.
- Only the CLI changes: an app on 0.6.2 needs no new copy of the package.
- The app's 51 scenes: 4 flicker errors before, 0 after.

The app's final pass (26 Oct) found `alive lint` at 0 errors on 48 of its 51 scenes. The other
three were designed and read as flickers by the 0.6.1 rule: ws_battery and ws_two blink the phone's 14% screen off and
on again, and wv_not_found_v1's tag flips through zero scale (sy 1 to -1 and back). Only the CLI changes: the runtime
is the same code as 0.6.2 (lib/ differs only by `aliveVersion`), so an app on 0.6.2 needs no new copy of the package.

### Changed

- `alive lint` flicker (tools/lib/flicker.mjs): before a fall is reported it is classified. A flip (a scale of the
  layer or of an ancestor has another sign when it is back than just before the fall, and its opacity stayed shown
  through the dip) and a designed blink (an opacity square pulse: cut off, off and flat within 0.02 for two frames or
  more, 66 ms, cut on again to within 0.1 of its level, its area kept throughout; a cut may take one frame part way at
  each end, as a cut keyed between two checked frames does) are reported as info (`flicker-designed`, with `--verbose`),
  never as errors. Everything else the rule caught is still an error: a fall that fades back in (the boards' record key,
  option fill and dot), an off of one frame, a hide by a scale or a box of 0, a return to another level, a
  scale that reaches 0 and comes back on the same side.
- Version 0.6.3 (pubspec, `aliveVersion`, the CLI's `ENGINE_VERSION`, the example's lock); no scene needs it.

### Added

- tools/test/flicker.test.mjs (7 tests): the app's three scenes' keys pass; the Diary Moments boards' flickers, each
  condition of a blink missed on its own, a flip whose opacity also drops out, and the cuts keyed between two frames.

### Measured (26 Oct, the 0.6.2 CLI against 0.6.3 on the same files)

| Scenes | 0.6.2 flicker errors | 0.6.3 flicker errors | 0.6.3 designed (info) |
|---|---|---|---|
| the app's 51 scenes (the app's `assets/alive_src`, alive lint as the app runs it) | 4, in 3 scenes | 0 | 4: 2 blinks, 2 flips |
| the ten Diary Moments engine moments of 26 Oct | 0 | 0 | 0 |
| the 24 Oct boards' micro reduced scene, exported again | 2 (the option fill and dot of Well) | 2, the same | 0 |
| the 71 board exports of the corpus (`alive sweep`, `--no-pixels`) | 31 | 20 | 11: 4 blinks, 7 flips |

The 20 left in the corpus: 6 are two confetti pieces of the old completion export, whose scale reaches 0 and comes
back on the same side (a tumble with no sign change, which the rule does not tell from a hide by scale); 5 are caret
dips of one frame; 3 are the held value of the slider, cut to 0 and faded back in; 2 the recorder's window door and 4
storage labels, falls that fade back. Every other lint rule gives the same results on all of these files.

## Engine 0.6.2 and kit 1.7.0: the fail checks and dense parity, a gradient with no box paints nothing, and touching paws by default (26 Oct 2026)

**Highlights**

- Two lint rules, fail-sending and fail-progress: once the saved card shows, no text still says Sending and no progress object still moves.
- `alive parity --every N`: the board and the engine compared every Nth frame, not only at the beats.
- safe-margin counts the app's own `ui/` objects, and glows, halos and rings.
- A bounding-box gradient on a shape with no width or height paints nothing, as in SVG and Chrome.
- Kit 1.7.0: touching paws are the default paw style; detached is the named variant.

The Diary Moments boards of 24 Oct had defects the 0.6.1 checks could not see: ending C's engine drew five hard
black trail lines for 5 frames as the train left (between two beats, so parity passed), the last question's finish
badge, glow and rings sat in the 16 pt margin (the margin check read only item/ objects, left glows out and ran only
on the scenes with Fabio), and the Not sent endings kept saying Sending under the app's saved card. Each class now has
a check that fails on those boards (docs/checks.md, with the numbers). And touching paws are the default paw style,
the design team's choice of 26 Oct; the rig carries them.

### Changed

- Runtime: a gradient in bounding-box units on a shape with no width or no height (a horizontal or vertical line)
  paints nothing, as SVG says and Chrome does; it was drawn black (ending C's train trails). Test:
  test/degenerate_gradient_test.dart (336 black pixels before, 0 after).
- `alive html` leaves such a paint out and prints a warning (`5 x a bounding-box gradient on a shape with no width or
  height (trail): not painted, as Chrome`). Corpus parity: the old painter drew the same paint black (the Halfway
  Express's trails, 0.118 % of one scene's pixels), so the sweep gives it a copy of that scene's legacy art with those
  paints set to none (`oldPainterArt`); every other pixel is compared as drawn (71 scenes, worst 0.0000 %).
- safe-margin counts the app's own `ui/...` objects on a phone screen (300 by 500 pt or larger), and glows, halos,
  rings, sheens and glints from 0.2 opacity (they were left out by name); left out: `ui/` shapes wholly in the status
  bar band (top 54 pt) or the home indicator band (bottom 34 pt), and `ui/` text with no measured width (the app lays
  its text out; the 0.55 em estimate made one false error in the 24 Oct boards' 45 scenes, progress next-large's question line,
  counted in the before number below).
- Kit 1.7.0: touch is the default paw style and the rig carries it (the near paw at (140, 104), the far paw at
  (6, 106), kit 1.5.0's touching wave, thumbs, present, hold-up, carry-both, celebrate, carry-front and go-on);
  `pawStyles.detached` keeps the detached paws of the hands guide (anchors (160, 98) and (-16, 102), kit 1.6.0's actions
  and card offsets).
  Parts unchanged. The touch look references are kit 1.5.0's renders (kit-touch-r5/looks). `alive paws` and `alive lint`
  default to touch; the white History Fabio's paw stays royal in both styles. ci.sh and kit-qa: touch, then detached.
- Expected renders regenerated on purpose: 53 look references (Chrome) and 18 look goldens, no part changed; the
  example scenes follow the actions (examples/kit-motion, kit-vocab, test/assets/alive/fabio-kit) and the letter-ready
  moment's paw offsets go back to kit 1.5.0's.
- Version 0.6.2 (pubspec, `aliveVersion`, the CLI's `ENGINE_VERSION`, the example's lock); no scene needs it.

### Added

- `alive parity --every N` (2 by default; 0 for the beats only): the board played frame by frame and the engine are
  compared at every Nth frame of the whole timeline as well as at the beats; each run of differing frames is reported
  with a picture of its worst frame ("dense: X of Y frames differ"); exit 1 on it. `alive preview` takes `sheet: false`.
- `alive lint`, art scenes: `fail-sending` (error: once the saved card `ui/saved for submission` shows, a text at 0.2
  opacity or more still says Sending, Uploading or Submitting) and `fail-progress` (error: a progress object, a ring and
  its segments, a reel, a hub, the tape's marks, a needle, a count, a hole, a spinner, still turns, rolls, grows or
  lights another part after the card, past a 0.1 s grace). tools/lib/fail.mjs; tests tools/test/round8.test.mjs.

### Measured (the Diary Moments boards of 24 Oct, before these fixes)

Dense parity on the ten engine moments: C 3 of 191 sampled frames differ (one run, 9.40 to 9.53 s, 1026 px extra in
the engine: the trails), the other nine 0; at the beats 0, as 0.6.1 reported. Every one of the 45 board scenes
exported and linted: safe-margin 5 errors (the finish badge, its glow and its two rings; and the one false error,
fixed in the check), fail-sending 4 (B, C and D Not sent; Submit and not sent), fail-progress 0, flicker 2 (the
reduced motion scene's option fill and dot, new: 0.6.1 exported only the scenes with Fabio), face-missing,
face-blank and paw-blink 0. The trails on the 24 Oct board after the fix: 0 of 191 (a fresh export, and the earlier
export drawn by the 0.6.2 runtime). Kit paws: touch 0 of 79 cases, detached 0 of 79. The numbers of the boards made after
these fixes are kept with the Diary Moments boards.

## Engine 0.6.1: the board checks, and a missing face is the neutral face (24 Oct 2026; kit 1.6.0 unchanged)

**Highlights**

- A face the pack does not have is drawn as the neutral face, and reported once.
- Five lint rules for art scenes: face-missing, face-blank, paw-blink, safe-margin and flicker.
- `alive parity`: a board in headless Chrome against the runtime, picture to picture, at the board's beats.
- `alive validate` refuses a face or slot value the pack cannot resolve.

The Diary Moments boards had defects no check could see: a faceless Fabio for the whole of
two failure states (a face asked for that the figure was not given), a two-paw hold that blinked out between its
fades, a stub waiting 6 pt from the screen's edge, and the engine drawing something other than the board (ending A's
heart seal; every ending's radio dot and play triangle). Each class now has a check (docs/checks.md, with the numbers
before and after).

### Changed

- Runtime: a face the pack does not have is the neutral face. A clip's `face` channel naming one kept the look's face
  (the wrong feeling); a look naming one drew no eyes and no mouth. Both now wear the pack's neutral face, and the
  player reports the name once when the scene starts ("he wears the neutral face there instead"). The CLI's
  `resolveLook` does the same. Test: test/kit_engine_test.dart.
- `alive validate` reports as errors a kit figure's `face` or `slot:` channel value its pack cannot resolve, and an art
  scene's `face:<figure>` value with no layer `<figure>/face <name>` (docs/schema.md, faces in art scenes). `alive html`
  validates what it writes, so a board asking for a missing face is not exported.
- `alive html` carries a board dump's step channels (`channels`: seconds to ms; a pool prefix renames the figure), an
  animated height (`hv` to the box's `h`, as `wv` to `w`), a shear (`kx`: the board exporter now writes a garment's
  skew), and prints the dump's export warnings (what the board draws that the engine cannot carry).
- `alive preview` can render stills only (`video: false`: no frames written, no MP4), for `alive parity`.
- Version 0.6.1 (pubspec, `aliveVersion`, the CLI's `ENGINE_VERSION`); no scene needs it.

### Added

- `alive lint`, art scenes: `face-missing` (error), `face-blank` (error; a cross-fade with no face for under a third
  of a second is a warning), `paw-blink` (error: while his body shows his most visible paw stays at 0.8 opacity or
  more, at the clip's frame rate), `safe-margin` (error: an `item/...` object reaches into the 16 pt margin while it is
  wholly on the screen and not travelling fast; `--safe`, `--bleed`, `--no-margins`), `flicker` (error: something
  that shows drops by 0.45 or more in one frame and comes back within 0.4 s; face layers and things with no area left
  out). tools/lib/faces.mjs, face-names.mjs, paws/blink.mjs, margin.mjs, flicker.mjs.
- `alive parity <scene> --page <board> --scene <name>`: the board in headless Chrome and the scene drawn by the
  runtime, at the board's beats, picture to picture (patches missing in the engine, extra in it, or drawn differently,
  with pictures); and the board played frame by frame against the board jumped to each beat. tools/lib/parity.mjs,
  png-read.mjs (a PNG reader). Tests: tools/test/round7.test.mjs.
- docs/checks.md.

### Measured (the Diary Moments boards, before and after these checks, 24 Oct)

face channels refused by validate 2 scenes to 0; face-blank 2 scenes (90 frames each) to 0; paw-blink 2 scenes to 0;
safe-margin 5 scenes (9 objects) to 0; parity, engine differs 5 of 10 moments (32 beats) to 0; parity, played and
jumped differ 1 moment (10 beats) to 0; flicker 0 to 0 on the exports (a change on the way made 1, fixed), and
on every board scene (the boards' own probe) 2 to 0.

## Kit 1.6.0: detached paws are the default again; paw styles in the kit and the check (24 Oct 2026; engine 0.6.0 unchanged)

**Highlights**

- Paw styles in the kit: `detached` (the default in this kit) and `touch`; `withPawStyle` and `pawStyleNames`.
- `alive paws` and `alive lint` check either style (`--paws`); detached adds paw-air, paw-front, paw-reach and paw-rest.
- The white History Fabio keeps the royal paw; `--white-paw white` checks his white paw.
- A look can carry its own tints.
- Every paw action keyed to rest spots beside him: 0 of 79 kit cases fail.

Kit 1.5.0 made every paw touch Fabio and gave the white History Fabio white paws, following the team stickers. That
reversed two settled design decisions: the hands guide (paws clearly detached, about 9 units of air at rest, at least
6 when working, wholly in front of him only when both paws hold one thing, never on his outline) and the royal paw for
the white Fabio (the dark blue paw for the white Fabios). Kit 1.6.0 makes them the default again and keeps kit 1.5.0's
versions as options, so the two can be compared side by side.

### Changed

- The paw anchors are the hands guide's rest again: near (160, 98, -8), far (-16, 102, 8). Every action is keyed to
  the hands audit's spots beside him, not 1.4.0's long reaches: wave at the hands guide's (154, 42), rot 10, -8,
  9, -4 as the arrangement's; thumbs and go-on at (157, 70); present at (168, 92); hold-up and celebrate at (168, 68).
  A holding or open paw comes in on its way out and goes back to the resting paw half way home (a swapped paw at the
  rest spot reaches 7 units nearer him than the resting paw). carry-both and carry-front: the resting paws fade where
  they are and come back in front of him on the item, both holding it, the reverse at the end, so no paw slides across
  his outline; the parcel comes with them (carry-front holds it from 150 ms).
- The kit-final look references are the detached ones again (identical to 1.4.0's but pen pal's neutral face; kit
  1.5.0's in out/svg/kit-touch-r5); kit-refit/hands3/kit3.py REST is the detached rest (FABIO_PAWS=touch for kit 1.5.0's);
  kit-refit/figma/export_looks.py redraws only the twelve look references.
- `alive paws` and `alive lint` check a paw style: `--paws detached` (the default) or `--paws touch`. Detached rules:
  paw-air (at least 6 kit units of air, never on his outline), paw-front (wholly over him only in a two-paw hold),
  paw-reach (at most 40 units off him), paw-rest (a kit paw at rest at 9.25 near or 8.31 far from his bare body,
  within 1.5). Touch keeps paw-contact and paw-overlap. held-contact and paw-hidden are the same in both.
- paw-skin follows the white-paw option: the white History Fabio's royal paw by default, his white paw with
  `--white-paw white`; the blue Fabio's own blue paw.
- Kit figures are measured in their own units at their size at that instant (a pop-up from 0.6, a hop's squash), and
  a figure's look adjustments count.
- `alive paws --kit`: every action that moves a paw is also checked on a dressed figure (the letter carrier: for
  detached paws an outfit takes air away): 79 cases. tools/ci.sh runs both styles (steps `kit-paws`, `kit-paws-touch`);
  kit-qa shows both.
- Example scenes made from the actions follow them (examples/kit-motion, examples/kit-vocab, examples/moments
  letter-ready, test/assets/alive/fabio-kit); the kit-vocab clips kit 1.5.0 had moved onto him are back at their kit 1.4.0
  spots or on the new actions' keys.

### Added

- `pawStyles` in the rig and kit.json: `default` (detached: the kit as written) and `touch` (kit 1.5.0's anchors and
  the eight actions it keyed), plus per style the look matrix cards' paw offsets. `withPawStyle(kit, style)`
  and `pawStyleNames(kit)` (tools/lib/kit/compose.mjs). The Flutter runtime plays the kit as written (the default);
  switching the default is a rig change.
- docs/paws/max-air-round10.json: the 97 placements of the hands audit measured again without its 80-unit cap, with the
  subset the bound is taken from.
- A look can carry its own tints: `"tint": {slot or token: "#RRGGBB"}` in the rig's looks, applied whenever the look
  is worn, under the figure's own tints (`KitDef.lookTints` in Dart, `resolveLook` in the JS tools; `alive kit lint`
  checks them). The cold day look's knit sweater is camel (`#C59D72`, the outfit and its hem cloth), so it is no longer
  the pen pal's cream sweater (rig looks could not carry tints). Tests in kit_look_test and
  tools/test/kit.test.mjs; the cold day golden and its composed reference change on purpose.

### Measured

- `alive paws --kit`, detached: kit 1.5.0 71 of 71 cases fail (142 paws, 245 errors); kit 1.4.0 11 of 71; kit 1.6.0
  0 of 79 (air 6.7 to 23.5 kit units over every case). Touch: kit 1.5.0 0 of 71; kit 1.6.0 0 of 79.
- The bound: the hands audit's figure placements reach 38.2 (the carrier's bubble overhead); the desk's retired reaches
  start at 42.9 and run to 150. 40 = 38.2 + 1.8.
- Expected renders regenerated on purpose: 53 look references (Chrome) and 18 look goldens; no part changed.

## Kit 1.5.0 and the pixel paw check (23 Oct 2026; engine 0.6.0 unchanged)

**Highlights**

- `alive paws`: every sampled frame drawn without a browser, and each paw measured on pixels.
- `alive lint` runs the pixel paw rules by default; `--no-pixels` keeps the old centre measure.
- Rest paws touch him, and every action keeps them on him.
- New parts: the FABLA TAPE housing with a cassette bay, and the white History Fabio's own white paws.

Fabio's paws floated off him in every kit look and in four of the Diary Moments endings,
and no check could see it: `alive lint` measured each paw's centre against an ellipse fitted to his bounding box
(`paw-attached`), the figure rules measured a paw's travel from its rest. Both passed a paw 13 units off his outline
and failed one hidden behind the desk.

### Added

- `alive paws <scene>... | --kit <pack>` (docs/paws.md): every sampled frame is drawn by a small scanline rasterizer
  (tools/lib/paws/raster.mjs: path data with every command, rects, ellipses, lines, polygons, strokes, clips, boxes,
  text as its box; no browser) and each paw that shows is measured on pixels: `paw-contact` (error) it floats more
  than 0.5 kit units off his figure; `paw-overlap` (warning) it only grazes him (under 1.5 units deep, or the paw
  slots' physics max on a figure that rides physics); `held-contact` (error) an item held by a paw does not touch it,
  with R4: the far paw drawn in front, carrying the near paw's item, is measured from that item; `paw-hidden` (info)
  a paw covered by what is drawn over it, or off the screen, is not detached; `paw-skin` (warning) a paw that is not
  the colour of his body. `--out` writes a picture of each failing frame. `--kit` checks every look at rest, every
  action over time (on the bare figure, the strictest case) and the cards (the look matrix's held items and
  gestures, every handheld item on the open paw): 71 cases.
- `alive lint` runs the pixel rules by default; `--no-pixels` keeps the old centre measure. `tools/ci.sh` runs
  `alive paws --kit` (step `kit-paws`), kit-qa shows it (section "Paws on his body").
- The kit importer reads `grips_from` in an index beside the props: an effect state of an item takes that item's grip
  points (the popper mid-burst sat 6.7 units above the open paw, its box taking in the confetti).

### Changed (kit 1.5.0, 221 parts)

- Rest paws touch him: the near paw over his right edge by a third of its width (140, 104), the far paw a third
  behind his left edge (6, 106) (kit3.py REST and the rig's anchors; were (160, 98) and (-16, 102), 7 to 9 units off
  him). Every action re-keyed so each paw stays on him: wave (it waved 29 units off him), thumbs, present (26 units),
  hold-up, celebrate, go-on, carry-both, carry-front. In carry-front the far paw is the front carrying part only while
  it is on the parcel (R4); it travels behind him.
- Every look is neutral by default (pen-pal, rainy-day, cold-day and sunny-day were happy, party and space joyful):
  cheeks only in a happy or shy moment, which an action brings.
- The lab coat has no contour lines: side panels where the grey seams ran along his silhouette, lapels lifted by the
  shadow they cast, pockets as patches with their hemmed mouths, a dashed hem stitch; inner seams in a darker tone of
  the coat.
- The glasses: the near temple is a short stub that bows up and tapers, as on the canonical Professor Fabio (it ran
  16 units across his face); the far temple ends on his silhouette.
- Example scenes made from the actions follow them: examples/kit-motion (8 clips), examples/kit-vocab (7 action clips
  and 9 of its own re-keyed to the new rest), examples/moments letter-ready (the present beat), test/assets/alive/
  fabio-kit (4 clips).

### New parts

- `desk-recorder-housing-bay` and `desk-recorder-housing-bay-lip` (AR-15): the FABLA TAPE housing with a cassette
  bay; the hero cassette sits in it at 0.5 (top-left at (20.5, 27)), the lip drawn over its foot; a small LCD strip, the
  VU meter, three keys.
- Skin `white`: the white History Fabio's own paws (edge, wave, thumbs, hold, present, simple; near and far), white
  with his thin grey edge.

### Measured

- `alive paws --kit`: kit 1.4.0 71 of 71 cases failed (141 paws: 143 errors, 2 warnings; docs/paws/baseline-1.4.0.json);
  kit 1.5.0 0 of 71.
- Expected renders regenerated on purpose: Chrome references and goldens of 3 changed parts (kit-glasses,
  outfit-lab-coat, skirt-lab-coat), 14 new parts, every look; nothing else moved.

## 0.6.0 (23 Oct 2026)

**Highlights**

- A clip keeps its keys in typed arrays: less heap per scene, the same values.
- `alive pack` writes path data short and linear tracks as compact keys: the app's 46 scenes 705 to 469 KB gzipped, the same pixels.
- Compact keys in alive/1 (`{"dt": [...], "v": [...]}`); such scenes need engine 0.6.0.
- `AliveCache.dispose()`, and a cache no longer keeps its memory-pressure listener after its preloads are gone.

### Fixed

- A cache that had preloaded kept its memory-pressure listener on the app's binding for good, so the binding held
  that cache (and a test that made many caches held them all). The listener is now removed when the cache's last
  preload is taken over by a controller, runs out of time, is released (`releasePreloads`, memory pressure) or
  fails to load, and added again by the next preload. Swept: it was the only binding observer in the package (the
  controller's lifecycle listener is disposed with it; its post-frame callbacks run once).

### Changed

- A clip keeps its keys in plain typed arrays (`ClipKeys`: every key number in one buffer, four ints a track, two a
  keyed layer, a segment hint per track) instead of a `Track` object per track; the player samples the arrays. The
  same values (the parity tests at 1e-9 pass unchanged). Measured (COST, the app's 46 scenes): heap held by the
  recording scene 443 to 273 KB, median 55 to 50 KB. `ClipDef.tracks` is now a getter that builds `LayerTracks` and
  `Track` views of the arrays on each call (reading it is unchanged; the player no longer reads it).

- `alive pack` writes path data short (each segment in the shorter of its absolute and relative forms from the same
  rounded points, lines along an axis as H or V, a command letter only where it changes) and leaves out the files'
  `source` notes (nothing reads them at run time; the unpacked folder keeps them). The app's 46 scenes packed with
  `--share`: 705 to 524 KB gzipped (the COST method: each file gzipped by dart:io, 23 Oct 17:05), the same pixels as
  before exactly (largest channel difference 0 over 459 frames). Plain SVG path data: no newer engine reads it
  differently.

- `alive pack` writes a track whose segments are all linear in the compact key form where that is shorter:
  `{"dt": [ms, ...], "v": [...]}` (the first key's time, then the time since the key before; the values in one list).
  The app's 46 scenes packed with `--share`: 524 to 469 KB gzipped, the same pixels exactly (largest channel
  difference 0). Such scenes are stamped `"requires": "0.6.0"`; `--keys list` keeps the lists for an app on 0.5.0.

### Added

- Compact keys in alive/1 (docs/schema.md): a property's keys may be `{"dt": [...], "v": [...]}` (every segment
  linear), read by the runtime and every CLI reader (validate, lint, info) as the list they stand for; times to a
  thousandth of a millisecond. Shared schema fixtures `ok-compact.json`, `bad-compact-keys.json`.
- `AliveCache.dispose()`: lets go of the cache's preloads, removes its listener and refuses new loads (`acquire`
  throws an `AliveLoadError`, `preload` returns one per scene, `tryAcquire` gives null); scenes screens hold stay
  until those screens let go. A second call does nothing; `AliveCache.shared` lives as long as the app and throws a
  `StateError`. `AliveCache.isDisposed`, `AliveCache.watchesMemoryPressure`.

## Kit 1.4.0 (23 Oct 2026): the front paw and the hem, on engine 0.5.0

**Highlights**

- A front z for the far paw: `carry-front`, a parcel carried with both paws, the far paw in front.
- Hem slots: a skirt for every outfit, waving after a hop or a turn.
- `examples/kit-motion/scene.json` shows both: the hem on two hops and a turn, and the two-hand carry.

### Added

- `"zFront": 117` on the far paw's slot: `hand-carry-front-far-*` (tagged front) draws over the held item and under the
  near paw. `hand-carry-side-near-{blue,royal}`: the M3 near paw with a carry grip (fingers into the item from its right).
  Action `carry-front`: a parcel carried with both paws, the far paw in front.
- The `outfit-skirt` hem slot and a skirt for every outfit (`skirt-<outfit>`, 15), worn by every look with an outfit;
  the hem waves after a hop or a turn when the figure rides physics, and holds its line at rest and with reduced motion.
- `examples/kit-motion/scene.json`: the hem on two hops and a turn, and the two-hand carry (physics on).

### Known

- `alive lint` flags `carry-front`: the far paw travels 88 kit units from its own rest (the ring is 50), though it stays
  on his body holding the same item as the near paw. Still to do: measure a front-z paw by the held item.


## 0.5.0 (23 Oct 2026)

**Highlights**

- Preloading: `AliveController.preload` loads the next page's scenes ahead.
- Large files are parsed in an isolate and art is prepared in slices after frames, so pages open without hitches.
- `alive pack`: scenes written smaller for shipping, with shared art written once.
- His eyes on a point (`lookAt`), the kit blink, skew, trimmed strokes, plugin nodes and font mapping.
- `requires` stamps, and the public API checked by `tools/api.mjs`.

Pages open without his hitches: scenes load off the page's frames and can be loaded ahead. Measured on the
page-opening benchmark (docs/scoreboard.md, P1).

### Added

- `AliveController.preload(scenes)` and `AliveCache.preload(library, scenes, keep:)`: load scenes on the page before;
  each is held until a controller takes it over, or for `keep` (30 s). Returns the scenes that failed; never throws.
  `AliveCache.tryAcquire`, `AliveCache.isLoaded`.
- A controller whose scene is loaded already (preloaded, or on another screen) is ready in its constructor; its events
  (`AliveLoaded`, the first clip's) still arrive, in order, to listeners added right after it.
- `AliveLibrary.assets(background: true, backgroundMinBytes: 16384)`: files of 16 KB or more are decoded and parsed in
  a short-lived isolate, their SVG path data read into drawing commands there; the art is then prepared in slices of
  `AliveCache(prepareSlice:)` (4 ms), each after a frame while frames are coming.
- `CompiledArt.prepare` and `AliveSceneData.prepare` (the same result in slices), `ArtDef.parse(prepare: true)`
  (path commands ahead of time), `Geometry.commands`.
- A loaded scene is drawn once off screen (texts that follow a layer's colour laid out, kit parts compiled), so his
  first frame on screen only replays.
- Benchmarks: `benchmark/open_benchmark_test.dart` with `tools/bench-open.mjs` (page opening, the engine's frame
  timings, on against off against preload; `OPEN_TIMELINE=1` reads the VM timeline), `benchmark/scene_cost_test.dart`
  (load, heap and size of every scene of a folder). `docs/scoreboard.md`.
- `tools/ci.sh`: the whole suite in one command (analyze, Flutter tests, CLI tests, corpus parity, kit-qa gated).
- Kits: a slot's front z (`zFront`): a part tagged `front` draws there (the far paw over a held item, under the near
  paw; `hand-carry-front-far-*`). Hem slots (`hem`: an edge, a ripple, a shear): the slot's cloth is clipped above a
  resting line just under his outline, ripples below it with the slot spring's energy after a move and shears by its
  lag, in the fixed steps; still with reduced motion; `alive kit compose` clips it at its line; `alive kit lint`
  checks both.
- `alive lint` paw ring for a two-hand carry: a far paw at its slot's front z carrying the item the near paw holds is
  measured from that item (within its half width plus 12) instead of its own rest; on its way round it may still be
  within the ring of its rest (the pack's `carry-front` lints clean).
- `alive lint`: a look, a clip's `face` or `slot:` channel, or a pool's `wear` naming no part of the pack (or a slot
  the pack lacks) is an error (`unknown-part`, with the names the slot knows); the runtime reports each once when the
  scene starts (`AliveUsageError`).
- `AliveSceneData.releaseArtTrees`, `AliveCache(keepArtTrees:)`, `ArtDef.header`, `CompiledArt.releaseTree`.
- Trimmed strokes: `trimStart` and `trimEnd` on a layer (0..1) cut the strokes under it from where SVG starts each
  shape (a board's stroke-dashoffset progress ring, a tick drawn on); strokes under a trimmed layer are drawn per
  frame, the cut cached while the share holds. `alive upgrade` and `alive sweep` keep a board's trim keys (they were
  dropped); `--no-trims` drops them as before (the corpus parity sweep uses it: the old painter drew strokes whole).
- `alive pack <scenes> --out <dir> [--share] [--min 4000]`: an app's scene folder written smaller for shipping, the
  same pixels: numbers to the precision the screen shows (path positions rounded where they land, so relative
  commands never drift and closed shapes stay closed), and with `--share` art that two or more scenes draw the same
  written once (`_shared/<id>.json`, kind `fragment`; `{"use": "<id>"}` nodes; the scene's `"shared"` list), put back
  by the loader (`ArtDef.splice`, `SceneDef.shared`). The app's 46 scenes: 1,060 to 705 KB gzipped, 4.65 to 2.70 MB raw;
  `test/pack_parity_test.dart`: 0 of 459 frames with a pixel over 40 of 255.
- Fonts: text in any family keeps its family as a font key (`IBM Plex Mono` is `ibm-plex-mono`) and
  `AliveFonts(families: {'ibm-plex-mono': 'IBMPlexMono'})` maps it to the app's registered family; a key with no
  family draws in Rubik, as every unknown family did before (no pixel changes for existing scenes).
- Plugin nodes: `{"plugin": "<kind>", "w", "h", "params"}` in art, drawn by the app's painter
  (`AliveController(extensions: AliveExtensions(nodes: {'<kind>': AlivePlugin(paint, animates: ...)}))`) in the
  node's box at its place in the tree, reading `AliveFrame` (time, clip, inputs, channels, layer values); a kind with
  no painter draws nothing and is reported once.
- Entry points: `package:alive/alive_core.dart` (playing scenes), `alive_kit.dart` (figures and looks),
  `alive_tools.dart` (files, player, compiled art); `alive.dart` exports all three, as before. `docs/extending.md`
  (plugins, fonts, kits, shipping, the stability policy). `docs/api.txt`, the reviewed public API, checked by
  `node tools/api.mjs --check` in `tools/ci.sh`.
- `requires`: the CLI stamps a scene that uses a 0.5.0 feature (skew or trims, a gaze, a kit blink, shared art,
  plugin nodes) with `"requires": "0.5.0"`; the runtime refuses a scene that needs a newer engine with a message that
  says which (`aliveVersion`, `compareVersions`), before any other problem.
- `AliveCache.releasePreloads()`, called by itself when the system reports memory pressure: preloaded scenes no screen
  shows are let go.
- `AliveStage(deferFirstPaint: false)` paints a scene that is ready when the stage is built in the same frame.
- His eyes on a point: `live.gaze` (layers that move toward it by at most their offset, smoothly, fixed-step; a kit
  figure's open eyes swap to the pack's `look-<direction>` parts) and `AliveController.lookAt` / `lookAtLocal`
  (the text answer's caret).
- A kit figure blinks: `live.blink.figure` swaps its open eyes (tagged `pill` or `pill-wide` in the pack) to the
  pack's blink parts during the blink; other eyes do not blink.
- Skew: `kx` and `ky` on a layer (degrees, about its pivot, before scale and rotation; CSS `skewX` and `skewY`).
- `LayerProp` has four more values (`kx`, `ky`, `trimStart`, `trimEnd`, before `fill` and `stroke`):
  `LayerProp.numeric` is 13 (was 9). Code that names properties is unchanged; code that stored `LayerProp.index`
  values must store names.

### Changed

- A scene loaded through the cache lets go of its parsed art trees once prepared (what is static is in pictures,
  what moves is compiled): `AliveSceneData.arts` then hold headers (id, size, offset, layers). Measured: Dart heap
  held per scene, median 195 to 74 KB, max 1,039 to 708 KB over the app's 46 scenes. `AliveCache(keepArtTrees: true)`
  keeps them for tools.
- Tracks keep only what they need: no ease list when every segment is linear, only the properties a layer keys
  (`LayerTracks.props`, `tracks`, `track(prop)`), a clip's key numbers in one buffer. `Track.times`, `values`,
  `eases` and `LayerTracks.byProp` still read the same, built when read. Measured: heap held per scene, largest 708 to
  503 KB, median 74 to 58 KB; load unchanged.
- A stage built on a scene that is ready paints him from the next frame (the frame that builds the page is its
  heaviest).
- Widget tests on the assets library: the isolate is real asynchronous work like the asset read itself; let it go on
  with `tester.runAsync` between pumps, or pass `AliveLibrary.assets(background: false)`. Memory libraries load as
  before (all on the UI thread, in one go).

## Kit 1.3.0 (23 Oct 2026): the vocabulary, part 3

**Highlights**

- Encouraging faces, actions and pools: you-did-it, no-worries, go-on.
- Nine more outfits drawn with more detail.
- The space helmet's glass reads by its own volume; the sunglasses, umbrella and flower pot gain a second tone.

### Added

- Faces `you-did-it` (a calm well done), `no-worries` (gentle reassurance) and `go-on` (encouraging), split like every
  face; actions of the same names (a slow nod, a head tilt, two eager bounces and a thumbs up) and the pools
  `well-done`, `reassure` and `cheer-on`, which play them in any look of the kit.

### Changed

- The other nine locked outfits carry kit 1.2.0's detail density, upgraded in place (same ids, shapes, colours and
  layout): gardener, utility vest, photographer, meditation robe, doorman coat, knit sweater, track jacket, pajama top,
  safari shirt. All twelve originals are in out/svg/kit-locked-r1/. Their goldens, reference renders and the kit's look
  references changed on purpose.
- `hat-space-helmet`: the glass reads by its own volume (a radial tint, clear in the middle, deeper at the rim), no edge
  line. `kit-sunglasses`, `prop-umbrella`, `prop-flower-pot`: a second tone and more construction detail.

## Kit 1.2.0 (23 Oct 2026): the vocabulary, part 2

**Highlights**

- The satchel in layers, for a letter that drops into it, and the hero cassette in layers.
- The space explorer look, and seasonal looks and items.
- More construction detail on four outfits.

### Added

- The satchel in layers for a letter that drops into it: `kit-satchel-back`, `-mouth`, `-letter`, `-front`, `-flap`,
  `-flap-open` (back, letter, front and flap stack to `kit-satchel`, 0 pixels over 32 at 4x; the flap's hinge and the
  open flap's pivot in kit-final/kit/satchel-layers.json). Asked for by the Diary Moments boards.
- The hero cassette `desk-cassette-hero` (250 x 160, the kit tape's palette, the label blank) and its layers for boards
  (shadow, cavity, reels, tape, hubs, shell with the window cut out, glass) in kit-final/items/cassette-hero/ with the
  reel and hub pivots.
- The space explorer: `outfit-space-suit` and `hat-space-helmet` (a tinted glass dome seated on the suit's neck ring);
  look `space`.
- Seasonal, no holidays: `kit-sunglasses`, `kit-earmuffs-far` and `kit-earmuffs-near` (the headset's band and near cup
  places), `prop-umbrella`, `prop-flower-pot`; looks `cold-day`, `sunny-day`.
- Hem-swing skirts for all 15 outfits (art, not in the pack: they wait on an engine slot) in
  out/svg/kit-swing/*.skirt.svg.

### Changed

- The host cardigan, conductor jacket, postal jacket and lab coat carry more construction detail (knit texture and
  ribbing, a watch chain and piping, pleated pockets and a waistband, topstitching), same ids and layout; their goldens
  and the kit's look references for host, conductor and letter carrier changed on purpose. The eye parts' edges sit
  on the quarter-unit grid (the worst part at 4x went from 0.985 % to 0.000 % in regions).


## Kit 1.1.0 (23 Oct 2026): the vocabulary, part 1

**Highlights**

- New faces and whole-face blinks, the eye channel and the look actions.
- Hats, accessories, outfits, props and three new looks.
- The two-paw carry and the celebrate action.
- `alive kit import --into <pack> --rig <rig>` adds parts and replaces the rig's looks and actions.

Fabio's visual vocabulary grows at the team sticker bar, as parts of the pack (no runtime change; 39 parts, no locked
part changed). Generators: `<boards>/illustration/kit-refit/vocab/` (they write into kit-final; the kit's own
export calls them, so a full re-export keeps them).

### Added

- Faces: proud, curious, focused, sleepy-happy, wink (split into eyes, brows and mouth like every face), and the
  whole-face blinks `face-neutral-blink` and `face-neutral-blink-half` (asked for by the Diary Moments boards).
- The eye channel: `eye-look-{left,right,up,down,up-left,up-right,down-left,down-right}` and the blink frames
  `eye-blink-half`, `eye-blink-closed` (and `-wide` for the big round eyes), a new `eyes` folder rule; actions `blink`,
  `look-left`, `look-right`, `look-up`, `look-down`.
- Hats: party hat, rain hat. Accessories: bow tie, lanyard. Outfits: lab coat (the team's "i catch feelings
  scientifically" sticker), raincoat. Looks: researcher, rainy day, party.
- Props: popper, popper-burst, pennant, balloon, sealed diary, mail bag, stamp (all handheld); desk: bunting.
- Paws: the two-handed carry `hand-carry-both-{wide,narrow}-near-{blue,royal}` (both M3 paws on top, fingers into the
  item; a carry paw, so the near paw stays near its spot) and action `carry-both`; `hand-carry-front-far-*`, the far
  paw for a future layer in front of the held item. Action `celebrate` (popper lifted, pulled, a hop).
- `alive kit import --into <pack> --rig <rig>`: the rig's looks, actions, pools and lists replace the pack's, its
  folder rules join them, and the version is bumped.
- Import tags each part with its whole name when it has several words, so `sleepy-happy` or `look-up-left` resolve.

### Fixed

- `ticket` in the held slot resolved to the ticket punch (fewer tags); it now returns the ticket.
- `examples/kit-vocab/scene.json`: every new action and demo clips (eyes tour, faces tour, carries, celebration).

## 0.4.0 (22 Oct 2026)

**Highlights**

- `alive preview`: a scene drawn by the runtime itself, as MP4, GIF or a review page.
- Moment files and `alive moment`: beats compiled to a scene, with the art and motion rules.
- The alive-author skill for Claude Code: a moment from words or rough images, no API key.
- `alive prompt` and `alive sketch` through the Anthropic API; `alive storyboard` from Figma frames.

Authoring without Figma Motion: a moment from words, from rough images, or from Figma frames as a storyboard. Every
route ends in a validated, linted scene and a preview drawn by the runtime.

### Added

- `alive preview <scene>`: the scene drawn by the runtime itself (`test/preview_test.dart` loads it with the
  runtime's loader, kit packs included, advances an `AlivePlayer` frame by frame and paints with the stage's steps),
  encoded by ffmpeg as MP4 or GIF, or wrapped in a review page; a contact sheet and stills. `--draft`, `--look`,
  `--viewport`, `--at`.
- Moment files and `alive moment`: a kit figure, items (kit props, simple shapes), confetti or sparkle, and beats
  (key poses in time, each with its cause; kit actions on top of the pose; the bubble; cues) compiled to a scene with
  `figures`. `alive catalog` lists what a moment can use.
- The alive-author skill (`.claude/skills/alive-author/`: SKILL.md, the moment format, the motion law, the review
  checklist): Claude Code authors a moment from words or rough images with no API key, and iterates on the
  runtime's stills.
- `alive prompt "<words>"` and `alive sketch <images>`: the same through the Anthropic API when ANTHROPIC_API_KEY is
  set (default model claude-opus-5-5, `--model`; problems from validate and lint go back to the model until the
  moment passes). The SDK is an optional dependency. Without a key they say how to use the skill route.
  `alive sketch --beats <moment>` compiles a moment read from images and previews each image beside its beat.
- `alive storyboard <name>`: Figma frames as the beats of one flow, Smart Animate style (layers matched by name path
  and content; eased moves, size and colour changes, fades where layers appear and leave), timing from frame names
  ("03 Tap Record 0.6s ease-out hold 1.2s"), a `notes` layer or `--timing`; through the `alive figma` converter, so
  Figma's own Fabio is the art. `tools/figma/read-storyboard.figma.js` (read only) and `tools/figma/storyboard.mjs`
  save a storyboard to `tools/figma/cache/storyboards/` (the Halfway Express storyboard is there).
- Lint: the art rules for kit figures (no pointing paw, M3 paws, holding paws within 50 kit units, held items only
  on holding paws, body colour) and the motion rules (causes, eased moves, no snaps, a purposeful pause, notes), on
  for authored moments and with `alive lint --motion`.
- `tools/figma-proof.mjs plan --at <ms,...>`: instants of your own.
- docs/authoring/ (one page per route), docs/authoring-proof.md (four moments, every pass, the storyboard measured
  against the approved film: 1.5 % of the picture differs on average at the six figma-proof instants).

### Fixed

- `alive figma`: art borrowed from another export could not be a single shape (a text's outlines, one path); it
  came out empty. No existing conversion used one (`alive figma --all` writes the same files).

## 0.3.0 (22 Oct 2026)

**Highlights**

- Art packs (kits): Fabio as named slots filled from a pack, composed at run time.
- `alive kit import`, `lint`, `compose`, `scene` and `refs`.
- Looks and customisation: `AliveLook`, `dress`, `wear`, tints; the same action plays on any look.
- Every part and look checked against Chrome, pixel by pixel; renderer fixes for dashes, gradients and clips.

Kits: Fabio as named slots filled from an art pack, composed at run time, customisable, and checked pixel by pixel
against the kit's own renders.

### Added

- Art packs: `kits/<id>/kit.json` (kind `kit`: canvas, bones, slots with anchors, attach rules, drawing order and
  alternate order, allowed adjustments and physics; grips (M3); skins; tint tokens; the parts index; looks; actions;
  pools) and `kits/<id>/parts/<part>.json` (plain art). The Fabio pack in `kits/fabio`: 134 parts from the kit page
  Fabio kit (final), faces split into eyes, brows, mouth, cheeks and marks (194 parts), the twelve looks of the kit,
  seven actions, three pools. The rig is `tools/kit/fabio.rig.json`, every number cited.
- `alive kit import <svg folder | Figma export>... --rig <rig> --out <pack>` and `--into <pack>` (new parts join a
  pack: no engine change); `alive kit lint` (canvas size, anchors and grips, stroke-only shapes, white lenses, no
  pointing paw, M3 paws, the body colour, what the renderer leaves out, looks, actions and pools resolve);
  `alive kit compose` (a look as one SVG); `alive kit scene` (a scene with a figure and the pack's actions);
  `alive kit refs` (Chrome reference renders).
- Figures in scenes (`figures`, the figure id in `art`), a `part` art node, clip channels `face` and `slot:<slot>`
  that swap parts while a clip plays, pool variants that `dress` and `wear` from the kit (`@looks`, `@<tag>`).
- `AliveLook` (preset, parts, tints, skin, `AlivePartAdjust` clamped to the slot's range), `controller.dress`, `wear`,
  `takeOff`, `kitLook`, `worn`, `kit`; `AliveKit` (`KitDef`). The same action plays on any look.
- Visual congruence: `test/kit_congruence_test.dart` (every part against Chrome), `test/kit_look_test.dart` (the kit's
  twelve looks against the kit's own renders, the CLI's compositions, 22 more looks, and the customisation API),
  `test/kit_congruence_gate_test.dart` (negative controls), golden images of every part and look, and the QA sheet
  (`npm run kit-qa`, `tools/kit-qa.mjs`). Renderer test cards in `test/kit/cards-src`.

### Fixed (the renderer, every scene)

- A filled shape with a dash pattern lost its fill (the fill used the dashed path; the old painter filled the whole
  shape). A gradient on a dashed stroke now takes the whole shape's box.
- Dashed rects and ellipses start their dashes where SVG starts them (a rect's top left, an ellipse's right end).
- The miter limit is read; gradient `spread` (reflect, repeat), radial focal points and one-stop gradients are drawn;
  a clip shape's even-odd rule is drawn (the exact union of the clip's shapes).
- SVG text with letter spacing sat half a spacing to the right.
- None of this changes a legacy export: `alive upgrade` and `sweep` write the same art byte for byte, and the corpus
  parity holds (71 exports, 213 frames, 0 % of pixels over 40).

### Measured (22 Oct, flutter test against headless Chrome, 2x)

- 134 of 134 kit parts within the gate (worst 0.54 % of drawn pixels in regions; worst 5.5 % over 32 on the small eyes,
  anti-aliasing of their curves; at 4x worst 3.0 %). 46 of 46 looks (worst 0.01 % in regions, 0.09 % over 32). 19 of 19
  renderer cards (text: within one pixel, see docs/limits.md). Not measured on a device renderer (Impeller).

## 0.2.0 (22 Oct 2026)

**Highlights**

- `alive figma`: a Figma Motion frame straight to a scene, Figma's own Fabio as compiled art.
- Figma's keys and easing mapped exactly; V1 to V3 frames become one pool.
- Proved against Figma's MP4 exports: 41 frames, 0.8% of the picture differs on average.

The lean Figma Motion converter: a Figma Motion frame straight to a scene, with Figma's own Fabio as compiled art.

### Added

- `alive figma <dump.json>... --id <scene> --out <dir>`: the keyframe dump under `<boards>/motion` (any of its
  shapes: one frame, several moments, V1 to V3 versions) names the frame; its read and SVG export come from the Figma
  cache (`--cache`, `ALIVE_FIGMA_CACHE`, default `tools/figma/cache` in this repository: the 6 Oct reads and SVG
  exports of all 41 frames, copied from fabio-engine-plus, the exports brotli-compressed). Fabio, his
  props and outfits are the frame's own vectors: no engine-drawn Fabio, so the moment runs on the lean runtime. Every
  kit part and every layer named `fabio...` is its own layer; `roles.fabio` and `meta.figma` say which is which.
- Figma's keys as they are (translation, rotation, scale, opacity, width and height, fills and strokes, corner radius)
  and Figma's easing mapped exactly (linear, HOLD, the cubic and back curves, custom cubics, spring presets, custom
  springs). A dump's beats become cues.
- Kit parts the SVG export leaves out (opacity 0 at rest: faces that fade in, paws that appear, a headset) are drawn
  from a visible instance of the same component elsewhere in the cache, or its mirror; other left-out layers from the
  geometry reads and the per-moment fixes. Everything filled in is noted per layer; nothing is dropped silently.
- Several frames (V1 to V3) become one scene with a pool; `--frame` picks one; a dump with several different moments
  gives one scene per moment; `--all` converts every moment of the cache with a manifest.
- A dump that disagrees with the frame (length, layers) is reported; a board page dump is refused with a pointer to
  `alive html`; a frame the cache has no read for is refused with what to do.
- `tools/figma/fixes.json`: facts read from Figma on 22 Oct (read only) that the 6 Oct cache lacks (fonts, layer
  order, the paint of children read only as boxes, frames no longer in Figma), and the read scripts
  (`read-frames`, `read-nodes`, `read-facts`).
- The art rules read the kit map of a converted scene: pointing paws by their kit pose, holding paws (Pose=Hold)
  measured in kit units at that Fabio's own scale, every Fabio of a frame on its own.
- The proof: `tools/figma-proof.mjs` and `test/figma_proof_test.dart` draw every converted moment with the runtime at
  the instants of Figma's MP4 export and measure the difference (`docs/figma-proof.md`): 41 frames, 246 instants,
  0.8% of the picture differs on average (the procedural import measured 1.3% on the same instants); 0.9% on eight
  moments against fresh exports made today.
- Tests: CLI tests on a hand-written Figma cache and one real frame (`tools/test/figma.test.mjs`), golden images of
  four converted moments (`test/figma_golden_test.dart`).
- Docs: "From Figma Motion to the app in one command" in `authoring.md`, `figma-proof.md`, `meta` in `schema.md`, the
  steps to re-record `procedural/`'s parity fixtures in `limits.md`.

### Changed

- A text box (a Figma text read, a board's text box) shares its line height evenly above and below the line, as
  Figma and CSS do; Flutter's default put Rubik about 1.5 px lower at 16 on 24. SVG text (one line on its baseline) is
  unchanged.

## 0.1.0 (22 Oct 2026)

**Highlights**

- alive/1: one versioned schema for scenes and compiled art, checked the same way by the CLI and the runtime.
- `AliveController` and `AliveStage`: app state, mic level, taps, events, looks, cues, anchors.
- Variant pools, live breath and blink, worn-item physics, reduced motion and semantics.
- The `alive` CLI: upgrade, validate, lint, sweep, info.

The first version of `alive`, the production runtime for Fabla's designed Fabio moments, with the `alive` CLI.

### Lineage

- The repository starts from `fabio_plus` as it was in `fabio-engine-plus` (`flutter/fabio_plus`), the
  copy the app spike vendored (its `packages/fabio_plus`). That code is kept whole in
  `procedural/`, renamed `alive_procedural`; its parity tests read the reference presets from `<fabio-engine-plus>`.
- `fabio_plus` itself ports the Fabla team's procedural engine (branch `feature/fabio-animation`, Fabio Studio).
- The new runtime keeps the old lean art path's drawing rules (FigmaRig's transform model, FigmaArtPainter's paint
  rules) and is checked against them pixel by pixel.

### Added

- alive/1: one versioned schema for scenes (layers, clips, pools, looks, states, events, live behaviours, inputs,
  bindings, worn items, anchors, semantics, meta) and art (compiled vector art), checked by the CLI and the runtime
  with the same rules and the same error paths (shared fixtures).
- `AliveController` and `AliveStage`: load a scene by id (`scene` or `scene/clip`), async, shared through a
  refcounted cache and released when the last screen goes; app state, mic level, taps, events, looks, live layer
  offsets, holds at cues, `play(from:)`, seek; events for loads, clips, cues, bubble text, state changes and failures;
  anchors and world-to-local mapping; parts drawn by the app (`AlivePart`, `paintArt`).
- Variant pools ("fresh every run"): never the last pick, remembered through a pluggable `AliveStore`, seeded by
  diary, day and question when given.
- Live behaviours from scene data: breath, blink, the nod at the end of a loud stretch of the mic.
- Worn-item physics: a damped spring with tilt, in fixed 1/240 s steps (the same poses at any frame rate).
- Reduced motion (the OS setting: still poses; cues and clip ends keep their times), pause in the background,
  TickerMode, a calm switch (no live behaviours), errors that never reach the widget tree (fallback widget, events).
- Semantics: decorative by default, labels from the scene per app state or from the app.
- SVG text drawn (anchors, weights, letter spacing, colour that follows a layer); the old runtime left it out.
- CLI: `upgrade` (legacy exports and the app's alive_v0 folders), `validate`, `lint` (art rules), `sweep` (every
  board export), `info`.
- Tests: schema, timing, holds, states, pools, store, looks, bindings, behaviours, physics determinism, controller and
  stage (fallback, reduced motion, lifecycle, semantics, cache), render parity with the old runtime (the spike's two
  flows and all 71 board exports), golden images, CLI tests.
- Benchmark: old against new in one process, with budgets.
- Docs: integration and authoring guides, schema reference, architecture, performance, limits.

### Changed (from the old lean path, for apps that used it)

- No SVG parsing in the app (no `xml` dependency); art is compiled by the CLI.
- No global registry (`FIGMA_ART`) and no engine data assets in the package.
- Frame work on the UI thread is about 10 to 15 times lower at p50 and 5 to 19 times lower at p99 in the benchmark
  (see `docs/performance.md`).

### Known state of `procedural/`

- Its own tests run 67 passing and 111 failing, exactly as in fabio-engine-plus's own layout: the parity
  fixtures were recorded at its stage 4 and the JavaScript engine changed after (wardrobe gaps, physics feel,
  paws). Re-recording them (`npm run flutter-parity` in fabio-engine-plus) was not done here: that repository has
  uncommitted work. `alive` does not depend on it at run time.
