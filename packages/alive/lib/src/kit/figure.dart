// Kit figures at run time.
//
// A figure's art is generated from the pack's rig: his root layer (the figure id, placed where the scene says), one
// layer per bone (`fabio.body`, `fabio.head`, `fabio.neck`) and one per slot (`fabio:hat`, `fabio:near-paw`, ...),
// nested as the rig attaches them, and in each slot group a part node drawn by whatever the look puts there. Every
// position is in canvas units (no static transform below the root), so pivots, anchors and physics all agree. A clip
// keys these layers, so it plays on any look; a look only changes what the part nodes draw.
//
// Placement of a worn part (the same as compose.mjs placement):
//   translate(anchor x, y) . rotate(anchor rot) . translate(dx, dy) . rotate(rot) . scale(scale) . translate(-origin)
// For a held item the anchor is its paw's anchor point plus the held slot's, without the paw's rotation, and its
// origin is its grip point for the paw's grip kind.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../render/art_renderer.dart';
import '../runtime/layer_state.dart';
import '../schema/art_def.dart';
import '../schema/scene_def.dart';
import 'kit_def.dart';
import 'look.dart';

/// A loaded art pack: its kit, the part art loaded so far, and compiled parts shared by every player of the scene.
class KitData {
  /// A pack.
  KitData(this.def, {this.fonts = const AliveFonts()});

  /// The kit.
  final KitDef def;

  /// Fonts for any text in parts.
  final AliveFonts fonts;

  /// Part art loaded so far, by part id.
  final Map<String, ArtDef> art = {};
  final Map<String, CompiledArt> _compiled = {};
  /// The values parts are drawn with (parts have no animated layers of their own).
  final LayerState rest = LayerState(0);
  bool _disposed = false;

  /// Is the part's art loaded?
  bool has(String part) => art.containsKey(part);

  /// The compiled part for [w] (its tint included), prepared on first use. Null when its art is not loaded.
  CompiledArt? compiled(WornPart w) {
    if (_disposed) return null;
    final hit = _compiled[w.cacheKey];
    if (hit != null) return hit;
    final a = art[w.part];
    if (a == null) return null;
    return _compiled[w.cacheKey] = CompiledArt(a, const {}, fonts: fonts, recolour: w.recolour);
  }

  /// Release every compiled part.
  void dispose() {
    _disposed = true;
    for (final c in _compiled.values) {
      c.dispose();
    }
    _compiled.clear();
  }
}

/// One figure of a scene: its rig in the scene, the layer ids, the generated art and the placement of parts.
class FigureRig {
  /// The rig of [def] from [kit].
  FigureRig(this.def, this.kit);

  /// The figure.
  final FigureDef def;

  /// Its pack.
  final KitData kit;

  KitDef get _k => kit.def;

  /// The figure id.
  String get id => def.id;

  /// The layer of a bone (the root bone is the figure itself).
  String boneLayer(String bone) => bone == _k.rootBone ? id : '$id.$bone';

  /// The layer of a slot.
  String slotLayer(String slot) => '$id:$slot';

  /// The slot a slot hangs from (an item held by a paw), or null when it hangs from a bone. A bone wins over a slot
  /// of the same name (Fabio has a `body` bone and a `body` slot).
  KitSlot? holderOf(KitSlot s) => _k.bones.containsKey(s.attach) ? null : _k.slot[s.attach];

  /// Where a slot's anchor sits in canvas units (a held item: its paw's anchor plus its own).
  (double, double) anchorOf(KitSlot s) {
    final holder = holderOf(s);
    return holder == null ? (s.ax, s.ay) : (holder.ax + s.ax, holder.ay + s.ay);
  }

