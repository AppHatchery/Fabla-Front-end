# Extending Alive

What an app or a designer can add without changing the engine, and how the engine's own API changes.

## Which import

| Import | For |
|---|---|
| `package:alive/alive_core.dart` | a screen that plays scenes: `AliveController`, `AliveStage`, `AlivePart`, `AliveLibrary`, `AliveCache`, events, errors, `LayerProp`, `AliveFonts`, `AliveExtensions` |
| `package:alive/alive_kit.dart` | kit figures dressed at run time: `AliveLook`, `AlivePartAdjust`, `KitDef` and the pack's parts and slots |
| `package:alive/alive_tools.dart` | tools, tests and previews: `SceneDef`, `ArtDef`, `PathCommands`, `AliveSceneData`, `AlivePlayer`, `CompiledArt` |
| `package:alive/alive.dart` | all three (what every app used before 0.5.0; unchanged) |

A release build keeps only what the app calls, whichever import it uses. The kit's loading code stays in the build
whenever scenes may name figures (the loader reads them); not measured on a device build here.

## Art the engine does not draw: plugin nodes

A node in an art file can name a painter the app gives its controller:

```json
{ "layer": "recorder", "pivot": [215, 640], "kids": [
  { "tf": [1, 0, 0, 1, 155, 630], "plugin": "waveform", "w": 120, "h": 24, "params": { "bars": 24, "colour": "#244E8A" } }
] }
```

```dart
final fabio = AliveController(
  vsync: this,
  scene: 'recording',
  extensions: AliveExtensions(nodes: {
    'waveform': AlivePlugin((canvas, node, frame) {
      final bars = (node.params['bars'] as num).toInt();
      final level = frame.input('mic');            // the mic level the app sets
      for (var i = 0; i < bars; i++) {
        final h = node.h * level * (0.4 + 0.6 * ((i * 37) % 11) / 10);
        canvas.drawRect(Rect.fromLTWH(i * node.w / bars, (node.h - h) / 2, node.w / bars * 0.6, h), Paint()..color = const Color(0xFF244E8A));
      }
    }, animates: true),
  }),
);
```

- The painter draws in the node's own box, (0, 0) to (`w`, `h`), at its place in the tree: its layer's moves,
  opacity, clips and filters apply, and it draws in the scene's order.
- `AliveFrame` gives `time`, `clip`, `clipTime`, `input(name)`, `channel(name)` (a clip's step channels),
  `value(layer, prop)` and `reducedMotion`. The painter runs every frame the stage paints.
- `animates: true` keeps the clock running while the scene shows (a live meter, particles); without it the painter
  is drawn when something else moves.
- A kind the app did not register draws nothing and is reported once (`AliveUsageError`). `alive validate` checks
  `plugin` is a name and `params` an object.

## Fonts

Text keeps its font family as a key (`IBM Plex Mono` is `ibm-plex-mono`; Rubik, VT323, Pixelify and the system font
have their own). Register the font in the app and map the key:

```dart
const fonts = AliveFonts(families: {'ibm-plex-mono': 'IBMPlexMono'});
AliveController(vsync: this, scene: 'lcd', library: const AliveLibrary.assets(fonts: fonts));
```

A key with no family draws in Rubik.

## Live behaviours a scene turns on

`live.breath`, `live.blink` (layers, or a kit figure's eyes with `"figure": true`), `live.nod` (the mic), `live.gaze`
(layers toward a point the app gives with `lookAt`, and a kit figure's eyes), `worn` (springs), `bindings` (an input
onto a property). See `docs/schema.md`.

## Kits

A pack's rig decides its slots: their order (`z`, `zAlt`, `zFront` for parts tagged `front`), what they hang from,
their anchors, physics and hems (`hem`: cloth clipped at his outline that waves after a move). Parts are SVG art
imported with `alive kit import`. A new mascot is a new rig and pack; no engine change. See `docs/kit.md`.

## Shipping

`alive pack --share` writes an app's scenes smaller with the same pixels; the loader puts shared art back. Since 0.6.0
it writes linear tracks as compact keys, which need engine 0.6.0 (`--keys list` for an older app). See
`docs/integration.md`.

## Stability

- The version is semver: `0.MINOR.PATCH` while the API settles. A minor version adds and may deprecate; it does not
  remove or change the meaning of a public member, a scene field or a CLI flag without a deprecation shim that keeps
  the old way working for at least one minor version, with a `@Deprecated` message naming the new way.
- `docs/api.txt` is the reviewed list of the public Dart API (classes, constructors, fields, getters, methods with
  their parameters). `node tools/api.mjs --check` (run by `tools/ci.sh`) fails when the code and the list disagree: a
  removed or changed line is a breaking change; review it, add the shim, then `node tools/api.mjs --write`.
- Scene files: `alive/1` only grows (new optional fields and node kinds). A scene that uses a new field needs a
  runtime that knows it: the CLI stamps it with `"requires": "<version>"`, and a runtime older than that refuses it
  with a message naming the version (0.5.0 and later); old scenes keep their meaning.
- Behaviour changes that reach existing scenes are listed in `docs/breaking-changes.md` and the
  changelog, with the flag that keeps the old behaviour where one exists (`--no-svg-text`, `--no-trims`).
