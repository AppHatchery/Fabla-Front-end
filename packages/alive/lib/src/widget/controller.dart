// AliveController: what an app screen holds. It loads the scene, owns the clock, takes the inputs and reports events.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Alignment, BoxFit, applyBoxFit;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;

import '../kit/kit_def.dart';
import '../kit/look.dart';
import '../loader/library.dart';
import '../runtime/events.dart';
import '../runtime/extensions.dart';
import '../runtime/player.dart';
import '../runtime/scene_data.dart';
import '../runtime/variants.dart';
import '../schema/errors.dart';
import '../schema/track.dart';

/// Where a controller is.
enum AliveStatus {
  /// Loading the scene.
  loading,

  /// Playing (or ready to).
  ready,

  /// The scene could not be loaded or drawn; the stage shows its fallback.
  failed,

  /// Disposed.
  disposed,
}

/// Whose word decides reduced motion.
enum AliveReducedMotion {
  /// The OS setting (MediaQuery.disableAnimations), read by the stage.
  system,

  /// Always the still poses.
  always,

  /// Never (for previews of the motion).
  never,
}

/// Tuning for a controller.
class AliveOptions {
  /// Options.
  const AliveOptions({this.idleFrameRate = 30, this.maxStep = 0.1, this.reducedMotion = AliveReducedMotion.system, this.pauseInBackground = true});

  /// Repaints per second while he only breathes and blinks (designed moves always repaint every frame).
  final double idleFrameRate;

  /// Longest step of the clock per frame, seconds (a long frame slows him down instead of skipping).
  final double maxStep;

  /// Reduced motion policy.
  final AliveReducedMotion reducedMotion;

  /// Stop the clock while the app is in the background.
  final bool pauseInBackground;
}

/// Plays one scene for one screen. Create it in initState with the State as [vsync]; dispose it in dispose.
///
/// Every call is safe at any time: before the scene has loaded calls are queued, on a failed or disposed controller
/// they do nothing. Nothing is ever thrown into the widget tree.
class AliveController {
  /// A controller for [scene] (`recording`, or `warnings/phone-almost-full` to start with that clip or pool).
  AliveController({
    required TickerProvider vsync,
    required String scene,
    AliveLibrary? library,
    AliveCache? cache,
    this.store,
    this.run,
    this.options = const AliveOptions(),
    this.onError,
    this.extensions = AliveExtensions.none,
    String? look,
    math.Random? random,
  })  : sceneId = scene.split('/').first,
        _first = scene.contains('/') ? scene.substring(scene.indexOf('/') + 1) : null,
        library = library ?? const AliveLibrary.assets(),
        cache = cache ?? AliveCache.shared,
        _random = random,
        _look = look {
    _ticker = vsync.createTicker(_tick);
    if (options.pauseInBackground) {
      _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    }
    if (options.reducedMotion != AliveReducedMotion.system) _systemReduced = options.reducedMotion == AliveReducedMotion.always;
    _constructing = true;
    ready = _load();
    _constructing = false;
  }

  bool _constructing = false;

  /// Load scenes ahead of the screens that show them (call it on the page before): a controller made for one of them
  /// afterwards is ready in its constructor, with nothing left to load or prepare, and its stage paints him from the
  /// frame after the one that builds the page (that frame is the page's heaviest). Each scene is held until a
  /// controller takes it, or for [keep]. `'warnings/phone-almost-full'` names the scene `warnings`. See
  /// [AliveCache.preload]; the scenes that could not be loaded are returned.
  static Future<List<AliveError>> preload(Iterable<String> scenes, {AliveLibrary? library, AliveCache? cache, Duration keep = const Duration(seconds: 30)}) =>
      (cache ?? AliveCache.shared).preload(library ?? const AliveLibrary.assets(), [for (final s in scenes) s.split('/').first], keep: keep);

  /// The scene id.
  final String sceneId;
  final String? _first;

  /// Where the scene's files come from.
  final AliveLibrary library;

  /// The cache that shares and releases scenes.
  final AliveCache cache;

  /// Remembers the last pick of each pool, if given.
  final AliveStore? store;

  /// The run, for reproducible picks.
  final AliveRunContext? run;

  /// Tuning.
  final AliveOptions options;

  /// Called with every error, besides the [AliveFailed] event.
  final void Function(AliveError error)? onError;

  /// What the app adds to the scene: painters for its plugin nodes (`{"plugin": "waveform"}` in the art).
  final AliveExtensions extensions;

