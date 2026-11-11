// The engine's core: one scene on one clock. Plain Dart (no widgets), deterministic: the same calls at the same times
// give the same frames at any frame rate. Clips are sampled at the exact time; behaviours and physics advance in
// fixed steps of 1/240 s, so 30, 60 and 120 Hz screens see the same poses.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../kit/figure.dart';
import '../kit/kit_def.dart' show KitHem;
import '../kit/look.dart';
import '../schema/art_def.dart' show PluginNode;
import '../schema/errors.dart';
import '../schema/scene_def.dart';
import '../schema/track.dart';
import 'events.dart';
import 'extensions.dart';
import 'layer_state.dart';
import 'scene_data.dart';
import 'variants.dart';

/// The fixed step of behaviours and physics, in seconds.
const double aliveStep = 1 / 240;

class _Worn {
  _Worn(this.def, this.layer, this.anchor);
  final WornDef def;
  final int layer, anchor; // anchor: the layer whose motion it follows (-1: the world)
  double x = 0, y = 0, vx = 0, vy = 0;
  double p1x = 0, p1y = 0, p2x = 0, p2y = 0;
  bool primed = false;
  // a kit hem slot: its lag shears the cloth (it does not move it) and its speed is the ripple's energy
  KitHem? hem;
  FigureDress? dress;
  String slot = '';
  double scale = 1, energy = 0;
  bool get settled => x.abs() < 1e-3 && y.abs() < 1e-3 && vx.abs() < 1e-2 && vy.abs() < 1e-2 && energy < 1e-3;
}

/// Plays one scene: clips, pools, states, events, inputs, live behaviours and worn-item physics.
class AlivePlayer implements AlivePluginHost, AliveFrame {
  /// A player for [data]. [maxStep] caps one advance (a long frame slows him down instead of skipping).
  AlivePlayer(this.data, {VariantPicker? picker, this.maxStep = 0.1})
      : picker = picker ?? VariantPicker(data.def.id),
        state = LayerState(data.layerIds.length),
        _slot = Int32List(data.layerIds.length)..fillRange(0, data.layerIds.length, -1) {
    final def = data.def;
    _group = def.live?.group == null ? -1 : data.layerIndex[def.live!.group!] ?? -1;
    for (final w in data.worn) {
      final li = data.layerIndex[w.layer]!;
      final anchor = w.on != null ? data.layerIndex[w.on!]! : data.parent[li];
      _worn.add(_Worn(w, li, anchor));
    }
    for (final b in def.bindings) {
      _bindings.add((b, data.layerIndex[b.layer]!));
    }
    final gaze = def.live?.gaze;
    if (gaze != null) {
      for (final e in gaze.layers.entries) {
        _gazeLayers.add((data.layerIndex[e.key]!, e.value.$1, e.value.$2));
      }
    }
    final blink = def.live?.blink;
    if (blink != null) {
      _blinkHide.addAll(blink.hide.map((id) => data.layerIndex[id]!));
      _blinkShow.addAll(blink.show.map((id) => data.layerIndex[id]!));
    }
    if (data.figures.isNotEmpty) {
      dress = AliveDress(data.figures, {for (final f in data.figures.values) f.id: AliveLook(preset: f.def.look, parts: f.def.parts)});
      state.dressing = dress;
      for (final f in dress!.figures.values) {
        for (final p in f.resolved.problems) {
          _usage('figure "${f.rig.id}": $p');
        }
      }
      // which clip channels swap which figure's slots: 'face' and 'slot:<slot>' address the first figure
      for (final c in def.clips.values) {
        final list = <(FigureDress, String, String)>[];
        for (final name in c.channels.keys) {
          if (name == 'face' && dress!.first != null && dress!.first!.rig.kit.def.slot.containsKey('face')) list.add((dress!.first!, 'face', name));
          if (!name.startsWith('slot:')) continue;
          final rest = name.substring(5), i = rest.indexOf(':');
          final f = i < 0 ? dress!.first : dress!.figures[rest.substring(0, i)];
          if (f != null) list.add((f, i < 0 ? rest : rest.substring(i + 1), name));
        }
        if (list.isNotEmpty) _swaps[c.id] = list;
      }
      FigureDress? figureOf(String? id) => id == null ? null : (id.isEmpty ? dress!.first : dress!.figures[id]);
      _gazeFigure = figureOf(def.live?.gaze?.figure);
      _blinkFigure = figureOf(def.live?.blink?.figure);
      // hem slots of figures that ride physics
      for (final f in dress!.figures.values) {
        if (!f.rig.def.physics) continue;
        for (final sl in f.rig.kit.def.slots) {
          final li = sl.hem == null ? null : data.layerIndex[f.rig.slotLayer(sl.id)];
          for (final w in _worn) {
            if (w.layer != li) continue;
            w
              ..hem = sl.hem
              ..dress = f
              ..slot = sl.id
              ..scale = f.rig.def.scale == 0 ? 1 : f.rig.def.scale.abs();
          }
        }
      }
      // a swap naming no part (or a slot the pack lacks) is skipped while it plays: say so once, at the start
      for (final c in def.clips.values) {
        for (final (f, slot, channel) in _swaps[c.id] ?? const <(FigureDress, String, String)>[]) {
          final k = f.rig.kit.def;
          if (!k.slot.containsKey(slot)) {
            _usage('clip "${c.id}": channel "$channel" names the slot "$slot", which the kit "${k.id}" does not have; its swaps are skipped');
            continue;
          }
          final seen = <String>{};
          for (final (_, v) in c.channels[channel]!) {
            if (v is! String || v.isEmpty || !seen.add(v)) continue;
            if (k.resolve(slot, v, skin: f.resolved.skin) == null) {
              _usage(slot == 'face'
                  ? 'clip "${c.id}": channel "$channel" names the face "$v", which the kit "${k.id}" does not have; he wears the neutral face there instead'
                  : 'clip "${c.id}": channel "$channel" names "$v", which no part of the kit "${k.id}" is for the $slot slot; that swap is skipped');
            }
          }
        }
      }
    }
    // where the gaze looks from: the scene says, else its first layer, else the figure's eyes
    if (gaze != null) {
      final from = gaze.from ?? (gaze.layers.isNotEmpty ? gaze.layers.keys.first : _gazeFigure?.rig.slotLayer('eyes'));
      _gazeFrom = from == null ? -1 : data.layerIndex[from] ?? -1;
    }
  }

