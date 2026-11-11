// Fabio in the app update dialog: the dev team's dialog (3 Nov) with Fabio in the art's place. The new version
// is his own upgrade. Four scenes, two concepts in two versions:
//
//   au-boost-v1   Boost V1, Lift-off: a space helmet and a jetpack; he springs into a hover.
//   au-boost-v2   Boost V2, Boost lap: the same gear; he blasts off the right edge and comes back in from the left.
//   au-level-v1   Level-up V1, Star power: three stars from the phone, he grows a size, a crown drops on.
//   au-level-v2   Level-up V2, Level-up beam: a beam lifts him, a crown appears, he lands a size bigger.
//
// Each scene has the same states, driven by the dialog:
//
//   available   when the dialog opens: he walks in from the dialog's left edge with the phone, the update fills its
//               arrow and upgrades him, then he waits in an upgraded loop (loop A or loop B, a different one each time
//               the dialog opens).
//   now         Yes, Update Now: a payoff under a second. Open the store in the same tap; this plays over it and
//               never holds it up.
//   later       Maybe later: a calm goodbye with one small wave, then he rests.
//
// With reduced motion on (the phone's setting), every state shows its still pose instead.
//
// A tap can come at any moment of a loop, while each payoff opens on his upgraded pose (the loop's first frame). So the
// widget blends him in: it starts the payoff at its "react" cue (where his face changes), and over 5 to 9 frames
// (0.17 to 0.3 s; the Boost flames swing furthest) glides every part that shows from where the loop had it to where
// the payoff has it (the engine's live offsets: translation, turn and scale). Measured at ten moments of the loops in
// all four scenes: nothing moves more than 1.15 pt a frame beyond the payoff's own motion (the test's gate is 1.5 pt).
// His face changes once, on the tap. A tap during the walk in glides over 12 frames (0.4 s). The loop's own accents
// (a glint, a sparkle, a puff) end on the tap.
//
// Size: the scene is the dialog's top 136 pt, the 32 pt above the art band and the 104 pt band where the 80 pt logo
// was, designed on a dialog 396 pt wide. The widget is 136 pt tall and as wide as the dialog; Fabio keeps his size (83
// pt tall) and stays centred, so a narrower dialog crops the sides of the walk in (he still enters from its edge). Put
// it at the very top of the dialog, full width, in place of the top padding and the logo, and clip it with the dialog's
// rounded corners. Nothing is drawn below the band, so the title starts where it did.
import 'dart:async';
import 'dart:math' as math;

import 'package:alive/alive.dart';
import 'package:flutter/material.dart';

/// Drives the dialog's choices into [AppUpdateFabio]. Call [onUpdateNow] or [onLater] from the button's own tap.
class AppUpdateFabioController {
  _AppUpdateFabioState? _state;

  /// Yes, Update Now: the payoff. Open the store in the same tap; nothing waits for it.
  void onUpdateNow() => _state?._set('now');

  /// Maybe later: the goodbye.
  void onLater() => _state?._set('later');

  /// The engine's controller while the widget is shown (its status, clip and events), or null.
  AliveController? get alive => _state?._fabio;
}

class AppUpdateFabio extends StatefulWidget {
  const AppUpdateFabio({
    super.key,
    required this.scene,
    this.controller,
    this.library,
    this.store,
    this.fallback,
    this.onError,
    this.blend = true,
    this.scale = 1,
    this.initialState,
  });

  /// One of [scenes].
  final String scene;
  final AppUpdateFabioController? controller;

  /// Where the scenes are (default: the app's assets under assets/alive). Give [preload] the same one.
  final AliveLibrary? library;

  /// Remembers which loop played last across launches (optional; without it the loop is picked at random).
  final AliveStore? store;

  /// Shown if the scene cannot load or draw, for example the app's logo. Default: nothing.
  final WidgetBuilder? fallback;
  final void Function(Object error)? onError;

  /// Blend him from the loop's pose into a payoff (on by default; off, a payoff starts on its first frame).
  final bool blend;

  /// His size: 1 is the scene's own size (body 83 pt, 136 pt tall); [dialogScale] (110 / 83) matches the dev team's
  /// dialog. The widget is [height] x [scale] tall; the scene keeps its proportions and stays centred.
  final double scale;

