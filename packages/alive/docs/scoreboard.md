# Scoreboard

The engine's performance goals: each with today's measured baseline, a target, how it is measured, and the result
after the work, measured the same way. When a goal is met it is raised or the next one is added, with the date and
time. Numbers are measured or marked "not measured"; what got worse is listed with each result.

Machines and methods: the test machine (M2 Pro, 16 GB, paging: swap free is logged with every run), `flutter test` in
debug (JIT). The app integration's simulator harness is the device-side check; its
numbers are quoted with its date, never mixed with these.

## Methods

| Id | Method | Command |
|---|---|---|
| OPEN | Page opening: a question page pushed with an iOS transition on an iPhone 17 Pro Max window (440 x 956 at 3x), his controller made in initState and his stage in the page (on), the same page with an empty box (off), or on with the scene preloaded on the page before (preload). The engine's own frame timings (FrameTiming, as the app's PERF_LOG): per entry, the frames from the push to 1.4 s after it. Slow = build or raster over 16.7 ms (the app's rule). Late = the frame began over 16.7 ms after its vsync (the UI thread was busy elsewhere, e.g. loading). Over 8.3 = build or lateness over 8.3 ms (a 120 Hz screen's budget). Nine entries in tour order, from the app's own scenes (`<app>/assets/alive`, read only); one process per mode and run, alternated, 3 runs per mode, counts pooled over the runs. Raster in flutter test has no screen behind it (under 0.2 ms every frame): it is not a raster measurement. | `node tools/bench-open.mjs --modes on,off,preload --runs 3 --scenes <app>/assets/alive` |
| COST | What each scene costs: load phases (decode, parse, prepare, first paint) p50 of 5 after a warm-up; the Dart heap held on screen after a full GC (VM service), median of 3; after release; native picture bytes; files raw and gzipped. All 46 app scenes. | `ALIVE_SCENES=<app>/assets/alive flutter test --enable-vmservice benchmark/scene_cost_test.dart` |
| PAINT | Frame work and load against the old fabio_plus path (the 22 Oct benchmark). | `flutter test --enable-vmservice benchmark/paint_benchmark_test.dart` |
| OPEN-CPU | His share of a page's opening frames as UI-thread work: the same question page pushed without him (off), with his scene preloaded and painted from the second frame (preload) or in the first (preload-now), and loading as it opens (on, a memory library: the decode runs in the push frame, unlike the assets library); the wall time of each of the first six frames, median of 15 openings after a warm-up, modes alternated. Fake-async widget test: steadier under the laptop's load than counting slow frames. | `ALIVE_SCENES=<app>/assets/alive flutter test benchmark/open_cpu_test.dart` |
| SUITE | Flutter tests, CLI tests, corpus parity (71 board exports, 213 frames), kit-qa, analyze. | `tools/ci.sh` (from milestone 1; before it, each command by hand) |
| OPEN-2 | OPEN made steadier on a busy laptop (from 23 Oct): each round runs every mode once and the control twice (off and off-b, the same page without him), the order rotated by one place a round; 5 rounds; every run records the load average and swap free at its start and end, and waits up to 180 s for the 1-minute load to come under 6 (a run that could not is flagged); per entry and mode, each run's slow + late and over 8.3 counts as the median and range over the runs, beside the pooled counts. Noise floor: off against off-b; a difference between modes no larger than it is not shown by the run. | `node tools/bench-open.mjs --modes on,off,preload --runs 5 --scenes <app>/assets/alive` |
| COST-2 | COST with the heap reading made steadier (from 23 Oct 17:08): four rounds a scene, the first a warm-up not counted (its "before" still held the load loop's garbage: it read 0.1 to 2 MB low on every scene), held = the lowest of the other three (a higher round also holds code the VM compiled during it; the spread is kept per scene); each reading the lower of two full collections. Files: the folder's sum, each JSON file gzipped by dart:io. | `ALIVE_SCENES=... flutter test --enable-vmservice benchmark/scene_cost_test.dart` |
| HEAP | What a scene's held heap is made of: the scene loaded ten times over (a cache, a player and 30 drawn frames each), live bytes by class after full collections before and after, per copy; "data" leaves out the VM's objects for compiled code. | `ALIVE_SCENES=... ALIVE_SCENE=recording flutter test --enable-vmservice benchmark/heap_classes_test.dart` |
| OPEN-CPU-2 | OPEN-CPU paired (from 23 Oct): every rep opens the page once per mode, in an order shuffled a rep (seeded; a fixed rotation kept the same mode before each mode, and what ran before an opening moves its first frame); his added work per frame is the median over the reps of each rep's difference to that rep's control opening; the control runs twice a rep (off, off-b) and their paired difference is the noise floor; mode preload-ctl makes his controller from the preload with no stage on the page. | `ALIVE_SCENES=... OPEN_CPU_MODES=off,preload-ctl,preload,preload-now flutter test benchmark/open_cpu_test.dart` |

## Goals

### P1. Page opening: no more slow frames with him than without him

Baseline 23 Oct 13:25 (OPEN, files `benchmark/out/open-baseline-2026-10-23/`, swap free 0.42 to 1.62 GB). "preload"
here is what the API allowed before this work: `AliveCache.shared.acquire` on the page before, held.

| Entry | slow + late on / off / preload | over 8.3 ms on / off / preload | build max ms on / off / preload | late max ms on / off / preload |
|---|---|---|---|---|
| recording/greet (first: pays the JIT) | 1+3 / 0+0 / 0+0 | 8 / 3 / 8 | 32.5 / 12.7 / 16.0 | 62.0 / 7.5 / 9.4 |
| qt_one/peek | 0 / 0 / 0 | 4 / 2 / 3 | 11.9 / 10.4 / 11.5 | 9.0 / 7.5 / 6.5 |
| qt_slider/grab | 0 / 0 / 1+0 | 4 / 0 / 3 | 15.3 / 8.3 / 20.6 | 6.2 / 6.9 / 8.0 |
| qt_text/open | 0 / 0 / 1+0 | 2 / 3 / 2 | 14.6 / 10.4 / 35.9 | 6.4 / 7.0 / 6.9 |
| hx_v1/arrive | 0+1 / 0 / 0 | 5 / 3 / 4 | 11.1 / 11.9 / 15.3 | 33.1 / 7.4 / 7.4 |
| wv_server_v1/flow | 1+0 / 0 / 0 | 4 / 2 / 4 | 19.1 / 14.2 / 11.9 | 6.8 / 6.4 / 10.1 |
| ws_mic/flow | 1+0 / 0 / 0 | 4 / 2 / 3 | 30.4 / 9.2 / 8.8 | 9.4 / 7.1 / 9.3 |
| phone_almost_full/flow | 0 / 0 / 0 | 4 / 1 / 2 | 10.7 / 10.9 / 11.5 | 9.0 / 7.5 / 7.0 |
| st_keeper/onShelf | 1+0 / 0+1 / 0+4 | 2 / 2 / 12 | 18.6 / 9.6 / 12.8 | 8.0 / 27.7 / 33.4 |
| all nine | 4+4 / 0+1 / 2+4 | 37 / 18 / 41 | | |

The page below while the old-style preload ran: up to 47.6 ms late (the load ran on the UI thread there instead).
Where the extra frames sit: the stage's first paint (8 to 36 ms build, frame 1 or 2 after the push), and the load
itself as late frames (33 to 62 ms, 50 to 190 ms after the push, recording and the Halfway Express). The
st_keeper lateness at 0.6 to 1.3 s appears in off runs too (the laptop, not him).

Device side (the app integration, 22 Oct 15:29 to 16:00, simulator, debug, slow = build or raster over 16.7 ms, pooled over 3
runs): Halfway Express 21 vs 7, Tap Record 25 vs 12, Phone almost full 17 vs 6, Microphone off 8 vs 5, Text answer
18 vs 15; Storage page opening one 300 ms frame.

Targets, in order:
1. slow + late per entry, on and preload, no more than off + 1 (pooled over 3 runs). Baseline: misses on
   recording/greet (4 vs 0) and st_keeper preload (4 vs 1).
2. The page below a preload: no late frame over 16.7 ms.
3. over 8.3 ms per entry, preload no more than off + 1. Baseline: 7 of 9 entries miss.
4. Then: the app integration confirms on the simulator.

Result 23 Oct 14:11 (OPEN, `benchmark/out/open-m1b-2026-10-23.json`, swap free 1.03 to 1.33 GB): after decoding and
parsing off the UI thread (an isolate, with the path data read into commands there), preparing the art in 4 ms slices
after frames, drawing it once off screen when loaded, and `AliveController.preload`.

| Entry | slow + late on / off / preload | over 8.3 ms on / off / preload | build max ms on / off / preload | late max ms on / off / preload |
|---|---|---|---|---|
| recording/greet | 0+1 / 0 / 0 | 9 / 0 / 4 | 15.5 / 8.2 / 16.1 | 19.2 / 7.3 / 7.5 |
| qt_one/peek | 0 / 0 / 0 | 2 / 2 / 1 | 10.2 / 11.2 / 10.5 | 6.9 / 7.4 / 7.6 |
| qt_slider/grab | 0 / 0 / 0 | 1 / 1 / 4 | 8.5 / 12.3 / 14.4 | 7.2 / 6.7 / 7.5 |
| qt_text/open | 1+0 / 0 / 0 | 3 / 2 / 2 | 23.8 / 11.4 / 10.3 | 6.9 / 11.0 / 7.8 |
| hx_v1/arrive | 0 / 0+1 / 0 | 1 / 1 / 1 | 9.6 / 8.0 / 12.4 | 7.7 / 21.9 / 7.4 |
| wv_server_v1/flow | 0 / 0 / 0 | 2 / 2 / 1 | 9.9 / 11.8 / 13.8 | 7.4 / 7.0 / 8.3 |
| ws_mic/flow | 0 / 0 / 0 | 0 / 1 / 2 | 8.3 / 12.4 / 13.5 | 8.1 / 6.9 / 8.2 |
| phone_almost_full/flow | 0+1 / 0 / 0 | 3 / 1 / 3 | 8.4 / 11.8 / 9.1 | 26.1 / 7.7 / 7.7 |
| st_keeper/onShelf | 0 / 0 / 0 | 1 / 0 / 2 | 15.5 / 7.7 / 9.1 | 6.5 / 7.4 / 7.8 |
| all nine | 1+2 / 0+1 / 0+0 | 22 / 10 / 20 | | |

- Target 1 MET: every entry on and preload within off + 1 (on 3 in all, preload 0, off 1; baseline on 8, preload 6).
- Target 2 MET at 14:11: the page below a preload, late at most 15.6 ms (baseline 47.6 ms). Not held under the 15:55
  load: 2 of 18 preload runs went over (26.9 and 65.9 ms late; the other 16 at most 13 ms); re-measure on a quiet laptop.
- Target 3 NOT MET: over 8.3 ms, preload 20 against off 10; 4 entries over off + 1 (recording 4 vs 0, qt_slider 4
  vs 1, phone_almost_full 3 vs 1, st_keeper 2 vs 0). The VM timeline shows where: the push frame, the page's own
  build (8 to 12 ms in debug here, with him or without), plus about 1 to 3 ms of his (the controller and his first
  paint, measured warm in a widget test: 0.8 to 2.5 ms). Moving his first paint to the next frame (23 Oct 14:14) was
  measured in a second set (`open-m1c`) while another job used 90 % of a core and swap fell to 0.28 GB: off 11,
  preload 20, on 20; that set also had 86 ms frames on the page below, so it decides nothing either way.
- Worse: the on page's late max for recording is 19.2 ms (the first entry, the JIT compiling the engine's code); one
  late frame each on recording and phone_almost_full (on).