  /// What the scene's kit figures wear (null: the scene has none).
  AliveDress? dress;

  // ---------- plugins ----------

  AliveExtensions _ext = AliveExtensions.none;
  bool _pluginsAnimate = false;

  /// The app's extensions (plugin painters). Set by the controller before the first frame; a plugin kind the scene
  /// draws with no painter is reported once.
  AliveExtensions get extensions => _ext;
  set extensions(AliveExtensions e) {
    _ext = e;
    final kinds = {for (final c in data.compiled.values) ...c.pluginKinds};
    state.plugins = kinds.isEmpty ? null : this;
    _pluginsAnimate = kinds.any((k) => e.nodes[k]?.animates ?? false);
    for (final k in kinds) {
      if (!e.nodes.containsKey(k)) _usage('scene "${_def.id}" draws plugin "$k", which the app did not register (AliveExtensions.nodes): it draws nothing');
    }
    _poseVersion++;
  }

  @override
  void paintPlugin(ui.Canvas canvas, PluginNode node) => _ext.nodes[node.kind]?.paint(canvas, node, this);

  @override
  double get time => now;
  final Map<String, List<(FigureDress, String, String)>> _swaps = {};

  /// The scene.
  final AliveSceneData data;

  /// Picks pool variants.
  final VariantPicker picker;

  /// The values of the last evaluated frame.
  final LayerState state;

  /// Largest advance per call, seconds.
  final double maxStep;

  /// Events since the last [takeEvents].
  final List<AliveEvent> _events = [];

  /// Stage clock in seconds.
  double now = 0;

  /// Show each clip's still pose; no breath, blink, nod or physics. Cues and clip ends keep their times.
  @override
  bool reducedMotion = false;

  /// Live behaviours and physics on (breath, blink, nod, worn items). Off plays the designed clips only (the
  /// "calm" setting, and the parity tests).
  bool live = true;

  bool get _calm => reducedMotion || !live;

  ClipDef? _clip;
  String? _pool;
  double _start = 0;
  String? _then;
  bool _ended = false;
  double? _hold; // clip seconds it waits at (a cue the app asked to hold at)
  String? _appState;
  String? _look;
  int _poseVersion = 0;
  // the clip's keys, and for each layer the keyed layer of the clip that drives it (-1: none)
  ClipKeys _keys = ClipKeys.none;
  final Int32List _slot;
  final Map<int, Float64List> _offsets = {}; // layer -> [tx, ty, rot, sx, sy, opacity] set by the app
  int _group = -1;
  final List<_Worn> _worn = [];
  final List<(BindingDef, int)> _bindings = [];
  final List<int> _blinkHide = [], _blinkShow = [];
  final Map<String, double> _input = {}, _smooth = {};
  double _physT = 0;
  double _loudFor = 0, _lastNod = -1e9;
  double? _nodAt;
  String? _bubbleText;
  bool _started = false;
  final Float64List _m = Float64List(6), _m2 = Float64List(6);
  late final List<List<int>?> _chains = List<List<int>?>.filled(data.layerIds.length, null);

  SceneDef get _def => data.def;

  // ---------- reading ----------

  /// The clip playing (or holding its last frame), if any.
  @override
  String? get clip => _clip?.id;

  /// The pool it was picked from, if any.
  String? get pool => _pool;

  /// Seconds into the current clip.
  @override
  double get clipTime => _clipTimeAt(now);

  /// The app state.
  String? get appState => _appState;

  /// The art to draw now: the current clip's own, or all of the scene's.
  List<String> get activeArt => _clip?.art ?? data.def.art;

  /// The look worn.
  String? get look => _look;

  /// Changes whenever the pose can change without the clock (a clip, look or state change); reduced motion
  /// repaints on this only.
  int get poseVersion => _poseVersion;

