# The alive/1 format

Two kinds of JSON file make a scene. Every file names its schema and kind, so the runtime refuses what it does not
understand with a message, instead of drawing nothing.

```
assets/alive/<scene>/scene.json         kind "scene": what moves, how it is driven, how it reads to assistive tech
assets/alive/<scene>/art/<art>.json     kind "art": what it looks like (vector art, compiled; no SVG is parsed in the app)
```

Both are checked twice with the same rules: by the CLI when they are made (`alive validate`) and by the runtime when
they load. The shared fixtures in `test/fixtures/schema/` keep the two in step (both must report the same paths).

Units: world units are the scene's own (the phone moments use the 430 x 932 Figma frame). Times are milliseconds in
files (the runtime works in seconds). Colours are `#RRGGBB` or `#RRGGBBAA`.

## Problems

A file that breaks a rule is reported with every problem, each with a JSON path, a message and usually a hint:

```
clips.greet.tracks.headset-far.tx[3]: time 300 comes before the previous key (450) (keys are sorted by time)
clips.x.tracks.ghost: layer "ghost" is not in any of the scene's art (mark it "data": true under "layers" if the app only reads its values)
schema: unsupported schema "undefined" (this is a legacy file: run `alive upgrade` first)
```

## scene.json

```json
{
  "schema": "alive/1",
  "kind": "scene",
  "id": "recording",
  "name": "Recording question: Fabio at the podcast desk",
  "size": [430, 932],
  "art": ["rec_scene", "rec_tape"],
  "layers": { ... },
  "clips": { ... },
  "pools": { ... },
  "looks": { ... },
  "states": { ... },
  "on": { ... },
  "initial": { "state": "ready" },
  "live": { ... },
  "inputs": { "mic": { "smooth": 0 } },
  "bindings": [ ... ],
  "worn": { ... },
  "anchors": { ... },
  "semantics": { ... },
  "roles": { "fabio": ["body-blue", "headset-far", ...] },
  "source": { "from": "...", "tool": "alive upgrade 0.1.0", "files": [...] }
}
```

| Field | Required | Meaning |
|---|---|---|
| `schema`, `kind`, `id` | yes | `"alive/1"`, `"scene"`, letters, digits and `_ . -` |
| `size` | yes | world width and height |
| `art` | yes | art ids, drawn in this order (`art/<id>.json`) |
| `layers` | no | layer declarations (below); layers only the art names need none |
| `clips` | yes, one or more | the designed moments |
| `pools`, `looks`, `states`, `on`, `initial` | no | how the app plays them |
| `live`, `inputs`, `bindings`, `worn` | no | behaviours: breath, blink, nod, input bindings, physics |
| `anchors`, `semantics`, `roles`, `source`, `name` | no | lining up app widgets, accessibility, provenance |
| `requires` | no | the oldest engine that reads the scene as it means (`"0.5.0"`), stamped by the CLI when the scene uses a newer feature; an older runtime refuses it with a message that names the version |
| `shared` | no | fragments of shared art its art files use (`alive pack --share`, below) |

### layers

```json
"layers": {
  "live:fabio": { "live": true },
  "face-neutral#2": { "rest": { "opacity": 0 } },
  "ui/warning card": { "data": true, "rest": { "fill": "#FFF3D6" } }
}
```

A layer is an animated group of the art (a group with `"layer": "<id>"`). Its properties:

| Property | Meaning | Neutral |
|---|---|---|
| `tx`, `ty` | translation, added to the rest position | 0 |
| `rot` | degrees about the layer's pivot (Figma's sign) | 0 |
| `sx`, `sy` | scale about the pivot | 1 |
| `opacity` | 0..1, multiplied into the layer | 1 |
| `w`, `h`, `r` | a parametric box's size and corner radius | the box's own |
| `kx`, `ky` | skew in degrees about the pivot, before scale and rotation (as CSS `skewX`, `skewY`) (0.5.0) | 0 |
| `trimStart`, `trimEnd` | the share (0..1) of each stroke under the layer that is drawn, from where SVG starts the shape (a circle at its right end, going down; a rect at its top left, going right): a progress ring, a tick drawn on (0.5.0) | 0, 1 |
| `fill`, `stroke` | a box's colours, or `currentColor` below a colour channel group | the art's own |