  /// The figure's art: the root layer placed in the scene, and each slot (at its z and, if it has one, its alternate
  /// z) inside the layers of the bones and slots it hangs from.
  Map<String, Object?> artJson() {
    final k = _k;
    final root = k.bones[k.rootBone]!;
    // placement: translate(at) . scale(scale) [. mirror about the canvas centre]
    var tf = <double>[def.scale, 0, 0, def.scale, def.x, def.y];
    if (def.flip) {
      final cx = k.canvas == null ? root.px : k.canvas![0] + k.canvas![2] / 2;
      tf = _mul(tf, [-1, 0, 0, 1, 2 * cx, 0]);
    }
    // each slot at its z, its alternate z and its front z (0, 1, 2)
    final entries = <(double, KitSlot, int)>[];
    for (final s in k.slots) {
      entries.add((s.z, s, 0));
      if (s.zAlt != null) entries.add((s.zAlt!, s, 1));
      if (s.zFront != null) entries.add((s.zFront!, s, 2));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    final kids = <Object?>[];
    for (final (_, s, zone) in entries) {
      Map<String, Object?> node = {'part': slotLayer(s.id), if (zone == 1) 'alt': true, if (zone == 2) 'front': true};
      // the slot's own layer, pivot at its anchor
      final (ax, ay) = anchorOf(s);
      node = {'layer': slotLayer(s.id), 'pivot': [ax, ay], 'kids': [node]};
      // up through what it hangs from: a holding slot, then bones to (not including) the root
      var at = s.attach;
      for (var guard = 0; guard < 16; guard++) {
        final holder = k.bones.containsKey(at) ? null : k.slot[at];
        if (holder != null) {
          node = {'layer': slotLayer(holder.id), 'pivot': [holder.ax, holder.ay], 'kids': [node]};
          at = holder.attach;
          continue;
        }
        final b = k.bones[at];
        if (b == null || b.parent == null) break;
        node = {'layer': boneLayer(b.id), 'pivot': [b.px, b.py], 'kids': [node]};
        at = b.parent!;
      }
      kids.add(node);
    }
    final c = k.canvas;
    return {
      'schema': 'alive/1',
      'kind': 'art',
      'id': id,
      'size': c == null ? [1, 1] : [c[2], c[3]],
      'source': {'from': 'kit', 'kit': k.id, 'version': k.version},
      'root': [
        {'layer': id, 'pivot': [root.px, root.py], 'tf': tf, 'kids': kids},
      ],
    };
  }

  /// Worn springs for the slots with physics (when the figure rides it).
  List<WornDef> worn() {
    if (!def.physics) return const [];
    final out = <WornDef>[];
    for (final s in _k.slots) {
      final ph = s.physics;
      if (ph == null) continue;
      final on = holderOf(s) != null ? slotLayer(s.attach) : boneLayer(s.attach);
      out.add(WornDef.figure(slotLayer(s.id), on, ph.stiffness, ph.damping, ph.mass, ph.tilt, ph.max));
    }
    return out;
  }

  /// The matrix [a, b, c, d, e, f] that draws a worn part in canvas units ([grip]: the near paw's grip kind).
  Float64List placement(KitSlot s, WornPart w, String? grip) {
    final part = _k.parts[w.part]!;
    final (ax, ay) = anchorOf(s);
    var m = <double>[1, 0, 0, 1, ax, ay];
    if (s.place != 'grip' && s.arot != 0) m = _mul(m, _rot(s.arot));
    final a = w.adjust;
    if (a.dx != 0 || a.dy != 0) m = _mul(m, [1, 0, 0, 1, a.dx, a.dy]);
    if (a.rot != 0) m = _mul(m, _rot(a.rot));
    if (a.scale != 1) m = _mul(m, [a.scale, 0, 0, a.scale, 0, 0]);
    // lettered items read the right way when he faces left
    if (def.flip && part.tags.contains('lettered')) m = _mul(m, [-1, 0, 0, 1, 0, 0]);
    var (ox, oy) = (part.ox, part.oy);
    if (s.place == 'grip') {
      final g = part.grips[grip ?? 'hold'] ?? part.grips['hold'];
      if (g != null) (ox, oy) = g;
    }
    m = _mul(m, [1, 0, 0, 1, -ox, -oy]);
    // the art is drawn in its frame (paint() takes its offset off): put it back, so its own units are canvas units
    final art = kit.art[w.part];
    if (art != null && (art.offsetX != 0 || art.offsetY != 0)) m = _mul(m, [1, 0, 0, 1, art.offsetX, art.offsetY]);
    return Float64List.fromList(m);
  }
}

List<double> _rot(double deg) {
  final r = deg * math.pi / 180, c = math.cos(r), s = math.sin(r);
  return [c, s, -s, c, 0, 0];
}

List<double> _mul(List<double> m, List<double> n) => [
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ];

Float64List _m4(Float64List m) => Float64List.fromList([m[0], m[1], 0, 0, m[2], m[3], 0, 0, 0, 0, 1, 0, m[4], m[5], 0, 1]);

/// What one figure wears now: its look, and what the playing clip swaps in (an action's paw poses, expressions).
class FigureDress {
  /// The figure in [look].
  FigureDress(this.rig, AliveLook look) : _look = look {
    _resolve();
  }

