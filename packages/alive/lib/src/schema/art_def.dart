// alive/1 art files, parsed into a typed node tree and checked. Pure Dart: the renderer (lib/src/render) turns the
// nodes into paths, paints and pictures on the UI isolate.
import 'dart:typed_data';

import 'errors.dart';
import 'path_data.dart';
import 'scene_def.dart' show ProblemSink, checkHeader, jsonKey;
import 'track.dart' show parseHex;

typedef _J = Map<String, dynamic>;
_J? _obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;
double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
String? _str(Object? v) => v is String ? v : null;

/// Geometry of a shape: an SVG path, a rounded rect, an ellipse, a line or a polyline.
class Geometry {
  Geometry._(this.kind, this.d, this.v, this.closed);

  /// 'd', 'rect', 'ellipse', 'line' or 'poly'.
  final String kind;

  /// SVG path data (kind 'd').
  final String? d;

  /// Numbers: rect [x, y, w, h, rx, ry]; ellipse [cx, cy, rx, ry]; line [x1, y1, x2, y2]; poly [x, y, ...].
  final Float64List? v;

  /// A closed polygon (kind 'poly').
  final bool closed;

  /// The path data read into drawing commands ahead of time (kind 'd'; the loader does it off the UI thread), or
  /// null: the renderer then reads [d] itself.
  PathCommands? commands;

  /// Read [d] into [commands] now. Malformed path data is left for the renderer to report.
  void prepare() {
    final dd = d;
    if (dd == null || commands != null) return;
    try {
      commands = PathCommands.parse(dd);
    } on FormatException {
      // the renderer meets the same data and reports it with the art's file name
    }
  }

  /// The geometry keys of alive/1.
  static const List<String> kinds = ['d', 'rect', 'ellipse', 'line', 'poly'];

  static Geometry? _read(_J n, String path, ProblemSink p) {
    for (final k in kinds) {
      final raw = n[k];
      if (raw == null) continue;
      if (k == 'd') {
        if (raw is! String || raw.isEmpty) {
          p.add('$path.d', 'd is SVG path data');
          return null;
        }
        return Geometry._(k, raw, null, false);
      }
      const len = {'rect': 6, 'ellipse': 4, 'line': 4};
      if (raw is! List || !raw.every((x) => _num(x) != null) || (len[k] != null && raw.length != len[k]) || (k == 'poly' && (raw.length < 2 || raw.length.isOdd))) {
        p.add('$path.$k', 'bad $k numbers');
        return null;
      }
      return Geometry._(k, null, Float64List.fromList([for (final x in raw) (x as num).toDouble()]), n['closed'] == true);
    }
    return null;
  }
}

/// A text span of a Figma text box.
class SpanDef {
  SpanDef._(this.text, this.font, this.size, this.weight, this.colour, this.lineHeight, this.letterSpacing);

  /// The characters.
  final String text;

  /// Font key: 'rubik', 'vt323', 'pixelify' or 'system' (mapped to the app's families by AliveFonts).
  final String font;

  /// Font size.
  final double size;

  /// Font weight, 100..900.
  final int weight;

  /// Colour 0xAARRGGBB, or -1 for currentColor (the colour channel of the layer above).
  final int colour;

  /// Line height as a multiple of the size, if set.
  final double? lineHeight;

  /// Letter spacing in world units, if set.
  final double? letterSpacing;
}

/// A parametric box: a frame or rectangle whose size, radius, fill or stroke a clip animates.
class BoxDef {
  BoxDef._(this.x, this.y, this.w, this.h, this.r, this.fill, this.fillOpacity, this.stroke, this.strokeWidth);

  /// Rest geometry.
  final double x, y, w, h, r;

  /// Rest fill (0xAARRGGBB) or null.
  final int? fill;

  /// Fill opacity.
  final double fillOpacity;

  /// Rest stroke or null (only boxes with a stroke at rest draw one).
  final int? stroke;

  /// Stroke width.
  final double strokeWidth;
}

/// A node of the art tree.
sealed class ArtNode {
  ArtNode(this.tf, this.opacity, this.clip, this.filter);

  /// Static transform [a, b, c, d, e, f], or null.
  final Float64List? tf;

  /// Static opacity.
  final double opacity;

  /// Clip id, or null.
  final String? clip;

  /// Filter id, or null.
  final String? filter;

  /// Does any part of it change from frame to frame (an animated layer, a box, a colour channel)?
  bool get isDynamic;
}

