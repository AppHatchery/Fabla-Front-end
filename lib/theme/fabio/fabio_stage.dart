import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../custom_typography.dart';
import 'fabio_fx.dart';
import 'fabio_math.dart';
import 'fabio_rig.dart';
import 'fabio_script.dart';
import 'fabio_sim.dart';

/// Plays [FabioScript]s on a [FabioStage].
class FabioStageController extends ChangeNotifier {
  _FabioStageState? _state;

  bool get isPlaying => _state?._playing ?? false;
  double get playhead => _state?._playhead ?? 0;

  /// Direct access to Fabio's sim for ad-hoc gestures mid-script.
  FabioSim? get sim => _state?._sim;

  /// Starts [script] from the beginning. Completes when it finishes and its
  /// props have settled (never, for looping scripts, until [stop]).
  Future<void> play(FabioScript script) {
    final state = _state;
    if (state == null) return Future.value();
    return state._play(script);
  }

  Future<void> playAsset(String asset) async => play(await FabioScript.load(asset));

  void stop() => _state?._stop();
}

/// A canvas the size of its parent on which Fabio performs choreographies:
/// flying anywhere across it, spawning props and talking in speech bubbles.
///
/// For a full-screen performance over the current route, use
/// [showFabioScript] instead of placing a stage yourself.
class FabioStage extends StatefulWidget {
  final FabioStageController? controller;

  /// Played automatically when the stage mounts.
  final FabioScript? script;

  /// Fabio's width in logical pixels at script scale 1.
  final double fabioSize;

  /// Hide Fabio when no script is playing.
  final bool hideWhenIdle;

  final VoidCallback? onFinished;

  /// Called for every `event` clip, so screens can sync real UI to a script.
  final ValueChanged<String>? onEvent;

  const FabioStage({
    super.key,
    this.controller,
    this.script,
    this.fabioSize = 110,
    this.hideWhenIdle = true,
    this.onFinished,
    this.onEvent,
  });

  @override
  State<FabioStage> createState() => _FabioStageState();
}

