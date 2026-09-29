import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'fabio_custom_prop.dart';
import 'fabio_expression.dart';
import 'fabio_fx.dart';
import 'fabio_math.dart';
import 'fabio_rig.dart';
import 'fabio_sim.dart';

/// Drives a standalone [Fabio] widget. Attach one controller to one widget.
class FabioController extends ChangeNotifier {
  final FabioSim sim;
  final FabioFx fx;
  final math.Random _random;

  /// Fabio's centre in the widget's local coordinates, updated by the widget.
  Offset center = Offset.zero;

  FabioController({FabioExpression expression = FabioExpression.neutral, int seed = 7})
      : sim = FabioSim(expression: expression, seed: seed),
        fx = FabioFx(seed: seed + 1),
        _random = math.Random(seed);

  FabioExpression get expression => sim.expression;
  set expression(FabioExpression e) => sim.expression = e;

  /// Shows [e] briefly, then returns to [expression].
  void flash(FabioExpression e, {double seconds = 1.5}) => sim.flashExpression(e, seconds);

  void play(FabioGesture gesture, {double? duration}) =>
      sim.play(gesture, duration: duration);

  /// Gaze direction, each axis -1..1, or `null` to let Fabio look around.
  void lookAt(Offset? direction) => sim.lookTarget = direction;

  void burst(FabioProp prop,
      {FabioFxMode mode = FabioFxMode.burst, int count = 10, Offset? at}) {
    fx.emit(prop, mode, at ?? center, count: count);
  }

  void burstCustom(FabioCustomProp prop,
      {FabioFxMode mode = FabioFxMode.burst, int count = 10, Offset? at}) {
    fx.emitCustom(prop, mode, at ?? center, count: count);
  }

  /// A random delightful reaction, used when Fabio is tapped.
  void react() {
    final pick = _random.nextInt(6);
    switch (pick) {
      case 0:
        play(FabioGesture.squish);
        flash(FabioExpression.joyful, seconds: 1);
        burst(FabioProp.heart, count: 5, mode: FabioFxMode.fountain);
      case 1:
        play(FabioGesture.laugh);
        flash(FabioExpression.joyful, seconds: 1.2);
        burst(FabioProp.note, count: 3, mode: FabioFxMode.float);
      case 2:
        play(FabioGesture.spin);
        flash(FabioExpression.excited, seconds: 1);
        burst(FabioProp.sparkle, count: 10, mode: FabioFxMode.ring);
      case 3:
        play(FabioGesture.bounce);
        flash(FabioExpression.happy, seconds: 1);
        burst(FabioProp.star, count: 8, mode: FabioFxMode.fountain);
      case 4:
        play(FabioGesture.wave);
        flash(FabioExpression.happy, seconds: 1.6);
      default:
        play(FabioGesture.pop);
        flash(FabioExpression.love, seconds: 1.4);
        burst(FabioProp.heart, count: 3, mode: FabioFxMode.float);
    }
  }

  void tick(double dt) {
    sim.update(dt);
    fx.anchor = center;
    fx.update(dt);
    notifyListeners();
  }
}

/// Fabio as a self-contained, always-alive widget.
///
/// ```dart
/// Fabio(size: 120, expression: FabioExpression.happy)
/// ```
///
/// Pass a [controller] to trigger gestures, props and expressions from code.
/// Gestures and props may paint outside the widget's bounds.
class Fabio extends StatefulWidget {
  final double size;
  final FabioController? controller;

  /// Resting expression. Changes animate smoothly.
  final FabioExpression? expression;

  /// Tap to react, drag to make Fabio follow your finger with his eyes.
  final bool interactive;
  final bool shadow;

  /// Set to false to keep Fabio still (e.g. for reduced motion).
  final bool hover;

  const Fabio({
    super.key,
    this.size = 120,
    this.controller,
    this.expression,
    this.interactive = true,
    this.shadow = true,
    this.hover = true,
  });

  @override
  State<Fabio> createState() => _FabioState();
}

class _FabioState extends State<Fabio> with SingleTickerProviderStateMixin {
  late FabioController _controller;
  bool _ownsController = false;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final List<double> _taps = [];

  @override
  void initState() {
    super.initState();
    _attach();
    _ticker = createTicker(_onTick)..start();
  }

  void _attach() {
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        FabioController(expression: widget.expression ?? FabioExpression.neutral);
    if (widget.expression != null) _controller.expression = widget.expression!;
    _controller.sim.hover = widget.hover ? 1 : 0;
  }

  @override
  void didUpdateWidget(Fabio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _attach();
    }
    if (widget.expression != null && widget.expression != oldWidget.expression) {
      _controller.expression = widget.expression!;
    }
    _controller.sim.hover = widget.hover ? 1 : 0;
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _controller.center = _center;
    _controller.fx.unit = widget.size / 110;
    _controller.tick(dt);
  }

  Offset get _center => Offset(widget.size / 2, widget.size * (69 / 144) + widget.size * 0.02);

  void _onTap() {
    final now = _controller.sim.time;
    _taps.add(now);
    _taps.removeWhere((t) => now - t > 1.2);
    if (_taps.length >= 4) {
      _taps.clear();
      _controller.play(FabioGesture.dizzy);
      _controller.burst(FabioProp.star, count: 5, mode: FabioFxMode.orbit);
    } else {
      _controller.react();
    }
  }

  void _look(Offset local) {
    final d = (local - _center) / (widget.size * 0.8);
    _controller.lookAt(Offset(clampD(d.dx, -1, 1), clampD(d.dy, -1, 1)));
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomPaint(
      size: Size(widget.size, widget.size * 1.08),
      painter: _FabioPainter(_controller, widget.size, widget.shadow),
    );
    if (widget.interactive) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onPanStart: (d) => _look(d.localPosition),
        onPanUpdate: (d) => _look(d.localPosition),
        onPanEnd: (_) => _controller.lookAt(null),
        onPanCancel: () => _controller.lookAt(null),
        child: child,
      );
    }
    return Semantics(label: 'Fabio', image: true, child: child);
  }
}

class _FabioPainter extends CustomPainter {
  final FabioController controller;
  final double fabioSize;
  final bool shadow;

  _FabioPainter(this.controller, this.fabioSize, this.shadow) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = controller.sim.pose;
    final center = controller.center;
    if (shadow) paintShadow(canvas, pose, Offset(center.dx, fabioSize * 0.98), fabioSize);
    controller.fx.paint(canvas, front: false);
    FabioRig.paint(canvas, pose, center, fabioSize);
    controller.fx.paint(canvas, front: true);
  }

  @override
  bool shouldRepaint(_FabioPainter old) =>
      old.controller != controller || old.fabioSize != fabioSize || old.shadow != shadow;
}

/// A soft ground shadow that shrinks as Fabio rises.
void paintShadow(Canvas canvas, FabioPose pose, Offset ground, double size) {
  final lift = clampD(-pose.offsetY / 40, 0, 1);
  final w = size * 0.62 * (1 - lift * 0.35) * pose.scale;
  canvas.drawOval(
    Rect.fromCenter(center: ground, width: w, height: w * 0.16),
    Paint()..color = const Color(0xFF0147A0).withValues(alpha: 0.12 * (1 - lift * 0.5)),
  );
}