/// A group, possibly an animated layer.
class GroupNode extends ArtNode {
  GroupNode._(super.tf, super.opacity, super.clip, super.filter, this.kids, this.layer, this.px, this.py, this.cc, this.box, this.clipBox, this.plane)
      : isDynamic = layer != null || box != null || kids.any((k) => k.isDynamic);

  /// Children, back to front.
  final List<ArtNode> kids;

  /// The animated layer this group is, or null.
  final String? layer;

  /// Pivot of the layer.
  final double px, py;

  /// Colour channel: 0 none, 1 the layer's fill colour is currentColor below it, 2 its stroke colour.
  final int cc;

  /// Parametric box drawn behind the kids.
  final BoxDef? box;

  /// Clip the kids to the box.
  final bool clipBox;

  /// Plane of a top-level node ('main' unless the art splits itself).
  final String plane;

  @override
  final bool isDynamic;
}

/// A filled and stroked shape.
class ShapeNode extends ArtNode {
  ShapeNode._(super.tf, super.opacity, super.clip, super.filter, this.geometry, this.fill, this.fillOpacity, this.stroke, this.strokeOpacity, this.strokeWidth, this.cap, this.join, this.dash, this.dashOffset, this.evenOdd,
      [this.miter = 4]);

  /// Its geometry.
  final Geometry geometry;

  /// `#RRGGBB(AA)`, `currentColor`, `url:<paint>` or null.
  final String? fill, stroke;

  /// Paint opacities.
  final double fillOpacity, strokeOpacity;

  /// Stroke width.
  final double strokeWidth;

  /// 'butt', 'round', 'square'.
  final String cap;

  /// 'miter', 'round', 'bevel'.
  final String join;

  /// Dash pattern, or null.
  final Float64List? dash;

  /// Dash offset.
  final double dashOffset;

  /// Even-odd fill rule.
  final bool evenOdd;

  /// Miter limit of a mitered stroke (SVG's default, 4, unless the art says otherwise).
  final double miter;

  @override
  bool get isDynamic => fill == 'currentColor' || stroke == 'currentColor';

  /// With both a fill and a stroke the element's opacity is a layer; otherwise it multiplies the paints.
  bool get both => fill != null && stroke != null;
}

/// A worn part: draws whatever part the look puts in a kit figure's slot (`{"part": "fabio:hat"}`), at its
/// regular or alternate z (`"alt": true`: e.g. the near paw under a presented item).
class PartNode extends ArtNode {
  PartNode._(super.tf, super.opacity, super.clip, super.filter, this.slot, this.alt, [this.front = false]);

  /// The slot layer it draws (`<figure>:<slot>`).
  final String slot;

  /// The alternate z of the slot (drawn only when the worn part asks for it).
  final bool alt;

  /// The front z of the slot (`"front": true`: drawn only when the worn part is tagged `front`).
  final bool front;

  @override
  bool get isDynamic => true;
}

/// A node the app draws (`{"plugin": "waveform", "w": 120, "h": 40, "params": {...}}`): a live waveform, particles,
/// anything the engine does not draw itself. Drawn every frame by the painter the controller's [AliveExtensions]
/// give for [kind], in the node's own box (0, 0, [w], [h]) at its place in the tree.
class PluginNode extends ArtNode {
  PluginNode._(super.tf, super.opacity, super.clip, super.filter, this.kind, this.w, this.h, this.params);

  /// The painter's name.
  final String kind;

  /// The box the painter draws in.
  final double w, h;

  /// What the art says to it (numbers, strings, lists), as the file has it.
  final Map<String, Object?> params;

  @override
  bool get isDynamic => true;
}

/// A Figma text box.
class TextNode extends ArtNode {
  TextNode._(super.tf, super.opacity, super.clip, super.filter, this.spans, this.x, this.y, this.w, this.align, this.nowrap, this.baseline, this.anchor);

  /// Spans.
  final List<SpanDef> spans;

  /// Top left and width of the box.
  final double x, y, w;

  /// 'left', 'center' or 'right'.
  final String align;

  /// One line, not wrapped.
  final bool nowrap;

  /// An SVG text: [y] is the baseline and [anchor] places it (else a Figma text box: x, y is its top left).
  final bool baseline;

  /// 'start', 'middle' or 'end' (SVG text only).
  final String anchor;

  @override
  bool get isDynamic => spans.any((s) => s.colour == -1);
}

/// A gradient.
class PaintDef {
  PaintDef._(this.radial, this.bbox, this.coords, this.stops, this.colours, this.tf, [this.spread = 'pad', this.focal]);