- Raster is not measured here (no screen behind flutter test).

New target (23 Oct 14:36): target 3 stays open; the app integration's simulator check (target 4) is next.

Re-measured 23 Oct 15:55 on the merged code (OPEN, four modes, `benchmark/out/open-m4-2026-10-23.json`; swap free 0.55
to 0.8 GB, a Python job at 75 to 95 % of a core, the media analysis service and Chrome running throughout; the
simulator had just stopped). preload-now: the stage paints a preloaded scene in the page's first frame
(`deferFirstPaint: false`).

| All nine entries, 3 runs each | slow + late | over 8.3 ms |
|---|---|---|
| without him (control) | 4 + 3 | 24 |
| with him | 5 + 0 | 36 |
| preloaded, painted from the second frame (the default) | 3 + 2 | 31 |
| preloaded, painted in the first frame | 5 + 3 | 22 |

Read with care: the control itself had 7 slow or late frames here against 1 at 14:11, so the laptop's load moves
these counts by more than the differences between modes. Per entry, with him and preloaded: within the control plus
one except recording (with him, 3 slow against 1: the first entry, compiling the engine's code; build max 54 ms) and
phone_almost_full preloaded (1 slow and 1 late against 0). The deferral is not shown to help or hurt by this set: it
stays the default (it can only move work out of the page's heaviest frame), with the option to paint at once.
Target 1 held at 14:11 and is not shown again under this load; target 2 neither (2 of 18 preload runs with a frame
of the page below over 16.7 ms late: 26.9 and 65.9 ms); target 3 is still open. A steadier measure of his
share of the opening frames (the CPU work, as medians over many openings) is next.

Steadier measure 23 Oct 16:00 (OPEN-CPU, `benchmark/out/open-cpu-2026-10-23.json`, swap free 1.5 GB): his added work
per frame of a preloaded page (preload minus off, ms, median of 15 openings) on the push frame and at most over the
first six frames:

| Entry | push frame, off | added: push, preload | added: worst frame, preload | added: push, preload-now |
|---|---|---|---|---|
| recording/greet | 9.0 | +0.23 | +0.72 | +1.69 |
| qt_one/peek | 6.7 | -0.28 | +0.29 | +1.30 |
| qt_slider/grab | 5.2 | +0.23 | +0.31 | +0.78 |
| qt_text/open | 4.4 | +0.77 | +0.77 | +0.96 |
| hx_v1/arrive | 3.9 | +1.17 | +1.17 | +1.43 |
| wv_server_v1/flow | 3.7 | +0.24 | +0.27 | +0.57 |
| ws_mic/flow | 3.6 | +0.40 | +0.40 | +1.49 |
| phone_almost_full/flow | 5.4 | -0.16 | +0.05 | -0.60 |
| st_keeper/onShelf | 4.9 | +1.34 | +1.34 | +0.76 |
| mean | | +0.44 | | +0.93 |

New target P1b (23 Oct 16:00): his added work in any of the first six frames of a preloaded page at most 1.5 ms: MET
(worst +1.34 ms, st_keeper). The deferral measured: the push frame +0.44 ms on average with it, +0.93 ms without, so
it stays the default. Next: at most 1.0 ms (hx_v1, st_keeper over; their controller costs 0.07 ms, so the rest is the
page's first build with the stage, not yet located).

The benchmark itself (goal: robust to a noisy laptop). OPEN-2 (`tools/bench-open.mjs`, Methods) run 23 Oct
19:04 to 19:29 on 0.6.0's code, `benchmark/out/open-r2-2026-10-23.json`, with `--runs 4 --max-load 10 --wait
60` (not the defaults of 5, 6 and 180: the laptop was not going to come under 6): 16 runs, the 1-minute load at their
starts 12.6 to 171.8 (median 23.5), all 16 started over 10 after waiting 60 s, swap free 343 to 993 MB. A first attempt
at 18:56 was thrown away: the stage's code was changed while it ran, and each run compiles the code it finds.

| All nine entries, per run: median (range) over 4 runs | slow + late | over 8.3 ms |
|---|---|---|
| without him (off) | 0 (0 to 2) | 5.5 (4 to 8) |
| without him again (off-b, the noise floor's twin) | 0.5 (0 to 5) | 8 (5 to 19) |
| with him | 2 (0 to 6) | 9.5 (2 to 30) |
| preloaded | 1.5 (0 to 4) | 12 (2 to 13) |

Noise floor (off against off-b): all nine per run, slow + late 0.5 and over 8.3 2.5; per entry at most 0.5 and 1.5.
Per entry (medians over the runs): with him and preloaded every entry at most 0.5 slow + late (off 0).

- Target 1 (slow + late per entry, on and preload no more than off + 1): MET by the per-run medians; the pooled
  counts the target was first written in (now over 4 runs) miss by one frame each on 4 entry and mode pairs (with him:
  recording, qt_slider, st_keeper; preloaded: phone_almost_full), inside what the control moves by against its own
  twin (recording: off 1 against off-b 2).
- Target 2 (the page below a preload: no frame over 16.7 ms late): NOT held: 4 of 9 entries had one frame 17.3 to
  23.9 ms late; the control's own opening frames were up to 22.5 ms late in this run, so it is not separated from the
  laptop.
- Target 3, 120 Hz in its relative form (over 8.3 per entry, preload no more than off + 1): 7 of 9 entries within it
  by the medians; ws_mic and phone_almost_full at off + 1.5, inside the per-entry floor (1.5): not shown either way.
  All nine together: preloaded 12 against off 5.5 and off-b 8 per run, more than the floor (2.5): preloaded openings
  do miss the 120 Hz budget more often than the control here.
- 120 Hz in its absolute form (no frame over 8.3 ms): not met and cannot be in this harness: the control alone has
  4 to 19 frames over 8.3 ms a run (the page's own build is 8 to 12 ms in debug JIT). It is a device question: asked of
  the app integration (release or profile build).
- The method: the control's twin is what made these readable; it differed from the control by up to 5 slow + late and
  15 over-8.3 frames in a single round (the first). Next target (19:30): runs at a load under 10 (or on the app integration's device), and
  the floor below the differences reported.

Device side, target 4 (the app integration, 23 Oct 16:50; simulator, debug, PERF_LOG, engine 0.5.0
with the preloads wired, 6 runs a side pooled; the app integration calls the runs noisy: load 5.9 to 18.3 on 10
cores): slow frames on / off: Tap Record 27 / 25, Halfway Express 23 / 9, Phone almost full with the Storage page
18 / 8, Microphone off 15 / 6, Text answer 20 / 22. The Storage page opening below its preload: 9 slow frames (a
300 ms build) on 22 Oct to 4 and 5 (builds of 56 and 91 ms). The preload path: the board ready 9 to 16 ms after the
push loaded ahead, 15 to 22 ms pushed. Still above the control there: the Halfway Express (slow builds of 17 to 31 ms
as the ticket rises while the next question slides in), Microphone off. Release, Android (17:45): +384 KB of AOT
code; total PSS median +5.5 MB on the tour.

23 Oct: target P1b at most 1.0 ms. First the method (OPEN-CPU-2: paired with the control's opening of the
same rep, the modes in a shuffled order a rep, the control run twice for a noise floor, 31 reps), then where his
part of a preloaded opening goes (`benchmark/open_parts_test.dart`: each of his steps timed on its own, 200 times
after 50 warm-up rounds).

Result 23 Oct 18:52 (OPEN-CPU-2, nine entries, the app's 46 scenes; files `benchmark/out/open-cpu-r2-*.json`): his
added work in the worst of the first six frames of a preloaded page, against the noise floor of the same run.

| Run | Load (1 min) | Worst added | Every other entry | Floor (control against its twin) |
|---|---|---|---|---|
| a, 18:22, unpacked scenes | 60 to 63 | 1.02 ms (recording, push frame) | at most 0.61 ms | 0.22 ms |
| b, 18:51, unpacked | about 18 | 0.98 ms (recording, push frame) | at most 0.62 ms | 0.53 ms |
| c, 18:52, packed (0.6.0) | 17 to 22 | 1.96 ms (qt_one) | recording 1.52, the rest at most 0.76 | 0.42 ms |
| d, 18:52, packed (0.6.0) | 20 to 22 | 0.70 ms (wv_server_v1) | at most 0.68 ms | 0.26 ms |
| gc, 18:46, unpacked, the heap collected before every push | 10 to 18 | 0.91 ms (phone_almost_full) | at most 0.49 ms | 1.13 ms |

- Target NOT MET, or rather not shown: the worst frame moves between 0.70 and 1.96 ms from run to run on the same
  code, more than the target's margin, and a run's own floor is 0.2 to 1.1 ms. In the two unpacked runs every entry
  but the first (recording/greet, which also pays for the JIT) is at most 0.62 ms. At 16:00 (the old method) the worst
  was 1.34 ms (st_keeper); st_keeper's worst frame is now 0.28 to 0.51 ms over the five runs.
- Located (open_parts, `benchmark/out/open-parts-r2-2026-10-23.json`): his own steps in a preloaded opening, warm,
  are small: making the controller from the preload 0.012 to 0.027 ms, playing the clip 0.005 to 0.008 ms, an
  evaluation 0.002 ms at most, his first paint 0.004 to 0.043 ms (hx_v1 the largest); 0.02 to 0.08 ms a page in all.
- So the push frame's excess is not his code. With the heap collected just before each push, the push frame's added
  work goes (recording 0.98 to -0.24 ms, hx_v1 0.62 to -0.13): it is the collection of the garbage the preload made a
  moment before, which this benchmark makes just before the push (the app preloads a page earlier). What stays is the
  stage's first frame (the frame after the push): +0.3 to +0.6 ms with the collection (recording 0.42, hx_v1 0.39,
  st_keeper 0.29), the framework building his stage's widgets, render objects and layer; his paint in it is 0.04 ms.
- Next target (23 Oct 18:55): P1b read as the median over five runs (one run cannot separate it), and the stage's
  first frame under 0.25 ms.
- The stage's first frame on its own (`benchmark/stage_frame_test.dart`, 19:29, load about 30, 150 reps): the frame
  that builds his stage against the same frame with an empty box, added 0.53, 0.44 and 0.39 ms by the medians
  (recording, hx_v1, st_keeper), 0.32, 0.32 and 0.21 ms by the minimums. Tried: one render object in place of the
  stage's LayoutBuilder (no build during layout, one render object fewer): 0.26, 0.28 and 0.21 ms by the minimums, the
  medians worse on two of the three; not separated from the noise, so not merged (the change is not in the code).

### P2. Per-scene heap and gzipped size

Baseline 23 Oct 13:27 (COST, `benchmark/out/scenes-baseline-2026-10-23.json`, swap free 1.07 GB): 46 scenes, Dart
heap held on screen median 195 KB, max 1,039 KB (recording), sum 10.6 MB; after release at most 10 KB; native
pictures 669 KB summed (max 68 KB, hx_v2); files 4.65 MB raw, 1,060 KB gzipped (per file, as the app bundle
compresses them). Measured duplication (23 Oct 13:20, read only, python over the 94 files): 2.14 MB of the 3.66 MB of
art JSON sits in subtrees that another scene also has (0.99 MB of them distinct); a shared art library per app would
make the art 630 KB gzipped instead of 828 KB (estimate from re-serialising, not built).

Targets: heap held median and max halved (under 98 KB and 520 KB); gzipped total under 850 KB (-20 %) with the
pixels unchanged (corpus parity 0 %, goldens unchanged).

Result 23 Oct 14:22 (COST, `benchmark/out/scenes-m1-2026-10-23.json`, swap free 0.29 GB): a loaded scene lets go of
its parsed art trees once prepared (static art is in pictures; the compiled groups keep only what drawing needs).
Heap held median 74 KB (target 98: MET, -62 %), max 708 KB (target 520: NOT MET, -32 %, recording), sum 4.7 MB
(-55 %); after release at most 15 KB; load median 1.56 ms (unchanged), pictures unchanged; the same pixels (test:
released trees draw the same, 0 pixels differ). Gzipped size unchanged (1,060 KB): not worked on yet.
Worse: nothing measured; `AliveSceneData.arts` of a cached scene now hold headers only (tools pass
`AliveCache(keepArtTrees: true)`).

New target (23 Oct 14:36): max heap under 520 KB (what holds recording's 708 KB: its 18 clips' tracks, not measured
yet); gzipped under 850 KB.

Result 23 Oct 15:17 (COST on the app's folder packed with `alive pack --share`, `benchmark/out/scenes-packed-share-2026-
10-23.json`, swap free 1.21 GB): the folder 4.65 MB raw and 1,060 KB gzipped to 2.70 MB raw and 705 KB gzipped (-33 %:
target 850 KB MET), 28 shared fragments; the same pixels (`test/pack_parity_test.dart`: 0 of 459 frames with a pixel
over 40 of 255, the largest channel difference 36). How: numbers rounded (paths to 5 decimals: 3 or 4 decimals moved
one anti-aliased pixel by 43 on a near-degenerate shape of ws_mic_android, so paths keep 5), then subtrees two scenes
draw the same written once. Rounding alone: -14 %. Worse: heap held median 74 to 79 KB and recording 708 to 735 KB in
this run (en_halfway_b, the first scene of the run, 37 to 102 KB: it pays for compiling the splice), not investigated
beyond that; 28 more files in the bundle.

New target (23 Oct 15:19): gzipped under 600 KB (sharing inside a fragment, scene.json tracks); max heap under 520 KB.

Result 23 Oct 15:39 (COST, `benchmark/out/scenes-m3b-2026-10-23.json`, the unpacked folder): tracks keep only what
they need (no ease list when every segment is linear: all 8,223 keys of the recording scene are; only a layer's keyed
properties instead of a slot for each of 15; a clip's key numbers in one buffer instead of two lists per track). Heap
held: median 74 to 58 KB, largest 708 to 503 KB (recording; target 520 MET), sum 4.7 to 3.8 MB. Load: 103.7 against
103.8 ms for all 46 scenes, back to back with the code before (unchanged). The same pixels and values (the parity
tests). Worse: `Track.times`, `values` and `eases` and `LayerTracks.byProp` are now built when read (views and lists
for tools), not stored.

New target (23 Oct 15:39): heap held largest under 400 KB; gzipped under 600 KB.

Result 23 Oct 15:47 (COST, `benchmark/out/scenes-m3c-2026-10-23.json`, the simulator and another job running): a
track keeps its values in the clip's buffer beside its times and no sampling scratch of its own (80 bytes instead of
96), a layer's tracks are a range of the clip's one list. Heap held: largest 503 to 443 KB, median 58 to 55 KB, sum
3.8 to 3.6 MB. Target 400 NOT MET: what is left in the recording scene (2,063 tracks, 8,223 keys) is the Track objects
(161 KB, measured by class over ten parses) and the keys themselves (135 KB, 16 bytes a key in double precision, which
the 1e-9 parity checks hold to). Next step if it is worth it: a clip's tracks as arrays instead of objects.
Load: 111 ms for all 46 (103.7 before, on a quieter machine): not separated from the load on the laptop.

Check 23 Oct 15:40 (PAINT, `benchmark/out/paint-2026-10-23T1540.json`, against the 22 Oct numbers): frame work p50 /
p90 / p99, recording 34 / 50 / 93 us (22 Oct: 34 / 52 / 101), Phone almost full 14 / 19 / 41 us (15 / 23 / 60); heap
on screen, recording +0.76 and +0.81 MB (22 Oct +0.91 to +0.96); load and first paint p50, recording 12.8 ms (12.7);
the old path's numbers in the same run as before. Every budget of docs/performance.md held.

From 23 Oct 16:12. Before, measured again in the same session on main's
code: heap held median 55.4 KB, largest 443.2 KB (COST, each reading the lower of two collections, 16:45,
`benchmark/out/scenes-r2-before-b-2026-10-23.json`); gzipped 705 KB (the folder packed by 0.5.0's `alive pack --share`,
dart:io gzip per file: 705,486 bytes).

Result 23 Oct 17:16, heap (COST-2, back to back with the code before, `benchmark/out/scenes-r2-before-2026-10-23.json`
from 0.5.0 and `benchmark/out/scenes-r2-after-2026-10-23.json`; load 8 to 25): a clip's keys are plain typed
arrays (one buffer of numbers, five ints a track, a segment hint per track; no `Track` object per track), and tracks
whose keys fall at the same times share one list of times (the recording scene: 8,223 key times, 2,019 distinct).

| | before | after |
|---|---|---|
| heap held, largest (recording) | 441.0 KB | 230.4 KB |
| heap held, median of the 46 | 54.7 KB | 46.5 KB |
| heap held, sum | 3,416 KB | 2,644 KB |
| after release, largest | 16.4 KB | 27.8 KB |
| load, median and sum of the 46 | 1.61 ms, 95.2 ms | 1.59 ms, 93.3 ms |

- Target (largest under 400 KB) MET. The steps on their own (COST, each reading the lower of two collections, 16:45
  to 17:06: `scenes-r2-before-b`, `-arrays-b`, `-times`): 443 to 271 KB with the arrays, 271 to 230 KB with the
  shared times.
- Read with care: the three rounds of one scene spread by up to 120 KB on the recording scene (72 KB after) and by
  over 300 KB on hx_v2, whose lowest round (113.5 before, 69.7 after) sits far under its others: the reading still has
  noise in both directions (garbage not yet collected in a round's "before" lowers it; code compiled during a round
  raises it). The class count is the steadier view of the recording scene: (HEAP, ten copies, data classes only)
  596.7 to 390.9 KB a copy: the 2,063 `Track` objects (161 KB) and 646 `LayerTracks` (30 KB) gone, key numbers 146
  to 97 KB, track rows and hints 55 KB new (`benchmark/out/heap-classes-recording-r2-before.json`, `-after.json`).
  The two methods do not agree on the level (the class count is higher; not explained yet), only on the drop (about
  200 KB on the recording scene).
- Worse: "after release" largest 16.4 to 27.8 KB (one scene's reading; it was 13 to 15 KB in the three runs before and
  is not separated from the reading's noise). Load is unchanged within the laptop's noise (it was loaded throughout).
- `ClipDef.tracks` is now a getter that builds views of the arrays on each call (reading it is unchanged).

Result 23 Oct 17:14, gzipped size (the folder sum of COST: every JSON file gzipped on its own by dart:io; the app's 46
scenes packed with `alive pack --share`; pixels by `test/pack_parity_test.dart`, every clip of every scene at three
instants, 459 frames):

| Pack | gzipped | pixels against the unpacked folder | against 0.5.0's pack |
|---|---|---|---|
| 0.5.0 (before) | 705,486 B | 0 frames with a pixel over 40, largest channel difference 36 | |
| + path data written short, `source` notes left out | 524,279 B | the same (36) | identical (largest difference 0) |
| + compact keys (`{"dt", "v"}`, needs engine 0.6.0) | 469,450 B | the same (36) | identical (largest difference 0) |

- Target (under 600 KB) MET: 705 to 469 KB (-33 %); 1,060 KB unpacked. Short paths: each segment in the shorter of
  its absolute and relative forms from the same rounded points, H and V for lines along an axis, a command letter
  only where it changes (art and shared fragments 463 to 301 KB). Compact keys: a linear track as the steps between
  its key times and its values in one list (scene files 223 to 168 KB).
- Measured and not built: dropping keys that lie on the line between their neighbours (within 0.01 units, 0.01
  degrees, 1e-4 in scale, 1/1024 in opacity) would remove 716 of the 61,634 keys (1.2 %): the exporters already
  simplified them. Sharing smaller subtrees (`--min 400` instead of 4000) was worth 3 % before the short paths; not
  measured after.
- Worse: a scene packed with compact keys needs engine 0.6.0 (it is stamped `"requires": "0.6.0"`; an older engine
  refuses it with a message that says so); `alive pack --keys list` keeps 0.5.0's key lists (524 KB).

### C1 to C5. Capability

| Goal | Baseline (23 Oct) | Target |
|---|---|---|
| C1 eye-look channel | none: the app's text answer notes "his eyes do not follow the caret (the scene has no look channel yet)" | a `look` input moves named eye layers toward a target point within limits, tested, documented, one scene using it. DONE 23 Oct 15:05: `live.gaze` + `controller.lookAt`/`lookAtLocal` (layers toward the point, kit eyes to the nearest of eight look parts), fixed-step (30, 60, 120 Hz equal), tested (test/gaze_blink_test.dart); on the app's qt_text in flutter test the face moves toward the point; the app wiring is asked of the app integration |
| C2 blink on split faces | `live.blink` does not reach kit face features (docs/limits.md) | a kit figure blinks through its eyes feature, tested. DONE 23 Oct 15:05: `live.blink.figure` (half, closed, half through the pack's blink parts; wide eyes the wide ones; only eyes tagged `pill`/`pill-wide`), tested; the tags are asked of the kit artwork |
| C3 hem swing | the outfit tilts only: no skew property | a skew property (`kx`, `ky`) in the schema, runtime, CLI validate and the worn physics for garments; old scenes unchanged. PART DONE 23 Oct 14:35 as R2: hem slots (clip, ripple from the spring's energy, shear by its lag), tested at 60 and 120 Hz; the generic `kx`/`ky` layer properties DONE 23 Oct 15:05 (tested against a reference polygon) |
| C4 two-handed carry | the kit has no far paw in front | slots and z order ready; the part itself is the kit artwork's (requested). DONE 23 Oct 14:35 as R1: `zFront`, parts tagged `front` (the asset's `hand-carry-front-far-*`), tested (draw order), CLI compose |
| C5 spring easing | springs read but never measured | sampled against a closed-form damped oscillator (and Figma's export if one with a spring appears). DONE 23 Oct 15:05: the closed form within 1e-6 of an RK4 integration (under, critical, over damped; test/spring_test.dart); lint `spring-cut` when a key's span is shorter than its spring settles (Figma presets 0.48 to 0.92 s). No Figma export with a spring exists to compare |
| C6 trimmed strokes (asked by DM) | dropped by `upgrade` with a note; boards rebuilt rings from segments | DONE 23 Oct 15:05: `trimStart`/`trimEnd` on a layer, from SVG's start point; within 0.4 % of reference arcs and lines; `upgrade` keeps board trims (`--no-trims` for the corpus parity) |

### M1 to M3. Modularity

| Goal | Baseline (23 Oct) | Target |
|---|---|---|
| M1 optional features in separate imports | one library `package:alive/alive.dart` exports everything (kit, runtime, schema) | `alive_core.dart` (play scenes), `alive_kit.dart`, physics and authoring split; an app that only plays scenes compiles less (measured with `dart compile` where possible). PART DONE 23 Oct 15:28: `alive_core`, `alive_kit`, `alive_tools` (alive.dart exports all three, unchanged). Not measured: the code size an app pays (no app build here; a release build tree-shakes by use anyway, and the kit loader stays reachable while scenes may name figures) |
| M2 plugin hook | none | a registered channel or node type drawn without touching the engine, tested. DONE 23 Oct 15:28: plugin nodes (`AliveExtensions`, `AlivePlugin`, `AliveFrame`), tested (test/plugin_test.dart: drawn in its box, moved with its layer, reading the mic input; unregistered kinds reported) |
| M3 extension API | not documented | docs/extending.md, every public member documented (analyzer clean). DONE 23 Oct 15:28: docs/extending.md (imports, plugins, fonts, live behaviours, kits, shipping, stability); analyze clean with public_member_api_docs |

### R1 to R4. Production

| Goal | Baseline (23 Oct) | Target |
|---|---|---|
| R1 API stability | 0.4.0, no deprecation policy | semver policy, deprecations with shims, an API snapshot test. DONE 23 Oct 15:28: the policy in docs/extending.md; docs/api.txt (569 lines: every public class, constructor, field, getter, method with parameters) checked by `node tools/api.mjs --check` in tools/ci.sh |
| R2 release-mode benchmark | none (flutter test is JIT only; no xcodebuild here) | AOT numbers for the pure Dart phases (decode, parse, evaluate) via `dart compile exe`, as a target. DONE 23 Oct 15:22: `benchmark/parse_aot.dart` (decode, parse and path commands: what the isolate does), AOT on the test machine over the app's 46 scenes: median 1.03 ms, max 4.6 ms (hx_v1), sum 55 ms; JIT after warm-up 0.94 / 4.6 ms (the JIT catches up on this hot loop). Target kept: median under 1.5 ms, max under 6 ms. Evaluate and paint need dart:ui, so they have no AOT number here |
| R3 one-command CI | each suite by hand (477 Flutter tests in 15.5 s, 51 CLI tests in 1.7 s, corpus parity 7.5 s, kit-qa needs Chrome) | `tools/ci.sh` runs all, checks swap before the Chrome step. DONE 23 Oct 14:41 (analyze, Flutter, CLI, corpus parity, kit-qa gated, exit 2 when a step cannot run); since then also pack parity and the API check; about 90 s in all |
| R4 docs kept honest | | every scoreboard result reflected in performance.md and limits.md |
| R5 the cache's memory-pressure listener | a cache that had preloaded kept its listener on the binding for good (16:08), so the binding held the cache | removed when the last preload goes, `AliveCache.dispose()`, a test. DONE 23 Oct 16:23: removed when the last preload is taken over, runs out, is released (by hand or by memory pressure) or fails, added again by the next preload; `dispose()` lets go of the preloads and the listener and refuses new loads (screens keep their scenes); `AliveCache.shared` cannot be disposed; `watchesMemoryPressure`, `isDisposed`; test/loader_test.dart. Swept: the only binding observer in the package (the controller's lifecycle listener is disposed with it) |

### Requests from the app, the kit and the boards (served ahead of the scoreboard)

| Request | State |
|---|---|
| R1 (ASSET) a draw layer above `held` for the front carry paw | DONE 23 Oct 14:35: `zFront` on a slot, parts tagged `front` |
| R2 (ASSET) a skirt or hem slot for garments | DONE 23 Oct 14:35: `hem` on a slot (edge, ripple, energy, shear) |
| R3 (ASSET) lint flags a channel value naming no part | DONE 23 Oct 14:35: `unknown-part` in `alive lint`; reported once at run time |
| DM: stroke-trim progress rings, or a documented alternative | DONE 23 Oct 15:05 (C6) |
| R4 (ASSET) paw ring for a two-hand carry | DONE 23 Oct 15:05: a front far paw carrying the near paw's item is measured from the item; the pack's `carry-front` lints clean |

