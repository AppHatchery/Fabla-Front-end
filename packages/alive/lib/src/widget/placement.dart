// AlivePlacement: a scene laid out the way its placement says (0.7.0, docs/standards.md). A thin layer over
// AliveStage: it sizes the stage from the placement (its fit and scale), clips and aligns it, and lets taps pass
// through a page. Every AliveStage parameter can still be set; AliveStage itself is unchanged.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'stage.dart';

/// How a placement lays a scene out. The five standard ones are [AlivePlacements]; a team can make its own (and list
/// it in standards/placements.json, so the tools check scenes against it too).
@immutable
class AlivePlacementSpec {
  /// A placement.
  const AlivePlacementSpec({
    required this.name,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clip = false,
    this.passTaps = false,
    this.scale = 1,
    this.maxScale = 1,
  });

  /// Its name, as scenes declare it (`"placement": "card"`).
  final String name;

  /// The box's designed width in points on the 430 pt phone (null: any).
  final double? width;

  /// The box's designed height in points, when the placement fixes it (the dialog's 136; null: the scene's own).
  final double? height;

  /// How the scene fits the box: [BoxFit.fitWidth] scales it evenly by the box's width (page, panel, card),
  /// [BoxFit.fitHeight] by its height (the dialog, whose sides crop on a narrow dialog), [BoxFit.contain] wholly inside.
  final BoxFit fit;

  /// Where the scene sits in the box.
  final Alignment alignment;

  /// Clip to the box.
  final bool clip;

  /// Let taps pass through to what is under the stage (a page laid over the app's own buttons).
  final bool passTaps;

  /// On-screen points per scene point at the design width: 1, or the dialog's 110 / 83 (its scene shows larger, so
  /// Fabio matches the dialog's own art).
  final double scale;

  /// The most the scaling rule scales the box over its size on the 430 pt phone (0.7.0): 1 keeps a phone design at
  /// its phone size on a tablet (centred in what the app gives it); [double.infinity] lets it fill a wide parent.
  final double maxScale;

  /// A copy with some fields changed.
  AlivePlacementSpec copyWith({String? name, double? width, double? height, BoxFit? fit, Alignment? alignment, bool? clip, bool? passTaps, double? scale, double? maxScale}) =>
      AlivePlacementSpec(
        name: name ?? this.name,
        width: width ?? this.width,
        height: height ?? this.height,
        fit: fit ?? this.fit,
        alignment: alignment ?? this.alignment,
        clip: clip ?? this.clip,
        passTaps: passTaps ?? this.passTaps,
        scale: scale ?? this.scale,
        maxScale: maxScale ?? this.maxScale,
      );

  @override
  String toString() => 'AlivePlacementSpec($name)';
}

/// The standard placements (standards/placements.json, whose values these mirror; a test keeps them equal).
abstract final class AlivePlacements {
  /// The phone the scenes are designed on: 430 pt wide.
  static const double designWidth = 430;

  /// The whole screen (an ending, the recording page): scaled evenly by width; the app's own buttons stay on top and
  /// take the taps.
  static const page = AlivePlacementSpec(name: 'page', width: 430, fit: BoxFit.fitWidth, alignment: Alignment.topCenter, passTaps: true);

  /// A sheet inside the page (the warning sheets): Fabio rises from its bottom edge, clipped to it.
  static const panel = AlivePlacementSpec(name: 'panel', width: 366, fit: BoxFit.fitWidth, alignment: Alignment.bottomCenter, clip: true);

  /// A card in the page's column (the web page error cards).
  static const card = AlivePlacementSpec(name: 'card', width: 398, fit: BoxFit.fitWidth, clip: true);

  /// A dialog's art band where its logo was: the scene's 136 pt shown at 110 / 83, as wide as the dialog; a narrower
  /// dialog crops the sides.
  static const dialog = AlivePlacementSpec(name: 'dialog', width: 396, height: 136, fit: BoxFit.fitHeight, clip: true, scale: 110 / 83);

  /// A small piece beside the app's own widgets (a question type, a badge, a peek at an edge).
  static const inline = AlivePlacementSpec(name: 'inline');

  /// Anything else: the scene's own box, wholly inside the stage (what a plain [AliveStage] does).
  static const custom = AlivePlacementSpec(name: 'custom');

  /// All of them, by name.
  static const Map<String, AlivePlacementSpec> all = {'page': page, 'panel': panel, 'card': card, 'dialog': dialog, 'inline': inline, 'custom': custom};

  /// The standard placement called [name], or null.
  static AlivePlacementSpec? byName(String? name) => name == null ? null : all[name];
}

/// Shows a controller's scene laid out by its placement: [placement], or the one the scene declares, or
/// [AlivePlacements.custom]. Each argument given here wins over the placement's own.
///
/// The scaling rule: scenes are designed at 430 pt wide. On another phone the box scales by the width ratio,
/// evenly, never stretched: the stage is as wide as its parent allows (or, unbounded, the scene's width times the
/// screen's width over 430) and as tall as the scene's proportions make it (fitWidth), or as tall as the placement's
/// height times its scale (fitHeight, the dialog). In a box the parent sizes both ways, the stage takes that box.
/// Two limits (0.7.0): it never grows past [AlivePlacementSpec.maxScale] times its size on the 430 pt phone (1 by
/// default: on a tablet it keeps its phone size, placed in its parent by the placement's alignment), and it is never
/// taller than its parent allows, or than the screen (a box the width would make too tall fits the height instead).
class AlivePlacement extends StatelessWidget {
  /// A stage laid out by a placement.
  const AlivePlacement({
    super.key,
    required this.controller,
    this.placement,
    this.viewport,
    this.fit,
    this.alignment,
    this.clip,
    this.passTaps,
    this.scale,
    this.maxScale,
    this.plane = 'main',
    this.placeholder,
    this.fallback,
    this.semanticsLabel,
    this.excludeFromSemantics,
    this.deferFirstPaint = true,
  });