class _FabioStageState extends State<FabioStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = _Repaint();
  FabioSim _sim = FabioSim();
  FabioFx _fx = FabioFx();

  FabioScript? _script;
  FabioTimeline? _timeline;
  Size _size = Size.zero;
  Completer<void>? _done;

  bool _playing = false;
  bool _settling = false;
  double _playhead = 0;
  double _fired = -1;
  double _settleTime = 0;
  Duration _last = Duration.zero;
  final Map<FabioFxClip, double> _emitDebt = {};

  Offset _pos = Offset.zero;
  Offset? _prevPos;
  double _scale = 1;
  double _alpha = 0;
  double _safeTop = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _ticker = createTicker(_onTick);
    final s = widget.script;
    if (s != null) _play(s);
  }

  @override
  void didUpdateWidget(FabioStage old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    if (widget.script != null && widget.script != old.script) _play(widget.script!);
  }

  Future<void> _play(FabioScript script) {
    _done?.complete();
    _done = Completer<void>();
    _script = script;
    _sim = FabioSim(expression: script.start.expression, seed: script.seed)
      ..face(script.start.facing);
    _sim.pose.facing = script.start.facing;
    _fx = FabioFx(seed: script.seed + 1);
    _timeline = _size.isEmpty ? null : FabioTimeline(script, _size);
    _playing = true;
    _settling = false;
    _playhead = 0;
    _fired = -1;
    _prevPos = null;
    _emitDebt.clear();
    _last = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
    return _done!.future;
  }

  void _stop() {
    _playing = false;
    _settling = false;
    _fx.clear();
    _ticker.stop();
    _repaint.notify();
    _done?.complete();
    _done = null;
  }

  double get _unit => widget.fabioSize / 110;

  void _onTick(Duration elapsed) {
    final dt = clampD((elapsed - _last).inMicroseconds / 1e6, 0, 0.05);
    _last = elapsed;
    final timeline = _timeline;
    final script = _script;
    if (timeline == null || script == null) return;

    if (_playing) {
      final prev = _playhead;
      _playhead += dt;
      _fire(timeline, prev, _playhead);
      _updateFabio(timeline, dt);
      if (_playhead >= script.duration) {
        if (script.loop) {
          _playhead = 0;
          _fired = -1;
        } else {
          _playing = false;
          _settling = true;
          _settleTime = 0;
        }
      }
    } else if (_settling) {
      _settleTime += dt;
      if (_fx.particles.isEmpty || _settleTime > 2.5) {
        _settling = false;
        _ticker.stop();
        _done?.complete();
        _done = null;
        widget.onFinished?.call();
      }
    }

    _sim.update(dt);
    _fx.unit = _unit;
    _fx.bounds = _size;
    _fx.anchor = _pos;
    _fx.update(dt);
    _repaint.notify();
  }

  void _updateFabio(FabioTimeline timeline, double dt) {
    final sample = timeline.motionAt(_playhead);
    _pos = sample.position;
    _scale = sample.scale;
    _alpha = sample.alpha;
    final px = widget.fabioSize * math.max(_scale, 0.2);
    final prev = _prevPos;
    if (prev != null && dt > 0 && _alpha > 0.5) {
      var v = (_pos - prev) / dt / px;
      if (v.distance > 14) v = v / v.distance * 14;
      _sim.velocity = v;
    } else {
      _sim.velocity = Offset.zero;
    }
    _prevPos = _pos;
    _sim.expression = timeline.expressionAt(_playhead);

    final look = timeline.lookAt(_playhead);
    if (look == null || (look.at == null && look.target != 'viewer')) {
      _sim.lookTarget = null;
    } else if (look.at == null) {
      _sim.lookTarget = Offset.zero;
    } else {
      final d = (timeline.stagePoint(look.at!) - _pos) / (px * 1.2);
      _sim.lookTarget = d.distance > 1 ? d / d.distance : d;
    }

    for (final c in _timeline!.script.fx) {
      if (!c.continuous) continue;
      final end = c.t + (c.d ?? 1);
      if (_playhead < c.t || _playhead >= end) continue;
      var debt = (_emitDebt[c] ?? 0) + c.rate * dt;
      while (debt >= 1) {
        debt -= 1;
        if (c.mode == FabioFxMode.rain) {
          _emit(c, Offset.zero, count: 1);
        } else {
          final v = _sim.velocity;
          final behind = v.distance > 0.1 ? v / v.distance * -px * 0.3 : Offset.zero;
          _emit(c, _pos + behind + Offset(0, px * 0.25), count: 1);
        }
      }
      _emitDebt[c] = debt;
    }
  }

  void _fire(FabioTimeline timeline, double from, double to) {
    bool crossed(double t) => t > _fired && t <= to;
    final script = timeline.script;
    for (final c in script.actions) {
      if (crossed(c.t)) _sim.play(c.gesture, duration: c.d);
    }
    for (final c in [...script.fx, ...timeline.derivedFx]) {
      if (c.continuous || !crossed(c.t)) continue;
      final at = c.at == null ? _pos : timeline.stagePoint(c.at!);
      _emit(c, at,
          count: c.count, life: c.mode == FabioFxMode.orbit ? (c.d ?? 2) : null);
    }
    for (final c in script.events) {
      if (crossed(c.t)) widget.onEvent?.call(c.name);
    }
    _fired = to;
  }

  void _emit(FabioFxClip c, Offset at, {required int count, double? life}) {
    final custom = c.custom;
    if (custom != null) {
      _fx.emitCustom(custom, c.mode, at,
          count: count, color: c.color, spread: c.spread, sizeScale: c.size, life: life);
    } else {
      _fx.emit(c.prop!, c.mode, at,
          count: count, color: c.color, spread: c.spread, sizeScale: c.size, life: life);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    _ticker.dispose();
    _repaint.dispose();
    _done?.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _safeTop = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _size && size.isFinite) {
        _size = size;
        final script = _script;
        if (script != null) _timeline = FabioTimeline(script, size);
      }
      return CustomPaint(
        size: size,
        painter: _StagePainter(this),
      );
    });
  }
}

