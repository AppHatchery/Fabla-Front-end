# Known limits

What Alive does not do, or does only partly, as of 23 Oct 2026 (the flicker line: 26 Oct, 0.6.3). Each line says what happens instead.

## Not measured on a phone

- No iOS or Android build was made from this repository, and no simulator was run (the laptop rules of this work).
  Frame build and raster on the simulator, heap on a device and the size added to the APK and IPA are requested from
  the app integration's harness (simulator and Android runs). The numbers in `performance.md` are from `flutter test` (debug JIT,
  software renderer) on a laptop that was paging.
- Impeller has not drawn these scenes here; blur and drop shadows are the parts most likely to look different.
- Raster time is not measured on this side at all: flutter test has no screen behind its frames (their raster time
  is under 0.2 ms whatever is drawn). The page-opening benchmark measures the UI thread (build, and how late frames
  start); raster comes only from the app integration's simulator runs.
- The page-opening benchmark runs in debug (JIT): the first entry of each run pays for compiling the engine's code,
  which a release build does not.

## Drawing

- Inner shadows are left out (as the old runtime did), and a filter's region is not clipped.
- Trimmed strokes (`trimStart`, `trimEnd` on a layer, 0.5.0) cut every stroke under the layer by the same share of
  its own length; there is no trim offset, and a dashed stroke is dashed after the cut. `alive figma` does not read
  Figma's trim keys yet (none of the cached frames keys one, so the field names and units are not checked); `upgrade`
  keeps a board's `trimEnd` (its stroke-dashoffset rings) unless `--no-trims`. Measured against reference drawings
  (arcs and lines) in test/trim_skew_test.dart, not against Chrome.
- `<image>`, `<mask>` and `<pattern>` in the SVG are not drawn (`upgrade` and `kit import` note each). `<use>` is drawn
  for new art (`alive kit import`), not for legacy exports; a `<use>` of a `<symbol>` is not drawn.