  /// Is the clip waiting at a hold point?
  bool get holding => _clip != null && _hold != null && !_ended && now - _start >= _hold!;

  /// Is a clip running, a nod under way or a worn item still settling? (Then every frame differs.)
  bool get busy {
    final c = _clip;
    if (c != null && (c.loop || !_ended) && !holding) return true;
    if (_pluginsAnimate && !reducedMotion) return true;
    if (_calm) return false;
    if (_nodAt != null) return true;
    if (_def.live?.gaze != null && _gazeMoving) return true;
    for (final w in _worn) {
      if (!w.settled) return true;
    }
    return false;
  }

  /// Is he breathing or blinking while nothing else moves? (Idle life.)
  bool get idleLife => !_calm && _def.live != null && (_def.live!.breath != null || _def.live!.blink != null);

  /// Take the events that happened since the last call.
  List<AliveEvent> takeEvents() {
    if (_events.isEmpty) return const [];
    final out = List<AliveEvent>.of(_events);
    _events.clear();
    return out;
  }

  /// A smoothed input value.
  @override
  double input(String name) => _smooth[name] ?? _input[name] ?? 0;

  /// A step channel of the current clip (face, lamp, ...) at the shown time.
  @override
  Object? channel(String name) => _clip?.channelAt(name, _shownClipTime());

  /// The bubble now: its text (null: none) and opacity.
  (String?, double) get bubble {
    final c = _clip;
    if (c == null || c.bubble.isEmpty) return (null, 0);
    final t = _shownClipTime();
    BubbleCue? cur;
    for (final b in c.bubble) {
      if (b.t <= t) {
        cur = b;
      } else {
        break;
      }
    }
    return cur == null ? (null, 0) : (cur.text, cur.opacity);
  }

  /// A layer value of the last frame (for data layers the app draws itself); null for an unknown layer.
  @override
  double? value(String layer, LayerProp prop) {
    final i = data.layerIndex[layer];
    if (i == null) return null;
    if (prop.isColour) {
      final c = prop == LayerProp.fill ? state.fill[i] : state.stroke[i];
      return c < 0 ? null : c.toDouble();
    }
    return state.get(i, prop);
  }

  /// A named anchor's world point in the last frame (it moves with its layer); null when unknown.
  (double, double)? anchor(String name) {
    final a = _def.anchors[name];
    if (a == null) return null;
    final li = a.layer == null ? -1 : data.layerIndex[a.layer!] ?? -1;
    if (li < 0) return (a.x, a.y);
    _worldOf(li, _m, fromState: true);
    return (_m[0] * a.x + _m[2] * a.y + _m[4], _m[1] * a.x + _m[3] * a.y + _m[5]);
  }

  /// A layer's world matrix [a, b, c, d, e, f] in the last frame (its ancestors' deltas, then its own), or null.
  List<double>? worldMatrix(String layer) {
    final i = data.layerIndex[layer];
    if (i == null) return null;
    _worldOf(i, _m, fromState: true);
    return List<double>.of(_m);
  }

  /// Worn-item lag of a layer (world units), for tests.
  (double, double)? wornOffset(String layer) {
    for (final w in _worn) {
      if (data.layerIds[w.layer] == layer) return (w.x, w.y);
    }
    return null;
  }

  // ---------- driving ----------

  void _emit(AliveEvent e) => _events.add(e);
  void _usage(String m) => _emit(AliveFailed(now, AliveUsageError(m)));

  /// Start the scene: its initial state or clip.
  void start() {
    if (_started) return;
    _started = true;
    final s = _def.initialState ?? (_def.initialClip == null && _def.states.isNotEmpty ? _def.states.keys.first : null);
    if (s != null) {
      setAppState(s);
    } else if (_def.initialClip != null) {
      play(_def.initialClip!);
    }
    evaluate();
  }

  /// Play a clip or a pool (a fresh variant, never the last one). [then] plays after it ends; otherwise the
  /// app state's idle clip does, or the last frame holds. [holdAt] names a cue to wait at until [proceed]. [from]
  /// starts it that many seconds in (cues before it do not fire): a screen opened again shows him already settled.
  bool play(String id, {String? then, String? holdAt, double from = 0}) {
    String clipId = id;
    String? pool;
    final p = data.pools[id];
    if (p != null) {
      final v = picker.pick(p);
      clipId = v.clip;
      pool = id;
      if (v.look != null) _setLook(v.look);
      // a variant that pulls from the kit dresses the first figure (from then on, as a look does)
      final f = dress?.first;
      if (f != null && (v.dress != null || v.wear.isNotEmpty)) {
        var look = v.dress != null ? AliveLook(preset: v.dress, tints: f.look.tints, skin: f.look.skin) : f.look;
        for (final w in v.wear.entries) {
          look = look.wear(w.key, w.value);
        }
        f.dress(look);
        _poseVersion++;
      }
    }
    final c = _def.clips[clipId];
    if (c == null) {
      _usage('no clip or pool "$id" in scene "${_def.id}"');
      return false;
    }
    if (then != null && !_def.clips.containsKey(then) && !_def.pools.containsKey(then)) {
      _usage('no clip or pool "$then" in scene "${_def.id}"');
      then = null;
    }
    final f = from.isFinite ? from.clamp(0.0, c.duration) : 0.0;
    _clip = c;
    _pool = pool;
    _start = now - f;
    _then = then;
    _ended = false;
    _hold = holdAt == null ? null : _cueTime(c, holdAt);
    _slot.fillRange(0, _slot.length, -1);
    final k = _keys = clipKeys(c);
    for (var j = 0; j < k.layerCount; j++) {
      _slot[k.layerAt(j)] = j;
    }
    _poseVersion++;
    _emit(AliveClipStarted(now, c.id, pool: pool, look: _look));
    if (f == 0) _fireCues(c, -1, 0);
    if (!c.loop && f >= c.duration && c.duration > 0) {
      // started at its end: it has ended (what follows plays on the next advance)
      _start = now - c.duration;
    }
    _bubbleCheck();
    return true;
  }

