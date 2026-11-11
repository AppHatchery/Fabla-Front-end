# Preview: see a scene the way the app draws it

```bash
node tools/alive.mjs preview <scene dir> [--clip <clip>...] [--out <file.mp4 | .gif | .html | dir>] [--look <look>]
                                         [--draft] [--fps 30] [--scale 1] [--stills 6] [--at <ms>...]
                                         [--viewport x,y,w,h] [--no-live] [--kits <dir>]
```

The frames are drawn by the runtime itself, not by a lookalike: `flutter test test/preview_test.dart` loads the scene
with the runtime's loader (kit packs and their parts included), plays each clip on an `AlivePlayer` advanced frame by
frame as the controller advances it (cues, physics, and the scene's breath and blink unless `--no-live`), and paints
each frame with the stage's own steps. ffmpeg then encodes them.

What you get, next to `--out`:
- the video (`.mp4`; or a `.gif`; or `.html`: a review page with the video, each clip's note, cues and length, and the
  stills);
- `<out>.sheet.png`: a contact sheet of stills with their times (six even instants per clip, plus `--at` times);
- `<out>.stills/`: the same stills as full-size PNGs.

`--draft` is 12 fps at half size (about 10 s for a 3 s clip on a 16 GB M2 Pro MacBook): use it while iterating, then render the
final at 30 fps. `--look` wears a kit look (`explorer`) or one of the scene's looks. `--viewport` crops to a part of
the world (a close look at his paws). It needs flutter and ffmpeg; check memory first (`sysctl vm.swapusage`).

`alive moment --preview`, `alive sketch --preview` and `alive storyboard --preview` call the same preview and add
their own stills: every beat, every input image beside its beat, every storyboard frame's arrival.
