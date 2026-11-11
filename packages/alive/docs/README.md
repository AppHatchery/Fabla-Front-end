# The docs

Every doc in this repository, one line each. Paths are from the repository's root.

## Start

- [README](../README.md): what Alive is, a quick start and a map of the repository.
- [START-HERE.md](../START-HERE.md): the walkthrough: from a fresh clone to the showcase, your first moment and Fabio
  in an app, with the measured time of each step.
- [handoff/DEV-GUIDE.md](../handoff/DEV-GUIDE.md): for the Fabla team: Alive in the Fabla app, step by step, and what
  is not built yet.
- [showcase/README.md](../showcase/README.md): the local site where every scene and the kit play live, its pages
  and its API.

## Integrate

- [integration.md](integration.md): adding Alive to a screen: the dependency, assets, controller, inputs, events,
  lifecycle, reduced motion and tests.
- [standards.md](standards.md): placements, Fabio's size tiers, the scaling rule (`AlivePlacement`) and the
  templates (`alive new`).
- [extending.md](extending.md): plugin nodes, fonts, kits, shipping packed scenes, and the stability policy.
- [limits.md](limits.md): what Alive does not do, or does only partly, and what happens instead.
- [breaking-changes.md](breaking-changes.md): changes that reach existing scenes or code, and the flag that keeps the old
  behaviour.

## Author

- [authoring.md](authoring.md): every route from a designed moment to a scene: Figma Motion, board pages, words,
  rough images, storyboards and older exports.
- [authoring/moments.md](authoring/moments.md): the moment file: a kit figure, items and beats, compiled by
  `alive moment`.
- [authoring/preview.md](authoring/preview.md): `alive preview`, a scene drawn by the app's own runtime as an MP4,
  GIF, stills or a review page.
- [authoring/prompt.md](authoring/prompt.md): a moment from words, with the Claude Code skill or the API.
- [authoring/sketch.md](authoring/sketch.md): a moment from rough images, one beat per image.
- [authoring/storyboard.md](authoring/storyboard.md): Figma frames as the beats of one flow, eased from frame to
  frame.
- [kit.md](kit.md): the Fabio kit: slots, art packs, looks, actions, paw styles and the customisation API.
- [adding-artwork.md](adding-artwork.md): for designers: new art from Figma or SVG to a pack in five steps.
- [The authoring skill](../.claude/skills/alive-author/SKILL.md): what Claude Code follows when it writes a moment.

## Reference

- [schema.md](schema.md): the alive/1 scene format, every field.
- [architecture.md](architecture.md): how a frame is made, and why.
- [api.txt](api.txt): the public Dart API, one line per member (`node tools/api.mjs --check` keeps it current).
- [performance.md](performance.md): the budgets and the measured numbers, before and after.
- [scoreboard.md](scoreboard.md): the engine's performance goals, each measured before and after.
- [CHANGELOG.md](../CHANGELOG.md): every release, newest first, each with its highlights.

## Checks and proofs

- [checks.md](checks.md): what `alive lint` and `alive parity` check on board scenes, and what they measured.
- [paws.md](paws.md): the pixel paw check: the two paw styles, every rule, and the kit's results.
- [handoff/DATA.md](../handoff/DATA.md): the measured numbers: app size, memory, slow frames, packed sizes and tests.
- [figma-proof.md](figma-proof.md): every converted Figma Motion frame against Figma's own MP4 export.
- [authoring-proof.md](authoring-proof.md): moments made without Figma Motion, every pass, and the storyboard
  measured against the approved film.
- `tools/ci.sh`: the whole suite in one command (`--quick` for what needs nothing outside this repository).

## Paths in the docs

`<engine>` is this repository, `<app>` a checkout of the Fabla app, `<boards>` the boards folder (fabla-alive, not
part of this repository: the board pages under `streams/`, their engine exports under `motion/`), and
`<fabio-engine-plus>` the earlier JavaScript engine `procedural/` was ported from. `<design file>`, in the Figma cache
and in what was converted from it, stands for the key of the Figma file the frames were read from: a cache of your
own names its file in `moments.json` (`file`).
