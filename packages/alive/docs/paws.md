# The pixel paw check

Fabio's paws have a style, and the check measures each paw on the pixels a participant sees against the style's rules.

- **Touch, the default** (kit 1.7.0 and later): every paw that shows touches or overlaps his figure, as the team
  stickers draw them. The near paw rests over his right edge by a third of its width at (140, 104), the far paw a
  third behind his left edge at (6, 106), and every action is keyed to keep each paw on him. The white History Fabio
  keeps the royal paw. The rig carries the touch rests and actions, because the Flutter runtime plays the kit as
  written.
- **Detached, the named variant** (`pawStyles.detached`; the default of kit 1.6.0): paws held clearly apart from his
  body, at rest near (160, 98) and far (-16, 102) on his canvas, about 9 units of air; a working paw keeps at least 6
  units of air, or sits wholly in front of him when both paws hold one thing; never on his outline.

In both, the wave and the rest stay as they are, and a paw that holds or picks up something makes no long trips
around the screen.

Before kit 1.5.0 nothing measured either: `alive lint` compared each paw's centre with an ellipse fitted to his body's
bounding box (`paw-attached`, a warning), and the kit's figure rules measured how far a paw travelled from its rest
spot. `alive paws` (and `alive lint`, which runs it unless `--no-pixels`) draws every frame it looks at, with no browser
(tools/lib/paws/raster.mjs: path data, rects, ellipses, strokes, clips, boxes, text as its box; one sample per pixel at
4 pixels per kit unit) and measures shapes. Kit units are his own, at his size at that instant (a figure scaled, popping
up from 0.6 or squashed by a hop is measured in his units).

