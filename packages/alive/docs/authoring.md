# From a designed moment to a scene

This is for whoever turns a designer's motion into something the app plays. The design is the source of truth; the
engine plays it, it does not reinterpret it.

## Where moments come from

| Source | What it is | Today's path to alive/1 |
|---|---|---|
| A board page (live HTML, `<boards>/streams/<board>/html`) | the approved moments, drawn from the Fabio kit and timed in code; the Figma frames of the boards were generated from these pages | the board's exporter samples the page in headless Chrome into an engine export (`*.script.json` + `*.art.json`); `alive upgrade` turns it into a scene |
| An engine export already made (`<boards>/motion/<board>/engine/`) | 71 of them: question types, recording, rescue, storage, survey errors (V1 to V3), warnings, encouragement | `alive upgrade --art x.art.json --clips x.script.json --out ...` (all 71 convert; see `alive sweep`) |
| The app's cut scenes (`assets/alive_v0/<scene>/`, made by the app's `tools/alive/cut.py`) | an export cut down to Fabio and his props, split into clips by time | `alive upgrade assets/alive_v0/<scene> --out assets/alive/<scene>` |
| Figma Motion (a frame in the design file, its keyframe dump under `<boards>/motion/<board>/`) | moments designed directly in Figma | `alive figma <dump.json>`: one command, Figma's own Fabio kept as art (below). The older procedural import (Fabio cut out for the engine to draw) still plays with `alive_procedural` |
| Words (a prompt) | a designer describes the moment: "Fabio cheers when the diary is finished, confetti, then settles" | the alive-author skill in Claude Code (no key), or `alive prompt "<words>"` with an API key: a moment file, `alive moment` ([prompt.md](authoring/prompt.md)) |
| Rough images | sketches, screenshots, storyboard photos, frames of a video, one per beat | the skill reads them, or `alive sketch <images>` with an API key; preview with each image beside its beat ([sketch.md](authoring/sketch.md)) |
| A Figma storyboard | static frames in order (a section), the way the dashboard launch film was directed | `alive storyboard <name>`: Smart Animate between the frames, timing from the frame names ([storyboard.md](authoring/storyboard.md)) |

## Without Figma Motion: words, rough images, a storyboard

Each route ends in a validated, linted scene and a preview drawn by the runtime. One short page each:

- [preview.md](authoring/preview.md): `alive preview`, the runtime's own frames as MP4, GIF or a review page, with
  stills.
- [prompt.md](authoring/prompt.md): from words, with the alive-author skill (no key) or `alive prompt`.
- [moments.md](authoring/moments.md): the moment file both of those write (a kit figure, items, beats with causes),
  `alive moment` and the rules it checks.
- [sketch.md](authoring/sketch.md): from rough images.
- [storyboard.md](authoring/storyboard.md): from Figma frames as the beats of one flow, and how to read them.

The proof, with every pass and the measured match of the storyboard against the approved film:
[authoring-proof.md](authoring-proof.md).

## From Figma Motion to the app in one command

```bash
node tools/alive.mjs figma <boards>/motion/encouragement/halfway-express.json --id halfway-express \
  --out assets/alive/halfway-express
```

That is the whole path. The dump names the frame (any of the dump shapes the boards wrote: one frame, several
moments, or V1 to V3 versions); the command finds the frame's read and its SVG export in the Figma cache, converts the
frame, validates the scene, writes it and runs the art rules on it. Then, in the app:

```dart
late final fabio = AliveController(vsync: this, scene: 'halfway-express');
// fabio.play('enc-express'); cues: fabio.events (AliveCue 'pick', 'punch ...', 'slide to Q8, ...')
```

What it keeps from Figma, exactly:

- Fabio as Figma draws him: his body, faces, paws, headset, outfit and props are the frame's own vectors, compiled
  like every other layer. No engine-drawn Fabio, nothing procedural, so the moment runs on the lean runtime.
- Every layer by its role name: `fabio`, `fabio/face`, `fabio/hand-l`, `fabio/hand-r`, `item/<name>`, `ui/<name>`
  (and every kit part: each is its own layer even when it does not move, so the app can address it, for example
  `fabio.setOffset('fabio', ...)` or `fabio.value('ui/card', LayerProp.opacity)`). `roles.fabio` lists his parts, and
  `meta.figma` says which layer is which kit component.
- Figma's keys, unchanged: TRANSLATION_X and Y, ROTATION, SCALE (both axes or one), OPACITY, WIDTH and HEIGHT (a
  parametric box), fills and strokes (an animated colour), corner radius. The easing is mapped exactly: LINEAR,
  HOLD (the value holds until the key, then steps), EASE_IN, EASE_OUT, EASE_IN_AND_OUT and the three BACK curves as
  Figma's cubic curves, a custom cubic bezier as its four numbers, the spring presets (GENTLE, QUICK, BOUNCY, SLOW) as
  their springs, and a custom spring's bounce as a damping ratio of 1 - bounce. The ease on a key shapes the span
  that ends at it, as in Figma.