  /// The controller whose scene it shows.
  final AliveController controller;

  /// The placement (default: the one the scene declares, else [AlivePlacements.custom]).
  final AlivePlacementSpec? placement;

  /// [AliveStage.viewport].
  final Rect? viewport;

  /// Overrides the placement's [AlivePlacementSpec.fit].
  final BoxFit? fit;

  /// Overrides the placement's [AlivePlacementSpec.alignment].
  final Alignment? alignment;

  /// Overrides the placement's [AlivePlacementSpec.clip].
  final bool? clip;

  /// Overrides the placement's [AlivePlacementSpec.passTaps].
  final bool? passTaps;

  /// Overrides the placement's [AlivePlacementSpec.scale].
  final double? scale;

  /// Overrides the placement's [AlivePlacementSpec.maxScale] ([double.infinity]: no cap).
  final double? maxScale;

  /// [AliveStage.plane].
  final String plane;

  /// [AliveStage.placeholder].
  final Widget? placeholder;

  /// [AliveStage.fallback].
  final AliveFallbackBuilder? fallback;

  /// [AliveStage.semanticsLabel].
  final String? semanticsLabel;

  /// [AliveStage.excludeFromSemantics].
  final bool? excludeFromSemantics;

  /// [AliveStage.deferFirstPaint].
  final bool deferFirstPaint;

  /// The placement in effect: [placement], the scene's declared one, or [AlivePlacements.custom], with this widget's
  /// overrides applied.
  AlivePlacementSpec resolve() {
    final base = placement ?? AlivePlacements.byName(controller.scene?.def.placement) ?? AlivePlacements.custom;
    return base.copyWith(fit: fit, alignment: alignment, clip: clip, passTaps: passTaps, scale: scale, maxScale: maxScale);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AliveStatus>(
        valueListenable: controller.status,
        builder: (context, status, _) {
          final spec = resolve();
          final data = status == AliveStatus.ready ? controller.scene : null;
          final vp = viewport ?? (data == null ? null : Rect.fromLTWH(0, 0, data.def.width, data.def.height));
          final screen = MediaQuery.maybeSizeOf(context);
          final stage = AliveStage(
            controller: controller,
            viewport: viewport,
            fit: spec.fit,
            alignment: spec.alignment,
            plane: plane,
            clip: spec.clip,
            placeholder: placeholder,
            fallback: fallback,
            semanticsLabel: semanticsLabel,
            excludeFromSemantics: excludeFromSemantics,
            deferFirstPaint: deferFirstPaint,
          );
          final sized = LayoutBuilder(builder: (context, box) {
            final size = placementSize(spec, vp, box, screen?.width ?? AlivePlacements.designWidth, screenHeight: screen?.height);
            if (size == null) return stage;
            final child = SizedBox(width: size.width, height: size.height, child: stage);
            // narrower than its parent (capped on a tablet, or fit to the height): placed in it by the placement's
            // alignment, centred across; as tall as itself unless the parent fixes the height
            final narrower = box.hasBoundedWidth && size.width < box.maxWidth - 1e-6;
            final shorter = size.height < box.minHeight - 1e-6;
            return narrower || shorter ? Align(alignment: spec.alignment, heightFactor: 1, child: child) : child;
          });
          return spec.passTaps ? IgnorePointer(child: sized) : sized;
        },
      );
}

/// The stage's size for [spec] in [box] (null: let the stage take the box as it is). [viewport]: the scene's frame
/// (null while it loads); [screenWidth]: the phone's width, for an unbounded box; [screenHeight]: the screen's height,
/// the tallest the box may be when its parent does not bound it. The scaling rule of [AlivePlacement].
Size? placementSize(AlivePlacementSpec spec, Rect? viewport, BoxConstraints box, double screenWidth, {double? screenHeight}) {
  final cap = spec.maxScale;
  final ratio = math.min(screenWidth / AlivePlacements.designWidth, cap);
  final maxH = box.hasBoundedHeight ? box.maxHeight : (screenHeight ?? double.infinity);
  final loose = box.loosen();
  switch (spec.fit) {
    case BoxFit.fitHeight:
      // the dialog: its height is the placement's (or the scene's) times its scale, never past the screen; the width
      // is the parent's
      final h0 = spec.height ?? viewport?.height;
      if (h0 == null) return null;
      final h = math.min(h0 * spec.scale, maxH);
      final w = box.hasBoundedWidth ? box.maxWidth : (spec.width ?? viewport?.width ?? h0) * spec.scale;
      return box.constrain(Size(w, h));
    case BoxFit.fitWidth:
      if (viewport == null) return null;
      // as wide as the parent, up to maxScale times its width on the 430 pt phone; too tall: fit the height
      var w = box.hasBoundedWidth ? math.min(box.maxWidth, viewport.width * spec.scale * cap) : viewport.width * spec.scale * ratio;
      if (w * viewport.height / viewport.width > maxH) w = maxH * viewport.width / viewport.height;
      return loose.constrain(Size(w, w * viewport.height / viewport.width));
    default:
      if (box.hasBoundedWidth && box.hasBoundedHeight) return null;
      if (viewport == null) return null;
      final s = spec.scale * ratio;
      var w = box.hasBoundedWidth ? math.min(box.maxWidth, viewport.width * spec.scale * cap) : viewport.width * s;
      var h = box.hasBoundedHeight ? box.maxHeight : (box.hasBoundedWidth ? w * viewport.height / viewport.width : viewport.height * s);
      if (h > maxH) {
        w *= maxH / h;
        h = maxH;
      }
      return loose.constrain(Size(w, h));
  }
}