  double? _cueTime(ClipDef c, String cue) {
    for (final q in c.cues) {
      if (q.name == cue) return q.t;
    }
    _usage('no cue "$cue" in clip "${c.id}"');
    return null;
  }

  /// Let a held clip go on (to its end, or to the next hold at [holdAt]).
  void proceed({String? holdAt}) {
    final c = _clip;
    if (c == null || _hold == null) return;
    final at = _hold!;
    if (now - _start > at) _start = now - at; // it waited: continue from the hold point
    _hold = holdAt == null ? null : _cueTime(c, holdAt);
    _poseVersion++;
  }

  /// The time of a cue in the current clip, seconds.
  double? cueTime(String cue) {
    final c = _clip;
    if (c == null) return null;
    for (final q in c.cues) {
      if (q.name == cue) return q.t;
    }
    return null;
  }

  /// Enter an app state: its enter clip, then its idle clip.
  bool setAppState(String s) {
    final st = _def.states[s];
    if (st == null) {
      _usage('no state "$s" in scene "${_def.id}"');
      return false;
    }
    final from = _appState;
    _appState = s;
    _poseVersion++;
    _emit(AliveStateChanged(now, from, s));
    if (st.enter != null) {
      play(st.enter!, then: st.idle);
    } else if (st.idle != null) {
      play(st.idle!);
    }
    return true;
  }

  /// An app event or a tap (`tap:<target>`): the scene's `on` table says what it does. Events the scene does not
  /// list are ignored (a scene reacts only to what it was designed for).
  bool send(String event) {
    final a = _def.on[event];
    if (a == null) return false;
    if (a.state != null) setAppState(a.state!);
    if (a.play != null) play(a.play!, then: _def.states[_appState]?.idle);
    return true;
  }

  /// Set an input (0..1 for the mic level; any number for others).
  void setInput(String name, double v) {
    final x = v.isFinite ? v : 0.0;
    if (_input[name] == x) return;
    _input[name] = x;
    for (final (b, _) in _bindings) {
      if (b.input == name) {
        _poseVersion++;
        break;
      }
    }
  }

  /// Is an input still doing something (a level the nod listens to, a smoothed value still moving)?
  bool get inputsActive {
    if (_calm) return false;
    final nod = _def.live?.nod;
    if (nod != null && ((_input[nod.input] ?? 0) > 1e-3 || input(nod.input) > 1e-3 || _loudFor > 0)) return true;
    for (final (b, _) in _bindings) {
      if (((_smooth[b.input] ?? 0) - (_input[b.input] ?? 0)).abs() > 1e-4) return true;
    }
    return false;
  }

  /// Offsets the app adds to a layer on top of the clip (a lean that follows the drag speed, a live position):
  /// translation and rotation add, scale and opacity multiply. Null clears them. Returns false for an unknown layer.
  bool setOffset(String layer, {double tx = 0, double ty = 0, double rot = 0, double sx = 1, double sy = 1, double opacity = 1, bool clear = false}) {
    final i = data.layerIndex[layer];
    if (i == null) {
      _usage('no layer "$layer" in scene "${_def.id}"');
      return false;
    }
    if (clear) {
      _offsets.remove(i);
    } else {
      final o = _offsets[i] ??= Float64List(6);
      o
        ..[0] = tx
        ..[1] = ty
        ..[2] = rot
        ..[3] = sx
        ..[4] = sy
        ..[5] = opacity;
    }
    _poseVersion++;
    return true;
  }

  /// Look at a world point ([x], [y]), or ahead again (null). See the scene's `live.gaze`.
  void lookAt(double? x, double? y) {
    if (_def.live?.gaze == null) {
      _usage('scene "${_def.id}" has no live.gaze: nothing looks at the point');
      return;
    }
    _gazeAt = x == null || y == null ? null : (x, y);
    _poseVersion++;
  }

  /// Where he looks (a world point), or null (ahead).
  (double, double)? get lookingAt => _gazeAt;

