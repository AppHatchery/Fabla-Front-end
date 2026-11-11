# The board checks: what the board shows is what the engine draws

The Diary Moments boards of 24 Oct had five defects no check could see before 0.6.1: a faceless
Fabio for the whole of two failure states, a two-paw hold that blinked out between its fades, a stub waiting 5 to 6 pt from
the screen's edge, and two places where the engine drew something other than the board (ending A's heart seal never
showed; every ending's summary lost its radio dot and play triangle). Each class now has a check that fails on it,
and one more class found on the way (flicker).

| Check | Command | Severity | Catches |
|---|---|---|---|
| face-missing | `alive validate`, `alive lint` | error | a clip asks a figure for a face it was not given |
| face-blank | `alive lint` | error (warning under a third of a second) | his face shows nothing while his body shows |
| paw-blink | `alive lint` | error | a paw swap leaves him without a fully visible paw |
| safe-margin | `alive lint` | error | an object (since 0.6.2: the app's ui/ objects too, glows and rings included) reaches into the app's 16 pt margin while it is wholly on the screen and not travelling fast |
| flicker | `alive lint` | error | something pops out for a moment while it shows (found while fixing the others: one of those fixes caused one); 0.6.3: a designed blink or a flip is info, not an error |
| parity | `alive parity` | exit 1 | the engine draws an element the board does not, or the other way round (since 0.6.2: at every 2nd frame of the whole timeline, not only at the beats); or the board draws a beat differently when played and when jumped to |
| fail-sending (0.6.2) | `alive lint` | error | once the app's saved card shows, a text still says Sending, Uploading or Submitting |
| fail-progress (0.6.2) | `alive lint` | error | once the app's saved card shows, a progress object still turns, rolls, grows or lights another part |

## Faces

A face the figure lacks used to go three ways: the board set every face to 0 (blank), the runtime kept the look's face
(here happy, the wrong feeling), and a look naming a missing face drew no eyes and no mouth at all. Now:

- The runtime wears the neutral face where a clip's `face` channel or a look names a face the pack does not have, and
  reports the name once when the scene starts (`FigureDress.clipSwap`, `resolveLook`; the CLI's `resolveLook` too).
- `alive validate` reports, as errors at the channel entry's path, a kit figure's `face` or `slot:` channel value that
  its pack cannot resolve, and (art scenes) a `face:<figure>` channel value with no layer `<figure>/face <name>`.
  `alive html` validates what it writes, so a board that asks for a missing face cannot be exported.
- `alive lint` (art scenes): face-missing (as validate) and face-blank, measured on what is drawn at the clip's frame
  rate (30 fps): while his body is drawn at 0.5 opacity or more, something of his face layers (`<figure>/face`, a
  Figma export's default face, and `<figure>/face <name>`) must be drawn at 0.35 or more. A stretch of a third of a
  second or more is an error; a shorter one (a cross-fade with no face in the middle) a warning.

Board exports carry what each face was asked for: the board's `faceTo` logs every request, and the exporter writes it
as the step channel `face:<figure>` (docs/schema.md, faces in art scenes).

## paw-blink

Opacity only, at the clip's frame rate (the pixel paw check samples every 66 ms and stepped over a two-frame gap):
while his body shows, his most visible paw stays at 0.8 opacity or more; a dip under it that recovers within 0.6 s is
a blink, reported with its frames, how many had no paw at all and the lowest opacity. Overlap the fades (the incoming
paw up before the outgoing one goes). Longer absences (a paw put away) are not a blink.

## safe-margin

Each object's ink box (its shapes at 0.5 opacity or more, blurred shadows left out, cut by its clips), every frame at
30 fps. An object is an `item/...` layer and, on a phone screen (300 by 500 pt or larger), an app `ui/...` layer (round
8: the last question's finish badge is `ui/bar badge 4`). It breaks the rule in a frame when it is wholly on the
screen, reaches closer than `--safe` (16 pt) to an edge (1 pt tolerance), and is not travelling fast (its box moves
under 200 pt a second, measured to the frames before and after: a hold, a settle or an overshoot). Entrances and exits
are partly off the screen or fast; scenery wider than the safe area (the train, the rails, a full width page) and the
`--bleed` names (trails, puffs, steam, smoke, confetti, shadows, sparks: what drifts and fades past an edge by
design) are left out. `--no-margins` skips it.

Since 0.6.2: glows, halos, rings, sheens and glints count (they were bleed names), from 0.2 opacity (a fading ring is still
seen). Left out of the app's `ui/...` objects: a shape wholly in the phone's status bar band (the top 54 pt) or home
indicator band (the bottom 34 pt), which are the system's (the summary page carries the home indicator, 140 x 5 at y
914), and a text with no measured width: the app lays its own text out, and the width estimate the check would use
(0.55 em a character) runs wide of Rubik (the progress next-large question line read as x 426 for a line that
ends at 388 in Chrome; that was the one false error among the boards' 45 scenes). An `item/...` text keeps the estimate.
The Diary Moments boards run it on every scene (0.6.1 ran it only on the 24 scenes with Fabio).

## flicker

Opacity through its ancestors at the clip's frame rate, as 0 while the layer or an ancestor has no area (a scale, a box
width or a box height of 0): a fall of 0.45 or more from one frame to the next while it shows (0.5 or more) that comes
back to 0.5 or more within 0.4 s. Face layers are left out (an eye blink is a dip on purpose); a group that pops out is
reported once, not for every layer under it. The cause it was written for: a GSAP `fromTo` that starts later
(`immediateRender: false`) snaps its target to its from-value only when it starts, so whatever showed the target
before (its default opacity, or its page's own fade) shows it first. The boards' record key did that to Pause (at full,
then 0.18, then fading back in, at 0.90 to 0.97 s). Hide such a target from the start.

The boards have the same check for every scene, exported or not (streams/diary-moments/check-flicker.cjs: the board in
headless Chrome, played frame by frame).

### Designed blinks and flips (0.6.3)

Two designed moves fall the same way and are not flickers, so each fall is classified before it is reported:

- A flip: a scale of the layer or of an ancestor has another sign when it is back than just before the fall, and its
  opacity stayed shown through the dip (wv_not_found_v1's tag, sy 1 to -1 and back: the frame on 0 has no area).
- A designed blink: an opacity square pulse. It is cut off, stays off and flat (within 0.02) for two frames or more
  (66 ms), is cut on again to the level it had (within 0.1), and keeps its area throughout (ws_battery and ws_two: the
  phone's 14% screen off for 0.27 s and on again). A cut may take one frame part way at each end: a cut keyed at 60 fps
  can land between two of the checked frames (the old survey board's mouth swap reads 0, 0.49, 1).

Each is reported as info (rule `flicker-designed`, shown with `alive lint --verbose`), with what it saw. Still errors:
a fall that fades back in (the GSAP snap: the boards' record key, option fill and dot), an off of one frame, a
hide by a scale or a box of 0 (a hide by size, not an opacity blink), a return to another level, a flip whose opacity
drops out as well, and a scale that reaches 0 and comes back on the same side (not told from a hide by scale; key a
tumble through 0 so it changes sign). Tests: tools/test/flicker.test.mjs.

Measured on 26 Oct, the 0.6.2 CLI against 0.6.3 on the same files:

| Scenes | 0.6.2 flicker errors | 0.6.3 flicker errors | 0.6.3 designed (info) |
|---|---|---|---|
| the app's 51 scenes (the app's `assets/alive_src`) | 4, in 3 scenes | 0 | 4: 2 blinks, 2 flips |
| the ten Diary Moments engine moments of 26 Oct | 0 | 0 | 0 |
| the 24 Oct boards' micro reduced scene, exported again | 2 | 2, the same | 0 |
| the 71 board exports of the corpus (`alive sweep`, `--no-pixels`) | 31 | 20 | 11: 4 blinks, 7 flips |

Every other rule's lines are the same in both runs on all of these files. The 20 left in the corpus: two confetti
pieces of the old completion export whose scale reaches 0 on the same side (6), caret dips of one frame (5), the
slider's held value cut to 0 and faded back in (3), the recorder's window door (2) and storage labels (4), falls that
fade back.

## alive parity

    alive parity <scene dir> --page <board page> --scene <board scene> [--query "eng=1&rec=1"] [--at <s>...]
                 [--every 2] [--out <dir>] [--json <file>] [--scale 1] [--radius 2] [--threshold 60] [--min-area 24]

The board page in headless Chrome and the exported scene drawn by the runtime (`alive preview`, stills only), at the
board's beats: its labels, the midpoints between them and its end, on the 30 fps grid. A pixel differs only when no
pixel within `--radius` on the other side is within `--threshold` of its colour; a difference counts as a connected
patch of `--min-area` pixels or more, more than 2 pixels across both ways (a glyph or an edge a pixel over is not an
element). Each patch is reported as missing in the engine, extra in the engine, or drawn differently, with a picture
(board, engine, the difference) in `--out`.

The board is played frame by frame to each beat (as it plays for a person, and as `alive html` samples it) and is also
built afresh and jumped to each beat (scrubbing): a beat where the two differ fails too. That found a board defect that
had gone unseen: GSAP turns an `svgOrigin` into the element's own units through its transform at that moment, so a
tween naming the origin again on an element already moved re-anchored it, and ending A's carrier ended 15.7 pt right
and 10.5 pt up when played (and in the engine), but not when scrubbed. The boards now give each element its origin
once.

Dense (0.6.2): the beats were not enough. As ending C's train left, the engine drew five hard black trail lines for 5
frames (9.43 to 9.57 s) that the board never drew, between the beats at 8.5 and 10.3 s, and parity said the moment
matched. So the board (played frame by frame) and the engine are also compared at every `--every` frames (2 by
default, 0 for the beats only) over the whole timeline, with the same tolerances; each run of differing frames is
reported (its first and last frame, its largest patch and kind) with one picture, of its worst frame (`.dense.png`).
The played and jumped comparison stays at the beats (each jump builds the board afresh). A moment of 12 s is 191
sampled frames, about 40 s with the runtime's stills.

## fail-sending and fail-progress

A failed upload says one thing. The 24 Oct boards' Not sent endings showed the app's "Diary Saved for Submission" card while the
moment's own objects went on claiming the upload (C's ticket SENDING 3 of 7, B's dimmed LCD SENDING, D's entry chip
Sending). Measured on what is drawn at 30 fps, from the first frame the saved card (`ui/saved for submission`) shows at
0.5 or more, to the clip's end:

- fail-sending: a text drawn at 0.2 opacity or more, on the screen and not cut away by its clip, that says Sending,
  Uploading or Submitting (the 0.2 floor: a label dimmed to 0.35 still reads).
- fail-progress: after a grace of 0.1 s, a progress object (a layer named, or under one named, ring, segment, dash,
  reel, hub, marks, running, needle, count, odometer, hole, spinner or progress) changes its position, scale or turn
  while it shows, or one of its numbered parts (a ring segment, a hole) switches on. Fading out or changing colour is
  the stopped state, and is allowed.

A scene with no saved card has nothing to check.

## A bounding-box gradient on a shape with no area

A gradient in bounding-box units (SVG's default) on a shape with no width or no height, a horizontal or vertical line,
has no box to fill: SVG ignores the paint and Chrome draws nothing. The runtime built the gradient's matrix from the
zero-height box and painted the line black: ending C's train trails (`stroke="url(#trail)"` on `M1300 36h260`), five
hard black lines for 5 frames in the engine, nothing on the board. Now `alive html` leaves such a paint out and says so
(`warning: dm-terminus: 5 x a bounding-box gradient on a shape with no width or height (trail): not painted, as
Chrome`), and the runtime paints nothing for one (test/degenerate_gradient_test.dart: 336 black pixels before, 0
after), so an export made before the fix draws as the board does too.

## Measured on the Diary Moments boards

Before: the boards and exports as they were before 0.6.1 (the engine moments as committed, the other board scenes
exported with face names). After: the boards fixed with 0.6.1's checks. Ten engine moments, fourteen other board scenes with Fabio.

| Check | Before | After |
|---|---|---|
| validate (face channels) | 2 scenes refused, 4 errors (C and D Not sent: concerned, relieved) | 0 |
| face-blank | 2 scenes: C Not sent 90 frames from 5.03 s, D Not sent 90 frames from 3.83 s | 0 |
| paw-blink | 2 scenes: A and A slow, two dips each (6 and 5 frames, 2 and 1 with no paw) | 0 |
| safe-margin | 5 scenes, 9 objects: C's stub 57 frames at x 428.3 of 430, V2 and V3 the same and their tickets, C skip and the completion slot's stub at x 424.2 | 0 |
| parity, engine differs | 5 of 10 moments, 32 beats: the summary's radio dots and play triangle (4 endings), A's seal from 2.6 s and its closed flap, B's sent sticker, the record key's label | 0 of 10 |
| parity, played and jumped differ | ending A, 10 of 15 beats (the carrier 15.7 pt off) | 0 |
| flicker, the 24 exports | 0 (a record key change on the way made 1, fixed) | 0 |
| flicker, every scene of the four boards (check-flicker.cjs) | 2: Submit and not sent (Return Home drops out for a frame at 3.1 s), the summary before (a flash on its first frame) | 0 |

Board-side causes, fixed in the boards' exporter: an element that starts at scale 0 had no inverse at rest (the seal,
the closed flap, the stickers); CSS `::before` and `::after` boxes were never seen (the radio dot, the play triangle;
they are now exported as elements, and border triangles drawn as CSS draws them); HTML boxes were drawn in DOM order,
not CSS paint order (the record key's pressed shade covered its label in the browser only); a see-through border's
alpha went to fill-opacity; a garment's skew was dropped (now the layer's `kx`); animated heights are carried (`h`).

## Measured on the Diary Moments boards, before 0.6.2

Before: the boards as 0.6.1 left them (served from the Diary Moments main folder), their engine exports for dense
parity and the 0.6.1 runtime (art_renderer.dart as in engine 0.6.1); every one of the 45 scenes of the four boards
exported with `alive html` (query `eng=1&rec=1`, the detached paws, then the default) and linted without the pixel
paws. After: the boards fixed with 0.6.2's checks, in the changelog.

| Check | Before 0.6.2 |
|---|---|
| parity, dense (every 2nd frame) | 1 of 10 moments: C, 3 of 191 sampled frames, one run 9.40 to 9.53 s, 1026 px extra in the engine at x 0 to 256 (the five trails); the other nine 0 (posted 0 of 170, tape 0 of 149, today 0 of 126, three 0 of 79, completion after 0 of 81, next 0 of 77, quarter 0 of 59, choose one 0 of 57, record key 0 of 68); at the beats 0 |
| safe-margin, every scene | 5 errors in 2 scenes: the last question's finish badge (its edge at x 422.7 at the pulse, 130 frames), its glow (x 426.3), its two rings (x 427.8); and progress next-large's question line, a false error of the width estimate (now left out, see above) |
| fail-sending | 4 scenes: B Not sent (the LCD's SENDING at 0.35 under the card), C Not sent (SENDING on the ticket), D Not sent (the entry chip Sending), Submit and not sent (Submitting... drawn under the saved card) |
| fail-progress | 0 |
| flicker, every exported scene | 2 in the reduced motion scene: the option fill and dot of Well (they hid by width and scale 0, so the export showed them before the pick) |
| face-missing, face-blank, paw-blink | 0 |

The trails fix on the same board: C exported again (the trails left out, with the warning) and drawn by the
0.6.2 runtime, 0 of 191 sampled frames differ; the earlier export, trails and all, drawn by the 0.6.2 runtime, 0 of
191 too.

