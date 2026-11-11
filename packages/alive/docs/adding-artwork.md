# Adding new artwork

For designers. A new outfit, hat, prop, face, paw or even another mascot reaches the app as an **art pack**: SVG
files turned into parts the engine can put on Fabio at run time. No engine code changes. Five steps.

## 1. Draw it on his canvas

Every part that sits on Fabio is drawn on **his canvas: 148 x 163 units, viewBox `-2 -22 148 163`** (the frame of the
Figma page *Fabio kit (final)* in the design file). Draw it exactly where it sits on him: a hat
on the dome, glasses on the eye line (eyes at x 78.4 and 91.5, y 33 to 40), an outfit hanging from the neckline (y 60).
The engine does not move it; it only follows him when he moves.

Things he holds or that stand in a scene (props, desk items) have their own frame, with **their attach point at
(0, 0)**: the frame's viewBox starts negative, e.g. `-11 -37 22 68` for the mic. Paws are centred on (0, 0) of a
52 x 52 frame.

The kit's rules hold for new art too:

| Rule | Why |
|---|---|
| No outlines; form from one darker shade per surface | his whole kit is drawn that way |
| Body colour `#A8D0FB` | the canonical Fabio |
| **No stroke-only shapes.** Outline every stroke before you export (Figma: *Outline stroke*; or picosvg) | Figma gives a stroke-only shape a paint of its own on import: rims become filled white disks, the "glasses drawn as overlapping circles" |
| No white lenses or eyes (a tinted lens is `#BFE3E0` at 34 %) | the same bug, already baked in |
| No pointing paw | retired 20 Oct |
| One whole holding paw (M3), not palm and fingertips in two layers | the paw is over the item to hold or carry it, under it to present it |
| Cheek colour only on happy or shy faces | a design note |

## 2. Export SVG and name the files

Export each part as SVG (Figma: select the frame, *Export*, SVG). Name each file by its group and name, the way the kit
page does: `Hat / Bucket hat` or `hat-bucket-hat.svg`. The first word picks its place:

| Name starts with | Goes to | Notes |
|---|---|---|
| `Body` | body | the silhouette; only ever tinted |
| `Face` | face | split automatically into eyes, brows, mouth, cheeks and marks |
| `Hand` / `Paw` | near or far paw | `near` or `far` in the name; `hold`, `carry`, `present`, `wave`, `thumbs`, `edge` say the pose; `blue`, `royal` or `white` (the white History Fabio's own paw) the skin |
| `Hat` | hat | |
| `Outfit` | outfit | |
| `Kit` | by name: `glasses`, `headset-far`, `headset-near`, `satchel` (and its layers), `whistle`, `knit-scarf`, `bow-tie`, `lanyard`, `earmuffs-far`, `earmuffs-near` | add a name to the rig's `kit` folder rule for a new accessory |
| `Eye` | eyes | eyes on their own (a look direction, a blink frame), on his canvas; a clip swaps them with `slot:eyes` |
| `Prop` | held (and the item slots) | |
| `Desk` | front and behind item slots | |

Put them in one folder (a flat Figma export), or in the kit's folders (`body/`, `faces/`, `hats/`...).

## 3. Import them into the pack

```bash
node tools/alive.mjs kit import path/to/new-hats --into kits/fabio
```

This compiles each SVG to a part (`kits/fabio/parts/<id>.json`), adds it to `kits/fabio/kit.json` with its slot, tags,
origin, colours and tint tokens, bumps the pack's version, and runs the lint. New looks, actions or folder rules go in the rig
(`tools/kit/fabio.rig.json`); pass it too (`--into kits/fabio --rig tools/kit/fabio.rig.json`) and they join the pack. A brand new pack (another mascot) takes a
rig instead: `--rig rig.json --out kits/<name>` (see `tools/kit/fabio.rig.json` for Fabio's).

## 4. Lint, and look at it

```bash
node tools/alive.mjs kit lint kits/fabio
node tools/alive.mjs kit compose kits/fabio --look explorer --wear hat=hat-bucket-hat --svg /tmp/try.svg
```

The lint names the file and the shape for anything that breaks a rule above, and says how to fix it. `compose` draws
a look with your part as one SVG: open it in a browser. `npm run kit-qa` builds the visual QA sheet (Chrome and the
engine side by side for every part and look).

## 5. Ship it

Copy the pack to the app: `kits/fabio/` to `assets/alive/kits/fabio/` (list `kit.json` and `parts/` under
`flutter: assets:`). The app dresses Fabio in it:

```dart
fabio.wear('hat', 'hat-bucket-hat');
fabio.dress(const AliveLook(preset: 'explorer', parts: {'hat': 'hat-bucket-hat'}));
```

A pool can pull it in automatically: give it a tag the pool names (`"wear": {"hat": "@hats"}` picks any hat).

## What the engine does with it

The engine places a part by its slot's anchor (from the rig), draws it in the slot's layer order (far paw behind him,
body, outfit, accessories, face, glasses, hat, headset, near paw and what it holds in front), lets it follow the bone it
hangs from (the hat and face follow his head, the outfit hangs from the neckline, paws float beside his body), and can
tint it (`tints: {'outfit': Color(0xFF5B8DEF)}` shifts the outfit's main colour family and keeps its shades) or adjust
it within the slot's range (a hat may scale 0.9 to 1.1, move 5 units, tip 10 degrees). `docs/kit.md` has the details.