  // the gaze: the point, the eyes' offset now (-1..1 of each layer's largest) and its speed, its goal
  (double, double)? _gazeAt;
  double _gx = 0, _gy = 0, _gvx = 0, _gvy = 0, _goalX = 0, _goalY = 0;
  int _gazeFrom = -1;
  final List<(int, double, double)> _gazeLayers = [];
  FigureDress? _gazeFigure, _blinkFigure;

  // settled within half a percent of the offset (a hundredth of a unit for a 2-unit offset)
  bool get _gazeMoving => (_gx - _goalX).abs() > 5e-3 || (_gy - _goalY).abs() > 5e-3 || _gvx.abs() > 2e-2 || _gvy.abs() > 2e-2;

  // the gaze's goal at stage time [ts]: toward the point from the eyes, full at the reach, nearer less
  void _gazeGoal(double ts) {
    final g = _def.live!.gaze!;
    final at = _gazeAt;
    if (at == null || _gazeFrom < 0) {
      _goalX = _goalY = 0;
      return;
    }
    _worldOf(_gazeFrom, _m, at: ts);
    final px = data.pivotX[_gazeFrom], py = data.pivotY[_gazeFrom];
    final ex = _m[0] * px + _m[2] * py + _m[4], ey = _m[1] * px + _m[3] * py + _m[5];
    final dx = at.$1 - ex, dy = at.$2 - ey, d = math.sqrt(dx * dx + dy * dy);
    if (d < 1e-6) {
      _goalX = _goalY = 0;
      return;
    }
    final k = math.min(1.0, d / (g.reach <= 0 ? 1 : g.reach)) / d;
    _goalX = dx * k;
    _goalY = dy * k;
  }

  void _applyOffset(int li, Float64List out) {
    final o = _offsets[li];
    if (o == null) return;
    out[LayerProp.tx.index] += o[0];
    out[LayerProp.ty.index] += o[1];
    out[LayerProp.rot.index] += o[2];
    out[LayerProp.sx.index] *= o[3];
    out[LayerProp.sy.index] *= o[4];
    out[LayerProp.opacity.index] *= o[5];
  }

  /// Dress a kit figure (null: the first) in [look]. Its parts must be loaded (the controller loads them).
  bool dressFigure(String? figure, AliveLook look) {
    final f = figure == null ? dress?.first : dress?.figures[figure];
    if (f == null) {
      _usage(figure == null ? 'scene "${_def.id}" has no kit figure' : 'no figure "$figure" in scene "${_def.id}"');
      return false;
    }
    f.dress(look);
    for (final p in f.resolved.problems) {
      _usage('figure "${f.rig.id}": $p');
    }
    _poseVersion++;
    return true;
  }

  /// The look a kit figure wears (null: the first figure).
  AliveLook? figureLook([String? figure]) => (figure == null ? dress?.first : dress?.figures[figure])?.look;

  /// Wear a look (null: none).
  bool setLook(String? id) {
    if (id != null && !_def.looks.containsKey(id)) {
      _usage('no look "$id" in scene "${_def.id}"');
      return false;
    }
    _setLook(id);
    return true;
  }

  void _setLook(String? id) {
    if (_look == id) return;
    _look = id;
    _poseVersion++;
  }

  /// Jump to [t] seconds into the current clip (no cues fire for the skipped part; physics settles).
  void seek(double t) {
    final c = _clip;
    if (c == null) return;
    final ct = t.clamp(0.0, c.duration);
    _start = now - ct;
    if (_hold != null && ct > _hold!) _hold = null;
    _ended = !c.loop && ct >= c.duration;
    for (final w in _worn) {
      w.primed = false;
      w.x = w.y = w.vx = w.vy = 0;
    }
    _poseVersion++;
  }

  /// Advance the clock by [dt] seconds (capped at [maxStep]): cues, clip ends, behaviours, physics.
  void advance(double dt) {
    if (!(dt > 0)) return;
    final target = now + math.min(dt, maxStep);
    for (var guard = 0; guard < 64; guard++) {
      final end = _clipEnd();
      final stop = math.min(target, end);
      _stepTo(stop);
      if (end <= target && _clip != null && !_ended) {
        _onClipEnd();
        if (now >= target) break;
        continue;
      }
      break;
    }
    _bubbleCheck();
  }

  double _clipEnd() {
    final c = _clip;
    if (c == null || _ended) return double.infinity;
    if (_hold != null && _hold! < c.duration) return double.infinity;
    if (c.loop) return c.duration <= 0 ? double.infinity : _start + c.duration;
    return _start + c.duration;
  }

  double _clipTimeAt(double t) {
    final c = _clip;
    if (c == null) return 0;
    if (_ended) return c.duration;
    final raw = (t - _start).clamp(0.0, c.duration);
    final h = _hold;
    return h != null && raw > h ? h : raw;
  }

  double _shownClipTime() => reducedMotion ? (_clip?.still ?? 0) : clipTime;

  void _stepTo(double t) {
    final c = _clip;
    final a = _clipTimeAt(now);
    while (_physT + aliveStep <= t + 1e-12) {
      _physT += aliveStep;
      _fixed(_physT);
    }
    now = t;
    if (c != null && !_ended) _fireCues(c, a, _clipTimeAt(t));
  }