  final math.Random? _random;
  String? _look;
  late final Ticker _ticker;
  AppLifecycleListener? _lifecycle;
  AliveSceneHandle? _handle;
  AlivePlayer? _player;
  final _Status _status = _Status();
  final _Repaint _frame = _Repaint();
  final StreamController<AliveEvent> _events = StreamController<AliveEvent>.broadcast();
  final List<void Function(AlivePlayer)> _queued = [];
  AliveError? _error;
  Duration? _lastElapsed;
  double _lastPaint = -1;
  int _paintedPose = -1;
  bool _paused = false, _backgrounded = false, _systemReduced = false;

  /// Completes when the scene is loaded (or has failed: check [status]). Never completes with an error.
  late final Future<void> ready;

  /// Loading, ready, failed or disposed.
  ValueListenable<AliveStatus> get status => _status;

  /// Why it failed, if it did.
  AliveError? get error => _error;

  /// What happened: clips started and ended, cues, bubble text, state changes, failures.
  Stream<AliveEvent> get events => _events.stream;

  /// Notifies when a stage should repaint.
  Listenable get frame => _frame;

  /// The loaded scene (null until ready).
  AliveSceneData? get scene => _player?.data;

  /// The player (null until ready); for advanced use and tests.
  AlivePlayer? get player => _player;

  // While true, events wait in the player: the scene was ready inside the constructor (it was loaded already), and
  // whoever listens to [events] subscribes after the constructor returns.
  bool _holdEvents = false;

  Future<void> _load() async {
    try {
      // a scene loaded already (preloaded, or on another screen) is taken at once: ready inside the constructor
      final now = cache.tryAcquire(library, sceneId);
      final h = now ?? await cache.acquire(library, sceneId);
      if (_status.value == AliveStatus.disposed) {
        h.release();
        return;
      }
      _handle = h;
      final picker = VariantPicker(sceneId, store: store, run: run, random: _random, onError: _report);
      final pools = h.data.def.pools.keys;
      if (store != null && pools.isNotEmpty) {
        await picker.preload(pools);
        if (_status.value == AliveStatus.disposed) return;
      }
      final p = AlivePlayer(h.data, picker: picker, maxStep: options.maxStep)
        ..reducedMotion = reducedMotion
        ..extensions = extensions;
      _player = p;
      if (_look != null) p.setLook(_look);
      p.start();
      if (_first != null) p.play(_first);
      for (final q in _queued) {
        q(p);
      }
      _queued.clear();
      p.evaluate();
      _status.value = AliveStatus.ready;
      if (_constructing) {
        _holdEvents = true;
        scheduleMicrotask(() {
          _holdEvents = false;
          if (isDisposed) return;
          _events.add(AliveLoaded(p.now, sceneId));
          _deliver(p);
        });
      } else {
        _events.add(AliveLoaded(p.now, sceneId));
        _deliver(p);
      }
      _wake();
      _frame.ping();
    } on AliveError catch (e) {
      _fail(e);
    } catch (e) {
      _fail(AliveLoadError('$sceneId/scene.json', 'could not load scene "$sceneId": $e', e));
    }
  }

  void _fail(AliveError e) {
    if (_status.value == AliveStatus.disposed) return;
    _error = e;
    _ticker.stop();
    _status.value = AliveStatus.failed;
    _report(e);
  }

  void _report(AliveError e) {
    if (!_events.isClosed) _events.add(AliveFailed(_player?.now ?? 0, e));
    onError?.call(e);
    if (kDebugMode) debugPrint('alive: $e');
  }

  /// Report a drawing failure (the stage calls this); the controller fails and the stage falls back.
  void reportRenderError(Object error, StackTrace stack) {
    if (_status.value != AliveStatus.ready) return;
    // never change state in the middle of a paint
    SchedulerBinding.instance.addPostFrameCallback((_) => _fail(AliveRenderError('drawing "$sceneId" failed: $error', error, stack)));
  }

  // ---------- calls (queued until loaded, ignored after a failure or dispose) ----------

  void _do(void Function(AlivePlayer p) f) {
    final s = _status.value;
    if (s == AliveStatus.disposed || s == AliveStatus.failed) return;
    final p = _player;
    if (p == null) {
      _queued.add(f);
      return;
    }
    f(p);
    p.evaluate();
    _deliver(p);
    _wake();
    _frame.ping();
  }