  /// Fabla: the state to start in instead of "available" (for example "later", to open on his goodbye with no walk
  /// in). Applied as the scene loads, so its first frame is already in this state.
  final String? initialState;

  /// The dev team's dialog of 3 Nov: their Fabio's body is 110 pt tall, 57.6 to 168 pt below the dialog's top. At
  /// 110 / 83 ours (the widget at the dialog's very top) has his head at 59.6 pt and his feet at 169.6 pt.
  static const double dialogScale = 110 / 83;

  static const List<String> scenes = ['au-boost-v1', 'au-boost-v2', 'au-level-v1', 'au-level-v2'];

  /// The scene's world: the dialog's width it was designed on, and the height the widget takes.
  static const double designWidth = 396, height = 136;

  /// The art band (where the logo was) inside that height: from 32 pt to 136 pt.
  static const double bandTop = 32, bandHeight = 104;

  /// Load the scene before the dialog shows (when the app knows an update is waiting), so he is ready on its first
  /// frame. Returns the scenes that could not be loaded; never throws.
  static Future<List<AliveError>> preload(String scene, {AliveLibrary? library}) =>
      AliveController.preload([scene], library: library ?? const AliveLibrary.assets());

  @override
  State<AppUpdateFabio> createState() => _AppUpdateFabioState();
}

class _AppUpdateFabioState extends State<AppUpdateFabio> with SingleTickerProviderStateMixin {
  late final AliveController _fabio = AliveController(
    vsync: this,
    scene: widget.scene, // the scene starts in its state "available": the walk in and the upgrade, then a loop
    library: widget.library ?? const AliveLibrary.assets(),
    store: widget.store,
    onError: (e) => widget.onError?.call(e),
  );

  void _set(String state) {
    if (_fabio.appState == state) return;
    final a = _fabio, p = a.player, s = a.scene;
    if (!widget.blend || p == null || s == null || a.reducedMotion) {
      _endBlend();
      a.appState = state;
      return;
    }
    // the pose on screen now (a blend still running included)
    final ids = s.layerIds, parent = s.parent;
    List<List<double>> read() => [
          for (final id in ids) [for (final q in _props) a.value(id, q) ?? q.neutral],
        ];
    double shown(List<List<double>> v, int i) {
      var o = 1.0;
      for (var j = i; j >= 0; j = parent[j]) {
        o *= v[j][5];
      }
      return o;
    }

    final before = read();
    _endBlend();
    final walkingIn = a.clip == 'enter';
    a.appState = state; // plays the state's clip from its start
    final clip = s.def.clips[a.clip];
    final react = clip?.cues.where((c) => c.name == 'react').map((c) => c.t).firstOrNull;
    if (react != null) a.seek(react); // his reaction, without the upgraded pose it opens on
    final after = read();
    // every part that shows before and after: the difference, eased away
    final d = <int, List<double>>{};
    for (var i = 0; i < ids.length; i++) {
      if (shown(before, i) < .02 || shown(after, i) < .02) continue;
      final b = before[i], f = after[i];
      // the differences: translation, turn and scale, all as amounts added (the scale's offset is worked out each
      // frame from the payoff's own scale then, so a flame that shrinks in the payoff does not carry the blend with it)
      final e = <double>[b[0] - f[0], b[1] - f[1], b[2] - f[2], b[3] - f[3], b[4] - f[4], 1, 1];
      if ((b[6] - f[6]).abs() > .01) {
        // a skew differs (a flame's sway): offsets carry no skew, so the turn and scale that come closest to the
        // loop's drawing over the payoff's skew stand in for it
        final (rot, sx, sy) = _fit(b, f[6]);
        e[2] = rot - f[2];
        e[3] = sx - f[3];
        e[4] = sy - f[4];
      }
      if (e[0].abs() < .01 && e[1].abs() < .01 && e[2].abs() < .01 && e[3].abs() < 1e-4 && e[4].abs() < 1e-4) continue;
      d[i] = e;
    }
    if (d.isEmpty) return;
    // the farthest any part's drawing goes (its pivot and four points 25 pt around it, through its parents)
    final pb = _points(s, before), pa = _points(s, after);
    var most = 0.0;
    for (var i = 0; i < ids.length; i++) {
      if (shown(before, i) < .02 || shown(after, i) < .02) continue; // a part moves with its parents too
      for (var k = 0; k < 10; k += 2) {
        most = math.max(most, math.sqrt(math.pow(pb[i][k] - pa[i][k], 2) + math.pow(pb[i][k + 1] - pa[i][k + 1], 2)));
      }
    }
    _blend = d;
    _blendFrom = a.clipTime;
    _blendClip = a.clip;
    // 5 frames, or as many as spread the largest move over 1 pt a frame (the jetpack's flames swing further than he
    // does), at most 12 (a tap during the walk in: a quick glide to his place)
    _blendFrames = walkingIn ? 12 : (most / 1.0).ceil().clamp(5, 12);
    _apply(1);
    p.evaluate();
    a.frame.addListener(_onFrame);
  }

