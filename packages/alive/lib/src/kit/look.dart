// Looks: what a kit figure wears. A look names a part per slot (or a preset of the pack), tints, a skin, and small
// adjustments within what each slot allows. The same rules as the CLI's composer (tools/lib/kit/compose.mjs), so a
// look drawn by `alive kit compose` and by the app are the same picture (kit_look_test checks it).
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'kit_def.dart';

/// Scale, offset and rotation of a part in its slot. Clamped to the slot's allowed ranges.
class AlivePartAdjust {
  /// An adjustment (the identity by default).
  const AlivePartAdjust({this.scale = 1, this.dx = 0, this.dy = 0, this.rot = 0});

  /// Scale about the slot's anchor.
  final double scale;

  /// Offset in kit units.
  final double dx, dy;

  /// Rotation in degrees (SVG's sign: clockwise on screen).
  final double rot;

  /// No change.
  static const AlivePartAdjust none = AlivePartAdjust();

  /// Is it the identity?
  bool get isNone => scale == 1 && dx == 0 && dy == 0 && rot == 0;

  @override
  bool operator ==(Object other) => other is AlivePartAdjust && other.scale == scale && other.dx == dx && other.dy == dy && other.rot == rot;

  @override
  int get hashCode => Object.hash(scale, dx, dy, rot);

  @override
  String toString() => 'AlivePartAdjust(scale: $scale, dx: $dx, dy: $dy, rot: $rot)';
}

/// What a kit figure wears: a preset of the pack, parts per slot on top of it, tints, a skin and adjustments.
///
/// ```dart
/// fabio.dress(const AliveLook(preset: 'explorer', parts: {'glasses': 'kit-glasses', 'held': 'prop-mic', 'face': 'happy'},
///     tints: {'outfit': Color(0xFF5B8DEF)}, adjust: {'hat': AlivePartAdjust(scale: 1.05, dy: -1)}));
/// ```
class AliveLook {
  /// A look.
  const AliveLook({this.preset, this.parts = const {}, this.tints = const {}, this.adjust = const {}, this.skin});

  /// A look of the pack (`host`, `explorer`, ...) to start from, or null for the pack's defaults only.
  final String? preset;

  /// Part per slot: a part id, or a name the slot knows (`'happy'` in `face`, `'wave'` in `near-paw`); null takes the
  /// slot off. `face` with a split expression fills `eyes`, `brows`, `mouth`, `cheeks` and `marks`.
  final Map<String, String?> parts;

  /// Tints: a slot (shifts its part's main colour family to the colour) or a token (`skin`, `paw`, `lens`...).
  final Map<String, Color> tints;

  /// Adjustments per slot (clamped to the slot's range).
  final Map<String, AlivePartAdjust> adjust;

  /// The skin (paw family: `blue`, `royal`), or the pack's default.
  final String? skin;

  /// This look with one slot changed.
  AliveLook wear(String slot, String? part, {Color? tint, AlivePartAdjust? adjust}) => AliveLook(
        preset: preset,
        parts: {...parts, slot: part},
        tints: tint == null ? tints : {...tints, slot: tint},
        adjust: adjust == null ? this.adjust : {...this.adjust, slot: adjust},
        skin: skin,
      );

  /// This look with other values.
  AliveLook copyWith({String? preset, Map<String, String?>? parts, Map<String, Color>? tints, Map<String, AlivePartAdjust>? adjust, String? skin}) =>
      AliveLook(preset: preset ?? this.preset, parts: parts ?? this.parts, tints: tints ?? this.tints, adjust: adjust ?? this.adjust, skin: skin ?? this.skin);

  @override
  String toString() => 'AliveLook(preset: $preset, parts: $parts, tints: $tints, adjust: $adjust, skin: $skin)';
}

/// One slot of a resolved look.
class WornPart {
  /// A worn part.
  WornPart(this.part, {this.alt = false, this.front = false, this.adjust = AlivePartAdjust.none, this.recolour = const {}});

  /// The part id.
  final String part;

  /// Drawn at the slot's alternate z.
  final bool alt;

  /// Drawn at the slot's front z (when it has one; it wins over [alt]).
  final bool front;

  /// Its adjustment (already clamped).
  final AlivePartAdjust adjust;

  /// Colour swaps (0xRRGGBB to 0xRRGGBB).
  final Map<int, int> recolour;

  /// A key for caching compiled parts by part and colours.
  late final String cacheKey = recolour.isEmpty ? part : '$part|${(recolour.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}:${e.value}').join(',')}';
}

/// A look resolved against a pack: what each slot wears, and what could not be resolved.
class ResolvedLook {
  /// A resolved look.
  ResolvedLook(this.slots, this.skin, this.problems);

  /// Slot id to what it wears (slots not listed wear nothing).
  final Map<String, WornPart> slots;

  /// The skin.
  final String skin;

  /// Names that did not resolve, adjustments clamped.
  final List<String> problems;
}