  /// Play a clip, or a pool (a fresh variant each time, never the last one). [then] plays after it. [holdAt] names
  /// a cue to wait at (the flow continues it with [proceed], e.g. after a tap). [from] starts it that many seconds in
  /// (a question opened again shows him already settled: `play('peek', from: 99)` lands on its end).
  void play(String clipOrPool, {String? then, String? holdAt, double from = 0}) => _do((p) => p.play(clipOrPool, then: then, holdAt: holdAt, from: from));

  /// Offsets added to a layer on top of the clip (a lean with the drag speed, a live position): translation and
  /// rotation add, scale and opacity multiply. [clear] removes them. The pose repaints on the next frame.
  void setOffset(String layer, {double tx = 0, double ty = 0, double rot = 0, double sx = 1, double sy = 1, double opacity = 1, bool clear = false}) =>
      _do((p) => p.setOffset(layer, tx: tx, ty: ty, rot: rot, sx: sx, sy: sy, opacity: opacity, clear: clear));

  /// Have him look at [world] (a world point: a text caret, a button), or ahead again (null). The scene's
  /// `live.gaze` says what moves: layers toward the point (each by at most its offset), a kit figure's open eyes to
  /// the nearest of eight directions. Smooth unless the phone asks for reduced motion.
  void lookAt(ui.Offset? world) => _do((p) => p.lookAt(world?.dx, world?.dy));