  /// The figure.
  final FigureRig rig;

  AliveLook _look;
  late ResolvedLook _base;
  final Map<String, WornPart> _clip = {}; // slot -> what the clip puts there
  final Map<String, WornPart?> _resolveCache = {};
  final Map<String, (WornPart, String?, Float64List)> _placed = {};
  /// Changes whenever the look changes.
  int version = 0;

  KitDef get _k => rig.kit.def;

  /// The look.
  AliveLook get look => _look;

  /// The look resolved: problems are names that did not resolve and clamped adjustments.
  ResolvedLook get resolved => _base;

  /// Wear [look].
  void dress(AliveLook look) {
    _look = look;
    _resolve();
  }

  void _resolve() {
    _base = resolveLook(_k, _look);
    _resolveCache.clear();
    version++;
  }

  /// What a slot wears now (the clip's swap, else the look's).
  WornPart? worn(String slot) => _live[slot] ?? _clip[slot] ?? _base.slots[slot];

  /// What the look and the clip put in [slot], before a live swap (a blink, the gaze).
  WornPart? designed(String slot) => _clip[slot] ?? _base.slots[slot];

  final Map<String, WornPart> _live = {};

  /// A live swap over the clip's and the look's (a blink, the gaze): a name the slot knows, or null to clear it.
  void liveSwap(String slot, String? name) {
    if (name == null) {
      _live.remove(slot);
      return;
    }
    final key = '$slot|$name';
    final w = _resolveCache.containsKey(key) ? _resolveCache[key] : (_resolveCache[key] = _wornFor(slot, name));
    if (w == null) {
      _live.remove(slot);
    } else {
      _live[slot] = w;
    }
  }

  /// Clear every live swap.
  void clearLive() => _live.clear();

  /// The open eyes the pack says can blink and look about: the eyes worn now (before live swaps), when tagged
  /// `pill` (null otherwise) or `pill-wide` ('wide').
  String? pillEyes() {
    final w = designed('eyes');
    final tags = w == null || w.part.isEmpty ? null : _k.parts[w.part]?.tags;
    if (tags == null) return null;
    if (tags.contains('pill-wide')) return 'wide';
    if (tags.contains('pill')) return '';
    return null;
  }

  /// Part ids the look needs.
  Iterable<String> get needed => _base.slots.values.map((w) => w.part);

  /// A clip's swap of a slot: a part id or a name the slot knows; a split expression in `face` swaps its features.
  /// Null clears it. A face the pack does not have falls back to the neutral face (round 7: a missing "concerned"
  /// left a board figure faceless; here it would have kept the look's face, whatever expression that is), so his face
  /// never goes blank and never shows the wrong feeling; the player reports the name once when the scene starts.
  void clipSwap(String slot, String? name) {
    if (name == null) {
      if (slot == 'face') {
        for (final f in const ['face', 'eyes', 'brows', 'mouth', 'cheeks', 'marks']) {
          _clip.remove(f);
        }
      } else {
        _clip.remove(slot);
      }
      return;
    }
    final key = '$slot|$name';
    final w = _resolveCache.containsKey(key) ? _resolveCache[key] : (_resolveCache[key] = _wornFor(slot, name));
    if (w == null) {
      if (slot == 'face' && name != neutralFace) clipSwap(slot, neutralFace);
      return;
    }
    final part = _k.parts[w.part]!;
    if (slot == 'face' && part.split.isNotEmpty) {
      for (final f in const ['eyes', 'brows', 'mouth', 'cheeks', 'marks']) {
        final sid = part.split[f];
        if (sid == null) {
          _clip[f] = _none;
        } else {
          _clip[f] = _resolveCache['$f|$sid'] ??= _wornFor(f, sid) ?? _none;
        }
      }
      _clip['face'] = _none;
      return;
    }
    _clip[slot] = w;
  }