- CSS `style` attributes on SVG shapes are read for new art (`alive kit import`) and not for legacy exports
  (`upgrade` keeps the old painter's output exactly); text boxes read theirs.
- SVG `<tspan>` positions are ignored: spans run on one line from the text's anchor.
- Text whose colour is `currentColor` follows its layer's colour without that colour's alpha (as the old runtime did
  for animated colours).
- Gradients are not animated (a layer's colour channel animates flat colours only).
- Text in a family the app has not registered draws in Rubik: a board's IBM Plex Mono digits sit slightly apart
  (Diary Moments). The CLI keeps each family as a font key (0.5.0); register the font in the app and pass
  `AliveFonts(families: {'ibm-plex-mono': '<family>'})` to the library.
- Text is laid out by Flutter, so a line can wrap or sit a pixel differently from the browser that made the export. A
  text box shares its line height evenly above and below the line, as Figma and CSS do (since 22 Oct).
- Blur and drop shadows are Flutter's: in the Figma proof they are most of what differs in Tips open (1.4%).

## Kits

- Compared with Chrome, small shapes differ in single edge pixels: his eyes (8 by 14 pixels at 2x) show up to 5.5 % of
  their pixels over 32 at 2x (3.0 % at 4x), because the two renderers anti-alias tight curves differently. Magnified
  10 times the same shapes match (test card `arcs`); the gate counts only differences that form regions.
- SVG text sits up to half a kit unit higher than in Chrome at 26 px (0 at 18 px); within one pixel, and kit parts
  carry no text.
- Faces are split into features by where each shape sits and its colour (rules in the rig); a new face drawn
  elsewhere on his canvas may need the rules adjusted. Drawn together the features are the face (checked).
- A clip's `face` channel changes the expression of the scene's first figure; blinking a kit figure (the scene's
  `live.blink`) is not wired to face features yet.
- Physics on slots is off unless the figure asks for it (`"physics": true`), as the headset settle is not switched on yet.
  Hem slots (0.5.0) wave only with it: without physics, and with reduced motion, the cloth holds its resting line.
  The outfit only tilts (it does not swing at its hem as the board pages' garments do: no skew property yet).
- Tints shift colours in HSL by the key colour's offset; a family whose key is near grey or near white can shift less
  than expected. Tinted parts are compiled once per tint and kept while the scene is loaded.
- A scene loads the parts its figures' looks, clip swaps and pools name; other parts load when the app asks
  (`dress`, `wear`), so a part from outside them appears a frame or two later.
- Not measured on Impeller: the congruence numbers are `flutter test`'s software renderer against Chrome.

## Data

- Figma Motion frames convert with `alive figma` (Figma's own Fabio as art), from the Figma cache of 6 Oct: 41 frames,
  0.8% of the picture differs from Figma's MP4 exports on average (`figma-proof.md`). What it does not do:
  - a moment made in HTML (warnings, rescue and cast rounds 3 and later) has no Figma frame; `alive figma` refuses a
    board page dump and points to `alive html`;
  - a frame designed after 6 Oct needs a read and an SVG export in the cache first (run
    `tools/figma/read-frames.figma.js` through `use_figma`; Node cannot read Figma Motion keys on its own, the REST API
    does not carry them);
  - a kit part the export left out (opacity 0 at rest) is drawn from a visible instance of the same component
    elsewhere in the cache: an instance override (a recoloured body, a swapped glyph) is not seen, except the drained
    body the warnings name in `moments.json`;
  - four frames converted from the cache are no longer in Figma (both Battery moments, both Mic moments), so they
    cannot be read or exported again;
  - a custom spring's bounce is read as a damping ratio of 1 - bounce at stiffness 170 (the reading fabio-engine-plus
    used); none of the 41 frames uses a spring, so it is not measured against a Figma export. The spring itself is
    checked against a physics reference (0.5.0, test/spring_test.dart: the closed form within 1e-6 of a fine numerical
    integration, under, critically and over damped). A spring needs its key's span to settle: Figma's presets take
    0.66 s (gentle), 0.48 s (quick), 0.58 s (bouncy) and 0.92 s (slow) to come within 1 %; a shorter span jumps at the
    key, and `alive lint` warns (`spring-cut`).
- The older procedural import (`fabio-engine-plus/presets/from-figma`, Fabio cut out as a slot for the engine to draw)
  still needs `alive_procedural`; `alive upgrade` refuses it and says so.
- Variants that differ in art (V1, V2, V3 of a board) share a scene through per-clip art (`clip.art`): `alive html`
  builds such a scene from several dumps, with each variant's layers prefixed. Each variant's art is loaded with the
  scene, so a pool of three costs the memory of three.
- Colour values interpolate in sRGB, channel by channel (as Figma's export and the old runtime did).

## Behaviour

- Worn-item physics is a damped spring on the item's position plus a tilt. It does not model stacking or weight (the
  procedural engine does); the recording scene ships without it until it is tuned against the design (a design decision of
  22 Oct).
- The nod, breath and blink are the recording page's; other boards define their own in the scene.
- The art-rule lint is heuristic: holding paws are found by name, the body outline is an ellipse fitted to the body
  art's box, and occlusion is not seen (a paw hidden behind the desk counts).
- The variant pick is seeded per occurrence within one controller; two screens showing the same pool at once pick
  independently (each still never repeats its own last pick, and the store keeps the last pick of all).

## Tooling

- A board page converts through its own exporter (`alive html --exporter`): what the exporter writes is what the
  runtime draws, in the order the page's elements come (CSS `z-index` is not carried by the board exporters; the
  Diary Moments boards append their top layers last), with the fonts the exporter names.

- `alive html` runs a board page with the board's own exporter script (every board page shares that contract) or
  takes dumps saved before; the recording page uses the app's own exporter (its shape differs) and comes in through
  `alive upgrade`. Pages are read in headless Chrome, which needs puppeteer-core, Chrome, the sandbox off and memory
  to spare; `alive html --page` was not run during this work (the laptop's swap was full), only `--dump` was.
- Golden images are made on macOS; another platform needs its own (`flutter test --update-goldens`).
- The flicker rule (0.6.3) tells a designed blink (an opacity square pulse) and a flip (a scale that changes sign) from
  a flicker, but not a scale that reaches 0 and comes back on the same side: a tumble keyed that way (two confetti
  pieces of the old completion export) reads as a flicker, as a hide by scale does. Key it through 0, or read the
  lines it prints. docs/checks.md has the numbers.
- `procedural/`'s parity tests need `<fabio-engine-plus>` (the JavaScript reference engine and its presets), and 111
  of them fail as they already did in fabio-engine-plus (its fixtures were recorded before its engine changed). They were not
  re-recorded: fabio-engine-plus has uncommitted work, and `alive` does not depend on them. To re-record them, once
  that work is committed:

  ```bash
  cd <fabio-engine-plus>
  git status --short                      # clean first: the fixtures must come from a committed engine
  npm run flutter-assets                  # the engine's data into flutter/fabio_plus/assets (fabio_parts, fabio_world, fabio_extra)
  npm run flutter-parity                  # runs the JS engine through the scenarios, writes flutter/fabio_plus/test/fixtures/*.json
  cp flutter/fabio_plus/assets/fabio_parts.json flutter/fabio_plus/assets/fabio_world.json \
     flutter/fabio_plus/assets/fabio_extra.json <engine>/procedural/assets/
  cp flutter/fabio_plus/test/fixtures/*.json <engine>/procedural/test/fixtures/
  cd <engine>/procedural && flutter test   # basics, compose, sim, stage, players: expect 178 passing
  ```

  If tests still fail after that, the Dart port lags the JS engine (wardrobe gaps, physics feel, paws changed after
  its fixtures were recorded): the failing scenario names in `players.json` and `sim.json` say which part to port.

## Authoring routes (0.4.0)

- `alive prompt` and `alive sketch` without `--beats` were tested only against a stand-in server: no API key was used
  while building them. How well a model authors through them is not measured. The skill route (Claude Code, no key)
  made the proof moments.
- A moment is drawn from the kit: a pose the kit has no part for is not drawn (a two-handed carry in front of him:
  the far paw stays behind his body; the sketch proof shows it). Shapes are pill, rect and circle with one line of
  text; a richer piece of UI belongs to the app.
- Lint checks causes, eases, snaps, pauses and the paw rules; it cannot see one focal point, crowding or a dull pose.
  That is the preview review (the skill's references/review.md).
- `alive storyboard` gives poses, not paths: a slide, a pass across the screen or a curved path between two frames
  becomes a straight eased move or a cross-fade (measured: the slide to Q8 in the Halfway Express storyboard, 10.9 %
  of the picture against the film mid-transition, where a cut measured 2.6 %). Layers are matched by name path and
  content; a layer with no role name that appears only in a later frame is not drawn. Frame timing is read from
  names, a `notes` layer or a timing file; the Halfway Express frames carry none, so its proof uses a timing file.
- `alive preview` needs flutter and ffmpeg (it runs `flutter test`); a draft takes about 10 s on the test machine, a 7 s
  phone moment at 30 fps about 30 s. Previews are not device frames.

## Loading (0.5.0)

- Background decoding uses `dart:isolate` (`Isolate.run`): fine on iOS and Android; a web build has no isolates
  (not a target of this work; `AliveLibrary.assets(background: false)` loads on the UI thread).
- In a widget test on fake time, the isolate is real asynchronous work: let it finish with `tester.runAsync` between
  pumps, or pass `background: false`.
- A preload held past its `keep` (30 s) is released; opening the page after that loads the scene again (still off the
  frames, but he appears a few frames into the page).
- A cache listens for the system's memory pressure only while it holds preloads (0.6.0); `AliveCache.shared` cannot be
  disposed (it lives as long as the app); a disposed cache refuses new loads.

## Packing (0.6.0)

- `alive pack` writes linear tracks as compact keys (`{"dt", "v"}`), which an engine before 0.6.0 refuses (the scenes
  say `"requires": "0.6.0"`); `--keys list` keeps the key lists for such an app. Compact key times are read to a
  thousandth of a millisecond.
- Shared art is found by exact match: a subtree that differs from another only in its transform or layer name is
  written twice. Measured, not built: dropping keys that lie on the line between their neighbours would remove 1.2 %
  of the app's keys (the exporters already simplified them).
