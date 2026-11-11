# Figma as the storyboard that directs the flow

This is how the Fabla dashboard launch film was made: the Figma frames of the design were the beats, and the film moved between
them. `alive storyboard` does that for a moment in the app: an ordered set of Figma frames becomes one scene that
eases from frame to frame.

```bash
node tools/alive.mjs storyboard halfway-express --id halfway-express-story --out examples/storyboard/out/halfway-express-story \
  --timing examples/storyboard/halfway-express.timing.json --preview
```

## How the frames become motion (Smart Animate style)

- **Matching:** a layer in one frame is the same layer in the next when it has the same name path (same-named
  siblings are numbered in order) and, for a text or a component instance, the same content. Name layers by role
  (`fabio`, `fabio/face`, `item/ticket`, `ui/next`), as every board already does.
- **Moving:** a matched layer eases from its pose in one frame to its pose in the next: position, rotation, scale
  (a frame resized with its contents), the size of a plain box (`ui/fill` growing is WIDTH, its corners kept),
  fill colour (a text's colour too) and opacity.
- **Appearing and leaving:** a layer that is in some frames only fades in where it first appears and out where it
  leaves; it is drawn from the SVG export of the frame it appears in. A changed text or a swapped component is a
  new layer, so it cross-fades.
- **Art:** the frames' own SVG exports, through the `alive figma` converter: Figma's own Fabio as art, every kit part
  its own layer, exact easing.
- **Cues:** each frame's arrival is a cue named after the frame (`fabio.events`: `AliveCue('Pick')`).

## Timing: frame names, a notes layer, or a timing file

Each frame after the first says how long the move INTO it takes, its ease, and how long it then holds:

```
03 Tap Record 0.6s ease-out hold 1.2s
```

- a leading number orders the frames (otherwise the section's left to right order, or the order of `FRAMES`);
- a length: `0.6s` or `600ms`;
- an ease: `ease-out`, `ease-in`, `ease-in-out`, `linear`, `back` (overshoot), `spring` (gentle), `bouncy`, `quick`,
  `slow`, `cut` (a step);
- `hold 1.2s`.

The same words can go in a text layer named `notes` inside the frame (hide it if you like), or in a timing file
(`--timing`, `{"frames": {"<frame name>": "0.6s ease-out hold 1.2s"}}`), which wins. Defaults: 400 ms ease in and
out, 600 ms hold.

## Reading a storyboard from Figma (read only), then working without Figma

1. The frames' reads: run `tools/figma/read-storyboard.figma.js` through `use_figma` on the file, with one of these
   lines in front of the script (it switches page once and changes nothing):

   ```js
   const FRAMES = ['<frame id>', '<frame id>'];        // the frames, in story order; two per call keeps replies whole
   // or
   const SECTION = '<section id>'; const EXCLUDE = ['Express']; // a section's frames, left to right, top to bottom
   ```

   The Halfway Express reads were four calls of this shape on the design file (`use_figma` takes its key): two frames
   a call, the seventh alone.

2. Each frame's SVG export with layer names as ids: `download_assets` with `nodeId` = the frame and
   `defaultFormat: "svg"` (then `curl` the URL it returns, quickly: it is short-lived), or Figma's Export > SVG with
   "Include id attribute" on. Save them as `<frame id with - for :>.svg` in one folder.

3. Save the storyboard into the cache:

   ```bash
   node tools/figma/storyboard.mjs --name halfway-express \
     --transcript ~/.claude/projects/<project>/<session>.jsonl \      # or --reads a.json b.json (saved results)
     --svg-dir <folder of exports> --frames <frame id>,<frame id>,...
   ```

   It writes `tools/figma/cache/storyboards/<name>/story.json` and `svg/<frame>.svg.br`, so anyone can run
   `alive storyboard <name>` without Figma open.

## What it does not do

A storyboard gives poses, not paths: a layer that moves along a curve, passes through the frame, or slides out
while another slides in between two frames is a straight eased move or a cross-fade here. Add a frame for the
in-between pose, or key that part in Figma Motion and use `alive figma`. Text inside a matched layer that changes is
a cross-fade, not a retype. A layer with no role name that appears only in a later frame is not drawn (it is not in
the read); name it. docs/authoring-proof.md has the measured match against the approved film.