class _Repaint extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _StagePainter extends CustomPainter {
  final _FabioStageState s;
  _StagePainter(this.s) : super(repaint: s._repaint);

  @override
  void paint(Canvas canvas, Size size) {
    s._fx.paint(canvas, front: false);
    final visible = s._timeline != null && (s._playing || !s.widget.hideWhenIdle);
    if (visible) {
      final pose = s._sim.pose..opacity = s._alpha;
      FabioRig.paint(canvas, pose, s._pos, s.widget.fabioSize * s._scale);
    }
    s._fx.paint(canvas, front: true);
    final speech = visible ? s._timeline!.speechAt(s._playhead) : null;
    if (speech != null) _paintSpeech(canvas, size, speech);
  }

  void _paintSpeech(Canvas canvas, Size size, FabioSpeechClip clip) {
    final elapsed = s._playhead - clip.t;
    final remaining = clip.t + clip.d - s._playhead;
    final pop = ease('outBack', clampD(elapsed / 0.22, 0, 1)) *
        (1 - smoothstep(0, 1, 1 - clampD(remaining / 0.15, 0, 1)));
    if (pop <= 0.01) return;

    final shown = math.min(clip.text.length, (elapsed * 40).floor());
    final style = TextStyle(
      fontFamily: CustomTypography.fontName,
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF242424),
    );
    final painter = TextPainter(
      text: TextSpan(style: style, children: [
        TextSpan(text: clip.text.substring(0, shown)),
        TextSpan(
            text: clip.text.substring(shown),
            style: const TextStyle(color: Color(0x00000000))),
      ]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.min(240, size.width - 48));

    const padH = 14.0, padV = 10.0, margin = 12.0;
    final w = painter.width + padH * 2;
    final h = painter.height + padV * 2;
    final fabioHalf = s.widget.fabioSize * s._scale * 0.55;
    var above = true;
    var top = s._pos.dy - fabioHalf - 14 - h;
    if (top < margin + s._safeTop) {
      above = false;
      top = s._pos.dy + fabioHalf + 14;
    }
    final left = clampD(s._pos.dx - w / 2, margin, math.max(margin, size.width - w - margin));
    final rect = Rect.fromLTWH(left, top, w, h);
    final tailX = clampD(s._pos.dx, rect.left + 18, rect.right - 18);

    final bubble = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final tail = Path();
    if (above) {
      tail
        ..moveTo(tailX - 8, rect.bottom - 1)
        ..lineTo(tailX + 2, rect.bottom + 10)
        ..lineTo(tailX + 8, rect.bottom - 1);
    } else {
      tail
        ..moveTo(tailX - 8, rect.top + 1)
        ..lineTo(tailX + 2, rect.top - 10)
        ..lineTo(tailX + 8, rect.top + 1);
    }
    final shape = Path.combine(PathOperation.union, bubble, tail);

    canvas.save();
    final anchor = Offset(tailX, above ? rect.bottom + 10 : rect.top - 10);
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(pop);
    canvas.translate(-anchor.dx, -anchor.dy);
    canvas.drawShadow(shape, const Color(0xFF0147A0), 6, false);
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFFFFF));
    painter.paint(canvas, Offset(rect.left + padH, rect.top + padV));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StagePainter old) => old.s != s;
}

/// Plays [script] full-screen above the current route, without blocking
/// touches, and removes itself when done.
Future<void> showFabioScript(
  BuildContext context,
  FabioScript script, {
  double fabioSize = 110,
  ValueChanged<String>? onEvent,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: FabioStage(
        script: script,
        fabioSize: fabioSize,
        onEvent: onEvent,
        onFinished: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return completer.future;
}
