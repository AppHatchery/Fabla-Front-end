# Architecture

## The idea

Every Fabla board so far is designed motion: art made in Figma (or on a board page built from the kit) and timed by a
designer. The engine's job is to play that motion exactly, react to what the app knows, and cost as little as
possible on the phone. So the work is split:

- **Build time (the CLI)** reads the designed motion, compiles the vector art into ready draw data, simplifies the
  keys, and checks everything (schema, references, art rules). Slow, thorough, once.
- **Run time (the package)** decodes JSON, builds paths and records the static art once per scene, then per frame
  only samples keys and walks the animated layers.

```
Figma Motion reads + SVG ─┐   (alive figma: Figma's own Fabio kept as art)
Live board page (Chrome) ─┼─> alive CLI ──> assets/alive/<scene>/scene.json + art/*.json ──> app bundle
Legacy fabio-script v2 ───┘    compile, simplify, validate, lint

AliveController ──> AliveCache ──> AliveSceneData (SceneDef + CompiledArt, shared, refcounted)
      │                                   │
      ├── AlivePlayer (one clock: clips, states, pools, inputs, behaviours, physics) ──> LayerState
      │                                                                                     │
      └── AliveStage (CustomPaint in a RepaintBoundary) ── CompiledArt.paint(canvas, LayerState)
```

## Layers of the package

| Layer | Files | Depends on |
|---|---|---|
| schema | `lib/src/schema/` (`scene_def`, `art_def`, `track`, `curves`, `errors`) | plain Dart |
| runtime | `lib/src/runtime/` (`player`, `layer_state`, `scene_data`, `variants`, `events`) | schema, render (compile only) |
| render | `lib/src/render/art_renderer.dart` | dart:ui, path_parsing |
| kit | `lib/src/kit/` (`kit_def`, `look`, `figure`) | schema, render |
| loader | `lib/src/loader/library.dart` | services (asset bundle) |
| widgets | `lib/src/widget/` (`controller`, `stage`) | Flutter widgets |

The player is plain Dart and deterministic; it can be tested without widgets (`test/player_test.dart`).

## How a frame is made

1. The controller's Ticker (created from the screen's `vsync`, so `TickerMode` mutes it when the route is covered)
   calls `player.advance(dt)` with dt capped at 0.1 s.
