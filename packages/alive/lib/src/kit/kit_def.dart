// alive/1 kit files (kind "kit"): an art pack's rig and parts index. Pure Dart, checked like scenes and art: every
// problem with its JSON path. The parts themselves are plain art files (parts/<id>.json).
import 'dart:math' as math;
import 'dart:typed_data';

import '../schema/errors.dart';
import '../schema/scene_def.dart' show ProblemSink, checkHeader, jsonKey;

typedef _J = Map<String, dynamic>;
_J? _obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;
double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
String? _str(Object? v) => v is String ? v : null;
List<Object?>? _list(Object? v) => v is List ? v.cast<Object?>() : null;
List<double>? _nums(Object? v, int n) => v is List && v.length == n && v.every((x) => _num(x) != null) ? [for (final x in v) (x as num).toDouble()] : null;

KitHem? _hem(Object? raw, String path, Object? place, ProblemSink p) {
  if (raw == null) return null;
  final h = _obj(raw);
  final e = h?['edge'];
  final pts = <double>[];
  if (h == null || e is! List || e.length < 2) {
    p.add(path, 'a hem is {edge: [[x, y], ...] (two or more, left to right), rest?, wave?, wavelength?, speed?, energy?, settle?, shear?}');
    return null;
  }
  var lastX = double.negativeInfinity;
  for (var i = 0; i < e.length; i++) {
    final v = _nums(e[i], 2);
    if (v == null || v[0] < lastX) {
      p.add('$path.edge[$i]', 'an edge point is [x, y], left to right');
      return null;
    }
    lastX = v[0];
    pts.addAll(v);
  }
  if (place != 'canvas') p.add(path, 'a hem slot is placed on the canvas ("place": "canvas"): its edge is in canvas units');
  return KitHem._(Float64List.fromList(pts), _num(h['rest']) ?? 0.5, _num(h['wave']) ?? 2.2, _num(h['wavelength']) ?? 58, _num(h['speed']) ?? 5.2, _num(h['energy']) ?? 60,
      _num(h['settle']) ?? 2, _num(h['shear']) ?? 0.02);
}

/// A bone of the rig: a point the slots hang from, with a pivot and a parent.
class KitBone {
  KitBone._(this.id, this.px, this.py, this.parent);

  /// Bone id (`root`, `body`, `head`, `neck` for Fabio).
  final String id;

  /// Pivot in canvas units.
  final double px, py;

  /// Parent bone (null: the root).
  final String? parent;
}

/// Allowed adjustment of a part in its slot: scale, offset and rotation ranges.
class KitRange {
  const KitRange._(this.scale, this.dx, this.dy, this.rot);

  /// [min, max] of each.
  final (double, double) scale, dx, dy, rot;

  /// No adjustment allowed.
  static const KitRange fixed = KitRange._((1, 1), (0, 0), (0, 0), (0, 0));
}

/// Physics of a slot (a worn spring: it lags behind its bone and settles).
class KitPhysics {
  KitPhysics._(this.stiffness, this.damping, this.mass, this.tilt, this.max);

  /// Spring parameters, as in a scene's `worn`.
  final double stiffness, damping, mass, tilt, max;
}

/// A hem: the part in this slot (cloth below a garment's hem) is clipped above a line just under his outline, so it
/// does not show at rest; after a move the line ripples and the cloth waves below it, then settles. The slot's spring
/// ([KitSlot.physics], on when the figure rides physics) gives the lag and the energy; the slot itself does not move
/// with the lag, it shears about its anchor instead. All lengths in canvas units.
class KitHem {
  KitHem._(this.edge, this.rest, this.wave, this.wavelength, this.speed, this.energy, this.settle, this.shear);

  /// The resting bottom edge, left to right: x0, y0, x1, y1, ...
  final Float64List edge;

  /// Ripple amplitude at rest.
  final double rest;

  /// Ripple amplitude added at full energy.
  final double wave;

  /// Length of one ripple along the edge.
  final double wavelength;

  /// How fast the ripple travels (radians of phase per second).
  final double speed;

