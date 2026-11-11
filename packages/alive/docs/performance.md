# Performance

## Budgets

The benchmark (`benchmark/paint_benchmark_test.dart`) fails when the new runtime leaves one of these, on its harness:

| Budget | Limit | Why |
|---|---|---|
| Frame work on the UI thread (evaluate + record the frame), p99 | 1 ms, and never worse than the old path | a 60 Hz frame is 16.7 ms for the whole screen; Fabio should cost a small slice of it |
| Dart heap after a full GC while he is on screen | +2 MB over the screen without him | the spike measured +3.5 to +4.2 MB on the old path in the simulator |
| Dart heap after he leaves | back within 0.1 MB | nothing of him stays |
| Assets per scene | 100 KB gzipped | the APK and IPA carry them |
| Load and first paint, p50 | 25 ms | done before he moves; must not stall the screen's opening |
| Frames while he holds a pose with no idle life | 0 | the clock stops (test/controller_test.dart) |

## Method

Same process, same clips, interleaved (old, new, new, old, ...), 5 repetitions after a warm-up, on this Mac in a
debug (JIT) `flutter test` with the test renderer. "Old" is fabio_plus's lean art path driven per frame exactly as the
app spike drove it (`SceneFrame.values` for the recording page with breath and blink, `ArtOnlyFabio` for Phone almost
full). "New" is `AlivePlayer.advance` + `evaluate` + `CompiledArt.paint`. The Dart heap is read after a full GC through
the VM service (`getAllocationProfile(gc: true)`), the method of the app spike's `LOG.md`. Swap is recorded at the start
and end of each run (the laptop runs at its memory limit; see the JSON files in `benchmark/out/`).

These are relative numbers on one machine: debug JIT is slower than a release build on a phone, and the test renderer
is software, not Impeller. Phone numbers (frame build and raster on the simulator harness, heap, APK size) come from the
app integration's harness and are reported there; until they are, they are "not measured" here.

```bash
flutter test --enable-vmservice benchmark/paint_benchmark_test.dart
```

## Results (22 Oct 2026, two runs on the final code: 13:43 and 14:03)

Files: `benchmark/out/paint-2026-10-22T1343.json`, `benchmark/out/paint-2026-10-22T1403.json`. Swap free at the start of
each: 0.74 GB and 1.27 GB (the laptop was paging throughout, for both paths alike; the 14:03 run was the busier one).

### Frame work on the UI thread (evaluate + record), microseconds, p50 / p90 / p99

| Scene | Frames per run | Old (13:43; 14:03) | New (13:43; 14:03) | Change |
|---|---|---|---|---|
| Recording (greet, record, one minute, done, rest) | 3,910 | 345 / 465 / 1,047; 398 / 780 / 1,700 | 34 / 52 / 101; 38 / 105 / 336 | p50 10x less; p99 5x to 10x less |
| Phone almost full | 2,885 | 232 / 288 / 1,152; 234 / 293 / 968 | 15 / 23 / 60; 15 / 21 / 68 | p50 15x less; p99 14x to 19x less |

Where it went: the old path built a map of values per layer per frame, rebuilt clip paths, parsed numbers and copied
styles per element, and walked every static element. The new one samples typed keys and replays pictures.

### Raster of the recorded frame (test renderer, software), microseconds, p50 / p99

| Scene | Old (13:43; 14:03) | New (13:43; 14:03) |
|---|---|---|
| Recording | 2,240 / 6,156; 2,798 / 7,992 | 2,156 / 4,282; 2,517 / 8,090 |
| Phone almost full | 2,647 / 6,845; 2,660 / 6,927 | 2,417 / 3,349; 2,422 / 4,387 |

About the same, as expected: both draw the same operations (render parity is exact). Raster on a phone (Impeller) was
not measured here.

### Load and first paint, milliseconds, p50 of 5

| Scene | Old (13:43; 14:03) | New (13:43; 14:03) | Phases of the new path, 14:03 |
|---|---|---|---|
| Recording | 19.0; 24.8 | 12.7; 16.6 | decode 3.8, parse 4.5, prepare (paths and pictures) 6.7, first paint 0.3 |
| Phone almost full | 3.5; 2.3 | 2.8; 4.6 | decode 0.8, parse 0.4, prepare 3.0, first paint 0.1 |

The recording page loads faster: the old path's first paint parsed the SVG (15.4 ms of its 24.8). Phone almost full,
a small scene, is not better: across three runs it was 2.6 vs 2.2, 2.8 vs 3.5 and 4.6 vs 2.3 ms (new vs old), so
it is unchanged to worse by up to 2.3 ms, all of it before he moves.

### Dart heap after a full GC, MB over the screen without him

