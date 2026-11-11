# Breaking changes

Changes that reach existing scenes or code, newest first, with the flag that keeps the old behaviour where one
exists. Every release is in `CHANGELOG.md`; this page lists only what can break something that worked before.

- 23 Oct 15:05 (0.5.0) `LayerProp` has four more values before `fill` and `stroke` (`kx`, `ky`, `trimStart`,
  `trimEnd`): `LayerProp.numeric` is 13. Code naming properties is unchanged. `alive upgrade` keeps a board's trim keys
  (drawn trimmed now); `--no-trims` drops them as before.
- 23 Oct 14:43 (0.5.0) A scene from the cache lets go of its parsed art trees once prepared: `AliveSceneData.arts`
  hold headers (id, size, offset, layers); `AliveCache(keepArtTrees: true)` keeps them. A stage built on a ready scene
  paints him from the next frame.

- 22 Oct 15:02 (0.2.0) A text box (`text` with a width: Figma text reads, and board text boxes cut with `text_as_fo`)
  now shares its line height evenly above and below the line, as Figma and CSS do. Before, Flutter's default put Rubik
  about 1.5 px lower at 16 on 24. SVG text on a baseline is unchanged; the goldens and the parity suites are unchanged.
  The upgrade tool string in `source.tool` reads `alive upgrade 0.2.0`; nothing else in upgraded scenes changed.

- 22 Oct 13:45 `alive upgrade` now DRAWS SVG `<text>` (fabio_plus never did; the app's cut.py works around it
  with `text_as_fo`). Text inside the layers you keep will appear. Pass `--no-svg-text` to keep the old behaviour, or drop
  the text in your cut spec. `<text>` with `fill="currentColor"` under a colour channel layer follows the layer's
  animated colour. Letter spacing is drawn. `<tspan>` positions are ignored (spans run on one line).
- 22 Oct 13:45 compiled art changed shape (a chunk's elements now join their parent group): re-run `alive upgrade`
  on the scene folders; the pixels are the same.