/// Resolve [look] against [kit] (the same rules as compose.mjs resolveLook).
ResolvedLook resolveLook(KitDef kit, AliveLook look) {
  final problems = <String>[];
  final base = <String, String?>{...kit.lookDefaults};
  if (look.preset != null) {
    final pre = kit.looks[look.preset];
    if (pre == null) {
      problems.add('no look "${look.preset}"');
    } else {
      base.addAll(pre);
    }
  }
  base.addAll(look.parts);
  final skin = look.skin ?? base['skin'] ?? kit.defaultSkin;
  final names = <String, String>{};
  for (final e in base.entries) {
    if (!kit.slot.containsKey(e.key)) continue;
    final name = e.value;
    if (name == null || name.isEmpty) {
      names.remove(e.key);
      continue;
    }
    // a face the pack does not have is the neutral face (round 7: never a blank face, never the wrong feeling)
    final own = kit.resolve(e.key, name, skin: skin);
    final fallback = own == null && e.key == 'face' ? kit.resolve('face', 'neutral', skin: skin) : null;
    if (own == null) problems.add(fallback != null ? 'no part "$name" for slot "face"; the neutral face instead' : 'no part "$name" for slot "${e.key}"');
    final id = own ?? fallback;
    if (id == null) continue;
    final part = kit.parts[id]!;
    if (e.key == 'face' && part.split.isNotEmpty) {
      // a split expression fills its feature slots (a feature named in the look itself wins)
      for (final f in part.split.entries) {
        if (!look.parts.containsKey(f.key)) names[f.key] = f.value;
      }
      names.remove('face');
      continue;
    }
    names[e.key] = id;
  }
  // the preset's own tints (kit 1.6.0: a look can carry tints), under the tints the figure's look adds
  final preTints = look.preset == null ? null : kit.lookTints[look.preset];
  final tints = preTints == null || preTints.isEmpty ? look.tints : <String, Color>{for (final e in preTints.entries) e.key: Color(0xFF000000 | e.value), ...look.tints};
  final slots = <String, WornPart>{};
  for (final e in names.entries) {
    final part = kit.parts[e.value]!;
    final adj = look.adjust[e.key];
    slots[e.key] = WornPart(
      e.value,
      alt: part.alt,
      front: part.front,
      adjust: adj == null ? AlivePartAdjust.none : clampAdjust(kit, e.key, adj, problems),
      recolour: recolourFor(kit, part, e.key, tints),
    );
  }
  return ResolvedLook(slots, skin, problems);
}

/// An adjustment clamped to what the slot allows.
AlivePartAdjust clampAdjust(KitDef kit, String slot, AlivePartAdjust a, [List<String>? problems]) {
  final r = kit.slot[slot]?.range ?? KitRange.fixed;
  double c(String k, double v, (double, double) lim) {
    if (v < lim.$1 || v > lim.$2) {
      problems?.add('$slot $k $v is outside ${lim.$1}..${lim.$2}; clamped');
      return v.clamp(lim.$1, lim.$2);
    }
    return v;
  }

  return AlivePartAdjust(scale: c('scale', a.scale, r.scale), dx: c('dx', a.dx, r.dx), dy: c('dy', a.dy, r.dy), rot: c('rot', a.rot, r.rot));
}

/// The colour swaps a part gets from tints: a slot tint shifts its main family, a token tint the token's family.
Map<int, int> recolourFor(KitDef kit, KitPart part, String slot, Map<String, Color> tints) {
  if (tints.isEmpty) return const {};
  final out = <int, int>{};
  void family(int key, List<int> fam, int target) {
    for (final c in fam) {
      out[c] = shiftColour(c, key, target);
    }
  }

  for (final e in tints.entries) {
    final target = e.value.toARGB32() & 0xFFFFFF;
    if (e.key == slot && part.mainKey != null) family(part.mainKey!, part.mainFamily, target);
    final tok = kit.tokens[e.key];
    if (tok != null && part.tokens.contains(e.key)) family(tok.colour, tok.family, target);
  }
  return out;
}

/// The key colour goes to the target; every other colour keeps its hue, saturation and lightness offsets from the key
/// (so an outfit's shades stay shades). 0xRRGGBB in and out. compose.mjs shiftColour does the same.
int shiftColour(int c, int key, int target) {
  if (c == key) return target;
  final (h, s, l) = _hsl(c);
  final (hk, sk, lk) = _hsl(key);
  final (ht, st, lt) = _hsl(target);
  final h2 = ((h + (ht - hk)) % 360 + 360) % 360;
  final s2 = sk > 0.001 ? (s * st / sk).clamp(0.0, 1.0) : st;
  final l2 = (l + (lt - lk)).clamp(0.0, 1.0);
  return _rgb(h2, s2, l2);
}

(double, double, double) _hsl(int c) {
  final r = ((c >> 16) & 255) / 255, g = ((c >> 8) & 255) / 255, b = (c & 255) / 255;
  final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b)), l = (mx + mn) / 2;
  var h = 0.0, s = 0.0;
  if (mx != mn) {
    final d = mx - mn;
    s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    h = mx == r ? (g - b) / d + (g < b ? 6 : 0) : mx == g ? (b - r) / d + 2 : (r - g) / d + 4;
    h *= 60;
  }
  return (h, s, l);
}

int _rgb(double h, double s, double l) {
  double k(double n) => (n + h / 30) % 12;
  final a = s * math.min(l, 1 - l);
  double f(double n) => l - a * math.max(-1, math.min(k(n) - 3, math.min(9 - k(n), 1)));
  int ch(double v) => (v * 255).clamp(0, 255).round();
  return (ch(f(0)) << 16) | (ch(f(8)) << 8) | ch(f(4));
}