| Scene | Old: on screen, after leaving | New: on screen, after leaving |
|---|---|---|
| Recording, 13:43 | +1.45, -0.02 / +1.48, +0.00 | +0.96, +0.03 / +0.93, +0.01 |
| Recording, 14:03 | +0.72, -0.73 / +1.48, +0.01 | +0.91, +0.00 / +0.93, +0.03 |
| Phone almost full, 13:43 | +0.46, -0.03 / +0.52, +0.00 | +0.23, +0.05 / +0.18, +0.01 |
| Phone almost full, 14:03 | +0.34, -0.17 / +0.52, +0.00 | +0.22, +0.05 / +0.18, +0.00 |

The new path holds +0.9 MB (recording) and +0.2 MB (Phone almost full) in every measurement; the old one +0.7 to
+1.5 MB and +0.3 to +0.5 MB (its first reading of a run starts from a heap that still held the previous phase, hence
the negative "after"). Plus native memory for the recorded pictures, which the Dart heap does not show: 37.8 KB
(recording), 12.4 KB (Phone almost full), from `Picture.approximateBytesUsed`. Both paths give everything back.

### Assets

| Scene | Old raw / gzip | New raw / gzip | Change |
|---|---|---|---|
| Recording (2 art + 13 clips + meta) | 484 KB / 85.3 KB | 312 KB / 63.8 KB | -35 % raw, -25 % gzip |
| Phone almost full | 108 KB / 21.5 KB | 94 KB / 22.0 KB | -13 % raw, +2.4 % gzip (worse) |

Compiled art repeats each shape's final paint where the SVG inherited it from a group; gzip mostly absorbs that, and
for Phone almost full not quite.

### Code size

Not measured: no Android or iOS builds were run from this side (the builds belong to the app integration). What is known: the old
lean path compiled to 237 KB of fabio_plus AOT code plus 72 KB of `package:xml` (spike, Android release); `alive` does
not depend on `xml` and ships no engine data assets (the old package's 132 KB compressed shipped even on the lean path).

### What got worse

- Phone almost full loads in up to 2.3 ms more (p50, 2 of 3 runs): paths and pictures are built at load.
- Phone almost full's assets are 2.4 % larger gzipped (+0.5 KB).
- Native memory now holds the static art as pictures (38 KB and 12 KB): memory the Dart heap does not show.
- Raster p99 of the recording page was 1 % higher in the busier run (8.09 vs 7.99 ms, software renderer); the other
  three raster comparisons were lower. Read it as unchanged.

### Not reported

Dart bytes allocated per frame: in `flutter test` the VM's allocation profile also counts what the test harness
allocates while the loop runs (about 170 KB of strings and lists per frame, varying by tens of KB from run to run),
which is larger than either path's own allocation. The sampling path was changed to allocate nothing per key (no
records returned per sample, matrices written into reused buffers), but that is a code fact, not a measurement.

## 0.5.0: page opening and heap per scene (23 Oct 2026)

### Page opening

Method (`benchmark/open_benchmark_test.dart`, run by `node tools/bench-open.mjs --modes on,off,preload --runs 3
--scenes <app>/assets/alive`): a question page pushed with an iOS transition on an iPhone 17 Pro Max window
(440 x 956 at 3x), in a live flutter test binding, so frames come from real vsyncs and the scene loads through an asset
bundle in real time. On: the page makes his controller in initState and shows his stage; off: the same page with an
empty box; preload: on, with the scene preloaded on the page before. The engine's own frame timings (FrameTiming, as
the app's PERF_LOG): per entry, the frames from the push to 1.4 s after it. Slow: build or raster over 16.7 ms. Late:
the frame began over 16.7 ms after its vsync (the UI thread was busy elsewhere). Nine entries in the app tour's
order, from the app's own scenes. One process per mode and run, alternated; counts pooled over 3 runs.
`OPEN_TIMELINE=1` with `flutter test --enable-vmservice` reads the VM timeline (what the long stretches were).

| All nine entries, 3 runs | Before (13:28) | After (14:11) |
|---|---|---|
| Slow + late frames with him | 4 + 4 | 1 + 2 |
| Slow + late frames, preloaded | 2 + 4 | 0 + 0 |
| Slow + late frames without him (control) | 0 + 1 | 0 + 1 |
| The page below a preload: latest frame | 47.6 ms late | 15.6 ms late |
| Recording (first entry) with him: latest frame | 62 ms late | 19.2 ms late |
| Frames over 8.3 ms (120 Hz), with him / preloaded / without | 37 / 41 / 18 | 22 / 20 / 10 |

Where the time went before (VM timeline): the decode and parse of each file (up to 30 ms for the recording scene, cold),
then preparing the art (10 to 27 ms) in one task on the UI thread, which made the frames after it late. After: decode
and parse run in an isolate; preparing runs in slices of about 4 ms, each after a frame. The rest is the page's own
first frame (8 to 12 ms in debug, with him or without) plus 1 to 3 ms of his (his controller and his first paint,
measured warm: 0.8 to 2.5 ms), which is what keeps the 120 Hz count above the control.

Not measured here: raster (flutter test has no screen behind its frames), release builds (JIT only), the device.

### Release mode (AOT), the off-thread part