  /// [lookAt] a point given in a stage's own coordinates (a widget's position inside a stage of [size] showing
  /// [viewport], as the stage fits it).
  void lookAtLocal(ui.Offset local, ui.Size size, {ui.Rect? viewport, BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) {
    final d = scene?.def;
    if (d == null) {
      // the scene is not loaded yet (the stage's transform needs its size): ask again once it is
      if (!isDisposed) unawaited(ready.then((_) => lookAtLocal(local, size, viewport: viewport, fit: fit, alignment: alignment)));
      return;
    }
    final t = stageTransform(size, viewport ?? ui.Rect.fromLTWH(0, 0, d.width, d.height), fit, alignment);
    lookAt(ui.Offset((local.dx - t.dx) / t.scaleX, (local.dy - t.dy) / t.scaleY));
  }

  /// Let a held clip go on, to its end or to the next [holdAt] cue.
  void proceed({String? holdAt}) => _do((p) => p.proceed(holdAt: holdAt));

  /// Is the clip waiting at a hold point?
  bool get holding => _player?.holding ?? false;

  /// The app state (the scene's `states`: its enter clip plays, then its idle clip).
  String? get appState => _player?.appState;
  set appState(String? s) {
    if (s != null) _do((p) => p.setAppState(s));
  }

  /// The mic level, 0..1. Use [AliveMic.fromDecibels] for flutter_sound's decibels.
  double get micLevel => _player?.input('mic') ?? 0;
  set micLevel(double v) => setInput('mic', v.clamp(0.0, 1.0));

  /// Set any input the scene binds or listens to.
  void setInput(String name, double value) {
    final p = _player;
    if (p == null) {
      _queued.add((p) => p.setInput(name, value));
      return;
    }
    if (_status.value != AliveStatus.ready) return;
    p.setInput(name, value);
    _wake();
  }

  /// A tap on him (or on another [target] the scene names): the scene's `tap:<target>` action.
  void tap({String target = 'fabio'}) => _do((p) => p.send('tap:$target'));

  /// An app event (`saved`, `micDenied`, ...): the scene's `on` table says what it does; unknown events are ignored.
  void send(String event) => _do((p) => p.send(event));

  /// The look (the scene's `looks`), or null.
  String? get look => _player?.look ?? _look;
  set look(String? id) {
    _look = id;
    _do((p) => p.setLook(id));
  }

  // ---------- kit figures: looks composed at run time ----------

  /// Dress a kit figure ([figure], or the scene's first) in [look]: a preset of the pack, parts per slot, tints, a
  /// skin, adjustments. Parts not loaded yet are loaded first; the future completes when he wears it. Names that do
  /// not resolve and clamped adjustments are reported as AliveFailed usage events; the rest of the look still applies.
  Future<void> dress(AliveLook look, {String? figure}) async {
    await ready;
    final d = scene, p = _player;
    if (d == null || p == null || isDisposed) return;
    final f = figure == null ? p.dress?.first : p.dress?.figures[figure];
    if (f == null) {
      _do((p) => p.dressFigure(figure, look)); // reports it
      return;
    }
    final kit = f.rig.kit;
    try {
      await AliveCache.loadKitParts(library, kit, {
        for (final w in resolveLook(kit.def, look).slots.values) ...[w.part, ...?kit.def.parts[w.part]?.split.values],
      });
    } on AliveError catch (e) {
      _report(e);
      return;
    }
    if (isDisposed) return;
    _do((p) => p.dressFigure(figure, look));
  }

  /// Put [part] (an id, or a name the slot knows: `'happy'` in `face`, `'wave'` in `near-paw`) in [slot] of a kit
  /// figure, mid moment if need be; null takes the slot off. [tint] and [adjust] change that slot only.
  Future<void> wear(String slot, String? part, {ui.Color? tint, AlivePartAdjust? adjust, String? figure}) {
    final current = kitLook(figure: figure) ?? const AliveLook();
    return dress(current.wear(slot, part, tint: tint, adjust: adjust), figure: figure);
  }

  /// Take a slot off (the hat, the glasses, what he holds).
  Future<void> takeOff(String slot, {String? figure}) => wear(slot, null, figure: figure);

  /// The look a kit figure wears (null before the scene loads, or when it has no figure).
  AliveLook? kitLook({String? figure}) => _player?.figureLook(figure);

  /// The part a kit figure's slot wears now (the playing clip's swap included), or null.
  String? worn(String slot, {String? figure}) {
    final d = _player?.dress;
    final f = figure == null ? d?.first : d?.figures[figure];
    final w = f?.worn(slot);
    return w == null || w.part.isEmpty ? null : w.part;
  }

  /// The art pack of a kit figure (its slots, parts by tag, looks), or null.
  KitDef? kit({String? figure}) {
    final d = _player?.dress;
    return (figure == null ? d?.first : d?.figures[figure])?.rig.kit.def;
  }

  /// Jump to [seconds] into the current clip.
  void seek(double seconds) => _do((p) => p.seek(seconds));

  /// The clip playing or holding.
  String? get clip => _player?.clip;

  /// Seconds into it.
  double get clipTime => _player?.clipTime ?? 0;

  /// The speech bubble now: text (null: none) and opacity. Draw it yourself so the copy can be translated.
  (String?, double) get bubble => _player?.bubble ?? (null, 0);

  /// A step channel of the clip (e.g. 'face', 'lamp').
  Object? channel(String name) => _player?.channel(name);

  /// A layer's value in the current frame (for data layers the app draws itself).
  double? value(String layer, LayerProp prop) => _player?.value(layer, prop);

  /// A named anchor's world point now.
  ui.Offset? anchor(String name) {
    final a = _player?.anchor(name);
    return a == null ? null : ui.Offset(a.$1, a.$2);
  }

  /// Draw one art file of the scene at rest, in scene units at the canvas's current transform (for app painters,
  /// e.g. the cassette inside the recorder). Does nothing until the scene is loaded.
  void paintArt(ui.Canvas canvas, String art) {
    final d = scene;
    if (d == null || d.disposed) return;
    d.compiled[art]?.paint(canvas, d.rest);
  }

  /// The world point [world] in a stage of [size] showing [viewport] (default: the whole scene).
  ui.Offset? worldToLocal(ui.Offset world, ui.Size size, {ui.Rect? viewport, BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) {
    final d = scene?.def;
    if (d == null) return null;
    final t = stageTransform(size, viewport ?? ui.Rect.fromLTWH(0, 0, d.width, d.height), fit, alignment);
    return ui.Offset(t.dx + world.dx * t.scaleX, t.dy + world.dy * t.scaleY);
  }

  // ---------- clock ----------

  /// Stop the clock (the pose holds; nothing fires).
  void pause() {
    _paused = true;
    _ticker.stop();
  }

  /// Start the clock again.
  void resume() {
    _paused = false;
    _wake();
  }

  /// Paused by the app?
  bool get paused => _paused;

  /// Are still poses shown (the OS asked, or the options say so)?
  bool get reducedMotion => _systemReduced;

  /// The stage passes the OS setting here.
  void setSystemReducedMotion(bool value) {
    if (options.reducedMotion != AliveReducedMotion.system || value == _systemReduced) return;
    _systemReduced = value;
    final p = _player;
    if (p != null) {
      p.reducedMotion = value;
      p.evaluate();
      _paintedPose = -1;
      _wake();
      _frame.ping();
    }
  }

  void _onLifecycle(AppLifecycleState s) {
    final bg = s == AppLifecycleState.paused || s == AppLifecycleState.hidden || s == AppLifecycleState.detached;
    if (bg == _backgrounded) return;
    _backgrounded = bg;
    if (bg) {
      _ticker.stop();
    } else {
      _wake();
    }
  }

  void _wake() {
    final p = _player;
    if (p == null || _paused || _backgrounded || _status.value != AliveStatus.ready) return;
    if ((p.busy || p.idleLife || p.inputsActive) && !_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final p = _player;
    if (p == null || _status.value != AliveStatus.ready) return;
    final last = _lastElapsed;
    _lastElapsed = elapsed;
    final dt = last == null ? 0.0 : (elapsed - last).inMicroseconds / 1e6;
    try {
      p.advance(dt);
      final busy = p.busy;
      bool repaint;
      if (p.reducedMotion) {
        repaint = p.poseVersion != _paintedPose;
      } else if (busy || p.poseVersion != _paintedPose) {
        repaint = true;
      } else {
        repaint = p.idleLife && (p.now - _lastPaint) >= 1 / options.idleFrameRate - 1e-6;
      }
      if (repaint) {
        p.evaluate();
        _lastPaint = p.now;
        _paintedPose = p.poseVersion;
        _frame.ping();
      }
      _deliver(p);
      if (!busy && !p.idleLife && !p.inputsActive) _ticker.stop();
    } catch (e, st) {
      _fail(AliveRenderError('advancing "$sceneId" failed: $e', e, st));
    }
  }

  void _deliver(AlivePlayer p) {
    if (_holdEvents) return;
    for (final e in p.takeEvents()) {
      if (e is AliveFailed) {
        onError?.call(e.error);
        if (kDebugMode) debugPrint('alive: ${e.error}');
      }
      if (!_events.isClosed) _events.add(e);
    }
  }

  /// Stop the clock and let go of the scene (its data is released when no other screen shows it).
  void dispose() {
    if (_status.value == AliveStatus.disposed) return;
    // no listener is told: the stages that listen are going too, and the tree may be locked
    _status.setSilently(AliveStatus.disposed);
    _ticker.dispose();
    _lifecycle?.dispose();
    _handle?.release();
    _handle = null;
    _player = null;
    _queued.clear();
    unawaited(_events.close());
    _frame.dispose();
    _status.dispose();
  }

  /// Has [dispose] run?
  bool get isDisposed => _status.value == AliveStatus.disposed;
}

class _Status extends ChangeNotifier implements ValueListenable<AliveStatus> {
  AliveStatus _v = AliveStatus.loading;
  @override
  AliveStatus get value => _v;
  set value(AliveStatus v) {
    if (v == _v) return;
    _v = v;
    notifyListeners();
  }

  void setSilently(AliveStatus v) => _v = v;
}

class _Repaint extends ChangeNotifier {
  bool _gone = false;
  void ping() {
    if (!_gone) notifyListeners();
  }

  @override
  void dispose() {
    _gone = true;
    super.dispose();
  }
}

/// How a stage maps world units onto its box.
class StageTransform {
  /// A transform.
  const StageTransform(this.dx, this.dy, this.scaleX, this.scaleY);

  /// Offset of the world origin in the box.
  final double dx, dy;

  /// Scale of world units.
  final double scaleX, scaleY;
}

/// The transform that fits [viewport] (world units) into [size] with [fit] and [alignment].
StageTransform stageTransform(ui.Size size, ui.Rect viewport, BoxFit fit, Alignment alignment) {
  final fs = applyBoxFit(fit, viewport.size, size);
  final sx = fs.source.width == 0 ? 1.0 : fs.destination.width / fs.source.width;
  final sy = fs.source.height == 0 ? 1.0 : fs.destination.height / fs.source.height;
  final dst = alignment.inscribe(fs.destination, ui.Offset.zero & size);
  final src = alignment.inscribe(fs.source, viewport);
  return StageTransform(dst.left - src.left * sx, dst.top - src.top * sy, sx, sy);
}

/// Mic levels for the controller.
abstract final class AliveMic {
  /// flutter_sound's decibels to 0..1, as the recording page maps them: (dB - floor) / range, clamped.
  static double fromDecibels(double db, {double floor = 28, double range = 58}) => ((db - floor) / range).clamp(0.0, 1.0);
}
