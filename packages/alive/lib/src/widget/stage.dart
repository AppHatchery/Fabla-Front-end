// AliveStage: the widget that shows a controller's scene. It never throws: while loading it shows [placeholder],
// on failure [fallback], and a paint that fails falls back from the next frame.
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../runtime/scene_data.dart';
import 'controller.dart';

/// Builds what shows when the scene failed.
typedef AliveFallbackBuilder = Widget Function(BuildContext context, Object? error);

/// Shows the scene of an [AliveController].
class AliveStage extends StatefulWidget {
  /// A stage for [controller].
  const AliveStage({
    super.key,
    required this.controller,
    this.viewport,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.plane = 'main',
    this.clip = false,
    this.placeholder,
    this.fallback,
    this.semanticsLabel,
    this.excludeFromSemantics,
    this.deferFirstPaint = true,
  });

  /// The controller whose scene it shows.
  final AliveController controller;

  /// The part of the world to show, in world units (default: the whole scene).
  final Rect? viewport;

  /// How the viewport fits the stage's box.
  final BoxFit fit;

  /// Where it sits in the box.
  final Alignment alignment;

  /// Which plane of the art to draw (a scene can split itself so app widgets sit between its planes).
  final String plane;

  /// Clip to the box (off by default: nothing of him is ever cut off).
  final bool clip;

  /// Shown while the scene loads (default: nothing).
  final Widget? placeholder;

  /// Shown when the scene failed (default: nothing).
  final AliveFallbackBuilder? fallback;

  /// Overrides the scene's label for assistive tech.
  final String? semanticsLabel;

  /// Force him out of (true) or into (false) the semantics tree; default: the scene decides (decorative or not).
  final bool? excludeFromSemantics;

  /// When the scene is ready as the stage is built (preloaded), paint him from the next frame (the default: the frame
  /// that builds a page is its heaviest) or, with false, in the same frame.
  final bool deferFirstPaint;

  @override
  State<AliveStage> createState() => _AliveStageState();
}

class _AliveStageState extends State<AliveStage> {
  // A scene that was ready when the stage was made (preloaded) is painted from the next frame: the frame that builds
  // the page is its heaviest, and he appears one frame later instead of adding to it.
  bool _waitOneFrame = false;

  @override
  void initState() {
    super.initState();
    if (widget.deferFirstPaint && widget.controller.status.value == AliveStatus.ready && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      _waitOneFrame = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _waitOneFrame = false);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.setSystemReducedMotion(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.isDisposed) return const SizedBox.shrink();
    return ValueListenableBuilder<AliveStatus>(
      valueListenable: c.status,
      builder: (context, status, _) {
        switch (status) {
          case AliveStatus.loading:
            return widget.placeholder ?? const SizedBox.shrink();
          case AliveStatus.ready when _waitOneFrame:
            return widget.placeholder ?? const SizedBox.shrink();
          case AliveStatus.failed:
          case AliveStatus.disposed:
            return widget.fallback?.call(context, c.error) ?? const SizedBox.shrink();
          case AliveStatus.ready:
            final data = c.scene!;
            final vp = widget.viewport ?? Rect.fromLTWH(0, 0, data.def.width, data.def.height);
            final paint = RepaintBoundary(
              child: CustomPaint(
                painter: _StagePainter(c, data, vp, widget.fit, widget.alignment, widget.plane, widget.clip),
                child: const SizedBox.expand(),
              ),
            );
            // in an unbounded box (a Column, a list) the stage takes the viewport's aspect ratio
            final sized = LayoutBuilder(
              builder: (context, box) => box.hasBoundedWidth && box.hasBoundedHeight ? paint : AspectRatio(aspectRatio: vp.width / vp.height, child: paint),
            );
            return _semantics(c, data, sized);
        }
      },
    );
  }

  Widget _semantics(AliveController c, AliveSceneData data, Widget child) {
    final s = data.def.semantics;
    final label = widget.semanticsLabel ?? s.states[c.appState] ?? s.label;
    final exclude = widget.excludeFromSemantics ?? (widget.semanticsLabel == null && s.decorative);
    if (exclude || label == null) return ExcludeSemantics(child: child);
    return Semantics(label: label, image: true, excludeSemantics: true, child: child);
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.c, this.data, this.viewport, this.fit, this.alignment, this.plane, this.clip) : super(repaint: c.frame);
  final AliveController c;
  final AliveSceneData data;
  final Rect viewport;
  final BoxFit fit;
  final Alignment alignment;
  final String plane;
  final bool clip;

  @override
  void paint(Canvas canvas, Size size) {
    final p = c.player;
    if (p == null || data.disposed || size.isEmpty) return;
    final t = stageTransform(size, viewport, fit, alignment);
    canvas.save();
    try {
      if (clip) canvas.clipRect(Offset.zero & size);
      canvas.translate(t.dx, t.dy);
      canvas.scale(t.scaleX, t.scaleY);
      for (final id in p.activeArt) {
        data.compiled[id]!.paint(canvas, p.state, plane: plane);
      }
    } catch (e, st) {
      c.reportRenderError(e, st);
    } finally {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) =>
      old.c != c || old.data != data || old.viewport != viewport || old.fit != fit || old.alignment != alignment || old.plane != plane || old.clip != clip;
}

/// One art file of a loaded scene, drawn at rest in its own frame (e.g. the cassette inside the app's recorder).
class AlivePart extends StatelessWidget {
  /// A part of [controller]'s scene.
  const AlivePart({super.key, required this.controller, required this.art, this.viewport, this.fit = BoxFit.contain});

  /// The controller whose scene holds the art.
  final AliveController controller;

  /// The art id.
  final String art;

  /// The part of the art to show (default: its frame, 0, 0, width, height).
  final Rect? viewport;

  /// How the viewport fits the box.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ValueListenableBuilder<AliveStatus>(
          valueListenable: controller.status,
          builder: (context, s, _) => s == AliveStatus.ready && controller.scene!.compiled.containsKey(art)
              ? CustomPaint(painter: _PartPainter(controller, controller.scene!, art, viewport, fit), child: const SizedBox.expand())
              : const SizedBox.shrink(),
        ),
      );
}

class _PartPainter extends CustomPainter {
  _PartPainter(this.c, this.data, this.art, this.viewport, this.fit);
  final AliveController c;
  final AliveSceneData data;
  final String art;
  final Rect? viewport;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.disposed) return;
    final a = data.compiled[art]!;
    final t = stageTransform(size, viewport ?? ui.Rect.fromLTWH(0, 0, a.def.width, a.def.height), fit, Alignment.center);
    canvas.save();
    try {
      canvas.translate(t.dx, t.dy);
      canvas.scale(t.scaleX, t.scaleY);
      a.paint(canvas, data.rest);
    } catch (e, st) {
      c.reportRenderError(e, st);
    } finally {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PartPainter old) => old.data != data || old.art != art || old.viewport != viewport || old.fit != fit;
}