2. `advance` moves the stage clock. Clip time is exact (the clip is sampled at the real time). Behaviours and physics
   run in fixed steps of 1/240 s up to the new time, so 30, 60 and 120 Hz see the same poses. Cues and clip ends
   inside the step fire as events; a clip end starts what follows (`then`, the state's idle clip) at the exact time.
3. If the frame needs painting (a clip runs, a nod or a worn item moves; or, when only breath and blink move, at the
   idle frame rate; with reduced motion only when the pose changes), `player.evaluate()` fills `LayerState`: rest
   values, then each keyed property of the clip, then looks, bindings, blink, breath and nod on the live group, and
   the worn items' lag converted into their parent's space. One flat Float64List; nothing is allocated.
4. The stage's painter maps the viewport onto its box and calls `CompiledArt.paint` for each art of the scene. The
   compiled art is a short list per plane: recorded pictures for everything static, and the animated groups with
   their static transform, clip, filter and children. Per animated group: skip it if hidden or transparent, apply
   its delta matrix about its pivot (`T(p + t) R(-rot) S(sx, sy) T(-p)`, the old rig's formula), clip, and draw its
   children (pictures replayed, nested groups walked), in an opacity layer only when it is translucent.

When nothing moves and there is no idle life, the Ticker stops: 0 frames while he holds a pose (as the spike measured).

## Why it is faster than the old lean path

The old runtime (fabio_plus `FigmaRig` + `FigmaArtPainter`) did all of this per frame:

- built a `Map` of values for every layer (a new map per layer per frame, plus copies for the blink);
- re-read each group's attributes (`g` maps copied, numbers parsed with a regular expression);
- rebuilt every clip path (a new `Path` with each shape transformed) for every clipped group;
- copied a style object per element and walked every static element of the art.

It also parsed the SVG markup with package:xml on the first paint (71 ms on the simulator in debug, 2.5 s on the
loaded emulator), and drew nothing, silently, when the markup was malformed.

The new runtime resolves the style cascade, the references and the transforms at build time, records static art
once into pictures, and samples typed keys with a cursor. `docs/performance.md` has the numbers.

## Kit figures

A scene can name figures: Fabio composed from an art pack (`kits/<id>/kit.json` and its parts) instead of drawn into
the scene's art. When the scene loads, the loader reads the pack, generates the figure's art from the rig (a layer per
bone and per slot, nested as the rig attaches them, every pivot in canvas units, and in each slot a `part` node at the
slot's z and alternate z) and loads the parts the figure's look, the clips' swaps and the pools name. Each player holds
an `AliveDress`: what each figure wears (its `AliveLook`, resolved against the pack), plus what the playing clip swaps
in (`face`, `slot:<slot>` channels). The renderer draws a part node by asking the frame's dressing: the worn part's
compiled art (shared per pack and tint) at its placement. So a look changes without touching the scene's art, clips
keyed on bones and slots play on any look, and two screens can show the same scene in two looks. See `docs/kit.md`.

## Loading (0.5.0)

A scene loads in steps, so the page that opens with him keeps its frames:

1. The files are read from the bundle (a platform reply, off the UI thread).
2. Each file of 16 KB or more is decoded, parsed and checked in a short-lived isolate (`Isolate.run`), its SVG path data
   read into drawing commands there (`PathCommands`: single precision, as the engine stores path points). Smaller
   files are decoded on the UI thread. Memory libraries (tests, previews) do all of this on the UI thread, as before.
3. The layer table, pivots and checks are made, then the art is prepared (`CompiledArt.prepare`): paths built from
   the commands, static runs recorded into pictures, one node at a time; after about `AliveCache.prepareSlice` (4 ms)
   it waits for the next frame to be drawn if one is due, and goes straight on when none is.
4. The scene is drawn once into a picture that is thrown away (texts that follow a layer's colour laid out, kit parts
   compiled), so the first frame on screen only replays.
5. The parsed art trees are let go (unless `AliveCache(keepArtTrees: true)`): what is static is in the pictures and
   what moves is compiled; `AliveSceneData.arts` keep their headers.

`AliveController.preload` runs these steps on the page before. A controller whose scene is loaded already takes it
from the cache in its constructor (its events are delivered a microtask later, to listeners added right after it),
and a stage built on a ready scene paints him from the next frame, so the frame that builds the page does not also pay
for his first paint. `docs/scoreboard.md` (P1, P2) has the measurements.

## Memory and lifetime

- `AliveCache.shared` loads a scene once and shares it between screens. Each controller holds a handle; the last
  `dispose()` disposes the pictures and drops the data. The bundle's string cache is bypassed (`cache: false`), so
  no copy of the JSON text stays behind.
- There is no global mutable state. The old `FIGMA_ART` registry and the engine data globals are gone from the
  default package (they live on in `alive_procedural`).
- Static art lives in native memory (pictures), not on the Dart heap; `CompiledArt.pictureBytes` reports it.

## Errors

Nothing reaches the widget tree:

| Where | What happens |
|---|---|
| a file is missing or not JSON | `AliveLoadError`; status `failed`; the stage shows `fallback` |
| a file breaks the schema | `AliveSchemaError` listing every problem with its JSON path and a hint |
| files disagree (a keyed layer no art draws, a look naming an unknown layer) | the same, from the loader |
| the app names an unknown clip, state, look or cue | `AliveUsageError` event; the call is ignored |
| the app sends an event the scene does not list | ignored (a scene reacts to what it was designed for) |
| the store fails | `AliveStoreError` event; picks go on without memory |
| painting or advancing throws | `AliveRenderError`; the controller fails after the frame; the stage falls back |

## Determinism

Same scene, same calls at the same clock times, same run context: the same frames and events at any frame rate.
Pool picks are seeded by FNV-1a over scene, pool, diary, day, question and occurrence (mulberry32, the old engine's
generator) when a run context is given, random otherwise. `test/player_test.dart` checks the physics at 30, 60 and
120 Hz for exact equality.

## The procedural engine

`procedural/` (package `alive_procedural`) is the full Fabio Engine Plus port: the locked Fabio drawn from the spec,
attachment physics for stacked hats, free items, scenes, and the script v2 player. Moments whose Fabio is drawn by the
engine (the older Figma imports with `figma.fabios`, art with Fabio cut out as a slot) need it; `alive upgrade` refuses
them with that reason. `alive figma` converts the same Figma frames with Figma's own Fabio as art instead, so they no
longer need it (41 frames, `docs/figma-proof.md`). It is a separate package so the app pays for it only if it imports it: on the spike's Android
build its engine code was 740 KB of AOT code against 237 KB for the lean path, and its 412 KB of data assets ship
with any app that declares them.
