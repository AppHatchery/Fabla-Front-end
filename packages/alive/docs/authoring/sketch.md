# From rough images (sketches, screenshots, storyboard photos, video frames)

Each image is a beat: his pose, where he stands, what he holds, his face, the items, the order.

```bash
# the skill route (no key): Claude reads the images and writes the moment, one beat per image ("image": "<file>")
node tools/alive.mjs sketch a.png b.png c.png --beats examples/sketch/x/x.moment.json --out examples/sketch/out/x \
  --preview examples/sketch/out/x.mp4 [--draft]

# the API route (ANTHROPIC_API_KEY set): the model reads the images and writes the moment
node tools/alive.mjs sketch a.png b.png c.png --out examples/sketch/out/x [--notes "he is tired"] [--times 0 800 1500]
```

Without `--beats` and without a key, `alive sketch` writes a starting moment (one beat per image, causes to fill
in) and says how to use the skill route.

The preview puts each input image beside the runtime's frame at its beat: `<out>.sheet.png` (pairs) and
`<out>.side-by-side.mp4` (each image held for its beat, the result beside it), so the designer can check the match.

Reading images well (what the skill tells Claude): map the image onto the scene's world first (a phone frame is
430 x 932; measure his feet, his height and the items' boxes against it); his size follows from his body width (144
kit units at scale 1); facing left is `flip`; app UI that hides him (a button he rises from behind) becomes an item
drawn in front of him. Where the image shows something the rules forbid (a pointing paw, paws far from his body, a
two-handed carry the kit cannot draw in front), follow the rules and say so in the beat's note.
