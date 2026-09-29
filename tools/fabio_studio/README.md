# Fabio animation system and Fabio Studio

Fabio is Fabla's ghost mascot. This folder and `lib/theme/fabio/` replace the
hand-made Rive files with a **procedural** Fabio: he is drawn in code from the
original SVG outline and animated by a small simulation, so he can fly
anywhere on screen, react, emote and conjure props, all driven by data.

There are two halves that must stay in sync:

| Half | Where | What it is |
|---|---|---|
| **Flutter runtime** | `lib/theme/fabio/` | Widgets that render and play Fabio in the app. |
| **Fabio Studio** | `tools/fabio_studio/` | A web dashboard for authoring choreographies ("scripts") with a timeline, path handles, a puppet, a prop maker and Claude-powered generation. It runs a JavaScript port of the same engine so its preview matches the app. |

Scripts are JSON files in `assets/fabio/scripts/`. Studio exports them; the
app plays them with `showFabioScript`.

- Published Studio: https://claude.ai/artifact/Pw86hqeW6vzCAaiSszt2UP (shared with the organization)
- Origin: requested by Yago Arconada (Sept 2026) to "increase the dynamism by a lot so the ghost animation is much more alive", with Fabio flying around the screen and assets appearing, and a dashboard for requesting new animations. The team chose a programmatic widget over generating `.riv` files. See [Background and decisions](#background-and-decisions).

---

## Contents

1. [Quick start](#quick-start)
2. [File map](#file-map)
3. [Using Fabio in the app](#using-fabio-in-the-app)
4. [Script format reference](#script-format-reference)
5. [Vocabulary](#vocabulary)
6. [Custom props](#custom-props)
7. [How the engine works](#how-the-engine-works)
8. [Keeping Dart and JS in sync](#keeping-dart-and-js-in-sync)
9. [Fabio Studio](#fabio-studio)
10. [Claude prompts used by Studio](#claude-prompts-used-by-studio)
11. [Testing](#testing)
12. [Gotchas and known limitations](#gotchas-and-known-limitations)
13. [Background and decisions](#background-and-decisions)
14. [Ideas for later](#ideas-for-later)
15. [Starter prompt for an agent](#starter-prompt-for-an-agent)

---

## Quick start

```dart
import 'package:audio_diaries_flutter/theme/fabio/fabio.dart';

// A living Fabio in a layout. Tap him, drag near him.
Fabio(size: 120, expression: FabioExpression.happy);

// A full-screen performance over the current screen (non-blocking to touches).
final script = await FabioScript.load('assets/fabio/scripts/goal_complete.json');
await showFabioScript(context, script, onEvent: (name) {
  if (name == 'goal_badge') { /* reveal real UI in sync with Fabio */ }
});
```

Studio:

```bash
node tools/fabio_studio/build.mjs      # -> tools/fabio_studio/dist/
node tools/fabio_studio/check.mjs      # engine sanity + Dart parity checks
cd tools/fabio_studio/dist && python3 -m http.server 8765   # open /preview.html
```

A dev page with every expression, gesture, prop and preset:
`FabioPlaygroundPage` (`lib/theme/fabio/fabio_playground.dart`). It is not
linked from the app; push it from a debug menu or run it from a throwaway
`main()`.

---

## File map

### Flutter (`lib/theme/fabio/`)

| File | Responsibility |
|---|---|
| `fabio.dart` | Barrel export. Import this. |
| `fabio_expression.dart` | Vocabulary enums: `FabioExpression` (+ `FabioFace` targets), `FabioGesture` (+ default durations), `FabioProp`, `FabioEyeShape`. Enum `.name`s are the JSON strings. |
| `fabio_math.dart` | `ease()` curves, `smoothstep`, `envelope`, `approach`, and `FabioRandom` (mulberry32, bit-identical to Studio). |
| `fabio_rig.dart` | `FabioPose` (every animatable value for one frame) and `FabioRig.paint` (draws body, arms, shine, face). The body outline is the SVG path from `fabio.svg`, sampled once and deformed per frame. |
| `fabio_sim.dart` | `FabioSim`, the "brain": turns intent (expression, velocity, gestures, look target) into a `FabioPose` each tick. All idle life lives here. |
| `fabio_fx.dart` | Particle system (`FabioFx`, `FabioFxMode`, `FabioPropPhysics`) and the procedural drawings of built-in props. |
| `fabio_custom_prop.dart` | Data-defined props (`FabioCustomProp`): emoji/text glyphs or SVG-path vectors, plus `parseSvgPath` and `parseSvgColor`. |
| `fabio_script.dart` | Script JSON model and lenient parser (`FabioScript`), and `FabioTimeline`, which resolves motion into pixel-space segments for a stage size. |
| `fabio_stage.dart` | `FabioStage` (plays scripts on a canvas the size of its parent), `FabioStageController`, speech bubbles, and `showFabioScript` (overlay helper). |
| `fabio_widget.dart` | `Fabio` standalone widget and `FabioController` (gestures, flashes, bursts, reactions). |
| `fabio_playground.dart` | Developer playground page. |

### Assets and tests

| Path | What |
|---|---|
| `assets/fabio/scripts/*.json` | Bundled scripts. Registered in `pubspec.yaml`. Each also appears as a built-in preset in Studio (the build inlines them). |
| `test/theme/fabio/fabio_test.dart` | Parser, timeline, sim, custom props, physics regression, widget and stage tests. |

### Studio (`tools/fabio_studio/`)

| File | What |
|---|---|
| `src/shell.html` | Markup and CSS (design tokens at the top, light and dark). No `<html>/<head>/<body>`: the Artifact host adds them. |
| `src/engine.js` | One-to-one port of the Dart engine: math, rig, sim, fx, custom props, parser, timeline, stage player. |
| `src/app.js` | Studio UI: transport, timeline editor, stage path handles, inspector, puppet, prop maker, hand-off, team library, Claude calls. Contains `/*PRESETS*/{}`, which the build replaces. |
| `build.mjs` | Concatenates the three sources plus all `assets/fabio/scripts/*.json` into `dist/fabio-studio.html` (publishable) and `dist/preview.html` (local). Fails on a script syntax error. |
| `check.mjs` | Node checks: RNG parity and custom-prop physics behaviour. |

---

## Using Fabio in the app

**Standalone widget**

```dart
final fabio = FabioController(expression: FabioExpression.neutral);

Fabio(size: 120, controller: fabio, interactive: true, shadow: true, hover: true);

fabio.expression = FabioExpression.listening;           // resting expression, eased
fabio.flash(FabioExpression.joyful, seconds: 1.2);       // temporary expression
fabio.play(FabioGesture.wave);                           // one-shot gesture
fabio.lookAt(const Offset(0.6, -0.2));                   // gaze, -1..1 per axis; null = autonomous
fabio.burst(FabioProp.heart, mode: FabioFxMode.fountain, count: 6);
fabio.burstCustom(myCustomProp, mode: FabioFxMode.float);
fabio.react();                                           // random delightful reaction
```

- One controller per widget; the widget's ticker drives the controller.
- `interactive`: tap to react, 4 fast taps make him dizzy, drag to make him watch your finger.
- `hover: false` stops the idle bob (use for reduced motion).
- Props and gestures paint outside the widget's box on purpose; give it room or wrap with a clip.

**Performances**

- `showFabioScript(context, script, {fabioSize, onEvent})` inserts an `IgnorePointer` overlay on the root overlay, plays the script, waits for particles to settle (max 2.5 s), removes itself and completes the future.
- `FabioStage(controller:, script:, fabioSize: 110, hideWhenIdle: true, onFinished:, onEvent:)` for embedding a stage yourself. `FabioStageController.play(script)`, `.playAsset(path)`, `.stop()`, `.sim` for ad-hoc gestures.
- `event` clips call `onEvent(name)` when the playhead crosses them. Use them to reveal real widgets in sync with Fabio (the "assets appearing" part of the brief).

**Not yet wired into product screens.** Existing Rive ghosts are still used in `today_goal.dart`, `home_calendar.dart`, `ghost_widget.dart`, `onboarding/login.dart` and `video_loading_indicator.dart`. A natural first integration is `goal_complete.json` when the daily goal is reached.

---

## Script format reference

A script is one JSON object. Parsing is lenient: unknown tracks, names and
fields are ignored (Studio lists what was skipped), so older app builds keep
playing newer scripts.

```json
{
  "version": 1,
  "name": "Goal complete",
  "seed": 21,
  "loop": false,
  "duration": 9000,
  "start": { "x": 0.5, "y": 1.25, "scale": 1, "expression": "determined", "facing": 1 },
  "props": { "...": "see Custom props" },
  "clips": [ { "track": "motion", "type": "dash", "t": 0, "d": 900, "path": [[0.5, 0.42]] } ]
}
```

| Field | Default | Notes |
|---|---|---|
| `seed` | 7 | Seeds idle behaviour, particles and `wander`. Same seed, same performance. |
| `loop` | false | Restarts from 0 in the app. |
| `duration` | computed | ms. Otherwise the latest clip end + 400 ms (fx add an 800 ms tail). |
| `start` | centre, scale 1, neutral, facing right | `facing: -1` puts his face on the left. |

**Units.** `t` (start) and `d` (duration) are **milliseconds** in JSON and
seconds inside both engines. Positions are **normalised to the stage**:
`[0,0]` top-left, `[1,1]` bottom-right, anything outside is off-screen. Radii
and heights are fractions of the stage's **shorter side**. Fabio is 110 px wide
at scale 1 (0.28 of a 390 pt phone).

### Tracks

| Track | Fields | Behaviour |
|---|---|---|
| `motion` | `type`, `t`, `d`, `ease`?, `scale`? + type fields below | Clips chain: each starts where the previous resolved end was. They should not overlap (the later one takes over). Before the first clip Fabio sits at `start`; between clips he holds the last end point. `scale` is the target scale at the end, eased. |
| `face` | `expression`, `t`, `d`? | Without `d` it holds until the next face clip. A timed one falls back to the last held expression. |
| `action` | `gesture`, `t`, `d`? | One-shot gesture, fired when the playhead crosses `t`. `d` defaults to the gesture's duration. Overlaps motion freely. |
| `look` | `t`, `d` (1000), `at`?: `[x,y]` or `target`: `"viewer"` / `"forward"` | Outside look clips Fabio looks where he flies, or glances around when still. |
| `fx` | `prop`, `mode` (`burst`), `t`, `count` (12), `at`? (omit = at Fabio), `d`?, `rate` (18/s), `spread` (1), `size` (1), `color`? | `trail` and `rain` emit `rate` per second during `[t, t+d]` (`d` defaults to 1000). `orbit` props live for `d` (default 2000). |
| `speech` | `text`, `t`, `d` (2000) | White bubble above Fabio (below if near the top), typewriter at 40 chars/s. Keep it under ~40 chars. |
| `event` | `name`, `t` | Calls the app's `onEvent(name)`. |

### Motion types

| `type` | Fields (defaults) | Default ease | Notes |
|---|---|---|---|
| `fly` (alias `path`) | `path: [[x,y],...]` | `inOutCubic` | Catmull-Rom spline from the current position through the points, re-parameterised by arc length so the ease alone controls speed. |
| `dash` | `path` | `outExpo` | Fast entrance. |
| `hold` | `to`? | `inOutCubic` | Stay, or glide to `to`. |
| `orbit` | `center` (0.5,0.5), `radius` (0.25), `radiusTo`?, `turns` (1, negative = counter-clockwise) | `inOutSine` | Starts at the current angle and blends the radius in over the first 25% so there is no jump. |
| `figure8` | `radius` (0.3), `turns` (1), `center`? (current position) | `inOutSine` | Lemniscate; starts at the current position. |
| `hop` | `to`, `hops` (3), `height` (0.08) | `linear` | Bouncing arcs. |
| `wander` | `radius` (0.15; use 0.03 to 0.08), `center`? | `linear` | Seeded organic drift. Best "alive idle" motion. |
| `teleport` | `to` | `linear` | Shrinks and fades at the start, reappears at `to`; smoke puffs are added automatically at 30% and 62%. |

### Fx modes

`mode` decides **where and how props spawn**. For custom props, the prop's
physics decides how they move afterwards in every mode. Built-in props keep
the per-mode tuning below.

| Mode | Spawn | Built-in override |
|---|---|---|
| `burst` | Explodes in every direction | none |
| `fountain` | Shoots upward in a cone | gravity forced down (≥ 520 px/s²) |
| `ring` | Evenly spaced ring | gravity 0, drag 3 |
| `float` | Single prop popping in and drifting up (`!`, `?`, `zzz`, mic) | gravity 0, drag 0.5 |
| `rain` | Screen-wide shower for `d` at `rate` | falls from the top. Custom: falling props from the top, floating ones rise from the bottom, weightless ones appear scattered across the screen |
| `orbit` | Circles Fabio (follows him) for `d` | n/a |
| `trail` | Emitted behind Fabio while `d` runs, drawn behind him | gravity × 0.25 (custom × 0.5) |

---

## Vocabulary

These names are the only valid strings. Adding one means changing both
engines (see [the checklist](#keeping-dart-and-js-in-sync)).

**Expressions (18):** `neutral` (matches the original artwork), `happy`,
`joyful`, `love` (heart eyes), `starstruck` (star eyes), `excited`,
`surprised`, `curious`, `listening`, `proud`, `shy`, `wink`, `sleepy`,
`asleep`, `determined`, `sad`, `dizzy` (spiral eyes), `knockedOut` (x eyes).

**Gestures (default duration):** `bounce` 0.75 s, `hop` 0.45, `spin` 0.9,
`flip` 1.05, `shake` 0.9 (no), `nod` 0.8 (yes), `wiggle` 1.0, `pop` 0.55,
`wave` 1.6, `cheer` 1.3, `shiver` 0.8, `squish` 0.75, `dizzy` 1.6, `laugh`
1.2, `yawn` 2.0, `startle` 0.7, `tada` 1.4, `think` 1.8. Wave, cheer, yawn,
startle, tada and think pop out little arms.

**Built-in props (14):** `sparkle`, `star`, `heart`, `note`, `confetti`,
`bubble`, `zzz`, `exclaim`, `question`, `check`, `flower`, `puff`, `drop`,
`mic`.

**Eases:** `inOutCubic` (default), `linear`, `inQuad`, `outQuad`,
`inOutQuad`, `inCubic`, `outCubic`, `inOutSine`, `outExpo`, `inBack`,
`outBack`, `outElastic`, `outBounce`.

---

## Custom props

Scripts can define their own props in a top-level `props` map and use them by
name in `fx` clips, exactly like built-ins. New props therefore ship without
an app release.

```json
"props": {
  "balloon": { "kind": "vector", "viewBox": [0, 0, 24, 31],
    "paths": [
      { "d": "M12 2C6.5 2 3 6.4 3 11.2 ...z", "fill": "currentColor" },
      { "d": "M8 7.5c.8-1.6 2.2-2.6 3.6-2.9", "fill": "none", "stroke": "#FFFFFF", "strokeWidth": 1.6, "opacity": 0.7 }
    ],
    "physics": "rise", "color": "#FF6F91", "size": 1.4 },
  "rocket": { "kind": "glyph", "text": "🚀", "physics": "drift" }
}
```

| Field | Notes |
|---|---|
| `kind` | `glyph` (emoji or up to ~8 characters) or `vector`. Inferred from `text` when omitted. |
| `viewBox` | `[x, y, w, h]`, default `[0,0,24,24]`. The prop is scaled so the longer side fits. |
| `paths[]` | `d` (SVG path data, commands `M L H V C S Q T A Z`, absolute and relative), `fill` (hex, `none` or `currentColor`; default `currentColor` unless a stroke is set), `stroke`, `strokeWidth` (1), `opacity` (1). |
| `color` | Default tint for `currentColor` and for plain-text glyphs. A clip's `color` overrides it. |
| `size` | Size multiplier (0.2 to 5). |
| `physics` | Preset name (below), optionally overridden by `gravity`, `drag`, `spin`, `sway`, `life`, `flip`, `pulse`. |

Rules: names cannot reuse a built-in prop name (ignored and flagged). A
vector with no drawable path is ignored, and clips that reference it are
dropped. Colors accept `#RGB`, `#RRGGBB`, `#RRGGBBAA` (CSS order), `black`
and `white`.

**Physics presets** (custom props only; gravity px/s², negative floats up):

| Preset | Label in Studio | gravity | drag | spin | sway | life × | extra |
|---|---|---|---|---|---|---|---|
| `float` | Floats up | -140 | 1.2 | 0 | 16 | 1.6 | |
| `rise` | Rises fast | -380 | 0.8 | 0 | 10 | 1.3 | |
| `fall` | Falls and spins | 520 | 0.6 | 5 | 0 | 1.4 | |
| `flutter` | Flutters | 160 | 2.2 | 6 | 60 | 1.8 | paper-like tumble (`flip`) |
| `drift` | Hangs in the air | 0 | 3.5 | 0 | 22 | 1.6 | gentle size `pulse` |
| `still` | Stays put | 0 | 10 | 0 | 0 | 1.4 | |
| `drop` | Drops fast | 1100 | 0.3 | 0 | 0 | 1.2 | |

Studio's showcase spawn per preset (used by the preview, "Add and drop at
playhead" and the Puppet): float and rise use `float`; fall, flutter and drop
use `fountain`; drift uses `burst` with spread 0.35; still uses a single
`float`.

---

## How the engine works

**Rig (`fabio_rig.dart`).** The SVG body outline (10 cubic segments) is
sampled once into ~220 points. Each frame every point goes through a deformer:

- hem ripple: a travelling sine wave on points below y≈96, stronger at speed
- drag: the lower body trails the direction of travel
- flare: the hem widens when rising
- tuft: a Gaussian patch at the top-left curl follows a damped spring
- wobble: jelly after sudden stops
- squash and stretch around a low pivot (volume-preserving), plus breathing

The outline is then redrawn with quadratic smoothing. Face features (capsule
eyes, "D" or "O" mouth morph, blush, happy arcs, special eye shapes) are
positioned by the same deformer. The face slides between the right side
(`facing: 1`, original art) and the left instead of flipping the body. Arms
are thick strokes drawn behind the body with the body gradient, so their
roots blend in.

**Sim (`fabio_sim.dart`).** Every tick (dt clamped to 1/20 s):

- smooths the velocity the stage feeds in, then derives lean, drag, stretch,
  flare, hem speed and the wobble impulse from acceleration
- turns the face toward the direction of travel, with hysteresis
- chooses the gaze: an explicit target, else the direction of flight, else
  seeded random glances
- blinks every 2 to 5.5 s, sometimes twice
- eases the face toward the expression's `FabioFace` plus the additive
  contributions of running gestures
- crossfades special eye shapes: out, swap, pop in

Gestures are pure functions of `u` (0..1 progress) and elapsed time that add
into a per-frame `_GestureFx` accumulator; nothing about them is stateful.

**Timeline (`FabioTimeline`).** Resolves motion clips into pixel-space
segments for a concrete stage size (re-resolved on resize). `motionAt(t)`
returns position, scale and alpha. The stage derives velocity from successive
positions, in Fabio-widths per second, capped at 14.

**Stage.** Fires `action`, `fx` and `event` clips when the playhead crosses
their `t`, emits continuous fx with fractional accumulators, and draws
particles behind, then Fabio, then particles in front, then the speech bubble.
With `hideWhenIdle` (the default) Fabio disappears when the script ends.

---

## Keeping Dart and JS in sync

`tools/fabio_studio/src/engine.js` is a hand port of the Dart engine. The
preview is only trustworthy while the two match. Section headers in
`engine.js` name the Dart file each part mirrors.

| Dart | JS (`engine.js`) |
|---|---|
| `fabio_math.dart` | math helpers, `ease`, `EASES`, `Rng` |
| `fabio_expression.dart` | `EXPRESSIONS`, `GESTURES`, `PROPS`, `MODES`, `MOTION_TYPES` |
| `fabio_rig.dart` | `newPose`, `BODY_CUBICS`, `OUTLINE`, `makeDeformer`, `Rig` |
| `fabio_sim.dart` | `GestureFx`, `Sim` |
| `fabio_custom_prop.dart` | `PHYS_PRESETS`, `svgColor`, `compileProp`, `paintCustom` (JS relies on the browser's `Path2D` instead of a parser) |
| `fabio_fx.dart` | `PROP_COLORS`, `PHYS`, `Fx` |
| `fabio_script.dart` | `parseScript`, `Spline`, `Timeline` |
| `fabio_stage.dart` | `StagePlayer` |

**Known intentional differences.** Studio steps at a fixed 1/60 s so scrubbing
is deterministic, while the app uses real frame time. Studio hard-codes a
47 pt safe top for speech bubbles; the app reads `MediaQuery`. Emoji render
with each platform's font.

**Checklist when changing the vocabulary or behaviour:**

1. Change the Dart source and the matching `engine.js` section with the same numbers.
2. Adding a name (expression, gesture, prop, motion type, fx mode, physics preset, ease): add it to both enums or tables. Studio's chips, inspector and the Claude prompt vocabulary read those tables automatically. Update `MOTION_HELP` or `PHYS_LABELS` in `app.js` if relevant, and the tables in this README.
3. Adding a built-in prop: add its drawing to `FabioFx.paintProp` and `Fx.paintProp`, its colour and physics to both tables.
4. Changing the JSON format: update both parsers (`FabioScript.fromJson`, `parseScript`), the Claude prompt in `app.js` (`buildPrompt`), and this README. Keep parsing lenient; never make an older field mandatory.
5. Run `node tools/fabio_studio/check.mjs`, `flutter test test/theme/fabio`, rebuild, and republish Studio.

---

## Fabio Studio

**Panels:**

- **Stage (left):** an iPhone-sized mock (Home, Recording or Plain backdrop)
  with the script playing on top. It shows the selected motion clip's path
  as a dashed curve with numbered, draggable handles:
  - double-click the stage to add a point, Alt-click a point to remove it
  - with nothing selected, drag the `S` handle to move the start position
  - `look` and `fx` clips with `at` get handles too

  Transport: play/pause (Space), restart, loop, speed. **Checks** appear
  under the stage, for example: ends on screen, skipped clips, overlapping
  motion, long speech, long duration, prop issues.
- **Direct Fabio:** describe a performance; Claude writes a new script or
  changes the current one (see prompts below).
- **Timeline:** seven tracks. Drag clips to retime, drag the right edge to
  resize, click or drag the ruler to scrub, `+` adds a clip at the playhead,
  Delete removes the selected clip.
- **Inspector:** per-track value chips (expression, gesture, prop, mode,
  motion type, ease, look target), help text, raw clip JSON, duplicate and
  delete. With nothing selected it edits script settings (starting
  expression, loop, seed, facing).
- **Puppet:** a close-up Fabio to try expressions, gestures and props live.
  "Add to script at playhead" records what you click as clips.
- **Prop maker:** build custom props three ways:
  - emoji or text
  - vector, by pasting SVG markup or path data, importing a `.svg` file,
    starting from 7 starters, or "Draw with Claude"

  Then pick the motion preset, color and size, and preview live at app size.
  "Add to script" / "Add and drop at playhead"; save to or load from Team
  props.
- **Hand off:** editable, formatted script JSON (invalid JSON is not applied
  and the error is shown) and a ready-to-paste Flutter snippet that includes
  a `switch` over the script's events.
- **Team library:** shared saved scripts.

Top bar: script name, open built-in presets or a blank script, Save to
library, Copy JSON, Export `.json` (download, falling back to clipboard).

**State.** The working script autosaves to `localStorage` under the key
`fabio-studio-draft` (per viewer). Shared data uses the Artifact `db`:

| Collection | Doc id | Fields |
|---|---|---|
| `scripts` | slug of the name | `name`, `json` (script as a string), `clipCount`, `duration` (s), `updatedAt` (ms) |
| `props` | prop name | `name`, `def` (prop definition as a string), `updatedAt` |

**Artifact capabilities.** `sample` (Claude calls, on the viewer's own usage,
consent on first call), `db` (the collections above; default rules: signed-in
viewers read, Contributors and up write) and `downloads` (Export). Without
them, for example when the page is opened outside claude.ai, generation,
drawing, library and team props hide or explain themselves and everything
else works.

**Build, preview, publish.**

1. `node tools/fabio_studio/build.mjs`
2. Preview locally: serve `tools/fabio_studio/dist/` over http and open
   `preview.html`. `file://` URLs will not load the fonts reliably, and the
   non-skeleton file lacks a charset.
3. Publish with the Claude Artifact tool: publish
   `tools/fabio_studio/dist/fabio-studio.html` with
   `url: https://claude.ai/artifact/Pw86hqeW6vzCAaiSszt2UP` to update the
   existing page in place. Omit `capabilities` to keep `sample`, `db` and
   `downloads`. From a new conversation, read the artifact first; a publish
   to an artifact the conversation hasn't read is refused. Publishing without
   `url` creates a separate page.
4. Anything added under `assets/fabio/scripts/` becomes a Studio preset on
   the next build. Give it a friendly label in `PRESET_LABELS` (`app.js`),
   otherwise the file name is shown.

Design: Rubik (the app's font) and JetBrains Mono, tokens on `:root` with
matching dark mode. The phone mock always uses the app's light palette. The
layout collapses to one column below 1020 px and has no horizontal scroll at
375 px.

---

## Claude prompts used by Studio

These live in `tools/fabio_studio/src/app.js`. That file is the source of
truth; if you change a prompt there, update this copy. Both are sent through
`sample.json(...)` with `cache: false`, so the reply is parsed as JSON.

### 1. Direct Fabio: script generation (`buildPrompt(request, current)`)

`current` is the whole current script when "Change this script" is selected;
otherwise the `welcome` preset is included as an example. `${vocabulary()}`
expands to the live name lists from `engine.js` (and the script's custom prop
names).

```text
You choreograph Fabio, the friendly ghost mascot of Fabla, a research app where people keep short audio diaries. Write ONE animation script as JSON.

STAGE: a portrait phone screen, 390x844 points. Positions are normalised [x, y]: [0,0] is top-left, [1,1] bottom-right. Values outside 0..1 are off-screen; use them for entrances and exits. Fabio is about 110 points wide at scale 1 (0.28 of the width). Keep him below y=0.12 while visible (status bar). The home screen has a goal ring near [0.3,0.37] and a record button at [0.5,0.84].
TIME: "t" (start) and "d" (duration) are milliseconds.

SCRIPT SHAPE:
{"version":1,"name":"Short title","seed":<int>,"start":{"x":..,"y":..,"scale":1,"expression":EXPR,"facing":1 or -1},"clips":[...]}

CLIP TRACKS:
- motion: {"track":"motion","type":TYPE,"t","d",...}. Motion clips run one after another and must not overlap; each begins where the previous ended. Optional on every type: "ease", "scale" (target scale, eased).
  fly: "path":[[x,y],...] smooth curve through the points. dash: like fly, fast start. hold: stay, or glide to "to". orbit: "center","radius"(fraction of width),"turns"(negative = counter-clockwise),"radiusTo"(optional spiral). figure8: "radius","turns" around the current position. hop: "to","hops","height". wander: organic drift within "radius" (0.03-0.08) around the current position, for alive idle moments. teleport: "to", vanishes in a puff and reappears.
- face: {"track":"face","expression":EXPR,"t","d"?}; without d it holds until the next face clip.
- action: {"track":"action","gesture":GESTURE,"t","d"?}; one-shot body performance, may overlap motion.
- look: {"track":"look","t","d","at":[x,y]} or {"track":"look","t","d","target":"viewer"}.
- fx: {"track":"fx","prop":PROP,"mode":MODE,"t","count"?,"at"?:[x,y] (omit to spawn at Fabio),"d"?,"rate"?,"spread"?,"size"?,"color"?:"#RRGGBB"}.
- speech: {"track":"speech","text":"under 40 characters","t","d"}.
- event: {"track":"event","name":"snake_case","t"}; lets the app sync its real UI (for example show a badge).

CUSTOM PROPS: when no built-in prop fits, define new ones in a top-level "props" map and use their names in fx clips. Names are snake_case and must not reuse a built-in name. Two kinds:
  {"kind":"glyph","text":"one emoji","physics":PHYSICS}
  {"kind":"vector","viewBox":[0,0,24,24],"paths":[{"d":"SVG path data","fill":"currentColor" or "#RRGGBB" or "none","stroke"?:"#RRGGBB","strokeWidth"?:1.5,"opacity"?:0.6}],"physics":PHYSICS,"color":"#RRGGBB"}
  PHYSICS: float (drifts up), rise (up fast), fall (falls, spins), flutter (like confetti), drift (hangs), still (stays), drop (drops fast). Keep existing props of the current script.

EXPRESSIONS: neutral, happy, joyful, love, starstruck, excited, surprised, curious, listening, proud, shy, wink, sleepy, asleep, determined, sad, dizzy, knockedOut
GESTURES (default ms): bounce 750, hop 450, spin 900, flip 1050, shake 900, nod 800, wiggle 1000, pop 550, wave 1600, cheer 1300, shiver 800, squish 750, dizzy 1600, laugh 1200, yawn 2000, startle 700, tada 1400, think 1800
PROPS: sparkle, star, heart, note, confetti, bubble, zzz, exclaim, question, check, flower, puff, drop, mic
FX MODES: burst (explodes), fountain (shoots up), ring, float (single prop drifting up, for !, ?, zzz, mic), rain (showers across the whole screen for d at rate per second: from the top, or up from the bottom for custom props that float), orbit (circles Fabio for d), trail (behind Fabio while he moves, needs d and rate)
EASES: inOutCubic, linear, inQuad, outQuad, inOutQuad, inCubic, outCubic, inOutSine, outExpo, inBack, outBack, outElastic, outBounce
[CUSTOM PROPS already in this script: <names>]   (only when the script has props)

CRAFT:
- 4 to 10 seconds. Enter from off-screen and end with an exit off-screen, because the app removes Fabio when the script ends.
- Make him feel alive: pair every move with an expression change, a gesture or a prop. Add a trail during big flights. Use wander or hold between beats instead of freezing.
- Stagger beats about 150-400 ms apart so they read one at a time. Gestures land best right after a motion arrives.
- Speech is warm, brief and supportive, with no emoji. Only use exact names from the lists above.

CURRENT SCRIPT (modify it as requested, keep what was not mentioned):
<current script JSON>
   — or, for a new script —
EXAMPLE of the format and quality bar:
<assets/fabio/scripts/welcome.json>

REQUEST: <what the user typed>

Reply with only the JSON object.
```

After the reply, Studio forces `version: 1`, fills `name` from the request
when missing, loads the script, and reports clip count, duration and how many
clips the parser skipped.

### 2. Prop maker: "Draw with Claude"

```text
Design one small flat vector icon for a friendly pastel mascot app (a light-blue ghost named Fabio): <idea>.
Rules: viewBox [0,0,24,24]. 1 to 6 paths using only SVG path data commands M L H V C S Q T A Z. Chunky, rounded, readable at 16 pixels. Flat colors, no gradients, no text. The main shape uses "currentColor" so the app can tint it; accents may use fixed hex colors; a white highlight (#FFFFFF with opacity 0.6) is welcome.
Also choose how it moves once spawned, one of: float, rise, fall, flutter, drift, still, drop; and its main color.
Reply with only JSON: {"name":"snake_case","viewBox":[0,0,24,24],"paths":[{"d":"...","fill":"currentColor"}],"physics":"float","color":"#RRGGBB"}. Path entries may also have "stroke" (hex), "strokeWidth" and "opacity".
```

The result is converted to SVG markup in the editor so it can be tweaked,
then goes through the same import path as a pasted SVG.

---

## Testing

```bash
flutter test test/theme/fabio/fabio_test.dart
node tools/fabio_studio/check.mjs
```

The Dart suite covers:

- RNG parity with Studio
- every bundled script parsing without dropped clips
- lenient parsing
- timeline chaining, teleport and expression fallback
- every gesture settling to a finite rest pose
- the SVG path and colour parsers
- custom prop definitions
- custom props obeying their physics in every mode (regression)
- built-ins keeping their tuning
- the widget reacting to taps
- the stage firing events and finishing

**SDK note (Sept 2026).** CI uses Flutter 3.44.4 (see
`.github/workflows/`), and dependencies such as `flutter_foreground_task`
require Dart ≥ 3.12. On a machine with an older Flutter, `pub get` fails for
the whole app. The Fabio module depends only on Flutter itself (plus
`custom_typography.dart`'s font name constant and `custom_colors.dart` in the
playground), so it was developed and tested in a scratch Flutter project:

1. Symlink `lib/theme/fabio/*.dart` into it.
2. Stub `custom_typography.dart` with `CustomTypography.fontName = 'Rubik'`.
3. Copy the test with `package:audio_diaries_flutter` replaced by the scratch
   package name.

Prefer running it in the real project with the right SDK.

Visual check: run `FabioPlaygroundPage` on a simulator and play each
choreography. For Studio, build and preview locally.

---

## Gotchas and known limitations

- **Fabio vanishes when a script ends** (`hideWhenIdle`). End scripts with an
  exit off-screen; Studio warns when a script ends with him on screen.
- **Speech bubbles and the status bar.** In the app the bubble flips below
  Fabio near the top safe area; keep him below y≈0.12.
- **Built-in-only behaviours are keyed by prop name:** confetti colours and
  tumble, puff growth, sparkle twinkle. Custom props get `flip` and `pulse`
  through physics instead.
- **Custom props obey physics in every mode; built-ins don't.** That is
  deliberate: built-ins keep their tuned look. See the fx mode table.
- **SVG import (Studio) handles** `path`, `circle`, `ellipse`, `rect` (incl.
  rounded), `polygon`, `polyline` and `line`, inherited `fill`/`stroke` and
  `style=` values, and `opacity`/`fill-opacity`.
  - Transforms are ignored and flagged; flatten them in the design tool.
  - Gradients and patterns become the prop colour.
  - Text must be outlined.
- **Emoji glyphs** look different on iOS, Android and web. Vectors are
  identical everywhere.
- **Performance.**
  - Particles are capped at 400 per system.
  - Each glyph particle uses a `saveLayer` for alpha, so keep glyph counts
    modest (tens, not hundreds).
  - The body path is rebuilt every frame (~220 points), which is cheap.
- **The face is small by design** (true to the original art). If
  expressions need to read at small sizes, consider a face scale parameter
  rather than editing the outline.
- **Script JSON is authored data.** It is parsed leniently and never
  evaluated, but it can still make Fabio say anything, so review
  Claude-generated scripts before shipping them in `assets/`.

---

## Background and decisions

- **Why not generate `.riv` files?** `.riv` is Rive's binary runtime export,
  authored in the Rive editor. Generating one by hand would break easily, and
  designers couldn't meaningfully edit the result. Flying across the whole
  screen doesn't belong in a fixed-size artboard anyway; it needs app-level
  movement.
- **Why procedural?** Fabio's art is simple: one body path, two capsule eyes
  and a mouth. That makes it cheap to deform in code. The approach unlocks
  flight across the screen, squash and stretch, secondary motion, and
  performances as data that Studio (and Claude) can write. It needs no
  designer loop per animation and no app release per new performance or
  prop.
- **Split of responsibilities:** "acting" (face, body, gestures) lives in the
  rig and sim; "choreography" (movement across the screen, props, speech,
  events) lives in scripts and the stage.
- **One engine, two languages.** Studio's preview has to match the app, so
  the engine is duplicated with identical formulas and a shared seeded RNG,
  rather than exported as video or approximated.

## Ideas for later

- Integrate into product moments: goal complete, streaks, first recording,
  reminders; retire the Rive ghosts gradually.
- A reduced-motion mode: honour `MediaQuery.disableAnimations` in
  `showFabioScript` and `Fabio`.
- An app-level prop registry (`assets/fabio/props.json`) so scripts can
  reference team props without inlining them.
- Undo/redo in Studio; multi-select and snapping on the timeline.
- An optional `faceScale` pose parameter for small sizes.
- Golden tests of key poses to catch rendering regressions.

## Starter prompt for an agent

Paste this at the start of a new session to continue the work:

```text
You're working on Fabio, the procedural mascot animation system in the
Audio-Diaries-Flutter repo. Read tools/fabio_studio/README.md first, it is the
source of truth for architecture, the script JSON format and the rules.

Key rules:
- The Flutter engine (lib/theme/fabio/) and the Studio engine
  (tools/fabio_studio/src/engine.js) are one-to-one ports. Any behaviour or
  vocabulary change goes into both, with identical numbers, and the README
  tables and the Studio Claude prompt (buildPrompt in app.js) get updated too.
- Script parsing stays lenient and backwards compatible.
- Verify with: flutter test test/theme/fabio, node tools/fabio_studio/check.mjs,
  node tools/fabio_studio/build.mjs, then preview dist/preview.html over http.
- Studio is published at https://claude.ai/artifact/Pw86hqeW6vzCAaiSszt2UP;
  republish the built dist/fabio-studio.html to that url (read it first),
  keeping its capabilities (sample, db, downloads).

Task: <describe the task>
```