  static const _props = [LayerProp.tx, LayerProp.ty, LayerProp.rot, LayerProp.sx, LayerProp.sy, LayerProp.opacity, LayerProp.kx];

  /// The turn (degrees, the engine's sign) and scale that, over a skew of [kx] degrees, come closest to the drawing of
  /// pose [v] ([_props]): R(-rot) S(sx, sy) K(kx) against R(-v.rot) S(v.sx, v.sy) K(v.kx), the turn found by a fine
  /// search around the drawing's own (least squares on the two axes).
  static (double, double, double) _fit(List<double> v, double kx) {
    final r = -v[2] * math.pi / 180, c = math.cos(r), sn = math.sin(r), tk = math.tan(v[6] * math.pi / 180);
    // the pose's matrix [[m00, m01], [m10, m11]], then without the skew kept: N = M K(kx)^-1
    final m00 = c * v[3], m10 = sn * v[3], m01 = c * v[3] * tk - sn * v[4], m11 = sn * v[3] * tk + c * v[4];
    final ta = math.tan(kx * math.pi / 180);
    final n00 = m00, n10 = m10, n01 = m01 - m00 * ta, n11 = m11 - m10 * ta;
    final f0 = math.atan2(n10, n00);
    var best = f0, score = -1.0;
    for (var k = -300; k <= 300; k++) {
      final f = f0 + k * .0005, cf = math.cos(f), sf = math.sin(f);
      final ax = n00 * cf + n10 * sf, ay = -n01 * sf + n11 * cf;
      if (ax * ax + ay * ay > score) {
        score = ax * ax + ay * ay;
        best = f;
      }
    }
    final cf = math.cos(best), sf = math.sin(best);
    return (-best * 180 / math.pi, n00 * cf + n10 * sf, -n01 * sf + n11 * cf);
  }

  /// Each layer's pivot and four points 25 pt around it in the world for a pose ([_props] per layer), through its
  /// parents: the engine's own delta about each pivot, T(p + t) R(-rot) S(sx, sy) K(kx) T(-p).
  static List<List<double>> _points(AliveSceneData s, List<List<double>> v) {
    final n = s.layerIds.length;
    final m = List<List<double>?>.filled(n, null);
    List<double> world(int i) {
      final w = m[i];
      if (w != null) return w;
      final x = v[i], px = s.pivotX[i], py = s.pivotY[i];
      final r = -x[2] * math.pi / 180, c = math.cos(r), sn = math.sin(r), k = math.tan(x[6] * math.pi / 180);
      final a = c * x[3], b = sn * x[3], cc = c * x[3] * k - sn * x[4], d = sn * x[3] * k + c * x[4];
      final own = [a, b, cc, d, px + x[0] - (a * px + cc * py), py + x[1] - (b * px + d * py)];
      final p = s.parent[i];
      if (p < 0) return m[i] = own;
      final q = world(p);
      return m[i] = [
        q[0] * own[0] + q[2] * own[1], q[1] * own[0] + q[3] * own[1],
        q[0] * own[2] + q[2] * own[3], q[1] * own[2] + q[3] * own[3],
        q[0] * own[4] + q[2] * own[5] + q[4], q[1] * own[4] + q[3] * own[5] + q[5],
      ];
    }

    return [
      for (var i = 0; i < n; i++)
        () {
          final w = world(i), px = s.pivotX[i], py = s.pivotY[i];
          return [
            for (final (dx, dy) in const [(0.0, 0.0), (-25.0, -25.0), (25.0, -25.0), (-25.0, 25.0), (25.0, 25.0)]) ...[
              w[0] * (px + dx) + w[2] * (py + dy) + w[4],
              w[1] * (px + dx) + w[3] * (py + dy) + w[5],
            ],
          ];
        }(),
    ];
  }
  Map<int, List<double>>? _blend;
  double _blendFrom = 0;
  String? _blendClip;
  int _blendFrames = 5;