  void _fireCues(ClipDef c, double a, double b) {
    for (final cue in c.cues) {
      if (cue.t > a && cue.t <= b) _emit(AliveCue(now, cue.name, c.id));
    }
  }

  void _onClipEnd() {
    final c = _clip!;
    _emit(AliveClipEnded(now, c.id));
    if (c.loop && c.duration > 0) {
      _start = now;
      _fireCues(c, -1, 0);
      return;
    }
    _ended = true;
    final next = _then ?? _def.states[_appState]?.idle;
    _then = null;
    if (next != null && next != c.id && next != _pool) play(next);
  }

  void _bubbleCheck() {
    final c = _clip;
    if (c == null || c.bubble.isEmpty) {
      if (_bubbleText != null) {
        _bubbleText = null;
        _emit(AliveBubble(now, null, c?.id ?? ''));
      }
      return;
    }
    final (text, _) = bubble;
    if (text != _bubbleText) {
      _bubbleText = text;
      _emit(AliveBubble(now, text, c.id));
    }
  }

  // ---------- fixed step: inputs, nod, physics ----------

  void _fixed(double ts) {
    for (final e in _input.entries) {
      final tau = _def.inputSmoothing[e.key] ?? 0;
      final s = _smooth[e.key] ?? e.value;
      _smooth[e.key] = tau <= 0 ? e.value : s + (e.value - s) * (1 - math.exp(-aliveStep / tau));
    }
    if (_calm) return;
    final nod = _def.live?.nod;
    if (nod != null) {
      if (_nodAt != null && ts - _nodAt! > nod.down + nod.gap + nod.up) _nodAt = null;
      final lv = input(nod.input);
      if (lv > nod.threshold) {
        _loudFor += aliveStep;
      } else {
        final c = _clip;
        final clipDone = !nod.afterClip || c == null || c.loop || _ended || _clipTimeAt(ts) >= c.duration;
        final stateOk = nod.states == null || nod.states!.contains(_appState);
        if (_loudFor > nod.minLoud && ts - _lastNod > nod.cooldown && clipDone && stateOk) {
          _nodAt = ts;
          _lastNod = ts;
        }
        _loudFor = 0;
      }
    }
    final gz = _def.live?.gaze;
    if (gz != null) {
      _gazeGoal(ts);
      if (gz.follow <= 0) {
        _gx = _goalX;
        _gy = _goalY;
        _gvx = _gvy = 0;
      } else {
        // critically damped: no overshoot, settles in about four times [follow]
        final w = 1 / gz.follow;
        _gvx += (w * w * (_goalX - _gx) - 2 * w * _gvx) * aliveStep;
        _gvy += (w * w * (_goalY - _gy) - 2 * w * _gvy) * aliveStep;
        _gx += _gvx * aliveStep;
        _gy += _gvy * aliveStep;
      }
    }
    for (final w in _worn) {
      _anchorPoint(w, ts);
      final px = _m2[4], py = _m2[5];
      if (!w.primed) {
        w.p1x = w.p2x = px;
        w.p1y = w.p2y = py;
        w.primed = true;
        continue;
      }
      var ax = (px - 2 * w.p1x + w.p2x) / (aliveStep * aliveStep), ay = (py - 2 * w.p1y + w.p2y) / (aliveStep * aliveStep);
      if ((px - w.p1x).abs() > 30 || (py - w.p1y).abs() > 30) {
        // a jump (a cut between poses), not a motion: no kick
        w.p1x = w.p2x = px;
        w.p1y = w.p2y = py;
        ax = ay = 0;
      }
      final d = w.def;
      final k = d.stiffness / d.mass, c = d.damping / d.mass;
      w.vx += (-k * w.x - c * w.vx - ax) * aliveStep;
      w.vy += (-k * w.y - c * w.vy - ay) * aliveStep;
      w.x += w.vx * aliveStep;
      w.y += w.vy * aliveStep;
      final len = math.sqrt(w.x * w.x + w.y * w.y);
      if (len > d.max) {
        w.x *= d.max / len;
        w.y *= d.max / len;
        w.vx *= 0.5;
        w.vy *= 0.5;
      }
      final hem = w.hem;
      if (hem != null) {
        final speed = math.sqrt(w.vx * w.vx + w.vy * w.vy) / w.scale / hem.energy;
        w.energy = math.max(w.energy * math.exp(-hem.settle * aliveStep), math.min(speed, KitHem.maxEnergy));
      }
      w.p2x = w.p1x;
      w.p2y = w.p1y;
      w.p1x = px;
      w.p1y = py;
    }
  }

  /// The worn item's pivot carried by its anchor's world matrix at [ts], into _m2[4], _m2[5].
  void _anchorPoint(_Worn w, double ts) {
    final px = data.pivotX[w.layer], py = data.pivotY[w.layer];
    if (w.anchor < 0) {
      _m2[4] = px;
      _m2[5] = py;
      return;
    }
    _worldOf(w.anchor, _m, at: ts);
    _m2[4] = _m[0] * px + _m[2] * py + _m[4];
    _m2[5] = _m[1] * px + _m[3] * py + _m[5];
  }

