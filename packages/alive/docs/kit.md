# Kits: modular art and customisation

Fabio as a kit: named **slots** (body, face and its features, glasses, hat, outfit, accessories, paws, what he holds),
each with an anchor on his canvas, a bone it follows and a place in the drawing order. An **art pack** holds the parts
that fill the slots. A scene names a **figure** (a pack and a look); the engine composes him at run time, so his look can
change at any moment and every action keyed on his bones and slots plays on any look. New art is a new pack or new
parts in a pack (docs/adding-artwork.md); the engine does not change.

```
tools/kit/fabio.rig.json ─┐
kit SVGs (kit-final/) ────┴─> alive kit import ──> kits/fabio/kit.json + parts/<id>.json ──> assets/alive/kits/fabio/
                                 compile, split faces, tokens, lint                             loaded by any scene with a figure
```

## The rig

`tools/kit/fabio.rig.json` is the source; `kit.json` carries it. Units are kit units on his canvas (viewBox
`-2 -22 148 163`; his body is 144 wide). Every number in it says where it comes from.

**Bones** (each is a layer a clip can key): `root` (the figure id, pivot between his feet (72, 141)), `body` (he leans
about his feet), `head` (pivot at the neckline (72, 60): face, glasses, hat and headset turn together on the dome),
`neck` (the neckline: garments hang from it).

**Slots**, in drawing order (back to front). z (alt) is the slot's place in the order and its alternate place.

| Slot | z (alt) | Hangs from | Anchor (x, y, rot) | Placed | Takes | Adjust (scale; dx, dy; rot) | Physics |
|---|---|---|---|---|---|---|---|
| `behind` | 0 | root | 72, 141, 0 | origin | props, desk | 0.25..2; -240..240, -240..240; -180..180 |  |
| `head-back` | 10 | head | 72, 20, 0 | canvas | headset-back | 0.95..1.05; -3..3, -3..3; -6..6 |  |
| `far-paw` | 20 (105) | body | -16, 102, 8 | origin | hands | 0.9..1.1; -8..8, -8..8; -20..20 | spring 520/30, tilt 0.8 |
| `body` | 30 | body | 72, 141, 0 | canvas | body | fixed |  |
| `outfit` | 40 | neck | 72, 60, 0 | canvas | outfits | 0.98..1.02; -2..2, -2..2; -3..3 | tilt only |
| `accessory` | 50 | neck | 72, 60, 0 | canvas | accessories | 0.95..1.05; -4..4, -4..4; -6..6 | spring 420/22, tilt 1.2 |
| `face` | 60 | head | 85, 41, 0 | canvas | faces | 0.9..1.1; -4..4, -4..4; -8..8 |  |
| `eyes` | 61 | head | 85, 36.5, 0 | canvas | eyes | 0.85..1.15; -4..4, -4..4; -10..10 |  |
| `brows` | 62 | head | 85, 29, 0 | canvas | brows | 0.85..1.15; -4..4, -4..4; -12..12 |  |
| `mouth` | 63 | head | 85, 48.5, 0 | canvas | mouths | 0.85..1.2; -4..4, -4..4; -12..12 |  |
| `cheeks` | 64 | head | 85.2, 46.6, 0 | canvas | cheeks | 0.85..1.15; -3..3, -3..3; 0 |  |
| `marks` | 65 | head | 85, 36.5, 0 | canvas | marks | 0.85..1.15; -6..6, -6..6; -10..10 |  |
| `glasses` | 70 | head | 86, 36.8, 0 | canvas | glasses | 0.92..1.08; -3..3, -3..3; -6..6 |  |
| `hat` | 80 | head | 66, 0, 0 | canvas | hats | 0.9..1.1; -5..5, -5..5; -10..10 | spring 600/26, tilt 0.9 |
| `head-front` | 90 | head | 24, 30, 0 | canvas | headset-front | 0.95..1.05; -3..3, -3..3; -6..6 |  |
| `near-paw` | 120 (110) | body | 160, 98, -8 | origin | hands | 0.9..1.1; -8..8, -8..8; -20..20 | spring 520/30, tilt 0.8 |
| `held` | 115 | near-paw | 0, 0, 0 | grip | props | 0.5..1.5; -12..12, -12..12; -30..30 |  |
| `front` | 200 | root | 72, 141, 0 | origin | props, desk | 0.25..2; -240..240, -240..240; -180..180 |  |

The order is the kit's own (kit-refit `kit3.py figure()`): the headset's far band, the far paw, the body, the outfit,
accessories, the face, the hat, the headset's near cup, then the near paw and what it holds.

