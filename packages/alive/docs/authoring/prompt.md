# From words (prompting)

A designer describes the moment: "Fabio cheers when the diary is finished, confetti, then settles".

## The primary route: the alive-author skill (no API key)

In Claude Code, in this repository, ask for it in words ("author a Fabio moment: ..."). The skill in
`.claude/skills/alive-author/` makes Claude:

1. write down the cause, his home, the one focal point and how it ends;
2. read the kit catalog (`node tools/alive.mjs catalog`) and the rules (references/motion-law.md);
3. write a moment file, `examples/moments/<id>.moment.json` ([the format](moments.md));
4. compile, check and draft-preview it: `node tools/alive.mjs moment <file> --out <dir> --preview <mp4> --draft`;
5. read the contact sheet and stills, and fix what breaks the review checklist (references/review.md), one or two
   changes a pass, keeping a log of the passes;
6. render the final at 30 fps.

Two moments were made this way (docs/authoring-proof.md): `diary-done` and `letter-ready`.

## The optional route: `alive prompt`

```bash
npm install                      # once: the Anthropic SDK is an optional dependency
export ANTHROPIC_API_KEY=...     # in your shell; alive never asks for it or stores it
node tools/alive.mjs prompt "Fabio cheers when the diary is finished, confetti, then settles" \
  --out examples/moments/out/diary-done --preview
```

It sends the same catalog, rules, moment format and an example moment to the model (default `claude-opus-5-5`,
`--model` or `ALIVE_MODEL` to change it; adaptive thinking, `--effort high` by default), compiles what comes back,
validates and lints it, and sends the problems back until the moment passes (`--tries 3`). It writes the moment file
next to the scene, so a designer can edit it and run `alive moment` again. Without a key it prints how to use the
skill route and exits with 2; nothing is sent.