`rest` sets values that hold when no clip keys them. `live: true` marks a wrapper the behaviours move (no clip keys
it). `data: true` marks a layer no art draws: its keys are values the app reads (`controller.value(id, prop)`), for
example a card drawn in Flutter but timed by the clip. A layer's pivot and parent come from the art.

### clips

```json
"greet": {
  "duration": 5000,
  "loop": false,
  "still": 4900,
  "tracks": {
    "paw-wave-near@front": {
      "rot": [[0, 0], [300, -12, "outBack"], [600, 0, [0.42, 0, 0.58, 1]]],
      "opacity": [[0, 0], [100, 1, "hold"]]
    }
  },
  "cues": [[1200, "waved"]],
  "bubble": [[2033, "Up to 5 minutes.", 0.46], [2133, "Up to 5 minutes.", 1], [4200, null, 0]],
  "channels": { "face": [[0, "neutral"], [367, "happy"]], "lamp": [[0, 0]] },
  "note": "Ready: he waves once, says Up to 5 minutes."
}
```

| Field | Meaning |
|---|---|
| `duration` | ms; the clip holds its last frame after it unless it loops or something follows |
| `loop` | plays again from the start; cues and the end fire every pass |
| `still` | ms; the pose shown when the phone asks for reduced motion (default: the end) |
| `tracks` | layer id to property to keys `[ms, value]` or `[ms, value, ease]`, sorted by time (or compact, below) |
| `cues` | named marks `[ms, name]`; reported as events; the app can hold a clip at one |
| `bubble` | `[ms, text or null, opacity]`: what the speech bubble says (the app draws it, so copy can be translated) |
| `channels` | step values `[ms, value]` the app and behaviours read (`face` drives the blink; `face:<figure>` in art scenes, below) |
| `note` | the designer's words for the moment |

An ease shapes the span that ends at its key: `"linear"` (default), `"hold"` (or `"step"`: jump at the key), a named
ease (`inQuad outQuad inOutQuad inCubic outCubic inOutCubic inOutSine outExpo inBack outBack outElastic outBounce`), a
cubic bezier `[x1, y1, x2, y2]`, or a spring `{"spring": {"mass": 1, "stiffness": 170, "damping": 20}}`. Before a
track's first key the first value holds; after the last, the last.

A step channel is different: before its first key it has no value. A `slot:` or `face` channel then shows the look's
own part, and `channel(name)` reads null; a `null` value does the same (0.7.0; before, the runtime held the first value
from 0 ms while the tools showed the look's part, so a held item keyed at 150 ms showed on the resting paw in the app
only). Key a channel at 0 ms to set what shows from the start.

Compact keys (0.6.0, what `alive pack` writes for a track whose segments are all linear): `{"dt": [ms, ...], "v":
[...]}`. `dt[0]` is the first key's time, each next entry the time since the key before it (0 or more); `v` holds one
value per key (numbers, or colours for `fill` and `stroke`). Times are read to a thousandth of a millisecond. These
two are the same track:

```json
"tx": [[0, 0], [300, 0], [383, 1.187], [433, -0.88]]
"tx": {"dt": [0, 300, 83, 50], "v": [0, 0, 1.187, -0.88]}
```

A scene that uses them is stamped `"requires": "0.6.0"`; an older runtime refuses it with a message that says so.

### pools, looks

```json
"pools": {
  "cheer": ["thumbs", "thumbs-wave", "thumbs-hop"],
  "outfit": [{ "clip": "rest", "look": "cardigan" }, { "clip": "rest", "look": "hoodie" }]
},
"looks": {
  "hoodie": { "show": ["outfit-hoodie"], "hide": ["outfit-host-cardigan"] }
}
```