  /// The spring's speed (units per second) that counts as full energy (energy is held at most at 1.4 of it).
  final double energy;

  /// How fast the energy dies away (per second).
  final double settle;

  /// The cloth's shear (tangent of its angle) per unit of the spring's horizontal lag.
  final double shear;

  /// The largest energy a move can give (as the board's outfit model).
  static const double maxEnergy = 1.4;
}

/// A slot: where a kind of part goes, in what order, and how it follows him.
class KitSlot {
  KitSlot._(this.id, this.z, this.zAlt, this.attach, this.ax, this.ay, this.arot, this.place, this.accepts, this.range, this.physics, [this.zFront, this.hem]);

  /// Slot id (`hat`, `near-paw`, `held`, ...).
  final String id;

  /// Drawing order (back to front), and the alternate order a part can ask for (M3: a present paw under its item).
  final double z;

  /// The alternate place in the order, if the slot has one.
  final double? zAlt;

  /// A third place in the order, for parts tagged `front` (the far paw in front of a held item when both paws
  /// carry it: above `held`, under the near paw), if the slot has one.
  final double? zFront;

  /// The hem the slot's part is clipped to and waves below (cloth under a garment), if it is one.
  final KitHem? hem;

  /// The bone (or, for an item held by a paw, the slot) it hangs from.
  final String attach;

  /// Anchor point (canvas units) and rotation (degrees, SVG's sign).
  final double ax, ay, arot;

  /// How parts are placed: `canvas` (drawn on his canvas), `origin` (a part's own origin at the anchor), `grip` (an
  /// item's grip point at its paw).
  final String place;

  /// Part categories it takes.
  final List<String> accepts;

  /// Allowed adjustment.
  final KitRange range;

  /// Physics, if it rides any.
  final KitPhysics? physics;
}

/// A part of the pack.
class KitPart {
  KitPart._(this.id, this.slot, this.category, this.tags, this.frame, this.ox, this.oy, this.grips, this.grip, this.alt, this.tokens, this.mainKey, this.mainFamily, this.split, this.of, this.name);

  /// Part id (its file is `parts/<id>.json`).
  final String id;

  /// Its slot and category.
  final String slot, category;

  /// Tags (`hats`, `safari`, `retired`, `handheld`, `lettered`, a skin...).
  final List<String> tags;

  /// Its frame [x, y, w, h] (the SVG viewBox).
  final Float64List frame;

  /// Its origin (where it attaches), in its own units.
  final double ox, oy;

  /// An item's grip points by grip kind (`hold`, `carry`, `present`), in its own units.
  final Map<String, (double, double)> grips;

  /// A paw's grip kind, if it holds things.
  final String? grip;

  /// Drawn at its slot's alternate z.
  final bool alt;

  /// Tint tokens it carries.
  final List<String> tokens;

  /// Its main colour family (what a slot tint shifts): the key colour and the family (0xRRGGBB).
  final int? mainKey;

  /// The colours of the main family.
  final List<int> mainFamily;

  /// A face split into features: feature slot -> part id.
  final Map<String, String> split;

  /// A face feature's face.
  final String? of;

  /// The designer's name for it.
  final String? name;

  /// Retired (never chosen: the pointing paw, the two-layer paws).
  bool get retired => tags.contains('retired');

  /// Drawn at its slot's front z, when the slot has one (tag `front`, or `"front": true`).
  bool get front => tags.contains('front');
}

/// A tint token: a named colour family (his skin, the paw, the lens...).
class KitToken {
  KitToken._(this.id, this.colour, this.family);

  /// Token id.
  final String id;

  /// Its key colour and family (0xRRGGBB).
  final int colour;

  /// Every colour of the family.
  final List<int> family;
}

/// A grip kind: does the paw draw over the item it holds, and which point of the item it takes.
class KitGrip {
  KitGrip._(this.id, this.pawOver);

  /// Grip id.
  final String id;

  /// The paw over the item (hold, carry), or under it (present).
  final bool pawOver;
}