- A dump's beats (Halfway Express has them) become cues the app can wait on.

What it fills in, and says so (one note per layer):

- Figma's SVG export leaves out a layer at opacity 0 at rest (a face that fades in later, a paw that appears). A kit
  part left out that way is drawn from a visible instance of the same component in any frame of the cache (this
  frame's export first), placed in the left-out instance's box; a left or right paw can come from its mirror. Other
  left-out layers come from the cache's geometry reads (`reads/nodes-<moment>.json`) and the per-moment fixes in
  `moments.json` (borrow, drain).
- `tools/figma/fixes.json` holds facts read from Figma later than the cache (fonts the older reads did not record,
  where a left-out layer sits among its siblings, the paint of children read only as boxes, frames no longer in
  Figma). Add to it with `tools/figma/read-facts.figma.js` through `use_figma` (read only).
- A dump that disagrees with the frame (another length, layers the frame no longer animates) is reported; the frame
  as Figma has it is converted.

Variants become one pool:

```bash
node tools/alive.mjs figma <boards>/motion/survey-errors/no-internet_keyframes.json \
  --id survey-no-internet --pool no-internet --out assets/alive/survey-no-internet       # V1 to V3 in one dump
node tools/alive.mjs figma system-v3/V1.json system-v3/V2.json system-v3/V3.json --id slider-carry --out ...
fabio.play('no-internet');   // a version other than the last one, remembered through the store
```

`--frame <id | name | V2>` picks one frame of a dump. A dump that holds several different moments
(`media/keyframes.json`) gives one scene per moment. `alive figma --all --out <dir>` converts every moment of the
cache (with a `manifest.json`), and `tools/figma-proof.mjs` measures them against Figma's MP4 exports
(`docs/figma-proof.md`: 41 moments, 0.8% of the picture differs on average).

The Figma cache: `--cache <dir>` (or `ALIVE_FIGMA_CACHE`), default `tools/figma/cache` in this repository (the 6 Oct
reads and exports, copied from fabio-engine-plus where they were made; the SVG exports are kept brotli-compressed as
`.svg.br`, and a plain `.svg` or `.svg.gz` works too), laid out as `reads/<frame>.json` (read-frames.figma.js), `reads/nodes-<moment>.json`
(read-nodes.figma.js), `svg-cache/<file>.svg` (the frame or its section exported as SVG with layer names as ids) and
`moments.json` (frame, export, MP4, dump and fixes per moment).

### A new Figma frame

"One command" holds for the 41 moments the cache has read. A frame the cache has not read needs two things from
Figma first, a read and an SVG export:

1. **The read.** `tools/figma/read-frames.figma.js` is read-only plugin code. Prepend
   `const FRAMES = ['<frame id>'];` (the frame's id; frames of one page per run) and run it where Figma's plugin API is:
   the Figma MCP's `use_figma` runs it as it is (on your design file, by its key); a development plugin can wrap it in an async function and print the
   result. It returns `{"tag": "FIGREAD", "frames": [...]}`: save each entry of `frames` as
   `reads/<frame id>.json` in the cache, the colon as a dash (frame `1:2` as `reads/1-2.json`).
2. **The export.** Export the frame (or its section) from Figma as SVG with "Include 'id' attribute" on, so the layers
   keep their names, into the cache's `svg-cache/` (or anywhere, given with `--svg`).
3. **Layers hidden at rest** (optional). Figma's export leaves out a layer at opacity 0 at rest. A kit part left out
   is drawn from another instance of its component; for anything else, read its geometry with
   `tools/figma/read-nodes.figma.js` and save it as `reads/nodes-<scene id>.json`.
4. **Convert.** The dump can be as small as the frame's id:

   ```bash
   echo '{"frame": "<frame id>"}' > frame.json
   node tools/alive.mjs figma frame.json --svg <export.svg> --id my-moment --out assets/alive_src/my-moment
   ```

   To convert it again without `--svg`, add the frame to `moments.json` (`{"id", "frame", "svg", "title"}`, plus
   `mp4` and `dump` when there are ones). `moments.json` also names the Figma file the frames are in (`file`, its
   key): `alive figma` writes that key into the scene (`meta.figma.file`), so a cache of another file names its own.

`ALIVE_FIGMA_CACHE` (or `--cache`) points at another cache folder laid out the same way.

What it does not do (`limits.md`): a moment made in HTML (the warning, rescue and cast moments) has no
Figma frame and comes in through `alive html`; a board page dump given to `alive figma` is refused with that pointer.

## The steps (board pages and engine exports)

### 1. Export

Every board page carries an exporter script (`export/exporter.js`, `exporter-wv.js`, ...) that samples the page's
animated parts at 30 or 60 fps into a scene dump. `alive html` runs it and converts the dump in one go (one tested
implementation of what each board's `make.mjs` did: keys simplified within 0.25 px, 0.15 degrees, 0.3 % scale and
0.8 % opacity, colour channels, flip-book frames, labels as cues):

```bash
# the survey error board: V1 to V3 of "No internet" as one scene with a pool
node tools/alive.mjs html --id survey-no-internet --out assets/alive/survey-no-internet \
  --page <boards>/streams/webview-errors/html/index.html \
  --exporter <boards>/streams/webview-errors/html/export/exporter-wv.js \
  --query "eng=0&v=0" "eng=0&v=1" "eng=0&v=2" --names v1 v2 v3 --pool no-internet
# or from dumps saved before
node tools/alive.mjs html --id survey-no-internet --dump no-internet_V1.json no-internet_V2.json no-internet_V3.json \
  --names v1 v2 v3 --pool no-internet --out assets/alive/survey-no-internet
```

The recording page has its own exporter (in the app's `tools/alive/recording/`), whose output comes in through
`alive upgrade` (next step). The page is read only.

### 2. Upgrade

```bash
node tools/alive.mjs upgrade --id recording --art rec_scene.art.json rec_tape.art.json \
  --clips clips/ --meta meta.json --with tools/presets/recording.json --out assets/alive/recording
```

What it does:

- compiles the art: the SVG is parsed once here (not in the app), the style cascade is resolved so each shape carries
  its final paint, gradients, filters and clip paths are checked and kept only if used, and SVG text becomes text the
  app draws (Rubik, VT323, Pixelify or the phone's own font);
- turns every clip into tracks (`[ms, value, ease]` per property), cues (the export's labels), bubble lines and step
  channels (face, lamp);
- keeps layers that have keys but no art as data layers (the app reads their values: a card Flutter draws, timed by
  the clip);
- refuses, with the reason, what alive cannot draw (a slot for the engine-drawn Fabio, procedural tracks) instead of
  dropping it silently;
- validates the result and writes nothing if it would not load.

`--with` merges the scene fields that are about behaviour rather than drawing (below). `--no-svg-text` leaves SVG text
out, as the old runtime did.

### 3. Say how the app drives it (`--with` file)

```json
{
  "initial": { "state": "ready" },
  "states": { "ready": { "enter": "greet", "idle": "rest" }, "recording": { "enter": "record" } },
  "on": { "saved": { "play": "thumbs" }, "tap:fabio": { "play": "cheer" } },
  "pools": { "cheer": ["thumbs", "thumbs-wave", "thumbs-hop"] },
  "live": { "group": "live:fabio", "breath": { "amp": 0.006, "period": 3600 },
            "blink": { "every": 3900, "for": 130, "phase": 700, "face": "neutral", "hide": ["face-neutral"], "show": ["face-neutral#2"] },
            "nod": { "input": "mic", "threshold": 0.4, "minLoud": 900, "cooldown": 2200, "depth": 2.2, "states": ["recording"] } },
  "worn": { "headset-far": { "on": "body-blue", "stiffness": 900, "damping": 40, "tilt": 0.6, "max": 1.5 } },
  "semantics": { "label": "Fabio, the Fabla mascot, at a podcast desk", "decorative": true }
}
```

The fields are documented in `schema.md`. Rules of thumb:

- One state per thing the app knows (ready, recording, paused, done); its enter clip is the transition, its idle clip
  the pose he rests in.
- Events are things that happen (saved, micAllowed); taps arrive as `tap:fabio`.
- Variants of a moment (V1, V2, V3) go in a pool: the app plays the pool, the engine picks one, never the last one.
- Breath, blink and nod are the page's own idle life; set them to what the board does, nothing more (he has no random
  movement: every move has a cause).
- Worn-item physics is subtle by design (a headset settles after a nod); tune it on the example app before shipping
  and keep `max` small so nothing looks detached.

### 4. Check

```bash
node tools/alive.mjs validate assets/alive/recording     # the schema, references, layers against art
node tools/alive.mjs lint assets/alive/recording         # the art rules
node tools/alive.mjs info assets/alive/recording         # clips, keys, sizes raw and gzipped
```

The art rules (`lint`): no pointing paw (retired 20 Oct); holding paws (the M3 paw: layers named simple, hold or
carry, or `--holding <regex>`) stay within 50 kit units of their rest spot in his body's frame (the object comes to
him); every paw stays within 30 kit units of his body's outline (a warning, it cannot see occlusion); no curled or
gripping paw parts; the body is #A8D0FB.

### 5. Look

Run the example app with your scene folder in its assets, or add a golden test (see `test/golden_test.dart`) for the
poses that matter. For a board that already played in the app on fabio_plus, `test/render_parity_test.dart` and
`test/corpus_parity_test.dart` compare the old and new drawing pixel by pixel.

## Changing a moment later

Edit the board page (or the Figma frame it came from), export again, upgrade again with the same `--with` file. The
scene id, clip ids, cues and state names are the contract with the app: keep them, or tell the developers which
changed. The upgrade is deterministic: the same inputs give the same files, so a diff shows exactly what moved.