`play('cheer')` picks a variant: never the one the pool played last (remembered in the app's store), seeded by the
run when the app gives one (diary, day, question). A variant with a look wears it from then on. A look's `hide`
always wins; `show` sets the layer's rest opacity to 1 (a clip can still fade it).

### states, on, initial

```json
"states": {
  "ready": { "enter": "greet", "idle": "rest" },
  "recording": { "enter": "record" }
},
"on": {
  "saved": { "play": "thumbs" },
  "tap:fabio": { "play": "cheer" },
  "micAllowed": { "play": "allow", "state": "ready" }
},
"initial": { "state": "ready" }
```

`appState = 'ready'` plays `enter`, then `idle`. After a clip from `on` (or any clip with nothing to follow) the state's
idle clip plays. `on` keys are app event names; taps arrive as `tap:<target>` (`tap:fabio` by default). Events a scene
does not list are ignored. `initial` is a state or a clip; without it, the first state starts.

### live, inputs, bindings

```json
"live": {
  "group": "live:fabio",
  "breath": { "amp": 0.006, "period": 3600 },
  "blink": { "every": 3900, "for": 130, "phase": 700, "face": "neutral", "hide": ["face-neutral"], "show": ["face-neutral#2"] },
  "gaze": { "layers": { "fabio/look": [3, 2] }, "reach": 80, "follow": 120 },
  "nod": { "input": "mic", "threshold": 0.4, "minLoud": 900, "cooldown": 2200, "depth": 2.2,
           "down": 140, "gap": 20, "up": 260, "ease": [0.65, 0, 0.35, 1], "states": ["recording"], "afterClip": true }
},
"inputs": { "mic": { "smooth": 120 } },
"bindings": [{ "input": "mic", "layer": "k-lamp-on", "prop": "opacity", "from": [0, 1], "to": [0.6, 1] }]
```

| Behaviour | What it does |
|---|---|
| `breath` | the group scales by 1 + amp sin(2 pi t / period) |
| `blink` | while the clip's `face` channel is `face`, for `for` ms of every `every` ms, `hide` layers go to 0 and `show` layers to 1 |
| `blink.figure` | (0.5.0) a kit figure's id, or `true` for the scene's first figure: during the blink its open eyes (eyes parts the pack tags `pill`, or `pill-wide`) swap to the pack's `blink-half`, `blink-closed`, `blink-half` (`-wide` for wide eyes), as the pack's blink action draws them; other eyes (arcs, hearts, stars) do not blink |
| `gaze` | (0.5.0) `controller.lookAt(point)` makes him look at a world point (a text caret): each of `layers` (`{"fabio/look": [3, 2]}`) moves toward it by at most its [x, y], full at `reach` world units (80) and less nearer, following with a critically damped approach of `follow` ms (120; 0 jumps), from the pivot of `from` (default: the first layer, or the figure's eyes); with `figure` a kit figure's open eyes swap to the pack's `look-<direction>` part (the nearest of eight) once the gaze is over `dead` (0.35) of its full share; `lookAt(null)` looks ahead again. Unlike the other behaviours it is the app's: with reduced motion it still follows the point, at once |
| `nod` | when `input` has stayed above `threshold` for `minLoud` ms and then drops, at most once per `cooldown` ms, in the listed `states`, and (with `afterClip`) only when the current clip has finished: the group dips `depth` units over `down` ms, holds `gap` ms, and comes back over `up` ms |
| `inputs.<name>.smooth` | a time constant (ms) for an input (0: raw) |
| `bindings` | an input's `from` range mapped onto a numeric property's `to` range, clamped |

All of it but the gaze is off with reduced motion and with the controller's `live` switch off (the calm setting).

### worn

```json
"worn": {
  "headset-far": { "on": "body-blue", "stiffness": 900, "damping": 40, "mass": 1, "tilt": 0.6, "max": 1.5 }
}
```

A damped spring lets a worn item lag behind the layer it sits on (`on`, default its parent in the art) when that
layer accelerates, overshoot and settle. `tilt` is degrees per unit of sideways lag; `max` caps the lag in world
units. It runs in fixed steps of 1/240 s, so every frame rate sees the same poses.

### anchors, semantics, roles

```json
"anchors": { "bubbleTip": { "at": [277.1, 412.4], "layer": "live:fabio" } },
"semantics": { "label": "Fabio, the Fabla mascot, at a podcast desk", "decorative": true, "states": { "recording": "Fabio is listening" } },
"roles": { "fabio": ["body-blue", "headset-far", "paw-wave-near@front"] }
```

An anchor is a world point that moves with its layer (`controller.anchor('bubbleTip')`). `semantics.decorative`
keeps him out of the semantics tree (the default when there is no label); the app can still label him. `roles` names
groups of layers for tools (the art-rule checks read `fabio`).

### meta

Free-form data for the app and the tools, kept as is (`scene.def.meta` at run time). `alive upgrade` puts an
alive_v0 folder's extra keys here (`window`, `slotSize`...). `alive figma` writes `meta.figma`: where each clip came
from and which layer is which kit part, per Fabio (the art rules read it):

```json
"meta": { "figma": { "file": "<design file>", "converter": "alive figma", "clips": {
  "enc-express": { "frame": "<frame id>", "name": "Express", "page": "Encouragement", "export": "<frame id>.svg",
    "fabios": [{ "root": "fabio#2", "body": "fabio/body#2", "scale": 1.05, "box": [138, 500, 293.4, 671.15],
                 "parts": { "fabio/body#2": "Fabio / Body:Color=Blue", "fabio/hand-r#2": "Fabio / Hand:Pose=Hold, Side=Right, Skin=Blue" } }] } } } }
```

`scale` is his kit scale (his body's width on the 148-unit kit canvas), `box` his body's rest box in world units.

## art/<id>.json

```json
{
  "schema": "alive/1",
  "kind": "art",
  "id": "rec_scene",
  "size": [430, 932],
  "offset": [0, 0],
  "paints": { "g1": { "type": "linear", "units": "bbox", "x1": 0, "y1": 0, "x2": 1, "y2": 0, "tf": [1, 0, 0, 1, 0, 0], "stops": [[0, "#FFFFFF"], [1, "#A8D0FB80"]] } },
  "filters": { "f1": { "blur": 0, "shadows": [{ "dx": 0, "dy": 2, "std": 3, "spread": 0, "color": "#00000040" }] } },
  "clips": { "c1": [{ "rect": [0, 0, 430, 676, 0, 0] }, { "d": "M0 0H10V10Z", "tf": [1, 0, 0, 1, 5, 5] }] },
  "root": [ ... nodes ... ],
  "source": { "from": "legacy art bundle", "frame": "html:recording-r11" }
}
```

`offset`: the art's coordinates minus the offset are the scene's (an art cut from a larger frame).

Nodes, back to front. Every node may have `tf` (a static transform `[a, b, c, d, e, f]`), `o` (opacity), `clip` (an
id in `clips`) and `filter` (an id in `filters`).

| Node | Fields |
|---|---|
| group | `kids`; as a layer: `layer`, `pivot`; `cc` (`"fill"` or `"stroke"`: the layer's colour is `currentColor` below it); `box` `{x, y, w, h, r, fill, fo, stroke, sw}` and `clipBox` (a parametric frame); `plane` (top level only) |
| shape | one of `d` (SVG path data), `rect` `[x, y, w, h, rx, ry]`, `ellipse` `[cx, cy, rx, ry]`, `line` `[x1, y1, x2, y2]`, `poly` `[x, y, ...]` with `closed`; paint: `fill`, `fo`, `stroke`, `so`, `sw`, `cap`, `join`, `miter` (miter limit, default 4), `dash`, `dashOff`, `evenOdd` |
| part | `part`: a kit figure's slot layer (`"fabio:hat"`), drawn with whatever the figure's look puts there; `alt`: the slot's alternate place in the order (docs/kit.md). The CLI's figure art and any art that leaves a hole for a worn part use it |
| text | `text` spans `[{t, font, size, weight, color, lh}]`, `x`, `y`, `w`, `align`, `nowrap` (a Figma text box; `font` is `rubik`, `vt323` or `pixelify`, mapped to the app's families) |

A paint may also carry `spread` (`pad`, `reflect`, `repeat`: beyond the gradient's ends) and, radial, a focal point
`fx`, `fy`, `fr`. A clip shape may carry `evenOdd` (its own clip rule; the clip is then the exact union of its shapes).
The CLI writes these, and reads CSS `style` attributes, `<use>`, gradient `href` chains and clipPath transforms, for
new art (kit parts, `alive kit import`); legacy exports are compiled exactly as the old painter drew them.

Paints are final: the style cascade of the source SVG is resolved when the art is compiled. `fill` and `stroke` are a
colour, `currentColor` or `url:<paint id>`. With both a fill and a stroke a shape's `o` is a layer; with one, it
multiplies the paint (the old painter's rule, kept so the pixels match).

The same order of drawing, clips and filter recipes as the old runtime applies: drop shadows draw behind the content
(spread as a dilation), a blur blurs the content, a clip path is the union of its shapes. Inner shadows are left out
(as before); see `docs/limits.md`.

### faces in art scenes (0.6.1)

An art scene (a board export, no kit figures) draws a figure's faces as its own layers, named
`<figure>/face <name>` (beside `<figure>/body`, under the face group `<figure>/face`), and says what a clip asks his
face to show with the step channel `face:<figure>`:

```json
"channels": { "face:fabio": [[0, "neutral"], [5000, "concerned"], [6200, "relieved"]] }
```

`alive validate` reports a `face:<figure>` value with no such face layer (path `clips.<clip>.channels.face:<figure>[i]`),
and `alive lint` checks that his face never goes blank while his body shows (docs/checks.md). The runtime does not read
these channels: the faces are layers with their own tracks. For kit figures, the `face` channel and looks name the
pack's faces; a face the pack does not have is the neutral face at run time, and `alive validate` reports it.

## figures (kit figures in a scene)

```json
"art": ["backdrop", "fabio"],
"figures": { "fabio": { "kit": "fabio", "look": "host", "parts": { "glasses": "kit-glasses" }, "at": [42, 34], "scale": 1, "flip": false, "physics": false } }
```

| Field | Meaning |
|---|---|
| `kit` | the art pack, `kits/<kit>/kit.json` beside the scene folders (`assets/alive/kits/`) |
| `look`, `parts` | the look he starts in (a look of the pack) and parts on top of it (slot to part id or name) |
| `at`, `scale`, `flip` | where his canvas origin sits in the scene, his size, facing left |
| `physics` | slots with physics ride springs (hats, accessories, paws) |

The figure id must be in `art` (where he draws among the scene's art; no art file is read for it). It adds the layers
`<id>` (root), `<id>.<bone>` and `<id>:<slot>`. A clip's step channels `face` and `slot:<slot>` (the first figure) or
`slot:<figure>:<slot>` swap parts while it plays. A pool variant may carry `dress` (a look of the kit, or `"@looks"`)
and `wear` (slot to part, or `"@<tag>"`); variants that name `@` expand into one per choice when the scene loads.

## Shared art (_shared/<id>.json, 0.5.0)

`alive pack --share` writes art that two or more scenes draw the same once. The art files keep a node in its place,
and the scene lists the fragments its art uses:

```json
// scene.json
"shared": ["f1a2b3c4d5e6f"]
// art/<id>.json: a node anywhere in the tree
{ "use": "f1a2b3c4d5e6f" }
// _shared/f1a2b3c4d5e6f.json, beside the scene folders (assets/alive/_shared/)
{ "schema": "alive/1", "kind": "fragment", "id": "f1a2b3c4d5e6f", "node": { "layer": "fabio", "kids": [...] },
  "paints": { "p...": {...} }, "filters": {...}, "clips": {...} }
```

When the scene loads, each `use` node is replaced by its fragment's `node` and the fragment's paints, filters and clips
join the art's (they are named by their content, so the same paint has the same id in every file); the result is the
art as it was before it was packed (`ArtDef.splice`). A `use` naming a fragment that is not there is a load error that
names the file. `alive validate <scene folder>` puts the fragments back before it checks.

## kits/<id>/kit.json

Kind `kit`: the rig (canvas, bones, slots, grips, skins, tint tokens), the parts index, looks, actions and pools.
Written by `alive kit import`; checked by the runtime when a scene with a figure loads. `docs/kit.md` describes every
field; `kits/<id>/parts/<part>.json` are art files as above.

## Versions

`alive/1` is the first version. A later version will be read by a runtime that says so; files never change meaning
under the same version. The CLI writes only `alive/1`, and `alive upgrade` turns every older export (fabio-script v2
with art bundles, and the app's interim alive_v0 folders) into it.