  static final WornPart _none = WornPart('');

  /// The face a missing face falls back to.
  static const String neutralFace = 'neutral';

  WornPart? _wornFor(String slot, String name) {
    final id = _k.resolve(slot, name, skin: _base.skin);
    if (id == null) return null;
    final part = _k.parts[id]!;
    final base = _base.slots[slot];
    return WornPart(id, alt: part.alt, front: part.front, adjust: base?.adjust ?? AlivePartAdjust.none, recolour: recolourFor(_k, part, slot, _look.tints));
  }

  /// Clear every clip swap.
  void clearClip() => _clip.clear();

  /// Does [slot] wear a loaded part at this z ([alt]: its alternate z)?
  bool wears(String slot, bool alt) => _zone(slot) == (alt ? 1 : 0);

  /// Does [slot] wear a loaded part at its front z?
  bool wearsFront(String slot) => _zone(slot) == 2;

  // where the worn part draws: 0 the slot's z, 1 its alternate z, 2 its front z; -1 nothing loaded is worn
  int _zone(String slot) {
    final w = worn(slot);
    if (w == null || w.part.isEmpty || !rig.kit.has(w.part)) return -1;
    final s = _k.slot[slot];
    if (s?.zFront != null && w.front) return 2;
    return s?.zAlt != null && w.alt ? 1 : 0;
  }

  /// The stage clock, for a hem's ripple (the player sets it each frame; 0 with reduced motion).
  double time = 0;

  final Map<String, (double, double)> _hems = {};

  /// A hem slot's spring this frame: its horizontal lag (the cloth shears by it) and its energy (0 to 1.4: the
  /// ripple grows with it). The player sets it while the figure rides physics.
  void setHem(String slot, double lagX, double energy) => _hems[slot] = (lagX, energy);

  /// Draw the part worn in [slot] at its placement, in canvas units.
  void paint(ui.Canvas c, String slot) {
    final w = worn(slot);
    if (w == null || w.part.isEmpty) return;
    final art = rig.kit.compiled(w);
    if (art == null) return;
    final s = _k.slot[slot]!;
    final hem = s.hem;
    if (hem != null) {
      final (lag, energy) = _hems[slot] ?? (0.0, 0.0);
      c.save();
      c.clipPath(hemClip(hem, time, energy));
      if (lag != 0 && hem.shear != 0) {
        // shear about the slot's anchor: the neckline stays, the hem trails
        final k = hem.shear * lag;
        c.transform(_m4(Float64List.fromList([1, 0, k, 1, -k * s.ay, 0])));
      }
      _paintAt(c, s, w, slot, art);
      c.restore();
      return;
    }
    _paintAt(c, s, w, slot, art);
  }

  void _paintAt(ui.Canvas c, KitSlot s, WornPart w, String slot, CompiledArt art) {
    final grip = s.place == 'grip' ? _k.parts[worn(_holder(s))?.part]?.grip : null;
    final hit = _placed[slot];
    Float64List m;
    if (hit != null && identical(hit.$1, w) && hit.$2 == grip) {
      m = hit.$3;
    } else {
      m = _m4(rig.placement(s, w, grip));
      _placed[slot] = (w, grip, m);
    }
    c.save();
    c.transform(m);
    art.paint(c, rig.kit.rest);
    c.restore();
  }