| Rule | Style | Severity | What |
|---|---|---|---|
| paw-air | detached | error | a paw that shows (35 % opacity or more, at least 10 % of it not covered or off the screen) has less than 6 kit units of air from his figure (body, outfit, hem, accessories, head, face, hat), or touches or straddles his outline |
| paw-front | detached | error | a paw sits wholly over his figure (none of it more than half a unit outside him) but both paws are not holding one thing (both over him, or one part drawing the pair) |
| paw-reach | detached | error | a paw is more than 40 kit units off him: a long trip (the bound, below) |
| paw-rest | detached | error | a kit paw at its rest spot (the look's own paw, its slot not moved) is not at the detached rest's air from his bare body: 9.25 near, 8.31 far, within 1.5 |
| paw-contact | touch | error | a paw that shows floats more than 0.5 kit units off his figure. A paw drawn in front of him (after his body in paint order) is measured on what shows: its pixels that show against the part of his figure that shows, his figure less what is drawn over him (a held item, a prop, a desk top; not his own paws) and less what lies outside the scene's frame (0.6.5, below). A paw drawn behind him is measured on full shapes |
| paw-overlap | touch | warning | it touches him less than 1.5 kit units deep into his full shapes, front paws too (on a figure that rides physics: the paw slots' physics max, 3) |
| held-contact | both | error | a held item does not touch the paw holding it. R4: the far paw drawn in front, carrying the item the near paw holds, is measured from that item, not from its rest behind him |
| paw-hidden | both | info | a paw 90 % or more covered by what is drawn over it, cut away by its own clip (tucked below a sill or a ring's rim) or off the screen is hidden, not measured; reported with how much shows |
| paw-skin | both | warning | a paw that is not this Fabio's paw: the blue Fabio's own blue paw; the white History Fabio's royal paw by default (the dark blue paw for the white Fabios), his white paw with `--white-paw white` |
| paw-blink | both | error | (`alive lint`, art scenes, since 0.6.1) a paw swap leaves him without a fully visible paw: while his body shows, his most visible paw dips under 0.8 opacity and comes back within 0.6 s, measured at the clip's frame rate on opacity alone (docs/checks.md) |

    alive paws <scene dir>... [--paws touch|detached] [--white-paw royal|white] [--out pictures/] [--json out.json] [--strict]
    alive paws --kit kits/fabio [--paws touch|detached] [--white-paw royal|white] [--out pictures/] [--json out.json] [--only <regex>]
    alive lint <scene dir>... [--paws touch|detached] [--white-paw royal|white]

## Front paws are measured on what shows (0.6.5)

Up to 0.6.4 paw-contact measured every paw against his full shapes. That is right for a paw drawn behind him: tucked
behind his edge, the part of it that shows meets him where his body covers the rest. For a paw drawn in front of him
it is not: the paw can overlap his shapes only where something hides him, and a viewer then sees a paw with none of
him beside it. Two cases passed with a gap of 0:

- a front paw at the edge of the scene's frame as he walks in, his body still outside the frame;
- a front paw on a held item (a phone, a tape, a card) that covers his belly, with none of his body showing next to
  the paw.

Since 0.6.5 a front paw's gap is measured from its pixels that show (not covered by what is drawn after it, inside the
frame) to the part of his figure that shows: his figure painted in order, less what is drawn over him after his
body's first item at 60 % opacity or more and not blurred (his own paws excepted: a paw is measured against him, and
his two paws do not hide him from each other), less what lies outside the scene's frame. When nothing covers him and
he is wholly inside the frame, that is his figure as drawn and the measure is the one 0.6.4 made. A paw that touches
him only where he does not show fails with "touches him only where he does not show"; a paw with none of him in
sight fails with "shows with none of his figure in sight". His clips (a dialog, a window) cut his figure and the paw
as before; a paw whose whole figure is cut away is now reported 60 units off him (the check's margin), not a number in
the billions.

paw-overlap keeps measuring how deep a touching paw sits in his full shapes, front paws too: what covers a front
paw's junction with him is most often the item the paw holds, which moves with the paw, so the depth into his shapes
is what keeps the paw on him as his physics or a hop moves it. The depth into the part of him that shows is in the
JSON output (`shownDepth`), not a rule. The detached rules (air, front, reach, rest) measure from his full shapes as
before.

What the measure leaves to the scene: a kit figure is drawn on its own (its parts and its held item), so art of the
scene outside the figure does not cover him in this check; in an art scene (a board export) everything drawn over him
counts.

Measured with the 0.6.4 check against 0.6.5 on the same files: the kit in both styles (79 cases each), the 71 board
exports, the app's 51 scenes, the ten Diary Moments engine moments and the encouragement export, and this repository's
examples and test scenes keep their results, but for one: the tape moment (`dm-tape` in the app, `tape` in the Diary
Moments engine folder). From 6.29 to 6.33 s (about 40 ms) the tape, flying up into the take paw, passed over his side
between the paw and his body, and the paw showed up to 16 units from the part of him that shows; before and after, it
touched him. The moment has since been drawn for it: the tape comes round below his paw and rises into it.

## The max-air bound (paw-reach): 40 kit units

Measured from the 97 placements of the hands audit (hands-v3/audit.json, the table at the bottom of the hands
guide), with the audit's own geometry (kit-refit/hands3/audit_lib.py: the paw's outline against his body outline)
run again without the 80-unit cap its search had (kit-refit/hands3/audit_uncapped.py; every row under the cap agrees
with the 6 Oct table to 0.3 units). All 97 rows with the subset and flags: docs/paws/max-air-round10.json.

- 64 placements have air, 8 sit in front of him (two-paw holds), 25 straddle his outline tucked behind a desk (hidden).
- The figure placements (the kit rest, the hands guide and its animation, poses-v3, the actions page, the clothes page;
  no desk) top out at **38.2**: the carrier holding a bubble overhead (poses-v3). Then the archivist's label 32.5, the
  phone 30.4, the tape 29.0; the wave 14.3 to 14.5, the thumbs up 11.7 to 14.0, the open paw 13.5, the rest 9.1 and 8.2.
- The desk arrangement's raised-paw reaches run from **42.9** (the tape toss) to **150** (the take set down at the far end
  of the desk): the tape flown to a paw in the clear zone. Those are the holding and picking-up trips the hands
  guide retired; a bound over all 97 (150) would allow every one of them.