  /// Radial (else linear).
  final bool radial;

  /// Coordinates in the shape's bounding box (else user space).
  final bool bbox;

  /// Linear [x1, y1, x2, y2] or radial [cx, cy, r].
  final Float64List coords;

  /// Stop offsets.
  final List<double> stops;

  /// Stop colours 0xAARRGGBB.
  final List<int> colours;

  /// Gradient transform, or null.
  final Float64List? tf;

  /// Beyond the ends: 'pad' (the end colours), 'reflect' or 'repeat'.
  final String spread;

  /// A radial gradient's focal point and radius [fx, fy, fr], or null (the centre).
  final Float64List? focal;
}

/// A drop shadow of a filter.
class ShadowDef {
  ShadowDef._(this.dx, this.dy, this.std, this.spread, this.colour);

  /// Offset, blur and spread.
  final double dx, dy, std, spread;

  /// Colour 0xAARRGGBB.
  final int colour;
}

/// Drop shadows and a layer blur.
class FilterDef {
  FilterDef._(this.blur, this.shadows);

  /// Layer blur sigma.
  final double blur;

  /// Drop shadows, drawn behind the content.
  final List<ShadowDef> shadows;
}

/// A clip shape (geometry with its own transform).
class ClipShapeDef {
  ClipShapeDef._(this.geometry, this.tf, [this.evenOdd = false]);

  /// Geometry.
  final Geometry geometry;

  /// Transform, or null.
  final Float64List? tf;

  /// Its clip-rule is even-odd (the clip is then the exact union of its shapes, each with its own rule).
  final bool evenOdd;
}

/// One art file.
class ArtDef {
  ArtDef._(this.id, this.width, this.height, this.offsetX, this.offsetY, this.paints, this.filters, this.clips, this.roots, [this._layersOf]);

  final Map<String, ({double px, double py, String? parent})>? _layersOf;

  /// Art id.
  final String id;

  /// Size of its frame.
  final double width, height;

  /// The art's own coordinates minus this offset are the scene's.
  final double offsetX, offsetY;

  /// Gradients by id.
  final Map<String, PaintDef> paints;

  /// Filters by id.
  final Map<String, FilterDef> filters;

  /// Clip shapes by id.
  final Map<String, List<ClipShapeDef>> clips;

  /// Top-level nodes.
  final List<ArtNode> roots;

  /// The same art without its node tree, paints, filters and clips: the id, size, offset and [layers] only (what a
  /// prepared art still needs). [roots] of the result is empty.
  ArtDef header() {
    return ArtDef._(id, width, height, offsetX, offsetY, const {}, const {}, const {}, const [], layers);
  }

  /// Every animated layer met in the tree, with its pivot and parent layer (first instance), in tree order.
  late final Map<String, ({double px, double py, String? parent})> layers = _layersOf ?? () {
    final out = <String, ({double px, double py, String? parent})>{};
    void walk(List<ArtNode> list, String? parent) {
      for (final n in list) {
        if (n is GroupNode) {
          var p = parent;
          if (n.layer != null) {
            out.putIfAbsent(n.layer!, () => (px: n.px, py: n.py, parent: parent));
            p = n.layer;
          }
          walk(n.kids, p);
        }
      }
    }

    walk(roots, null);
    return out;
  }();

  /// An art file's JSON with its `{"use": "<id>"}` nodes replaced by the subtrees of [fragments] (fragment files of
  /// `alive pack --share`, by id) and their paints, filters and clips merged in. Throws [AliveSchemaError] naming a
  /// fragment that is not given. The result is what the art was before it was packed.
  static Object? splice(Object? doc, Map<String, Object?> fragments, {String file = 'art.json'}) {
    final d = _obj(doc);
    if (d == null || fragments.isEmpty) return doc;
    final defs = <String, Map<String, dynamic>>{'paints': {}, 'filters': {}, 'clips': {}};
    final missing = <AliveProblem>[];
    var any = false;
    Object? walk(Object? n, String path) {
      final m = _obj(n);
      if (m == null) return n;
      final use = m['use'];
      if (use is String) {
        final f = _obj(fragments[use]);
        if (f == null) {
          missing.add(AliveProblem(path, 'no fragment "$use"', 'is _shared/$use.json there, and listed in the scene\'s "shared"?'));
          return n;
        }
        any = true;
        for (final k in defs.keys) {
          final x = _obj(f[k]);
          if (x != null) defs[k]!.addAll(x);
        }
        return f['node'];
      }
      final kids = m['kids'];
      if (kids is! List) return n;
      return {...m, 'kids': [for (var i = 0; i < kids.length; i++) walk(kids[i], '$path.kids[$i]')]};
    }

    final root = d['root'];
    if (root is! List) return doc;
    final out = [for (var i = 0; i < root.length; i++) walk(root[i], 'root[$i]')];
    if (missing.isNotEmpty) throw AliveSchemaError(file, missing);
    if (!any) return doc;
    return {
      ...d,
      'root': out,
      for (final e in defs.entries)
        if (e.value.isNotEmpty) e.key: {...e.value, ...?_obj(d[e.key])},
    };
  }