  String _holder(KitSlot s) => rig.holderOf(s)?.id ?? 'near-paw';
}

/// The region a hem slot's part is drawn in at [time] with [energy] (0 to 1.4): everything above the hem's edge,
/// the edge moved by a ripple of amplitude rest + wave x energy travelling along it. Canvas units.
ui.Path hemClip(KitHem h, double time, double energy) {
  final e = h.edge, n = e.length ~/ 2;
  final amp = h.rest + h.wave * energy.clamp(0.0, KitHem.maxEnergy);
  const far = 4096.0;
  final p = ui.Path()
    ..moveTo(e[0] - far, -far)
    ..lineTo(e[2 * n - 2] + far, -far)
    ..lineTo(e[2 * n - 2] + far, e[2 * n - 1]);
  for (var i = n - 1; i >= 0; i--) {
    final x = e[2 * i], y = e[2 * i + 1];
    p.lineTo(x, y + amp * math.sin(2 * math.pi * x / h.wavelength - h.speed * time));
  }
  return p
    ..lineTo(e[0] - far, e[1])
    ..close();
}

/// What every figure of a scene wears, for one player: the renderer's [AliveDressing].
class AliveDress implements AliveDressing {
  /// Dress for [rigs] (by figure id), each in its starting look.
  AliveDress(Map<String, FigureRig> rigs, Map<String, AliveLook> looks) {
    for (final e in rigs.entries) {
      figures[e.key] = FigureDress(e.value, looks[e.key] ?? const AliveLook());
    }
  }

  /// Figures by id.
  final Map<String, FigureDress> figures = {};

  /// The first figure (what `slot:<slot>` and `face` channels of a clip address).
  FigureDress? get first => figures.values.isEmpty ? null : figures.values.first;

  (FigureDress?, String) _split(String key) {
    final i = key.indexOf(':');
    if (i < 0) return (null, key);
    return (figures[key.substring(0, i)], key.substring(i + 1));
  }

  @override
  bool wears(String slot, bool alt) {
    final (f, s) = _split(slot);
    return f != null && f.wears(s, alt);
  }

  @override
  bool wearsFront(String slot) {
    final (f, s) = _split(slot);
    return f != null && f.wearsFront(s);
  }

  @override
  void paintPart(ui.Canvas canvas, String slot, bool alt) {
    final (f, s) = _split(slot);
    f?.paint(canvas, s);
  }
}

/// The parts a scene needs from the start for [rig]: its look, and every part its clips swap in (`slot:` and `face`
/// channels) or its pools dress it in. Parts outside these load when the app asks for them (controller.wear).
Set<String> partsNeeded(SceneDef def, FigureRig rig, Map<String, PoolDef> pools, {bool first = true}) {
  final k = rig.kit.def;
  final look = AliveLook(preset: rig.def.look, parts: rig.def.parts);
  final r = resolveLook(k, look);
  final out = <String>{for (final w in r.slots.values) w.part};
  void add(String slot, Object? name, String skin) {
    if (name is! String) return;
    final id = k.resolve(slot, name, skin: skin);
    if (id == null) return;
    out.add(id);
    out.addAll(k.parts[id]!.split.values);
  }

  for (final c in def.clips.values) {
    for (final e in c.channels.entries) {
      String? slot;
      if (e.key == 'face' && first) slot = 'face';
      if (e.key.startsWith('slot:')) {
        final rest = e.key.substring(5);
        final i = rest.indexOf(':');
        if (i < 0 && first) slot = rest;
        if (i > 0 && rest.substring(0, i) == rig.id) slot = rest.substring(i + 1);
      }
      if (slot == null || !k.slot.containsKey(slot)) continue;
      for (final (_, v) in e.value) {
        add(slot, v, r.skin);
      }
    }
  }
  if (first) {
    for (final p in pools.values) {
      for (final v in p.variants) {
        for (final d in v.dress == '@looks' ? k.looks.keys : <String>[if (v.dress != null) v.dress!]) {
          out.addAll(resolveLook(k, AliveLook(preset: d)).slots.values.map((w) => w.part));
        }
        for (final w in v.wear.entries) {
          for (final name in w.value.startsWith('@') ? k.tagged(w.key, w.value.substring(1)) : [w.value]) {
            add(w.key, name, r.skin);
          }
        }
      }
    }
  }
  return out;
}
