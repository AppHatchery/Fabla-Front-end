# Adding Alive to a screen

This is for a Fabla developer putting a designed Fabio moment on a screen. You need the scene's files (the designer
or the CLI makes them, see `authoring.md`) and about twenty lines of Dart.

## 1. The dependency and the files

```yaml
# pubspec.yaml of the app
dependencies:
  alive:
    path: ../alive-engine            # or a vendored copy, e.g. packages/alive

flutter:
  assets:
    - assets/alive/recording/
    - assets/alive/recording/art/
```

The package brings no assets and one dependency (`path_parsing`). Each scene is a folder: `scene.json` and `art/`.
List both folders; Flutter does not include subfolders on its own.

Check the files before a build:

```bash
node ../alive-engine/tools/alive.mjs validate assets/alive/recording
```

### Ship them packed (0.5.0)

`alive pack` writes the app's scene folder smaller for the build, drawing the same pixels (numbers to the precision the
screen shows; path data written short, each segment in its shorter absolute or relative form, the same points; the
files' `source` notes left out; with `--share`, art that two or more scenes draw the same written once in
`_shared/`):

```bash
node ../alive-engine/tools/alive.mjs pack assets/alive_src --out assets/alive --share
```

Measured on the app's 46 scenes (23 Oct, 0.6.0): 4.65 MB raw and 1,060 KB gzipped to 2.15 MB raw and 469 KB gzipped,
with 28 shared fragments (0.5.0's pack: 705 KB); every clip of every scene at three instants draws the same pixels as
the unpacked folder (`test/pack_parity_test.dart`, 0 of 459 frames with a pixel over 40 of 255), and 0.6.0's pack the
same pixels as 0.5.0's exactly (largest channel difference 0). With `--share`, list the shared folder too:
`- assets/alive/_shared/`.

0.6.0's pack writes linear tracks in the compact key form (`{"dt": [...], "v": [...]}`, docs/schema.md), which an
engine older than 0.6.0 refuses (the scenes are stamped `"requires": "0.6.0"`, and the old engine says so). An app
still on 0.5.0 packs with `--keys list` (524 KB on the same scenes); short path data is plain SVG either way.

## 2. A controller per screen

The controller loads the scene, owns the clock and takes the inputs. Make it like an `AnimationController`: in the
State, with the State as `vsync`, and dispose it with the State.

```dart
class _RecordingQuestionState extends State<RecordingQuestion> with SingleTickerProviderStateMixin {
  late final AliveController fabio = AliveController(
    vsync: this,
    scene: 'recording',
    store: AlivePrefsStore(prefs),                // remembers the last variant of each pool (see 6)
    run: AliveRunContext(diary: widget.diaryId, day: today, question: widget.index),
    onError: (e) => log.warning('alive: $e'),
  );

  @override
  void dispose() {
    fabio.dispose(); // releases his data when no other screen shows the scene
    super.dispose();
  }
```

`scene: 'warnings/phone-almost-full'` loads the scene `warnings` and starts the clip or pool `phone-almost-full`.

The controller takes one ticker from `vsync`. A State that also runs its own `AnimationController` needs
`TickerProviderStateMixin` (several tickers), not `SingleTickerProviderStateMixin`: with the single one the
controller's ticker is the second, Flutter refuses it, and the scene fails to load (the app integration met this on 22 Oct).

`ready` completes when the scene has loaded or has failed; it never completes with an error. Check `status` (or
`error`) after it: `await fabio.ready; if (fabio.status.value == AliveStatus.failed) ...`.

### Load it before the page opens

A scene loads in the background as the page opens: its files are read, decoded and parsed off the UI thread (an
isolate, for files of 16 KB or more with `AliveLibrary.assets`), then prepared and drawn once off screen, and he
appears a few frames into the page. To have nothing left to do when the page opens, load it on the page before,
while the user reads it:

```dart
// on the question before the voice question, or when the warning is decided
AliveController.preload(['recording']);
// later, on the next page: ready in its constructor; the stage paints him from the page's second frame
late final fabio = AliveController(vsync: this, scene: 'recording');
```

The stage paints a scene that was ready when it was built from the next frame, so the frame that builds the page (its
heaviest) does not also pay for his first paint. A preloaded scene is held until a controller takes it over (then it
goes when that screen goes) or for `keep` (30 s by default) if none does. `preload` returns the scenes that could not be loaded; it never throws. Several at once:
`AliveController.preload(['ws_storage', 'st_keeper'])` (a warning and the Storage page it can open). The cache
behind it: `AliveCache.shared.preload`, `isLoaded`, `tryAcquire`. While a cache holds preloads it listens for the
system's memory pressure and lets them go when it comes (`releasePreloads`); it stops listening when its last preload
is taken over, runs out or is released (0.6.0). Measured on the page-opening benchmark: see `docs/scoreboard.md` (P1).

## 3. The stage

```dart
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: AliveStage(controller: fabio, viewport: const Rect.fromLTWH(0, 300, 430, 460))),
        // your own widgets: the recorder sheet, buttons, the bubble
      ]);
}
```

| Parameter | Default | Use |
|---|---|---|
| `viewport` | the whole scene | the part of the world (scene units) to show; size him by choosing it |
| `fit`, `alignment` | `contain`, `center` | how the viewport fits the stage's box |
| `plane` | `'main'` | a scene split into planes lets your widgets sit between them (one stage per plane, one controller) |
| `clip` | `false` | nothing of him is cut off unless you ask |
| `placeholder` | nothing | shown while the scene loads (a few ms to tens of ms) |
| `fallback` | nothing | shown if the scene cannot load or draw; the screen keeps working |
| `semanticsLabel`, `excludeFromSemantics` | the scene decides | see 8 |

Put widgets where he is with `fabio.anchor('bubbleTip')` (a world point that moves with its layer) and
`fabio.worldToLocal(point, size, viewport: ...)`.

## 4. Driving him

| The app knows | Call | What the scene does |
|---|---|---|
| the screen's state | `fabio.appState = 'recording'` | plays the state's enter clip, then its idle clip |
| the mic level | `fabio.micLevel = AliveMic.fromDecibels(db)` | nods at the end of a loud stretch; drives bound layers |
| a tap on him | `fabio.tap()` | the scene's `tap:fabio` action |
| an app event | `fabio.send('saved')` | the scene's `saved` action (unknown events are ignored) |
| a moment to show | `fabio.play('thumbs')` | a clip, or a pool (a fresh variant each time) |
| a flow that waits | `fabio.play('phone_almost_full', holdAt: 'The phone is almost full')`, then `fabio.proceed()` | the clip waits at that cue until the tap |
| a look | `fabio.look = 'night'` | shows and hides the look's layers |
| any number the scene binds | `fabio.setInput('level', 0.4)` | bound layers follow |

All calls are safe at any time: before the scene has loaded they are queued, after a failure or `dispose` they do
nothing, and a name the scene does not have is reported (not thrown).

flutter_sound reports decibels; `AliveMic.fromDecibels` maps them as the recording page does, `(dB - 28) / 58`
clamped to 0..1. Feed it from the recorder's progress stream (every 150 ms is enough; the scene smooths if it says so).

### His eyes on a point (0.5.0)

Where the scene has a `live.gaze`, he looks at what the app points to: the text answer's caret, the button to press.

```dart
fabio.lookAtLocal(caretOffset, stageSize);   // a point in the stage's own coordinates (as the stage fits it)
fabio.lookAt(const Offset(215, 640));        // or a world point
fabio.lookAt(null);                          // ahead again
```

The layers in the gaze move toward the point by at most their offset, smoothly (reduced motion: at once); a kit
figure's open eyes swap to the pack's look parts. A scene without a gaze reports the call as a usage error.

## 5. Listening to him

```dart
fabio.events.listen((e) {
  switch (e) {
    case AliveCue(name: 'warned'):        showCardButton();
    case AliveClipEnded(clip: 'done'):    enableNext();
    case AliveBubble(:final text):        setState(() => bubble = text == null ? null : l10n.bubble(text));
    case AliveFailed(:final error):       log.warning('$error');
    default:
  }
});
```

| Event | When |
|---|---|
| `AliveLoaded` | the scene is ready (also `await fabio.ready`) |
| `AliveClipStarted(clip, pool, look)` | a clip starts (a pool names the variant picked) |
| `AliveClipEnded(clip)` | a clip reaches its end (every pass of a loop) |
| `AliveCue(name, clip)` | a clip passes a named mark |
| `AliveBubble(text, clip)` | the bubble text changes; read `fabio.bubble` for its opacity per frame |
| `AliveStateChanged(from, to)` | `appState` changed |
| `AliveFailed(error)` | a load, schema, render, store or usage problem |

Cues and clip ends keep their times with reduced motion on, so a flow that waits for them keeps its pacing.

Reading values: `fabio.clip`, `fabio.clipTime`, `fabio.holding`, `fabio.channel('face')`, `fabio.value(layer,
LayerProp.ty)` (for data layers: something Flutter draws but the clip times, like the warning card),
`fabio.status`, `fabio.error`.

## 6. Fresh every run

A pool picks a new variant every time it plays and never the one it played last. To remember the last pick across
app launches, give the controller a store. In the Fabla app, over shared_preferences:

```dart
class AlivePrefsStore implements AliveStore {
  AlivePrefsStore(this.prefs);
  final SharedPreferences prefs;
  @override
  Future<String?> read(String key) async => prefs.getString(key);
  @override
  Future<void> write(String key, String value) => prefs.setString(key, value);
}
```

With `run: AliveRunContext(diary:, day:, question:)` the picks are reproducible (a bug report can be replayed);
without it they are random. A failing store is reported (`AliveStoreError`) and the picks go on.

## 7. Lifecycle, reduced motion, calm

- The clock runs only while something moves. It stops in the background (`AppLifecycleState.hidden` or `paused`) and
  when the route is covered (TickerMode), and a long frame moves time by at most 0.1 s, so he never jumps.
- With the OS setting for reduced motion (`MediaQuery.disableAnimations`), each clip shows its designed still pose,
  with no breath, blink, nod or physics, and the stage repaints only when the pose changes.
  `AliveOptions(reducedMotion: AliveReducedMotion.always)` forces it (an in-app setting).
- `fabio.player?.live = false` keeps the designed clips but drops breath, blink, nod and physics (a calm setting).
- `pause()` and `resume()` stop and start the clock by hand.
- `AliveOptions(idleFrameRate: 30)` is the repaint rate while he only breathes and blinks (designed moves always
  repaint every frame).

## 8. Accessibility

Fabio is decorative by default: the stage is excluded from the semantics tree, because the screen's own controls
carry the meaning. Where he says something that matters, label him: `AliveStage(semanticsLabel: l10n.fabioListening)`
or `excludeFromSemantics: false` to use the scene's label (per app state, from `semantics.states`). Speech bubble
text comes as events, so the app shows it as real, translatable text.

## 9. Drawing a part yourself

The recording sheet draws the cassette inside the app's recorder. Any art file of a loaded scene can be drawn:

```dart
AlivePart(controller: fabio, art: 'rec_tape', viewport: Rect.fromCenter(center: Offset.zero, width: 48, height: 32))
// or inside your own CustomPainter, in scene units at the canvas's transform:
fabio.paintArt(canvas, 'rec_tape');
```

## 10. Testing a screen

`AliveLibrary.memory({'recording/scene.json': ..., 'recording/art/rec_scene.json': ...})` loads scenes without an
asset bundle; `AliveCache()` gives a test its own cache (`liveScenes` shows what is held). In widget tests, wait for
the load with `await tester.runAsync(() => fabio.ready)` and pump frames. See `test/controller_test.dart`.
With `AliveLibrary.assets`, large files are decoded in an isolate, which fake time does not advance: wait with
`tester.runAsync` (as for any asset read), or pass `AliveLibrary.assets(background: false)` in the test. A preload's
hold is a timer in the zone it was called from; a controller taking the scene cancels it. A preload that no
controller takes leaves that timer pending for `keep` (30 s), and flutter_test fails a test that ends with a pending
timer ("A Timer is still pending even after the widget tree was disposed"): end such a test with
`AliveCache.shared.releasePreloads()` (it cancels the timers), or give the test its own cache and end it with
`cache.dispose()` (its preloads let go, its memory-pressure listener removed, new loads refused; scenes screens hold
stay until they go). `AliveCache.shared` lives as long as the app and cannot be disposed. On a busy machine the
isolate can outlast one `runAsync`: in a settle loop, give real async time every few pumped frames, not only at its
start (found in the app integration, 23 Oct).

## Checklist for a new screen

- The scene folder and its `art/` are listed in `pubspec.yaml`, and `alive validate` passes.
- The controller is made in `initState` (or `late final`) with the State as `vsync`, and disposed in `dispose`.
- Every state the screen passes through is set with `appState`; events the scene listens to are sent.
- The flow listens to cues or clip ends rather than timers, so reduced motion keeps its pacing.
- Bubble text is drawn by the app and translated.
- The screen works with the fallback (pass a scene id that does not exist once and look).