`benchmark/parse_aot.dart` compiles to a native program (`dart compile exe benchmark/parse_aot.dart -o
build/parse_aot`) and times what a load does in its isolate: decode the JSON, parse and check it, read path data into
commands (median of 9 runs after 3 warm-up runs). On the test machine over the app's 46 scenes (23 Oct 15:22): median 1.03
ms, largest 4.6 ms (hx_v1), 55 ms for all 46. The same program in JIT after its warm-up: median 0.94 ms, largest 4.6
ms. Evaluating and painting use dart:ui and cannot be compiled this way; they have no release number on this side.

### Heap per scene

Method (`benchmark/scene_cost_test.dart`, `ALIVE_SCENES=<app>/assets/alive flutter test --enable-vmservice
benchmark/scene_cost_test.dart`): every scene of the folder loaded through the cache, 30 frames drawn, the Dart heap
read after a full GC through the VM service (on screen, then after release), median of 3; load phases p50 of 5 after a
warm-up; native picture bytes; files raw and gzipped.

| 46 app scenes | Before (13:27) | Art trees let go (14:22) | Compact tracks (15:39) |
|---|---|---|---|
| Dart heap held on screen, median | 195 KB | 74 KB | 58 KB |
| largest (recording) | 1,039 KB | 708 KB | 503 KB |
| sum over the 46 | 10.6 MB | 4.7 MB | 3.8 MB |
| after release, largest | 10 KB | 15 KB | 13 KB |
| load and first paint, median | 1.6 ms | 1.6 ms | 1.7 ms (103.7 against 103.8 ms for all 46, back to back) |
| native pictures, sum | 669 KB | 669 KB | 669 KB |
| files gzipped | 1,060 KB | 1,060 KB | 1,060 KB (705 KB packed with `alive pack --share`) |

What changed: once prepared, a scene lets go of its parsed art trees (the path data text, the static nodes); tracks
keep no ease list when every segment is linear, only a layer's keyed properties, and a clip's key numbers in one
buffer. What got worse: nothing measured; `AliveSceneData.arts` of a scene from the cache hold headers only, and
`Track.times`, `values`, `eases` and `LayerTracks.byProp` are built when read.

## 0.6.0: heap and files (23 Oct 2026)

Heap per scene, measured the steadier way (COST-2 in `docs/scoreboard.md`: a warm-up round, then the lowest of three
rounds), back to back with 0.5.0 on the same laptop (`benchmark/out/scenes-r2-before-2026-10-23.json`,
`scenes-r2-after-2026-10-23.json`):

| 46 app scenes | 0.5.0 | 0.6.0 |
|---|---|---|
| Dart heap held on screen, largest (recording) | 441 KB | 230 KB |
| median | 54.7 KB | 46.5 KB |
| sum over the 46 | 3.4 MB | 2.6 MB |
| the recording scene by class, ten copies, data only (`benchmark/heap_classes_test.dart`) | 597 KB | 391 KB |
| load and first paint, median (all 46) | 1.61 ms (95.2 ms) | 1.59 ms (93.3 ms) |

What changed: a clip's keys are plain typed arrays (one buffer of numbers, five ints a track, a segment hint per
track) instead of a `Track` object per track, and tracks whose keys fall at the same times share one list of times.
The two heap methods agree on the drop (about 200 KB on the recording scene), not on the level (the class count is
higher); the single readings spread by up to 120 KB on the largest scenes. What got worse: nothing measured beyond
that spread.

Files, the app's 46 scenes packed with `alive pack --share` (each JSON file gzipped by dart:io, summed):

| | 0.5.0's pack | 0.6.0's pack |
|---|---|---|
| gzipped | 705 KB | 469 KB (524 KB with `--keys list`, for an app on 0.5.0) |
| raw | 2.70 MB | 2.15 MB |
| pixels against the unpacked folder (459 frames) | 0 frames with a pixel over 40 | the same; identical to 0.5.0's pack (largest channel difference 0) |

What changed: path data written short (each segment in the shorter of its absolute and relative forms from the same
rounded points), the files' `source` notes left out, linear tracks in the compact key form. What got worse: scenes
with compact keys need engine 0.6.0.

## Correctness checks that guard the speed-ups

| Check | Result |
|---|---|
| Recording and Phone almost full, old against new, 70 sampled frames | 0 pixels differ (any channel over 40 of 255), max channel difference 0 |
| Every board engine export in `<boards>/motion` (71), 213 frames | 0 pixels differ |
| Layer values, every 1/30 s of every clip | within 1e-9 |
| The recording export's page matrices (83 rows) | 0.259 by the spike's own metric (it measured 0.26) |

## Requested from the app side

The same harness as the app spike's (its `LOG.md`) on the iOS Simulator (PERF_LOG frame build and raster p50/p99, missed
vsyncs, Dart heap after GC on screen and after leaving, 3 runs alternated), recording page on fabio_plus against the
same page on alive; and `flutter build apk --analyze-size` for both if Android is built. The app integration has measured them since, on the simulator and on Android.