  /// Weight [w] (1 at the tap, 0 when the payoff has him) of every part's difference, as the engine's live offsets.
  /// Translation and turn add; scale multiplies, so its offset is the wanted scale over the payoff's own scale this
  /// frame (the pose was evaluated with the last offsets: the payoff's own is the shown scale over them).
  void _apply(double w) {
    final p = _fabio.player, ids = _fabio.scene?.layerIds;
    final d = _blend;
    if (p == null || ids == null || d == null) return;
    for (final e in d.entries) {
      final v = e.value, id = ids[e.key];
      double scale(int k, LayerProp q) {
        final own = (p.value(id, q) ?? 1) / v[k + 2]; // the payoff's own scale: the shown one without the last offset
        final o = own.abs() < 1e-6 ? 1.0 : (own + v[k] * w) / own;
        v[k + 2] = o;
        return o;
      }

      p.setOffset(id, tx: v[0] * w, ty: v[1] * w, rot: v[2] * w, sx: scale(3, LayerProp.sx), sy: scale(4, LayerProp.sy));
    }
  }

  /// Each frame of the blend (the engine has advanced and evaluated the clip): the next weight, then the pose again.
  void _onFrame() {
    final a = _fabio, p = a.player;
    if (_blend == null || p == null) return;
    final u = (a.clipTime - _blendFrom) * 30 / _blendFrames;
    if (a.clip != _blendClip || u >= 1) {
      _endBlend();
      p.evaluate();
      return;
    }
    _apply(1 - u.clamp(0.0, 1.0)); // an even glide: the payoff is moving from the tap on
    p.evaluate();
  }

  void _endBlend() {
    final d = _blend, p = _fabio.player, ids = _fabio.scene?.layerIds;
    _blend = null;
    _fabio.frame.removeListener(_onFrame);
    if (d == null || p == null || ids == null) return;
    for (final i in d.keys) {
      p.setOffset(ids[i], clear: true);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    if (widget.initialState != null) _fabio.appState = widget.initialState; // queued until the scene has loaded
  }

  @override
  void didUpdateWidget(AppUpdateFabio old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller!._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    _fabio.frame.removeListener(_onFrame);
    _fabio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppUpdateFabio.height * widget.scale,
        width: double.infinity,
        child: AliveStage(
          controller: _fabio,
          fit: BoxFit.fitHeight, // his size stays; the width follows the dialog
          clip: true,
          fallback: (c, e) => widget.fallback?.call(c) ?? const SizedBox.shrink(),
          excludeFromSemantics: true, // the dialog's title says what this is
        ),
      );
}

/// An example of the placement: the dev team's dialog as built on 3 Nov (their words, buttons and sizes), with
/// [AppUpdateFabio] where their art was, at their Fabio's size ([AppUpdateFabio.dialogScale]).
///
/// The ask: the title, Yes, Update Now, Maybe later and Do not show again. Yes plays the payoff ([onUpdateNow]: open
/// the store in the same tap). Maybe later plays the goodbye, then the same dialog turns into the reminder (a quick
/// cross fade): a close X, "You can still update Fabla" and its line; Fabio stays where he is, resting in the pose the
/// goodbye ends on (no new walk in). The X calls [onClose] (by default it pops the dialog). After a choice the buttons
/// take no more taps.
class AppUpdateDialogExample extends StatefulWidget {
  const AppUpdateDialogExample(
      {super.key, required this.scene, this.onUpdateNow, this.onLater, this.onClose, this.onDoNotShowAgain, this.library});
  final String scene;
  final VoidCallback? onUpdateNow, onLater, onClose;
  final ValueChanged<bool>? onDoNotShowAgain;
  final AliveLibrary? library;

