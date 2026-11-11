// The values of every layer at one instant: what the renderer reads. One flat buffer, no allocation per frame.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../schema/track.dart';
import 'extensions.dart' show AlivePluginHost;

/// Draws the parts a kit figure wears (lib/src/kit). The art's part nodes ask it, so one compiled figure serves every
/// look: each player has its own dressing.
abstract class AliveDressing {
  /// Does the slot (`<figure>:<slot>`) wear a part at this z ([alt]: its alternate z)?
  bool wears(String slot, bool alt);

  /// Does the slot wear a part at its front z (a part tagged `front`, in a slot with a `zFront`)? None by default.
  bool wearsFront(String slot) => false;

  /// Draw the part worn in [slot], in the slot layer's coordinates (its anchor point at the origin).
  void paintPart(ui.Canvas canvas, String slot, bool alt);
}

/// Per-layer values of one frame: the numeric properties, the colour channels and whether a look hides the layer.
class LayerState {
  /// Buffers for [count] layers.
  LayerState(this.count)
      : values = Float64List(count * LayerProp.numeric),
        fill = colourList(count),
        stroke = colourList(count),
        hidden = Uint8List(count);

  /// Number of layers.
  final int count;

  /// Numeric values, [LayerProp.numeric] per layer, in [LayerProp] order.
  final Float64List values;

  /// Fill colour channel per layer (0xAARRGGBB), or -1 when unset.
  final List<int> fill;

  /// Stroke colour channel per layer, or -1 when unset.
  final List<int> stroke;

  /// 1 where a look hides the layer.
  final Uint8List hidden;

  /// What the scene's kit figures wear (null: no figures, or nothing worn).
  AliveDressing? dressing;

  /// Who draws plugin nodes in this frame (null: they draw nothing).
  AlivePluginHost? plugins;

  /// A numeric value.
  double get(int layer, LayerProp p) => values[layer * LayerProp.numeric + p.index];

  /// Set a numeric value.
  void set(int layer, LayerProp p, double v) => values[layer * LayerProp.numeric + p.index] = v;

  /// Copy everything from [o] (same layer count).
  void copyFrom(LayerState o) {
    values.setAll(0, o.values);
    fill.setAll(0, o.fill);
    stroke.setAll(0, o.stroke);
    hidden.setAll(0, o.hidden);
  }

  /// The layer's delta from rest as a column-major 4x4 matrix in [out]: T(p + t) R(-rot) S(sx, sy) T(-p), the old
  /// rig's formula. Returns false (and leaves [out] alone) when the layer is at rest.
  bool deltaInto(int layer, double px, double py, Float64List out) {
    final b = layer * LayerProp.numeric;
    final tx = values[b], ty = values[b + 1], rot = values[b + 2], sx = values[b + 3], sy = values[b + 4];
    final kx = values[b + _kx], ky = values[b + _ky];
    if (tx == 0 && ty == 0 && rot == 0 && sx == 1 && sy == 1 && kx == 0 && ky == 0) return false;
    final r = -rot * math.pi / 180, c = math.cos(r), s = math.sin(r);
    var a = c * sx, bb = s * sx, cc = -s * sy, d = c * sy;
    if (kx != 0 || ky != 0) {
      // R S K: the skew first (x += tan(kx) y, y += tan(ky) x), then scale, then rotation
      final tkx = math.tan(kx * math.pi / 180), tky = math.tan(ky * math.pi / 180);
      a = c * sx - s * sy * tky;
      bb = s * sx + c * sy * tky;
      cc = c * sx * tkx - s * sy;
      d = s * sx * tkx + c * sy;
    }
    out
      ..[0] = a
      ..[1] = bb
      ..[2] = 0
      ..[3] = 0
      ..[4] = cc
      ..[5] = d
      ..[6] = 0
      ..[7] = 0
      ..[8] = 0
      ..[9] = 0
      ..[10] = 1
      ..[11] = 0
      ..[12] = px + tx - (a * px + cc * py)
      ..[13] = py + ty - (bb * px + d * py)
      ..[14] = 0
      ..[15] = 1;
    return true;
  }
}

final int _kx = LayerProp.kx.index, _ky = LayerProp.ky.index;

/// The delta matrix [a, b, c, d, e, f] of a layer about its pivot, written into [out] (6 values). [kx] and [ky] skew
/// it (degrees), applied before scale and rotation.
void delta6Into(double px, double py, double tx, double ty, double rot, double sx, double sy, Float64List out, [double kx = 0, double ky = 0]) {
  final r = -rot * math.pi / 180, c = math.cos(r), s = math.sin(r);
  var a = c * sx, b = s * sx, cc = -s * sy, d = c * sy;
  if (kx != 0 || ky != 0) {
    final tkx = math.tan(kx * math.pi / 180), tky = math.tan(ky * math.pi / 180);
    a = c * sx - s * sy * tky;
    b = s * sx + c * sy * tky;
    cc = c * sx * tkx - s * sy;
    d = s * sx * tkx + c * sy;
  }
  out
    ..[0] = a
    ..[1] = b
    ..[2] = cc
    ..[3] = d
    ..[4] = px + tx - (a * px + cc * py)
    ..[5] = py + ty - (b * px + d * py);
}
