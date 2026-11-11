// SVG path data read once into a flat list of drawing commands (arcs already turned into cubics), so building the
// dart:ui Path on the UI thread is a loop over numbers instead of parsing text. Pure Dart: it can run off the UI
// isolate while a scene loads.
import 'dart:typed_data';

import 'package:path_parsing/path_parsing.dart';

/// Command codes in [PathCommands.data]: each code is followed by its points.
abstract final class PathOp {
  /// moveTo x y
  static const int move = 0;

  /// lineTo x y
  static const int line = 1;

  /// cubicTo x1 y1 x2 y2 x3 y3
  static const int cubic = 2;

  /// close
  static const int close = 3;
}

/// A path's commands: a code, then its numbers, again and again. Single precision, as the engine stores path points.
class PathCommands {
  /// Read SVG path data. Throws [FormatException] when it is malformed.
  factory PathCommands.parse(String d) {
    final w = _Writer();
    writeSvgPathDataToPath(d, w);
    return PathCommands._(w.done());
  }

  PathCommands._(this.data);

  /// Codes and numbers.
  final Float32List data;

  /// Hand every command to [proxy].
  void replay(PathProxy proxy) {
    final v = data;
    var i = 0;
    while (i < v.length) {
      switch (v[i].toInt()) {
        case PathOp.move:
          proxy.moveTo(v[i + 1], v[i + 2]);
          i += 3;
        case PathOp.line:
          proxy.lineTo(v[i + 1], v[i + 2]);
          i += 3;
        case PathOp.cubic:
          proxy.cubicTo(v[i + 1], v[i + 2], v[i + 3], v[i + 4], v[i + 5], v[i + 6]);
          i += 7;
        default:
          proxy.close();
          i += 1;
      }
    }
  }
}

class _Writer extends PathProxy {
  Float32List _b = Float32List(64);
  int _n = 0;

  void _room(int k) {
    if (_n + k <= _b.length) return;
    final nb = Float32List(_b.length * 2 + k);
    nb.setRange(0, _n, _b);
    _b = nb;
  }

  @override
  void moveTo(double x, double y) {
    _room(3);
    _b[_n++] = PathOp.move.toDouble();
    _b[_n++] = x;
    _b[_n++] = y;
  }

  @override
  void lineTo(double x, double y) {
    _room(3);
    _b[_n++] = PathOp.line.toDouble();
    _b[_n++] = x;
    _b[_n++] = y;
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _room(7);
    _b[_n++] = PathOp.cubic.toDouble();
    _b[_n++] = x1;
    _b[_n++] = y1;
    _b[_n++] = x2;
    _b[_n++] = y2;
    _b[_n++] = x3;
    _b[_n++] = y3;
  }

  @override
  void close() {
    _room(1);
    _b[_n++] = PathOp.close.toDouble();
  }

  Float32List done() => Float32List.fromList(Float32List.sublistView(_b, 0, _n));
}