- So the bound is 38.2 plus 1.8 units of tolerance: 40, under the nearest retired desk reach (42.9). The check measures
  the audit's rest spots at 9.25 and 8.31 on the bare figure where the audit's path geometry gives 9.14 and 8.24.
- What the bound does not do: kit 1.4.0's gestures reached 25 to 29 units off him (its wave at (170, 52)), inside the
  bound (the locked desk wave was 37.8). Kit 1.6.0's actions sit at the hands guide's spots (6.7 to 23.5 units of air
  over every case), so the closeness kit 1.5.0 gained is kept by the keys; a tighter bound for gestures would be a new
  design rule.

## Baselines and results

| Kit | Style | Cases failing | Paws | Errors | File |
|---|---|---|---|---|---|
| 1.4.0 | touch rules | 71 of 71 | 141 | 143 (+2 warnings) | baseline-1.4.0.json |
| 1.4.0 | detached | 11 of 71 | 12 | 14 | baseline-1.4.0-detached.json |
| 1.5.0 | detached | 71 of 71 | 142 | 245 | baseline-1.5.0-detached.json |
| 1.5.0 | touch | 0 of 71 | 0 | 0 | baseline-1.5.0-touch.json |
| 1.6.0 | detached (default) | 0 of 79 | 0 | 0 | final-1.6.0-detached.json |
| 1.6.0 | touch (`pawStyles.touch`) | 0 of 79 | 0 | 0 | final-1.6.0-touch.json |
| 1.7.0 | touch (default) | 0 of 79 | 0 | 0 | final-1.7.0-touch.json |
| 1.7.0 | detached (`pawStyles.detached`) | 0 of 79 | 0 | 0 | final-1.7.0-detached.json |
| 1.7.1 (engine 0.7.0) | touch (default) | 0 of 79 | 0 | 0 | final-1.7.1-touch.json |
| 1.7.1 | detached (its own held items keyed to the holding paw) | 0 of 79 | 0 | 0 | final-1.7.1-detached.json |

Kits 1.6.0 to 1.7.1 have 79 cases: 18 looks at rest, 18 actions on the bare figure plus the 8 that move a paw on a dressed one (the
letter carrier: for detached paws an outfit takes air away, so a dressed figure is the strictest case), 35 cards.

Who is who: kit figures by their slots (`near-paw`, `far-paw`, `held`; his figure is body, outfit, hem, accessory,
face parts, hat, glasses, headset). Board exports by their layer names: a root `fabio` or `fabio <name>`, its
`<root>/body`, paws `<root>/hand-...` (or `paw`), and nothing named `item/...`, `ui/...` or a window, shadow or prop
counts as his figure. A scene made by `alive figma` names them in `meta.figma`.

`--kit` checks every look at rest, every action over time (on the bare figure: an outfit only adds to his figure, so a
paw that touches the bare body touches every dressed one; and the actions that move a paw on the letter carrier, the
strictest case for detached paws), and the cards: the look matrix's held items and gestures and every handheld item on
the open paw. A kit with paw styles is checked in the style named. `tools/ci.sh` runs both styles (steps `kit-paws`,
the default touch, and `kit-paws-detached`) and kit-qa shows both.

The touch baseline (kit 1.4.0, 23 Oct, by the touch rules): 71 of 71 cases failed, 141 paws (143 errors, 2
warnings): every look's rest paws 6.7 to 9.3 units off him (the detached rest), the wave and the open paw
26 to 29 units. `docs/paws/baseline-1.4.0.json` lists each one.

Validated against Chrome on real art (23 Oct): the 12 composed kit looks and 5 cards rendered by this rasterizer and by
Chrome (the kit's reference renders, test/kit/refs, 2x) have silhouettes with IoU 0.988 to 0.994, and at most 0.03 % of
the drawn pixels differ by more than one pixel: the shapes agree to within half a kit unit. (Colours inside the shapes
differ on up to 3 % of pixels, because the check's quick colour pictures draw a gradient in its first stop; the
measures use shapes only.)
