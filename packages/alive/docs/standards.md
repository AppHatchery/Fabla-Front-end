# Standards: placements, Fabio's sizes and templates (0.7.0)

A new animation is assembled from standard pieces, the same way every time, instead of being sized and timed by eye
each time. Nothing here is required: a scene that declares nothing plays and checks exactly as before, and every
template is a starting point whose fields can all be changed.

## Placements

A placement is where an animation sits in the app. Each one fixes the box the scene is drawn for, how it scales on
other phones, and Fabio's size there. They are data, in `standards/placements.json`.

| Placement | The box (pt, on the 430 pt phone) | Fabio | How it fits | Clipped | Taps |
|---|---|---|---|---|---|
| `page` | 430 wide; 932 tall, or a multiple of 8 for the top of a page | XL | by width | no | pass through to the app |
| `panel` | 366 wide (a sheet in the page), height a multiple of 8 | XXL, rising from its bottom edge | by width | yes | taken |
| `card` | 398 wide (a card in the page's column), height a multiple of 8 | XL | by width | yes | taken |
| `dialog` | 396 x 136 (a dialog's art band), shown at 110 / 83 | M | by height | yes | taken |
| `inline` | up to 124 x 124 (beside the app's own widgets) | XS | inside the box | no | taken |
| `custom` | the scene's own | its own | inside the box | no | taken |

A scene says which one it is with `"placement": "card"`. A team adds its own placement to the same file with the same
fields: `box` (`width`, a list of `heights` or a `step` with `min` and `max`, `maxWidth` and `maxHeight` for a small
piece, `default` for `alive new`), `fabio` (its tier), `home` (where his feet stand, as fractions of the box's width
and height; a y over 1 puts his feet below the box, so he rises from its bottom edge), `scale`, `maxScale` (the most
it grows over its phone size on a wider screen; 1, or `null` for no cap), `fit` (`width`, `height` or `contain`),
`alignment`, `clip`, `passTaps` and `margins` (the safe margin of each edge for the lint).

## Fabio's sizes

His size is the height of his body (his blob, without hat, face or paws) as the person sees it on screen, in points:
the body drawn in the scene times the placement's scale. Named like text sizes:

| Tier | XS | S | M | L | XL | XXL |
|---|---|---|---|---|---|---|
| Body height on screen (pt) | 56 | 84 | 110 | 136 | 164 | 240 |

They come from the app's 55 scenes, measured (3 Nov): the question type peeks 47 to 57, the dialogs and the Halfway
Express 77 to 88 in the scene (the dialog's 83 is 110 on screen), the storage scenes 127 to 145, the 21 web page cards,
the recording page and the History peek 161 to 165, the warning sheets 236 to 252. M is the dev team's own dialog
art, 110 pt. A scene can ask for a tier other than its placement's with `"fabioSize": "L"`, or for points with
`"fabioSize": 120`.

`alive sizes <scene dir>...` measures him in any scene: from a kit figure, a body layer, or his body colour inside a
layer named fabio (a board export). It measures the scene's first clip (his entrance), so a payoff where he grows is
not his size. When only the top of his head is drawn (a peek over an edge), his height comes from his width (his body
is 1.035 times as wide as it is tall).

## The scaling rule

Everything is designed on a phone 430 pt wide. On any other phone the box scales by the width ratio, evenly: on a 375
pt phone everything is 375 / 430 = 0.87 times its size. Nothing is stretched (the scale is the same both ways) and
nothing is cut by surprise (the box keeps the scene's proportions). The dialog is the one placement that scales by
height: its band is 136 x 110 / 83 pt tall on every phone, so Fabio keeps the dialog's art size, and a narrower dialog
crops the sides of his walk in. Larger system text grows the app's text, not Fabio. With reduced motion the scene
shows its still.

Two limits keep a phone design from ballooning on a tablet (0.7.0):

- **No larger than its phone size.** A box grows at most `maxScale` times its size on the 430 pt phone (the scene's
  width times the placement's `scale`). `maxScale` is 1 for every placement, so on an iPad (820 pt wide) the warning
  sheet stays 366 pt wide instead of 1.9 times that, centred in what the app gives it (by the placement's alignment).
  An app whose content column is wider sets its own: `maxScale` in its copy of `standards/placements.json`, or
  `AlivePlacement(maxScale: 1.5)`, or `double.infinity` for no cap.
- **Never taller than the screen.** When the width would make the box taller than its parent allows, or than the
  screen, it fits the height instead (a full page on a tablet on its side is as tall as the screen, centred).

In the app, `AlivePlacement` does this (a thin layer over `AliveStage`, which is unchanged):

```dart
AlivePlacement(controller: fabio, placement: AlivePlacements.card)   // or the scene's own placement:
AlivePlacement(controller: fabio)                                    // reads "placement" from the scene
AlivePlacement(controller: fabio, placement: AlivePlacements.page, passTaps: false, clip: true) // anything overridden
```

It takes the placement's fit, alignment, clip, scale and cap and sizes the stage: as wide as its parent (up to its
phone size) and as tall as the scene's proportions make it (a page, panel or card), or the band's height times its
scale (the dialog), never taller than the screen. A page lets taps through (`IgnorePointer`), so the app's buttons
under it work. Every `AliveStage` argument can be given too. `test/placement_test.dart` checks it on phones 320, 375,
393 and 430 pt wide, on tablets 768 x 1024 and 1024 x 1366, and on a tablet on its side (1024 x 768).

## The checks

On a scene that declares a placement or a size, `alive lint` adds two rules:

- `placement-box`: the scene's box is the placement's (its width; a height from its list, or a multiple of its step
  in its range; an inline piece within 124 x 124).
- `fabio-size`: his body on screen is his size, within 6 % (at least 4 pt).

Both are warnings, never failing a build by default; `--strict` makes them errors; under the `custom` placement they
only report what they measure, as information. A scene that declares neither is not checked by them. `--standards
<file>` (or `ALIVE_STANDARDS`) checks against a team's own placements file. `--json <file>` writes every problem.

A declared placement also gives the safe-margin rule its margins. Without one, the app's 16 pt margin applies on the
edges of a scene that are the screen's (its sides when it is 430 pt wide, its top and bottom when it is 932 tall);
any other edge is a box in the app's layout, already inset from the screen, and is measured to its own edge.

## Templates

```bash
node tools/alive.mjs catalog                 # placements, tiers, patterns, beats, and the kit's looks and parts
node tools/alive.mjs new reaction --placement card --look party --out examples/moments/card-cheer.moment.json
node tools/alive.mjs moment examples/moments/card-cheer.moment.json --out examples/moments/out/card-cheer
```

`alive new <pattern> --placement <name>` writes a moment file, the same file for the same input every time (plain code,
no model). It sets Fabio's scale from his tier on screen (through the placement's scale and his body as the kit draws
it, 137.7 pt at scale 1), his feet at the placement's home spot, and fills the pattern's slots with beats. Options:
`--look`, `--size` (a tier or points), `--beats a,b` (the slots in order), `--props` (parts beside him), `--held` (a
part in his near paw), `--box WxH`, `--flip`, `--id`, and `--scene <dir>` to build it at once.

- **Patterns** (`templates/patterns/`): `reaction` (one beat, then he settles), `page-moment` (he comes in, does one
  thing, settles, leaves), `dialog` (the update dialog's clips: enter and the upgrade, a pool of two loops, now and
  later, played by state).
- **Beats** (`templates/beats/`): enter-left, enter-right, enter-bottom, settle, idle-loop, idle-look, wave-goodbye,
  thumbs-up, small-cheer, react-tap, leave-left, leave-right. Each is a few steps with their causes, at times from its
  start; `@offLeft`, `@offRight`, `@offTop` and `@offBottom` put him just outside the box's edge.

In a moment file a beat is named: `{"beat": "wave-goodbye", "at": 1200}`. Its own fields go to the beat's main step
(`{"beat": "small-cheer", "at": 300, "face": "starstruck", "cause": "the diary is done"}`), and `"steps": {"0": {...}}`
change any step. A moment may have several clips (`"clips": {"enter": {"beats": [...]}, ...}` with `states`, `pools`
and `initial`), as the dialog pattern writes them. Templates are where a moment starts; the moment file it writes can be
changed in any way afterwards, and a new beat a team will use again goes in `templates/beats`.

## Going custom

A moment that does not fit a placement says `"placement": "custom"` and keeps its own box and size: the checks then
report his size and the box as information. A scene that says nothing is not checked for size at all. A team that
needs a new placement (a banner, a tablet sheet) adds it to `standards/placements.json` or its own copy (`--standards`).

## Fidelity

The same or higher, measured on the checks the engine already has (see the numbers in CHANGELOG.md, 0.7.0):

- **Pack parity**: the app's scenes packed for shipping draw the same as written (`test/pack_parity_test.dart`, in
  `tools/ci.sh`): no frame with a pixel over 40 of 255.
- **The design's frames against the engine's**: `alive parity` (the board in Chrome against the runtime, at the beats
  and every second frame); the update dialog's frame compare (1768 frames at 2x, none differing) is the same method.
- **The preview**: `alive preview` and `alive moment --preview` draw at 60 fps and 3x by default (a phone's frame rate
  and density); `--draft` stays 12 fps at half size for quick looks.

What the runtime already does, pinned by `test/fidelity_test.dart`: the player samples time continuously, so a 120 Hz
display gets a new in-between pose every frame (a board export's 30 fps keys are interpolated, not repeated), and clip
paths are anti-aliased like the shapes they cut. While he only breathes and blinks the stage repaints at
`AliveOptions.idleFrameRate` (30 a second, to save power); designed moves repaint every frame. The engine draws no
raster images, so there is no image filter quality to set.