int? _hex(Object? v) {
  if (v is! String || !RegExp(r'^#[0-9A-Fa-f]{6}').hasMatch(v)) return null;
  return int.parse(v.substring(1, 7), radix: 16);
}

/// An art pack's kit.json.
class KitDef {
  KitDef._(this.id, this.name, this.version, this.canvas, this.bones, this.slots, this.parts, this.tokens, this.grips, this.skins, this.defaultSkin, this.looks, this.lookDefaults, this.actions, this.pools,
      this.bodyColour, [this.lookTints = const {}]);

  /// Pack id (the folder `kits/<id>`).
  final String id;

  /// Name and version.
  final String? name;

  /// The pack's content version (bumped by every import into it).
  final String version;

  /// His canvas [x, y, w, h], if the rig has one.
  final Float64List? canvas;

  /// Bones by id.
  final Map<String, KitBone> bones;

  /// Slots in the order the rig lists them, and by id.
  final List<KitSlot> slots;
  /// Slots by id.
  late final Map<String, KitSlot> slot = {for (final s in slots) s.id: s};

  /// Parts by id.
  final Map<String, KitPart> parts;

  /// Tint tokens by id.
  final Map<String, KitToken> tokens;

  /// Grip kinds.
  final Map<String, KitGrip> grips;

  /// Skins (paw families) and the default one.
  final List<String> skins;

  /// The skin a look gets unless it names one.
  final String defaultSkin;

  /// Look presets: slot -> part name, plus `skin`.
  final Map<String, Map<String, String>> looks;

  /// A look's own tints (kit 1.6.0): {look: {slot or token: 0xRRGGBB}}, under the tints a figure's look adds.
  final Map<String, Map<String, int>> lookTints;

  /// What every look starts from (the body, the paws at rest).
  final Map<String, String> lookDefaults;

  /// Actions (clips keyed on bone and slot layers, `@` for the figure id) and pools, as JSON.
  final Map<String, Object?> actions;

  /// Pools of actions, looks and parts, as JSON.
  final Map<String, Object?> pools;

  /// The canonical body colour (0xRRGGBB), if the rig names one.
  final int? bodyColour;

  /// The root bone.
  String get rootBone => bones.values.firstWhere((b) => b.parent == null, orElse: () => bones.values.first).id;