**Kit 1.7.1 (engine 0.7.0).** The detached style's `celebrate` and `carry-front` show the item they hold only while
the holding paw does (their `slot:held` is keyed from 0 ms, with `null` where the paw rests), and `alive kit lint`
checks every paw style's actions for a held item on a resting paw (held-item). The touching paws are unchanged.

**Paw styles (kit 1.7.0 and later).** The kit has two paw styles. **touch** (the default): every paw touches him.
At rest the near paw sits over his right edge by a third of its width at (140, 104) at -8 degrees and the far paw a
third behind his left edge at (6, 106) at 8; every action is keyed to keep each paw on him (the wave rises along his
right edge and waves beside his face, the thumbs up and the open paw sit on his right edge, the two-paw carries bring
the far paw round in front of the item). The white History Fabio keeps the royal paw. **detached** (the default of kit 1.6.0): paws held
apart from his body, the near paw at rest at (160, 98) and the far paw at (-16, 102), about 9 kit units of air; a
working paw keeps at least 6, or sits wholly in front of him when both paws hold one thing; the actions keyed to the
hands audit's spots beside him. It is the named variant: `pawStyles` in
the rig and kit.json names the default and lists, per other style, the paw anchors and the actions it replaces (and
the look matrix cards' paw offsets). The JS tools honour a style (`withPawStyle` in tools/lib/kit/compose.mjs; `alive
paws --kit kits/fabio --paws detached`); the Flutter runtime plays the kit as written, the default. Switching the
default is a rig change: move the other style's anchors and actions into the slots and actions, and the current ones
into pawStyles (kit 1.6.0 did it one way, kit 1.7.0 the other), then re-import with `--into` and regenerate the look
references and goldens. The touch style's look references are kit 1.5.0's renders (`kit-touch-r5/looks` beside
kit-final; the rig's `references.looks` points there), kit-final/looks holds the detached ones.

**Placed**: `canvas` parts are drawn on his canvas where they sit; their origin is the slot's anchor, so at rest the
engine draws them exactly where the designer drew them, and an adjustment scales or tips them about the anchor.
`origin` parts (paws, items) put their own (0, 0) on the anchor. `grip` parts (what he holds) put their grip point on
the near paw's point, without the paw's tilt (the paw sits diagonal against the item, hands-v3 `grip_tilt`).

**Grips and M3.** A paw part's pose names its grip: `hold` (the handle through the paw, the item's origin), `carry`
(the item's side edge, its right middle), `present` (the item resting on it, its bottom middle). Grip points come from
the item's solid shapes (a contact shadow is not where a paw takes it). For `hold` and `carry` the paw is drawn over
the item; for `present` under it: the paw part says `alt`, and the near paw draws at its alternate z (110, under the
held item at 115). The far paw's alternate z (105) brings it in front of him when both paws act on one thing.

**A third z: front** (0.5.0). A slot may also name `zFront`: a part tagged `front` (or `"front": true`) draws there
instead of at `z` or `zAlt`; a part without the tag never does. It is for the far paw in front of a held item when both
paws carry it: `"zFront": 117` on `far-paw` puts `hand-carry-front-far-*` above `held` (115) and under the near paw
(120). Only slots with a `zFront` read the tag (the satchel's `front` layer, in `accessory`, is unaffected).

**Hem slots** (0.5.0). A slot may carry a `hem`: cloth below a garment's hem (the board outfit model's 6 units of extra
cloth) that does not show at rest and waves below his outline after a move.

```json
{ "id": "outfit-skirt", "z": 35, "attach": "neck", "anchor": [72, 60, 0], "place": "canvas", "accepts": ["skirts"],
  "physics": { "stiffness": 180, "damping": 10, "mass": 1, "tilt": 0, "max": 6 },
  "hem": { "edge": [[-6, 132.4], [-3, 133.1], ...], "rest": 0.5, "wave": 2.2, "wavelength": 58, "speed": 5.2,
           "energy": 40, "settle": 2, "shear": 0.03 } }
```

- `edge`: the resting bottom line, left to right, in canvas units (the outfit model samples his outline every 3 units
  and adds 1.6). The slot's part is clipped above it.
- The line ripples: `y + A sin(2 pi x / wavelength - speed t)`, with `A = rest + wave x energy`. The energy is the
  slot spring's speed over `energy` (units per second), held at most at 1.4 and dying away at `settle` per second, in
  the fixed 1/240 s steps (the same at 30, 60 and 120 Hz).
- The slot does not move with its spring's lag: the cloth shears by `shear x lag` about the slot's anchor (the
  neckline stays, the hem trails).
- It waves only while the figure rides physics (`"physics": true`); otherwise, and with reduced motion, it holds its
  resting line. `alive kit compose` clips it at its line as the still pose. `alive kit lint` checks the fields.

**Physics** (off unless the figure says `"physics": true`; the headset settle is not switched on yet): the slot's
layer rides a damped spring on the bone it hangs from, the scene's `worn` model: it lags, tilts and settles in fixed
1/240 s steps.

**Tint tokens**: named colour families. `skin` (#A8D0FB, his body), `paw` (the blue paw: #A9CDFA, #7DB0F3, #6497E2),
`paw-royal`, `ink`, `cheek`, `lens` (#BFE3E0), `frame` (the glasses rims). Each part lists the tokens it carries and its
**main** family (its most used colour family that is not a token: the cardigan's ochres, the helmet's khakis).

## The pack

`kits/<id>/kit.json` (`schema alive/1`, `kind kit`, `version`), and `kits/<id>/parts/<part>.json`, plain alive/1 art
(the format scenes use), one per part, its frame the SVG's viewBox.

Each part in `kit.json`: `slot`, `category`, `tags` (its name's words, `retired`, `handheld`, `lettered`, the skin),
`frame`, `origin`, `grips` (items), `grip` and `alt` (paws), `tokens`, `main`, `colours`, `box`, `name` (the kit page's
name), `figma` (its node in the kit file), `source` (its SVG), and for a face `split` (its features) and `splitIndex`.

The Fabio pack (1.4.0): 207 parts from kit-final (1 body, 31 faces, 53 paws, 15 skirts, 13 hats, 15 outfits, 11 accessories, 2
glasses, the headset's 3 parts and the earmuffs' 2, 38 props, 12 desk items, 12 eye parts), and 90 face features (each
face split into eyes, brows, mouth, cheeks and marks; drawn together they are the face, checked against Chrome's
render of the face). 73 of the parts are the kit vocabulary (generators in `<boards>/illustration/kit-refit/vocab/`):
kit 1.1.0 (23 Oct): faces proud, curious, focused, sleepy-happy, wink and the whole-face blinks `face-neutral-blink` and
`face-neutral-blink-half`; the eye channel (`eye-look-*` in eight directions, `eye-blink-half`, `eye-blink-closed` and
their `-wide` forms); the party and rain hats; the bow tie and lanyard; the lab coat (the team's sticker) and raincoat;
the popper (and its burst), pennant, balloon, sealed diary, mail bag and stamp; the bunting; the two-handed carry pairs
`hand-carry-both-{wide,narrow}-near-*` and the far paw for a layer in front, `hand-carry-front-far-*`. Kit 1.2.0 (23 Oct):
the satchel in layers (`kit-satchel-{back,mouth,letter,front,flap,flap-open}`; back, letter, front and flap stack to
`kit-satchel` exactly; pivots in kit-final/kit/satchel-layers.json), the hero cassette (`desk-cassette-hero`, and its
layers for boards in kit-final/items/cassette-hero/), the space suit and glass helmet, sunglasses, earmuffs (far and near,
like the headset), umbrella and flower pot. The host cardigan, conductor jacket, postal jacket and lab coat were
upgraded in place (more construction detail, same ids; the earlier files in out/svg/kit-locked-r1/). Kit 1.3.0 (23 Oct): the
other nine locked outfits upgraded in place the same way (all twelve now carry kit 1.2.0's density; every original is in
kit-locked-r1/), the space helmet, sunglasses, umbrella and flower pot raised, and the faces `you-did-it`, `no-worries`
and `go-on` with their actions and the pools `well-done`, `reassure` and `cheer-on` (each plays in any look). Kit 1.4.0
(engine 0.5.0): the far paw's slot has `"zFront": 117`, so `hand-carry-front-far-*` draws over the held item and under the
near paw (action `carry-front`, with `hand-carry-side-near-*`, the M3 near paw with a carry grip); the `outfit-skirt`
hem slot (z 35, its `edge` his outline every 3 units plus 1.6) holds a skirt for every outfit, `skirt-<outfit>` (the same
garment 6 units lower), and every look with an outfit wears its skirt, so his hem waves after a hop when the figure rides
physics. An app that swaps the outfit with `wear('outfit', ...)` should swap `outfit-skirt` to the matching skirt too. The pointing paws
and the two-layer palm and tips are kept (the pack mirrors the kit page) but `retired`: never chosen by a name, a
look or a pool, and an error if anything asks for them.

**Looks**: the kit's twelve (host, safety, explorer, letter carrier, coach, gardener, night owl, conductor, doorman, pen
pal, photographer, calm), three from kit 1.1.0 (researcher, rainy day, party) and three from kit 1.2.0 (space, cold day,
sunny day), each a part per slot on top of
`lookDefaults` (the blue body, both paws at rest). A look may carry its own tints (kit 1.6.0): `"tint": {slot or token:
"#RRGGBB"}` in the rig shifts that slot's main colour family (or a token's) whenever the look is worn, under any tint
the figure's own look adds (`AliveLook.tints` wins). The cold day look wears the pen pal's knit sweater tinted camel
(`"tint": {"outfit": "#C59D72", "outfit-skirt": "#C59D72"}`), so the two looks no longer share one sweater. `KitDef.lookTints`
(Dart) and `resolveLook` (tools/lib/kit/compose.mjs) apply it; `alive kit lint` checks each key is a slot or a token and
each value a colour.
**Actions**: clips keyed on bones and slots (`@` for the figure id): `rest`, `wave`, `thumbs`, `present`, `hold-up`,
`hop`, `tilt`, and from kit 1.1.0 `blink` (a `slot:eyes` swap: half, shut, half), `look-left`, `look-right`, `look-up`,
`look-down` (the eye parts, the head following a little), `you-did-it`, `no-worries`, `go-on` (kit 1.3.0), `carry-both` (the pair carries what he holds; the far paw
fades out while it does) and `celebrate` (the popper lifted and pulled). **Pools**: `greet`, `dress-up` (any look), `show-item` (any handheld item), and `well-done`, `reassure`, `cheer-on`
(kit 1.3.0: the encouraging actions, each in any look).

A name resolves in a slot as: a part id; else the slot's least tagged part carrying the name (with the look's skin
for paws); else, in a feature slot, that feature of the face with the name (`happy` in `mouth` is `face-happy.mouth`).

## A figure in a scene

```json
{
  "art": ["backdrop", "fabio", "desk_front"],
  "figures": { "fabio": { "kit": "fabio", "look": "host", "parts": { "glasses": "kit-glasses" }, "at": [42, 34], "scale": 1, "flip": false, "physics": false } }
}
```

The figure id is listed in `art` where he draws among the scene's art; no art file is read for it. `at` is where his
canvas origin sits in the scene. `flip` mirrors the whole figure (lettered items still read the right way). His layers:
`fabio` (root), `fabio.body`, `fabio.head`, `fabio.neck`, and `fabio:<slot>` for every slot. A clip keys them like any
layer (`tx`, `ty`, `rot`, `sx`, `sy`, `opacity`), and swaps parts with step channels:

```json
"wave": {
  "duration": 1600,
  "channels": { "face": [[0, "happy"], [1500, "neutral"]], "slot:near-paw": [[0, "edge"], [120, "wave"], [1400, "edge"]] },
  "tracks": { "fabio:near-paw": { "ty": [[0, 0], [320, -46, "outBack"], [1250, -46], [1550, 0, "inOutCubic"]] } }
}
```

`face` and `slot:<slot>` address the scene's first figure (`slot:<figure>:<slot>` another one). A swap lasts while
its clip plays; then the look's own part is back. `alive kit scene kits/fabio --out <dir>` writes a scene with one
figure and the pack's actions as clips.

Pools pull from the kit: a variant may `dress` the figure in a look of the kit (`"@looks"`: one variant per look) and
`wear` parts (`{"held": "@handheld"}`: one variant per part of that slot with the tag). The expanded variants are
ordinary ones: never the last pick, seeded by the run.

**Live eyes** (0.5.0). A scene's `live.blink` with `"figure": true` makes the figure blink through its eyes slot, and
`live.gaze` with `"figure": true` makes its eyes follow `controller.lookAt`. Both swap the eyes worn now for the
pack's own parts by name (`blink-half`, `blink-closed`, `look-left`, `look-up-right`...; `-wide` blink parts for wide
eyes), over the clip's and the look's, and only when the eyes worn now are tagged `pill` (open pill eyes) or
`pill-wide` (surprised, worried): eyes drawn as arcs, hearts, stars or spirals are left alone. The pack decides which
eyes are pills by those tags.

A name that resolves to no part (a typo in a clip's `face` channel, a `slot:` channel for a slot the pack lacks, a look
or a pool's `wear` naming a part that is not there) would be skipped while the clip plays. `alive lint` reports each as
an error (`unknown-part`, with the names the slot knows as a hint), and the runtime reports each once, when the scene
starts, as an `AliveUsageError` event.

## The customisation API

```dart
late final fabio = AliveController(vsync: this, scene: 'fabio-kit');

await fabio.dress(const AliveLook(
  preset: 'explorer',                                   // a look of the pack
  parts: {'glasses': 'kit-glasses', 'held': 'prop-mic', 'face': 'happy', 'near-paw': 'hold'},
  tints: {'outfit': Color(0xFF5B8DEF), 'skin': Color(0xFFF4F4F4)}, // a slot's main family, or a token
  adjust: {'hat': AlivePartAdjust(scale: 1.05, dy: -1, rot: -4)},  // clamped to the slot's range
  skin: 'royal',                                         // the paw family
));
await fabio.wear('held', 'prop-parcel');                 // swap one part, mid moment if need be
await fabio.takeOff('hat');
fabio.play('wave');                                      // the same action on any look
fabio.worn('near-paw');                                  // 'hand-wave-near-blue' while he waves
fabio.kit()?.tagged('hat', 'hats');                      // what the pack offers
```

| Call | What it does |
|---|---|
| `dress(AliveLook look, {figure})` | wears a whole look; loads the parts it needs first (the future completes when he wears it) |
| `wear(slot, part, {tint, adjust, figure})` | one slot; `null` takes it off; the clip goes on |
| `takeOff(slot)` | the same as `wear(slot, null)` |
| `kitLook({figure})`, `worn(slot, {figure})` | what he wears now (the clip's swaps included in `worn`) |
| `kit({figure})` | the pack (`KitDef`, alias `AliveKit`): slots, parts, tags, looks, `resolve(slot, name)` |
| `AliveLook.wear(...)`, `copyWith(...)` | a look with changes (looks are immutable) |

Names that do not resolve and adjustments outside a slot's range are reported as `AliveFailed` usage events; the rest
of the look still applies, and adjustments are clamped. On the player: `dressFigure`, `figureLook`, `dress`.

**Tints.** A slot tint moves the part's main colour family: the key colour becomes the tint, every other colour of the
family keeps its hue, saturation and lightness offsets from the key, so shades stay shades. A token tint does the
same to that token's family in every part that carries it. Tinted parts are compiled once per tint and shared.

## How it is drawn

The figure's art is generated from the rig when the scene loads: his root layer placed in the scene, then for every
slot (at its z, its alternate z and its front z) the layers it hangs from, the slot's layer, and a **part node**
(`{"part": "fabio:hat"}`, a new kind of art node). A part node draws whatever the player's look puts in that slot, at
the slot's placement (anchor, rotation, adjustment, origin or grip point). Pivots, anchors and physics are all in canvas
units. Parts are compiled once per pack and tint and shared by every screen showing the scene.

## Checked against the kit (measured)

Every part and look is drawn by Chrome from the kit's own SVGs and by the engine from the pack, and compared pixel by
pixel (`test/kit_congruence_test.dart`, `test/kit_look_test.dart`, the QA sheet: `npm run kit-qa`). The measure counts
pixels whose largest channel differs by more than 32 of 255, then those that still differ allowing an edge one pixel
over, then those in regions of 4 pixels or more (the gate: under 1 % of the drawn pixels for a part, 2 % for a look).
The gate's negative controls fail as they should (the white-lens glasses, the body moved by one unit, another face).

22 Oct, scale 2x: 134 of 134 parts pass (worst 0.54 % of drawn pixels in regions, worst 5.5 % over 32: the small eyes,
whose curves anti-alias differently; mean 0.39 %); at 4x the same 134 pass (worst over 32: 3.0 %). 46 of 46 looks pass
(the kit's 12, the same 12 composed by the CLI, 22 more with glasses, expressions, held items, the royal skin, tints
and an adjusted hat): worst 0.01 % in regions, 0.09 % over 32. 19 of 19 renderer test cards pass.

23 Oct (pack 1.1.0, scale 2x): 173 of 173 parts pass; the 39 new ones are all at 0.000 % in regions (worst over 32:
11 % on `eye-look-up`, the same anti-aliasing of small curves as the locked eyes). 49 of 49 looks pass (the 3 new
looks join the matrix with glasses): worst 0.006 % in regions, 0.09 % over 32. 4x not measured for this pack (memory).
23 Oct (pack 1.2.0): at 2x 187 of 187 parts and 52 of 52 looks pass; at 4x 187 of 187 parts pass (worst 0.589 % in
regions, the locked glasses; every part new in 1.2.0 0.000 %, the eye parts after their edges were put on the quarter-unit
grid). 19 of 19 test cards at both scales.
The importer now also tags a part with its whole name when the name has several words (`sleepy-happy`, `look-up-left`,
`carry-both-wide`); checked over 6,099 name resolutions, the one that changed is `ticket` in the held slot, which
used to return the ticket punch and now returns the ticket.