  double _nodOffset(double t) {
    final nod = _def.live?.nod;
    final at = _nodAt;
    if (nod == null || at == null) return 0;
    final u = t - at;
    if (u <= 0) return 0;
    if (u < nod.down) return nod.depth * nod.ease.at(u / nod.down, nod.down);
    if (u < nod.down + nod.gap) return nod.depth;
    if (u < nod.down + nod.gap + nod.up) return nod.depth * (1 - nod.ease.at((u - nod.down - nod.gap) / nod.up, nod.up));
    return 0;
  }

  /// One layer's numeric values at clip time [ct] and stage time [t] (tracks, then live behaviours), into [out].
  void _layerAt(int li, double ct, double t, Float64List out) {
    final b = li * LayerProp.numeric;
    for (var p = 0; p < LayerProp.numeric; p++) {
      out[p] = data.rest.values[b + p];
    }
    final j = _slot[li];
    if (j >= 0) {
      final k = _keys;
      for (var i = k.firstTrack(j), e = k.endTrack(j); i < e; i++) {
        final p = k.propOf(i);
        if (p < LayerProp.numeric) out[p] = k.number(i, ct);
      }
    }
    _applyOffset(li, out);
    if (li == _group && !_calm) {
      final br = _def.live?.breath;
      if (br != null && br.period > 0) {
        final k = 1 + br.amp * math.sin(t * 2 * math.pi / br.period);
        out[LayerProp.sx.index] *= k;
        out[LayerProp.sy.index] *= k;
      }
      out[LayerProp.ty.index] += _nodOffset(t);
    }
  }

  final Float64List _vals = Float64List(LayerProp.numeric), _d6 = Float64List(6);

  /// World matrix of a layer: its ancestors' deltas, outer first, then its own. From the last frame's values
  /// ([fromState]) or evaluated at stage time [at].
  void _worldOf(int li, Float64List out, {bool fromState = false, double? at}) {
    final chain = _chains[li] ??= () {
      final c = <int>[];
      for (var i = li; i >= 0 && c.length <= 64; i = data.parent[i]) {
        c.add(i);
      }
      return c;
    }();
    out
      ..[0] = 1
      ..[1] = 0
      ..[2] = 0
      ..[3] = 1
      ..[4] = 0
      ..[5] = 0;
    final ct = at == null ? 0.0 : (reducedMotion ? (_clip?.still ?? 0) : _clipTimeAt(at));
    for (var k = chain.length - 1; k >= 0; k--) {
      final i = chain[k];
      final Float64List v;
      if (fromState) {
        v = _vals;
        for (var p = 0; p < LayerProp.numeric; p++) {
          v[p] = state.values[i * LayerProp.numeric + p];
        }
      } else {
        _layerAt(i, ct, at!, _vals);
        v = _vals;
      }
      final d = _d6;
      delta6Into(data.pivotX[i], data.pivotY[i], v[0], v[1], v[2], v[3], v[4], d, v[LayerProp.kx.index], v[LayerProp.ky.index]);
      final a = out[0], b = out[1], c = out[2], dd = out[3], e = out[4], f = out[5];
      out
        ..[0] = a * d[0] + c * d[1]
        ..[1] = b * d[0] + dd * d[1]
        ..[2] = a * d[2] + c * d[3]
        ..[3] = b * d[2] + dd * d[3]
        ..[4] = a * d[4] + c * d[5] + e
        ..[5] = b * d[4] + dd * d[5] + f;
    }
  }

  // ---------- the frame ----------