  /// Their copy, verbatim.
  static const title = 'A new version of Fabla is available. Would you like to update?',
      updateNow = 'Yes, Update Now',
      later = 'Maybe later',
      doNotShow = 'Do not show again',
      stillTitle = 'You can still update Fabla',
      stillBody = 'You can update Fabla to the latest version anytime through the App Store';

  @override
  State<AppUpdateDialogExample> createState() => _AppUpdateDialogExampleState();
}

class _AppUpdateDialogExampleState extends State<AppUpdateDialogExample> {
  final _fabio = AppUpdateFabioController();
  bool _chosen = false, _still = false, _doNotShow = false;

  static const _blue = Color(0xFF008DFF), _ink = Color(0xFF141514);
  static const _font = 'Rubik';

  void _updateNow() {
    if (_chosen) return;
    _chosen = true;
    _fabio.onUpdateNow(); // the payoff, and the store opens in the same tap
    widget.onUpdateNow?.call();
  }

  Timer? _timer;
  StreamSubscription<AliveEvent>? _sub;

  void _later() {
    if (_chosen) return;
    _chosen = true;
    _fabio.onLater(); // the goodbye
    widget.onLater?.call();
    void reminder() {
      if (mounted) setState(() => _still = true);
    }

    final a = _fabio.alive;
    if (a == null || a.status.value != AliveStatus.ready) {
      _timer = Timer(const Duration(milliseconds: 300), reminder);
      return;
    }
    // the reminder comes when the goodbye has played (its clip's end, or at most a little past its 2.5 s)
    void played() {
      _timer?.cancel();
      _sub?.cancel();
      _sub = null;
      _timer = Timer(const Duration(milliseconds: 250), reminder);
    }

    _sub = a.events.listen((e) {
      if (e is AliveClipEnded && e.clip == 'later') played();
    });
    _timer = Timer(const Duration(milliseconds: 3200), played);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _ask() => Padding(
        key: const ValueKey('ask'),
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 34),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(AppUpdateDialogExample.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _font, fontSize: 20, height: 1.4, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _updateNow,
              child: const Text(AppUpdateDialogExample.updateNow,
                  style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _later,
              child: const Text(AppUpdateDialogExample.later,
                  style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w500, color: _blue)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() => _doNotShow = !_doNotShow);
                widget.onDoNotShowAgain?.call(_doNotShow);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _doNotShow ? _blue : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _doNotShow ? _blue : const Color(0xFF3C3C40), width: 1.6),
                    ),
                    child: _doNotShow ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 14),
                  const Text(AppUpdateDialogExample.doNotShow,
                      style: TextStyle(fontFamily: _font, fontSize: 16, letterSpacing: .3, color: _ink)),
                ]),
              ),
            ),
          ),
        ]),
      );

  Widget _reminder() => const Padding(
        key: ValueKey('still'),
        padding: EdgeInsets.fromLTRB(28, 6, 28, 52),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppUpdateDialogExample.stillTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _font, fontSize: 24, height: 1.35, fontWeight: FontWeight.w600, color: Colors.black)),
          SizedBox(height: 14),
          Text(AppUpdateDialogExample.stillBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _font, fontSize: 16, height: 1.45, color: Colors.black)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 17),
      clipBehavior: Clip.antiAlias, // the dialog's rounded corners clip Fabio too
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF969696), width: 1.2)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // the art stays put from the ask to the reminder: Fabio is not built again
          Stack(children: [
            AppUpdateFabio(scene: widget.scene, controller: _fabio, library: widget.library, scale: AppUpdateFabio.dialogScale),
            Positioned(
              top: 30,
              right: 14,
              child: IgnorePointer(
                ignoring: !_still,
                child: AnimatedOpacity(
                  opacity: _still ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: IconButton(
                    onPressed: _close,
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 26, color: Color(0xFF1B1B1B)),
                  ),
                ),
              ),
            ),
          ]),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
            child: _still ? _reminder() : _ask(),
          ),
        ]),
      ),
    );
  }
}
