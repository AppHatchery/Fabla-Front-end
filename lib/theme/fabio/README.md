# Fabio (procedural mascot)

The code here draws and animates Fabio, Fabla's ghost mascot, from the
original SVG outline: the `Fabio` widget, the `FabioStage` choreography
player and `showFabioScript`.

The full documentation lives in
[`tools/fabio_studio/README.md`](../../../tools/fabio_studio/README.md). It
covers usage, the script JSON format, custom props, engine internals, the web
authoring tool (Fabio Studio), and the rules for keeping this Dart engine in
sync with Studio's JavaScript port.

If you change behaviour or vocabulary here, make the same change in
`tools/fabio_studio/src/engine.js` and follow the checklist in that README.