  /// The part a name means in a slot: a part id; or the most specific part of that slot carrying the name as a tag
  /// (with the skin, for paws); or, in a face feature slot, that feature of the face of that name. Null if none.
  /// The CLI resolves names the same way (tools/lib/kit/compose.mjs resolvePart).
  String? resolve(String slotId, String? name, {String? skin}) {
    if (name == null || name.isEmpty) return null;
    final s = slot[slotId];
    final direct = parts[name];
    if (direct != null) return direct.slot == slotId || (s?.accepts.contains(direct.category) ?? false) ? name : null;
    final sk = skin ?? defaultSkin;
    final skinSet = skins.toSet();
    final cands = parts.values.where((p) => p.slot == slotId && p.of == null && !p.retired && p.tags.contains(name) && (!p.tags.any(skinSet.contains) || p.tags.contains(sk))).toList()
      ..sort((a, b) {
        final c = a.tags.length.compareTo(b.tags.length);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    if (cands.isNotEmpty) return cands.first.id;
    // a face feature by its face's name: "happy" in the mouth slot is face-happy.mouth
    KitPart? best;
    for (final p in parts.values) {
      if (p.slot != slotId || p.of == null) continue;
      final face = parts[p.of!];
      if (face == null || !face.tags.contains(name)) continue;
      if (best == null || face.tags.length < parts[best.of!]!.tags.length) best = p;
    }
    return best?.id;
  }

  /// Parts of a slot carrying a tag (not retired), sorted by id.
  List<String> tagged(String slotId, String tag) => [for (final p in parts.values) if (p.slot == slotId && p.of == null && !p.retired && p.tags.contains(tag)) p.id]..sort();

  /// Parse and check a kit file. Throws [AliveSchemaError] listing every problem.
  static KitDef parse(Object? doc, {String file = 'kit.json'}) {
    final p = ProblemSink();
    if (!_header(doc, p)) throw AliveSchemaError(file, p.list);
    final d = _obj(doc)!;
    final bones = <String, KitBone>{};
    for (final e in (_obj(d['bones']) ?? const <String, dynamic>{}).entries) {
      final b = _obj(e.value);
      final pv = _nums(b?['pivot'], 2);
      if (b == null || pv == null) {
        p.add(jsonKey('bones', e.key), 'a bone is {"pivot": [x, y], "parent"?: bone}');
        continue;
      }
      bones[e.key] = KitBone._(e.key, pv[0], pv[1], _str(b['parent']));
    }
    if (bones.isEmpty) p.add('bones', 'a rig needs at least its root bone');
    for (final b in bones.values) {
      if (b.parent != null && !bones.containsKey(b.parent)) p.add('${jsonKey('bones', b.id)}.parent', 'unknown bone "${b.parent}"');
    }
    (double, double) range(Object? v, (double, double) def) {
      final r = _nums(v, 2);
      return r == null ? def : (math.min(r[0], r[1]), math.max(r[0], r[1]));
    }

    final slots = <KitSlot>[];
    final sl = d['slots'];
    if (sl is! List || sl.isEmpty) p.add('slots', 'a rig lists its slots');
    for (var i = 0; i < (sl is List ? sl.length : 0); i++) {
      final s = _obj((sl as List)[i]);
      final sp = 'slots[$i]';
      final a = _nums(s?['anchor'], 3);
      if (s == null || s['id'] is! String || _num(s['z']) == null || s['attach'] is! String || a == null) {
        p.add(sp, 'a slot is {id, z, attach, anchor: [x, y, rot], place, accepts, adjust}');
        continue;
      }
      final place = s['place'] ?? 'canvas';
      if (place != 'canvas' && place != 'origin' && place != 'grip') p.add('$sp.place', 'place is canvas, origin or grip');
      final adj = _obj(s['adjust']);
      final ph = _obj(s['physics']);
      slots.add(KitSlot._(
        s['id'] as String,
        _num(s['z'])!,
        _num(s['zAlt']),
        s['attach'] as String,
        a[0],
        a[1],
        a[2],
        place is String ? place : 'canvas',
        [for (final x in (_list(s['accepts']) ?? const [])) if (x is String) x],
        adj == null ? KitRange.fixed : KitRange._(range(adj['scale'], (1, 1)), range(adj['dx'], (0, 0)), range(adj['dy'], (0, 0)), range(adj['rot'], (0, 0))),
        ph == null ? null : KitPhysics._(_num(ph['stiffness']) ?? 600, _num(ph['damping']) ?? 30, _num(ph['mass']) ?? 1, _num(ph['tilt']) ?? 0, _num(ph['max']) ?? 2),
        _num(s['zFront']),
        _hem(s['hem'], '$sp.hem', place, p),
      ));
    }
    final slotIds = {for (final s in slots) s.id};
    for (final s in slots) {
      if (!bones.containsKey(s.attach) && !slotIds.contains(s.attach)) p.add(jsonKey('slots', s.id), 'slot "${s.id}" attaches to "${s.attach}", which is neither a bone nor a slot');
    }
    final parts = <String, KitPart>{};
    for (final e in (_obj(d['parts']) ?? const <String, dynamic>{}).entries) {
      final pp = jsonKey('parts', e.key);
      final x = _obj(e.value);
      final frame = _nums(x?['frame'], 4);
      if (x == null || x['slot'] is! String || frame == null) {
        p.add(pp, 'a part is {slot, category, tags, frame: [x, y, w, h], origin}');
        continue;
      }
      if (!slotIds.contains(x['slot'])) p.add('$pp.slot', 'unknown slot "${x['slot']}"');
      final o = _nums(x['origin'], 2) ?? const [0.0, 0.0];
      final grips = <String, (double, double)>{};
      for (final g in (_obj(x['grips']) ?? const <String, dynamic>{}).entries) {
        final v = _nums(g.value, 2);
        if (v != null) grips[g.key] = (v[0], v[1]);
      }
      final main = _obj(x['main']);
      parts[e.key] = KitPart._(
        e.key,
        x['slot'] as String,
        x['category'] is String ? x['category'] as String : x['slot'] as String,
        [for (final t in (_list(x['tags']) ?? const [])) if (t is String) t, if (x['front'] == true && !((_list(x['tags']))?.contains('front') ?? false)) 'front'],
        Float64List.fromList(frame),
        o[0],
        o[1],
        grips,
        _str(x['grip']),
        x['alt'] == true,
        [for (final t in (_list(x['tokens']) ?? const [])) if (t is String) t],
        _hex(main?['key']),
        [for (final c in (_list(main?['family']) ?? const [])) if (_hex(c) != null) _hex(c)!],
        {for (final s in (_obj(x['split']) ?? const <String, dynamic>{}).entries) if (s.value is String) s.key: s.value as String},
        _str(x['of']),
        _str(x['name']),
      );
    }
    for (final part in parts.values) {
      for (final s in part.split.values) {
        if (!parts.containsKey(s)) p.add('${jsonKey('parts', part.id)}.split', 'unknown part "$s"');
      }
    }
    final tokens = <String, KitToken>{};
    for (final e in (_obj(d['tokens']) ?? const <String, dynamic>{}).entries) {
      final t = _obj(e.value);
      final c = _hex(t?['colour']);
      if (c == null) continue;
      tokens[e.key] = KitToken._(e.key, c, [for (final f in (_list(t!['family']) ?? const [])) if (_hex(f) != null) _hex(f)!]);
    }
    final grips = <String, KitGrip>{};
    for (final e in (_obj(d['grips']) ?? const <String, dynamic>{}).entries) {
      grips[e.key] = KitGrip._(e.key, _obj(e.value)?['pawOver'] != false);
    }
    final sk = _obj(d['skins']);
    final looks = <String, Map<String, String>>{};
    final lookTints = <String, Map<String, int>>{};
    for (final e in (_obj(d['looks']) ?? const <String, dynamic>{}).entries) {
      looks[e.key] = {for (final f in (_obj(e.value) ?? const <String, dynamic>{}).entries) if (f.value is String) f.key: f.value as String};
      final lt = _obj(_obj(e.value)?['tint']);
      if (lt != null) lookTints[e.key] = {for (final t in lt.entries) if (_hex(t.value) != null) t.key: _hex(t.value)!};
    }
    if (!p.ok) throw AliveSchemaError(file, p.list);
    return KitDef._(
      d['id'] as String,
      _str(d['name']),
      d['version'] is String ? d['version'] as String : '0',
      _nums(d['canvas'], 4) == null ? null : Float64List.fromList(_nums(d['canvas'], 4)!),
      bones,
      slots,
      parts,
      tokens,
      grips,
      [for (final v in (_list(sk?['values']) ?? const [])) if (v is String) v],
      sk?['default'] is String ? sk!['default'] as String : 'blue',
      looks,
      {for (final f in (_obj(d['lookDefaults']) ?? const <String, dynamic>{}).entries) if (f.value is String) f.key: f.value as String},
      _obj(d['actions']) ?? const {},
      _obj(d['pools']) ?? const {},
      _hex(_obj(d['body'])?['colour']),
      lookTints,
    );
  }

  static bool _header(Object? doc, ProblemSink p) {
    final d = _obj(doc);
    if (d == null) {
      p.add('', 'not a JSON object');
      return false;
    }
    // kits share the scene and art header (schema alive/1, an id); their size is their canvas
    if (d['kind'] != 'kit') {
      p.add('kind', 'expected kind "kit", found ${d['kind']}');
      return false;
    }
    final probe = {...d, 'kind': 'kit', 'size': d['size'] ?? [1, 1]};
    return checkHeader(probe, 'kit', p);
  }
}
