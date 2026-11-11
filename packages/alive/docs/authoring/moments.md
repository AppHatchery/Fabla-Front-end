# The moment file

The prompt and sketch routes both end in a moment file, compiled by `alive moment`:

```bash
node tools/alive.mjs moment examples/moments/diary-done.moment.json --out examples/moments/out/diary-done \
  [--preview <file.mp4>] [--draft]
```

A moment is a kit figure (a look, where his feet stand, his size), items (kit props or simple shapes), an optional
effect (confetti, sparkle), and **beats**: key poses in time, each with the cause that makes it happen. Every
property a beat names eases to its new value from the previous beat (or over `in` ms); a property a beat does not
name holds. Kit actions (`wave`, `hop`, `tilt`...) play on top of the pose they start from. The scene it writes uses
the kit figure (`figures`), so the app needs the pack in `assets/alive/kits/fabio/`.

The full reference (every field and unit) is the skill's: `.claude/skills/alive-author/references/moment-format.md`.
`node tools/alive.mjs catalog` lists what a moment can use.

What it checks: unknown looks, faces, paws, items, slots and actions; a pointing paw or a retired part; beats out
of order; a beat without a cause; a beat that moves something a kit action owns. Then validate and lint run:

| Rule | Severity | What |
|---|---|---|
| no-pointing-paw | error | no look, part, swap or pool wears a pointing paw or a retired part |
| m3-paws | error | holding paws are the kit's M3 paw drawn whole (no two-layer palm and tips) |
| paw-ring | error | a holding paw stays within 50 kit units of its rest spot (the object comes to him) |
| paw-contact | error | every paw that shows touches his figure, measured on pixels (`alive paws`; a paw covered by what is drawn over it is hidden, not detached) |
| paw-overlap | warning | a paw sits at least 1.5 kit units into his figure (the paw slots' physics max, 3, on a figure that rides physics) |
| held-contact | error | an item held by a paw touches it (R4: the far paw in front, carrying the near paw's item, is measured from that item) |
| held-item | error | an item in the held slot only while the near paw holds |
| body-colour | error | his body is the canonical #A8D0FB |
| cause | error | every beat that changes something has a cause |
| eased | error | every move (tx, ty, rot, sx, sy) has an ease |
| snap | error | nothing covers more than 6 units or 8 degrees in under 100 ms |
| pause | warning | a clip of 1.5 s or more holds still for 200 ms somewhere |
| note | warning | every clip says what it is |

The figure rules run on every scene with kit figures; the motion rules on authored moments, and on any scene with
`alive lint --motion`. Lint cannot see one focal point, crowding or a dull pose: that is the preview review's job.
