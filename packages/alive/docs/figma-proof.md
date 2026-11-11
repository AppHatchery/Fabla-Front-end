# Figma Motion to alive: the proof

`alive figma` turns a Figma Motion frame into an alive/1 scene with Figma's own Fabio kept as compiled art (no
engine-drawn Fabio), so it plays on the lean runtime. This page measures how close the result is to Figma's own MP4
export of each frame, the same way the procedural import was measured (fabio-engine-plus `docs/figma-to-engine.md`,
"41 moments, 1.3%"), so the two numbers sit side by side.

Measured 22 Oct 2026 on the laptop, `flutter test` (debug, software renderer), Figma cache of 6 Oct
(`tools/figma/cache` in this repository: the reads and SVG exports made in fabio-engine-plus on 6 Oct; the MP4
exports are the boards' own under `<boards>/motion`, and for six frames the ones fabio-engine-plus exported).

## Method

- Every frame in the cache (41 frames, 37 scenes: Slider carry V1 to V3 and No internet V1 to V3 are one scene each,
  with a pool) is converted by `node tools/alive.mjs figma --all`.
- Six instants per moment, at (i + 0.5) / 6 of its length, each snapped to a frame of the MP4 (frame k at k / fps,
  ffprobe) and extracted exactly (ffmpeg seeks half a frame before it), scaled to the frame's 430 x 932. These are the
  instants the procedural import was measured at.
- The runtime (`AlivePlayer` and the compiled art, as the app draws it, live behaviours off) draws the same instants
  (`test/figma_proof_test.dart`). Fonts: Rubik, Rubik SemiBold, VT323 and Pixelify Sans, as the app registers them.
- Differs: the share of pixels whose largest colour channel differs by more than 40 of 255. Fabio offset: the distance
  between the centroids of his body blue (#A8D0FB) in the two pictures, in a box 24 px around where the runtime draws
  his body (blank when one picture has fewer than 40 such pixels there, for example under a card or in the white
  keeper).
- To run it again:

  ```bash
  node tools/alive.mjs figma --all --out /tmp/figma
  node tools/figma-proof.mjs plan --manifest /tmp/figma/manifest.json --work /tmp/figma-proof
  ALIVE_FIGMA_PROOF=/tmp/figma-proof flutter test test/figma_proof_test.dart
  node tools/figma-proof.mjs report --work /tmp/figma-proof --md docs/figma-proof.md
  ```

## Against the MP4 exports in the cache

<!-- proof:start -->
41 moments measured against Figma's MP4 exports, 6 instants each (246 frames): on average 0.8% of the picture differs visibly (0.7% leaving out the exports older than their frame). The procedural import measured 1.3% on the same moments and instants.

| Moment | Scene / clip | Differs (average) | Differs (worst instant) | Fabio offset | Procedural import (average) | Note |
|---|---|---|---|---|---|---|
| Tap Record | sys3-tap-record / sys3-tap-record | 1.2% | 1.6% | 3.1 px | 1.0% |  |
| Slider carry V1 | slider-carry / v1 | 0.4% | 0.4% |  | 3.4% |  |
| Slider carry V2 | slider-carry / v2 | 0.4% | 0.5% |  | 3.8% |  |
| Slider carry V3 | slider-carry / v3 | 0.3% | 0.4% |  | 3.5% |  |
| Turn | sys3-turn / sys3-turn | 0.6% | 0.6% | 0.2 px | 0.6% |  |
| Low battery arrives | sys3-arrives / sys3-arrives | 1.4% | 1.5% | 3.2 px | 1.1% |  |
| Halfway Express | enc-express / enc-express | 0.4% | 0.5% | 0.6 px | 1.5% |  |
| Halfway bar | enc-bar / enc-bar | 0.2% | 0.2% | 0.3 px | 0.2% |  |
| Last question | enc-last / enc-last | 0.4% | 0.4% |  | 0.4% |  |
| Completion | enc-done / enc-done | 0.2% | 0.3% | 0.3 px | 1.0% |  |
| Slider motion | qt-slider / qt-slider | 0.3% | 0.3% |  | 0.2% |  |
| Text motion | qt-text / qt-text | 0.3% | 0.3% |  | 0.5% |  |
| Pick motion | qt-pick / qt-pick | 0.9% | 1.4% |  | 0.9% |  |
| Record | rec-record / rec-record | 1.4% | 1.4% | 0.6 px | 2.2% |  |
| Recording | rec-recording / rec-recording | 1.3% | 1.3% |  | 1.6% |  |
| One minute left | rec-one-minute / rec-one-minute | 1.2% | 1.3% |  | 1.6% |  |
| Stop | rec-stop / rec-stop | 1.0% | 1.2% |  | 1.1% |  |
| Return | rescue-return / rescue-return | 3.4% | 11.6% | 2 px | 3.6% | export older than the frame |
| Replay and carry on | rescue-replay / rescue-replay | 1.2% | 1.4% |  | 2.2% |  |
| History peek | storage-peek / storage-peek | 0.2% | 0.3% | 1.3 px | 0.3% |  |
| Storage heads-up | storage-heads-up / storage-heads-up | 0.7% | 0.7% | 8.3 px | 0.7% |  |
| Last resort confirm | storage-confirm / storage-confirm | 0.2% | 0.4% | 0.9 px | 0.2% |  |
| Sending | storage-sending / storage-sending | 0.3% | 0.5% | 0.1 px | 0.7% |  |
| Tips open | storage-tips / storage-tips | 1.4% | 2.4% |  | 1.1% |  |
| Space back | storage-space-back / storage-space-back | 0.5% | 0.6% |  | 0.6% |  |
| Battery moment | warn-battery / warn-battery | 2.6% | 2.7% |  | 3.0% |  |
| Mic moment | warn-mic / warn-mic | 0.8% | 1.0% |  | 1.2% |  |
| Battery moment, Recording page | warn-battery-rec / warn-battery-rec | 2.5% | 2.6% |  | 3.1% |  |
| Mic moment, Recording page | warn-mic-rec / warn-mic-rec | 1.5% | 1.6% |  | 2.0% |  |
| Breathing timer | media-breathing / media-breathing | 0.9% | 0.9% | 0.4 px | 1.8% |  |
| Photo print | media-print / media-print | 0.9% | 0.9% | 0.4 px | 0.9% |  |
| Instructions letter | media-letter / media-letter | 0.3% | 0.3% | 0.5 px | 0.6% |  |
| Survey stamped | media-stamped / media-stamped | 0.7% | 0.7% | 1.6 px | 1.1% |  |
| Researcher clip | media-clip / media-clip | 0.5% | 0.6% | 0.3 px | 0.5% |  |
| Reaction pop | media-pop / media-pop | 0.2% | 0.2% | 0.1 px | 0.2% |  |
| No internet V1 | survey-no-internet / v1 | 0.3% | 1.1% | 0.3 px | 0.3% |  |
| No internet V2 | survey-no-internet / v2 | 0.3% | 1.1% |  | 0.3% |  |
| No internet V3 | survey-no-internet / v3 | 0.3% | 1.1% |  | 0.4% |  |
| System v2: recording, live | sys2-recording / sys2-recording | 0.6% | 0.6% | 0.6 px | 1.0% |  |
| System v2: slider | sys2-slider / sys2-slider | 0.3% | 0.4% | 0.7 px | 0.7% |  |
| System v2: state glow | sys2-state-glow / sys2-state-glow | 0.7% | 1.0% | 0.6 px | 1.1% |  |
<!-- proof:end -->

## Against fresh exports (22 Oct)

Where an MP4 is older than its frame, a fresh export (`export_video`, 24 fps, low quality, nothing in the file
changed) was measured too. The recording frames' MP4s were rendered at 00:17 on 6 Oct; the SVG exports at 00:59 the
same night already have sleeves on the host cardigan, and a screenshot of the frame taken today has them too, so the
MP4s show an older cardigan. Return's MP4 predates the recorder's rise (the procedural import noted it). The two
Battery frames and both Mic moment frames are no longer in the Figma file (export_video: not found), so they could not
be exported again. The procedural import's column below is its number against the old MP4s.

<!-- fresh:start -->
8 moments measured against fresh Figma MP4 exports (export_video), 6 instants each (48 frames): on average 0.9% of the picture differs visibly. The procedural import measured 1.7% on the same moments and instants.

| Moment | Scene / clip | Differs (average) | Differs (worst instant) | Fabio offset | Procedural import (average) | Note |
|---|---|---|---|---|---|---|
| Tap Record | sys3-tap-record / sys3-tap-record | 0.9% | 1.4% | 0.2 px | 1.0% |  |
| Low battery arrives | sys3-arrives / sys3-arrives | 1.1% | 1.2% | 0.3 px | 1.1% |  |
| Record | rec-record / rec-record | 0.8% | 0.9% | 0.6 px | 2.2% |  |
| Recording | rec-recording / rec-recording | 0.7% | 0.8% |  | 1.6% |  |
| One minute left | rec-one-minute / rec-one-minute | 0.8% | 0.8% |  | 1.6% |  |
| Stop | rec-stop / rec-stop | 0.5% | 0.7% |  | 1.1% |  |
| Return | rescue-return / rescue-return | 0.9% | 1.3% | 1.3 px | 3.6% |  |
| Tips open | storage-tips / storage-tips | 1.4% | 2.3% |  | 1.1% |  |
<!-- fresh:end -->

The fresh exports were not kept in the repository (they are 0.4 to 1.1 MB each). To measure them again, export each
frame with `export_video` (on the design file, by its key; 24 fps, quality low) into one folder as `<moment>.mp4`:
sys3-tap-record, sys3-arrives, rec-record, rec-recording, rec-one-minute, rec-stop, rescue-return and storage-tips
(each moment's frame is in `tools/figma/cache/moments.json`); then
`node tools/figma-proof.mjs plan --manifest <out>/manifest.json --work <dir> --mp4-dir <that folder>` and the same two
steps as above (`--marker fresh` for this table).

Tips open stays at 1.4% against its fresh export: what differs there is drawing, not age (the lamp's glow, the shelf's
shadow and a dashed tag: blur and shadow filters as Flutter draws them, see `limits.md`).

## Why a moment differs

| Moment | Average | Cause |
|---|---|---|
| Return | 3.4% (0.9% fresh) | the cached MP4 predates the frame (the recorder's rise moved) |
| Battery moment, and on the Recording page | 2.6%, 2.5% | the cached MP4's power strip predates the frame; the frames are no longer in Figma, so no fresh export |
| Record, Recording, One minute left, Stop | 1.4%, 1.3%, 1.2%, 1.0% (0.8, 0.7, 0.8, 0.5% fresh) | the cached MP4s predate the cardigan's sleeves |
| Tap Record, Low battery arrives | 1.2%, 1.4% (0.9, 1.1% fresh) | the same cardigan; the rest is text and shadow edges |
| Mic moment on the Recording page | 1.5% | the frame is no longer in Figma; its cached MP4 shows the older cardigan |
| Tips open | 1.4% (1.4% fresh) | blur and shadow filters as Flutter draws them |
| Everything else | 0.2% to 0.9% | edges of text and shapes (anti-aliasing), small filter differences |

## The art rules on the converted moments

`alive figma` runs `alive lint` on every scene it writes. The rules read the kit itself (the converter records which
layer is which kit part, `meta.figma`): a pointing paw is a hand whose kit pose says Point, a holding paw is
Pose=Hold, and distances are in kit units at that Fabio's own scale. 26 of the 37 scenes have no finding. No moment
has a pointing paw. The findings are the Figma frames of 6 Oct as designed, before the 20 Oct rules (M3 paws, the
object comes to him):

| Scene | Errors | Warnings | Findings |
|---|---|---|---|
| enc-done (Completion) | 2 | 0 | both holding paws travel 84.4 kit units with the flag he plants (limit 50) |
| storage-space-back (Space back) | 2 | 1 | both holding paws travel 55.0 kit units at 1.2 s; the left one 39.6 outside his body |
| rec-one-minute (One minute left) | 1 | 1 | the paw that brings the cue card travels 112.6 kit units and is 81.0 outside his body at 0.43 s |
| rec-record (Record) | 0 | 1 | the pressing paw is 57.1 kit units outside his body at 0.37 s |
| qt-text, qt-pick, sys3-turn, survey-no-internet (V3), sys2-recording, sys2-slider, sys2-state-glow | 0 | 1 or 2 | Grip edge paws (the kit's gripping paw, not the M3 paw) |

## What does not convert, and why

| Dumps under `<boards>/motion` | Why |
|---|---|
| `warnings/r4-*`, `r5-*`, `r6-*`, `r11-*` (36) | board page samples (HTML), not Figma Motion frames; the board pages come in through `alive html`, their engine exports through `alive upgrade` (the app's warning scenes do) |
| `recording-rescue/rescue-r4.keyframes.json`, `r3/rescue-r3.keyframes.json` | rounds 3 and 4 were made in HTML and rendered to MP4; there is no Figma frame |
| `recording-rescue/r1/return-r1`, `carry-on-r1` | early frames, replaced in Figma by Return and Replay and carry on (both converted) |
| `survey-errors/` the return, permission error, skipped and back, page not found, taking too long, server error | their frames are no longer in Figma (the Survey page was rebuilt with No internet V1 to V3 only, converted); the app's survey errors come from the webview-errors board page |
| `cast/actions.json`, `cast/outfits-motion.json` | made in HTML; no Figma frame |
| Live Activity v2 and v3 frames | never read into the cache (and native, out of the app's scope) |

The command says so for each: a board page dump is refused with the pointer to `alive html`, and a dump that names
no frame the cache has a read for is refused with what to do.

Converted but no longer in Figma (from the 6 Oct read and export, which cannot be refreshed): Battery moment,
Battery moment on the Recording page, Mic moment, Mic moment on the Recording page.