  /// Parse and check an art file. Throws [AliveSchemaError] listing every problem. [prepare] also reads every path's
  /// data into drawing commands ([Geometry.commands]), work the renderer would otherwise do on the UI thread.
  static ArtDef parse(Object? doc, {String file = 'art.json', bool prepare = false}) {
    final p = ProblemSink();
    final geometries = <Geometry>[];
    if (!checkHeader(doc, 'art', p)) throw AliveSchemaError(file, p.list);
    final d = _obj(doc)!;
    Float64List? tfOf(Object? v, String path) {
      if (v == null) return null;
      if (v is! List || v.length != 6 || !v.every((x) => _num(x) != null)) {
        p.add(path, 'tf is [a, b, c, d, e, f]');
        return null;
      }
      return Float64List.fromList([for (final x in v) (x as num).toDouble()]);
    }

    final paints = <String, PaintDef>{};
    for (final e in (_obj(d['paints']) ?? const <String, dynamic>{}).entries) {
      final gp = jsonKey('paints', e.key);
      final g = _obj(e.value);
      final stops = g?['stops'];
      if (g == null || (g['type'] != 'linear' && g['type'] != 'radial') || stops is! List || stops.isEmpty) {
        p.add(gp, 'a paint is {"type": "linear" | "radial", "stops": [[offset, "#RRGGBBAA"], ...]}');
        continue;
      }
      final offs = <double>[], cols = <int>[];
      for (var i = 0; i < stops.length; i++) {
        final s = stops[i];
        final c = s is List && s.length == 2 && s[1] is String ? parseHex(s[1] as String) : null;
        if (s is! List || _num(s[0]) == null || c == null) {
          p.add('$gp.stops[$i]', 'a stop is [offset, "#RRGGBB(AA)"]');
          continue;
        }
        offs.add(_num(s[0])!);
        cols.add(c);
      }
      final radial = g['type'] == 'radial', bbox = g['units'] != 'user';
      final coords = radial
          ? Float64List.fromList([_num(g['cx']) ?? (bbox ? .5 : 0), _num(g['cy']) ?? (bbox ? .5 : 0), _num(g['r']) ?? (bbox ? .5 : 0)])
          : Float64List.fromList([_num(g['x1']) ?? 0, _num(g['y1']) ?? 0, _num(g['x2']) ?? (bbox ? 1 : 0), _num(g['y2']) ?? 0]);
      final spread = g['spread'] ?? 'pad';
      if (spread != 'pad' && spread != 'reflect' && spread != 'repeat') p.add('$gp.spread', 'spread is pad, reflect or repeat');
      final focal = radial && (g['fx'] != null || g['fy'] != null || g['fr'] != null)
          ? Float64List.fromList([_num(g['fx']) ?? coords[0], _num(g['fy']) ?? coords[1], _num(g['fr']) ?? 0])
          : null;
      paints[e.key] = PaintDef._(radial, bbox, coords, offs, cols, tfOf(g['tf'], '$gp.tf'), spread is String ? spread : 'pad', focal);
    }
    final filters = <String, FilterDef>{};
    for (final e in (_obj(d['filters']) ?? const <String, dynamic>{}).entries) {
      final f = _obj(e.value);
      final sh = f?['shadows'];
      if (f == null || sh is! List) {
        p.add(jsonKey('filters', e.key), 'a filter is {"blur"?: n, "shadows": [...]}');
        continue;
      }
      final shadows = <ShadowDef>[];
      for (var i = 0; i < sh.length; i++) {
        final s = _obj(sh[i]);
        final c = s?['color'] is String ? parseHex(s!['color'] as String) : null;
        if (s == null || c == null) {
          p.add('${jsonKey('filters', e.key)}.shadows[$i]', 'a shadow is {dx, dy, std, spread?, color}');
          continue;
        }
        shadows.add(ShadowDef._(_num(s['dx']) ?? 0, _num(s['dy']) ?? 0, _num(s['std']) ?? 0, _num(s['spread']) ?? 0, c));
      }
      filters[e.key] = FilterDef._(_num(f['blur']) ?? 0, shadows);
    }
    final clips = <String, List<ClipShapeDef>>{};
    for (final e in (_obj(d['clips']) ?? const <String, dynamic>{}).entries) {
      final cp = jsonKey('clips', e.key);
      if (e.value is! List) {
        p.add(cp, 'a clip lists shapes');
        continue;
      }
      final list = e.value as List;
      final out = <ClipShapeDef>[];
      for (var i = 0; i < list.length; i++) {
        final s = _obj(list[i]);
        final g = s == null ? null : Geometry._read(s, '$cp[$i]', p);
        if (g == null) {
          p.add('$cp[$i]', 'a clip shape needs geometry');
          continue;
        }
        geometries.add(g);
        out.add(ClipShapeDef._(g, tfOf(s!['tf'], '$cp[$i].tf'), s['evenOdd'] == true));
      }
      clips[e.key] = out;
    }

    int? colourOf(Object? v, String path) {
      if (v == null) return null;
      final c = v is String ? parseHex(v) : null;
      if (c == null) p.add(path, 'bad colour $v');
      return c;
    }

    String? paintRef(Object? v, String path) {
      if (v == null) return null;
      if (v is String && (parseHex(v) != null || v == 'currentColor' || (v.startsWith('url:') && paints.containsKey(v.substring(4))))) return v;
      p.add(path, 'bad paint $v', 'a colour "#RRGGBB(AA)", "currentColor" or "url:<paint id>"');
      return null;
    }

    ArtNode? node(Object? raw, String path, bool top) {
      final n = _obj(raw);
      if (n == null) {
        p.add(path, 'a node is an object');
        return null;
      }
      if (n['slot'] != null) {
        p.add(path, 'a slot for the engine-drawn Fabio', 'this art needs alive_procedural; alive draws designed art only');
        return null;
      }
      final tf = tfOf(n['tf'], '$path.tf');
      final o = n['o'] == null ? 1.0 : _num(n['o']);
      if (o == null || o < 0 || o > 1) p.add('$path.o', 'o (opacity) lies in 0..1');
      final clip = _str(n['clip']);
      if (clip != null && !clips.containsKey(clip)) p.add('$path.clip', 'unknown clip "$clip"');
      final filter = _str(n['filter']);
      if (filter != null && !filters.containsKey(filter)) p.add('$path.filter', 'unknown filter "$filter"');
      final kinds = ['kids', 'text', 'part', 'plugin', ...Geometry.kinds].where((k) => n[k] != null).toList();
      if (kinds.length > 1) p.add(path, 'a node is one of a group, a shape or a text, found ${kinds.join(' + ')}');
      if (n['kids'] != null || n['layer'] != null || n['box'] != null) {
        final kidsRaw = n['kids'] ?? const <Object?>[];
        if (kidsRaw is! List) {
          p.add('$path.kids', 'kids is a list');
          return null;
        }
        final kids = <ArtNode>[];
        for (var i = 0; i < kidsRaw.length; i++) {
          final k = node(kidsRaw[i], '$path.kids[$i]', false);
          if (k != null) kids.add(k);
        }
        final pv = n['pivot'];
        double px = 0, py = 0;
        if (pv != null) {
          if (pv is List && pv.length == 2 && _num(pv[0]) != null && _num(pv[1]) != null) {
            px = _num(pv[0])!;
            py = _num(pv[1])!;
          } else {
            p.add('$path.pivot', 'pivot is [x, y]');
          }
        }
        BoxDef? box;
        final b = _obj(n['box']);
        if (n['box'] != null && b == null) p.add('$path.box', 'box is {x, y, w, h, r?, fill?, fo?, stroke?, sw?}');
        if (b != null) {
          box = BoxDef._(_num(b['x']) ?? 0, _num(b['y']) ?? 0, _num(b['w']) ?? 0, _num(b['h']) ?? 0, _num(b['r']) ?? 0, colourOf(b['fill'], '$path.box.fill'), _num(b['fo']) ?? 1,
              colourOf(b['stroke'], '$path.box.stroke'), _num(b['sw']) ?? 1);
        }
        final layer = n['layer'];
        if (layer != null && (layer is! String || layer.isEmpty)) p.add('$path.layer', 'layer is an id');
        final plane = n['plane'];
        if (plane != null && (!top || plane is! String)) p.add('$path.plane', 'only top-level nodes name a plane');
        final cc = n['cc'] == 'fill' ? 1 : n['cc'] == 'stroke' ? 2 : 0;
        return GroupNode._(tf, o ?? 1, clip, filter, kids, layer is String ? layer : null, px, py, cc, box, n['clipBox'] == true, plane is String ? plane : 'main');
      }
      if (n['plugin'] != null) {
        final kind = n['plugin'];
        if (kind is! String || kind.isEmpty) {
          p.add('$path.plugin', 'plugin names the painter the app registers ("waveform")');
          return null;
        }
        final params = n['params'];
        if (params != null && _obj(params) == null) p.add('$path.params', 'params is an object');
        return PluginNode._(tf, o ?? 1, clip, filter, kind, _num(n['w']) ?? 0, _num(n['h']) ?? 0, Map<String, Object?>.unmodifiable(_obj(params) ?? const <String, Object?>{}));
      }
      if (n['part'] != null) {
        final slot = n['part'];
        if (slot is! String || slot.isEmpty) {
          p.add('$path.part', 'part names a figure slot ("fabio:hat")');
          return null;
        }
        return PartNode._(tf, o ?? 1, clip, filter, slot, n['alt'] == true, n['front'] == true);
      }
      if (n['text'] != null) {
        final spans = <SpanDef>[];
        final t = n['text'];
        if (t is! List) {
          p.add('$path.text', 'text lists spans');
          return null;
        }
        for (var i = 0; i < t.length; i++) {
          final s = _obj(t[i]);
          final c = s?['color'] == 'currentColor' ? -1 : s?['color'] is String ? parseHex(s!['color'] as String) : 0xFF000000;
          if (s == null || s['t'] is! String || _num(s['size']) == null || c == null) {
            p.add('$path.text[$i]', 'a span is {t, font, size, weight, color}');
            continue;
          }
          spans.add(SpanDef._(s['t'] as String, s['font'] is String ? s['font'] as String : 'rubik', _num(s['size'])!, (_num(s['weight']) ?? 400).round(), c, _num(s['lh']), _num(s['ls'])));
        }
        final anchor = n['anchor'] ?? 'start';
        if (anchor != 'start' && anchor != 'middle' && anchor != 'end') p.add('$path.anchor', 'anchor is start, middle or end');
        return TextNode._(tf, o ?? 1, clip, filter, spans, _num(n['x']) ?? 0, _num(n['y']) ?? 0, _num(n['w']) ?? 0, n['align'] is String ? n['align'] as String : 'left', n['nowrap'] == true,
            n['baseline'] == true, anchor is String ? anchor : 'start');
      }
      final g = Geometry._read(n, path, p);
      if (g == null) {
        if (kinds.isEmpty) p.add(path, 'empty node');
        return null;
      }
      geometries.add(g);
      final dash = n['dash'];
      Float64List? dashes;
      if (dash != null) {
        if (dash is List && dash.every((x) => _num(x) != null)) {
          dashes = Float64List.fromList([for (final x in dash) (x as num).toDouble()]);
        } else {
          p.add('$path.dash', 'dash lists numbers');
        }
      }
      return ShapeNode._(tf, o ?? 1, clip, filter, g, paintRef(n['fill'], '$path.fill'), _num(n['fo']) ?? 1, paintRef(n['stroke'], '$path.stroke'), _num(n['so']) ?? 1, _num(n['sw']) ?? 1,
          n['cap'] is String ? n['cap'] as String : 'butt', n['join'] is String ? n['join'] as String : 'miter', dashes, _num(n['dashOff']) ?? 0, n['evenOdd'] == true, _num(n['miter']) ?? 4);
    }

    final roots = <ArtNode>[];
    final r = d['root'];
    if (r is! List) {
      p.add('root', 'root must be a list of nodes');
    } else {
      for (var i = 0; i < r.length; i++) {
        final n = node(r[i], 'root[$i]', true);
        if (n != null) roots.add(n);
      }
    }
    if (!p.ok) throw AliveSchemaError(file, p.list);
    if (prepare) {
      for (final g in geometries) {
        g.prepare();
      }
    }
    final size = d['size'] as List, off = d['offset'];
    return ArtDef._(d['id'] as String, (size[0] as num).toDouble(), (size[1] as num).toDouble(), off is List && off.length == 2 ? _num(off[0]) ?? 0 : 0,
        off is List && off.length == 2 ? _num(off[1]) ?? 0 : 0, paints, filters, clips, roots);
  }
}