  /// Fill [state] for the current time.
  void evaluate() {
    state.copyFrom(data.rest);
    final ct = _shownClipTime();
    final c = _clip;
    final n = state.count;
    final dr = dress;
    if (dr != null) {
      // the clip's swaps (an action's paw poses, its expressions) over each figure's look
      for (final f in dr.figures.values) {
        f.clearClip();
        f.clearLive();
        f.time = _calm ? 0 : now;
      }
      if (_calm) {
        for (final w in _worn) {
          if (w.hem != null) w.dress!.setHem(w.slot, 0, 0);
        }
      }
      final sw = c == null ? null : _swaps[c.id];
      if (sw != null) {
        for (final (f, slot, channel) in sw) {
          final v = c!.channelAt(channel, ct);
          f.clipSwap(slot, v is String ? v : null);
        }
      }
    }
    if (c != null) {
      final k = _keys;
      for (var j = 0, nl = k.layerCount; j < nl; j++) {
        final li = k.layerAt(j), b = li * LayerProp.numeric;
        for (var i = k.firstTrack(j), e = k.endTrack(j); i < e; i++) {
          final p = k.propOf(i);
          if (p < LayerProp.numeric) {
            state.values[b + p] = k.number(i, ct);
          } else if (p == LayerProp.fill.index) {
            state.fill[li] = k.colour(i, ct);
          } else {
            state.stroke[li] = k.colour(i, ct);
          }
        }
      }
    }
    for (final e in _offsets.entries) {
      final b = e.key * LayerProp.numeric, o = e.value;
      state.values[b + LayerProp.tx.index] += o[0];
      state.values[b + LayerProp.ty.index] += o[1];
      state.values[b + LayerProp.rot.index] += o[2];
      state.values[b + LayerProp.sx.index] *= o[3];
      state.values[b + LayerProp.sy.index] *= o[4];
      state.values[b + LayerProp.opacity.index] *= o[5];
    }
    final look = _look == null ? null : _def.looks[_look];
    if (look != null) {
      for (final id in look.show) {
        final i = data.layerIndex[id];
        if (i != null && (_slot[i] < 0 || _keys.trackOf(_slot[i], LayerProp.opacity.index) < 0)) state.set(i, LayerProp.opacity, 1);
      }
      for (final id in look.hide) {
        final i = data.layerIndex[id];
        if (i != null) state.hidden[i] = 1;
      }
    }
    for (final (b, li) in _bindings) {
      final v = input(b.input);
      final u = b.from1 == b.from0 ? 0.0 : ((v - b.from0) / (b.from1 - b.from0)).clamp(0.0, 1.0);
      state.set(li, b.prop, b.to0 + (b.to1 - b.to0) * u);
    }
    final gz = _def.live?.gaze;
    if (gz != null) {
      // the app's point: followed smoothly, or (reduced motion, calm) taken at once
      if (_calm) {
        _gazeGoal(now);
        _gx = _goalX;
        _gy = _goalY;
        _gvx = _gvy = 0;
      }
      for (final (li, mx, my) in _gazeLayers) {
        state.set(li, LayerProp.tx, state.get(li, LayerProp.tx) + _gx * mx);
        state.set(li, LayerProp.ty, state.get(li, LayerProp.ty) + _gy * my);
      }
      final f = _gazeFigure;
      if (f != null) {
        f.liveSwap('eyes', null);
        final m = math.sqrt(_gx * _gx + _gy * _gy);
        final pill = f.pillEyes();
        if (pill != null && m > gz.dead) {
          // the nearest of eight directions (screen y points down)
          const dirs = ['right', 'down-right', 'down', 'down-left', 'left', 'up-left', 'up', 'up-right'];
          final a = math.atan2(_gy, _gx);
          final k = ((a / (math.pi / 4)).round() % 8 + 8) % 8;
          f.liveSwap('eyes', 'look-${dirs[k]}');
        }
      }
    }
    if (_calm || n == 0) return;
    final blink = _def.live?.blink;
    if (blink != null && blink.every > 0) {
      final face = c?.channelAt('face', ct);
      final u = ((now + blink.phase) % blink.every) / blink.duration;
      if ((blink.face == null || face == blink.face) && u < 1) {
        for (final i in _blinkHide) {
          state.set(i, LayerProp.opacity, 0);
        }
        for (final i in _blinkShow) {
          state.set(i, LayerProp.opacity, 1);
        }
        // a kit figure's open eyes: lids half, shut, half (the pack's blink action: 55, 90 and 75 of 220 ms)
        final f = _blinkFigure;
        final pill = f?.pillEyes();
        if (f != null && pill != null) {
          final stage = u < 0.25 || u >= 0.66 ? 'half' : 'closed';
          f.liveSwap('eyes', pill == 'wide' ? 'blink-$stage-wide' : 'blink-$stage');
        }
      }
    }
    if (_group >= 0) {
      final br = _def.live?.breath;
      if (br != null && br.period > 0) {
        final k = 1 + br.amp * math.sin(now * 2 * math.pi / br.period);
        state.set(_group, LayerProp.sx, state.get(_group, LayerProp.sx) * k);
        state.set(_group, LayerProp.sy, state.get(_group, LayerProp.sy) * k);
      }
      final nod = _nodOffset(now);
      if (nod != 0) state.set(_group, LayerProp.ty, state.get(_group, LayerProp.ty) + nod);
    }
    for (final w in _worn) {
      if (w.x == 0 && w.y == 0) {
        if (w.hem != null) w.dress!.setHem(w.slot, 0, w.energy);
        continue;
      }
      // the lag is in world units; the layer's translation is in its parent's space
      final parent = data.parent[w.layer];
      var lx = w.x, ly = w.y;
      if (parent >= 0) {
        _worldOf(parent, _m, fromState: true);
        final det = _m[0] * _m[3] - _m[1] * _m[2];
        if (det.abs() > 1e-9) {
          lx = (_m[3] * w.x - _m[2] * w.y) / det;
          ly = (-_m[1] * w.x + _m[0] * w.y) / det;
        }
      }
      if (w.hem != null) {
        // a hem does not move with the lag: its cloth shears by it and its ripple grows with the energy
        w.dress!.setHem(w.slot, lx, w.energy);
        continue;
      }
      state.set(w.layer, LayerProp.tx, state.get(w.layer, LayerProp.tx) + lx);
      state.set(w.layer, LayerProp.ty, state.get(w.layer, LayerProp.ty) + ly);
      if (w.def.tilt != 0) state.set(w.layer, LayerProp.rot, state.get(w.layer, LayerProp.rot) - w.def.tilt * w.x);
    }
  }
}
