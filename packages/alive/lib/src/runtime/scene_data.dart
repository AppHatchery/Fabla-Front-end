// A scene with its art, ready to play: the layer table (declared layers plus art-only ones), parents and pivots
// from the art, cross-checks, and the compiled art. Shared by every controller that shows the scene (the cache
// counts them) and released when the last one goes.
import 'dart:typed_data';

import '../kit/figure.dart';
import '../render/art_renderer.dart';
import '../schema/art_def.dart';
import '../schema/errors.dart';
import '../schema/scene_def.dart';
import '../schema/track.dart';
import 'layer_state.dart';

/// A loaded scene.
class AliveSceneData {
  /// Assemble [def] with its [arts] (by id). Throws [AliveSchemaError] when they do not fit together.
  factory AliveSceneData(SceneDef def, Map<String, ArtDef> arts,
      {AliveFonts fonts = const AliveFonts(), String file = 'scene.json', Map<String, KitData> kits = const {}, Map<String, FigureRig> figures = const {}}) {
    final t = _tables(def, arts, file);
    final compiled = <String, CompiledArt>{};
    try {
      for (final id in def.art) {
        compiled[id] = CompiledArt(arts[id]!, t.index, fonts: fonts, trimmed: t.trimmed);
      }
    } catch (e) {
      for (final c in compiled.values) {
        c.dispose();
      }
      throw AliveSchemaError('art', [AliveProblem('', 'the art could not be prepared: $e')]);
    }
    return AliveSceneData._(def, arts, t.ids, t.index, t.parent, t.px, t.py, t.rest, compiled, kits, figures);
  }

  AliveSceneData._(this.def, this.arts, this.layerIds, this.layerIndex, this.parent, this.pivotX, this.pivotY, this.rest, this.compiled, this.kits, this.figures);

  /// The same scene, its art prepared in slices of about [slice], waiting on [pause] between them (see
  /// [CompiledArt.prepare]): what the loader does, so frames keep coming while a large scene is prepared.
  static Future<AliveSceneData> prepare(SceneDef def, Map<String, ArtDef> arts,
      {AliveFonts fonts = const AliveFonts(),
      String file = 'scene.json',
      Map<String, KitData> kits = const {},
      Map<String, FigureRig> figures = const {},
      Duration slice = const Duration(milliseconds: 4),
      Future<void>? Function()? pause}) async {
    final t = _tables(def, arts, file);
    final compiled = <String, CompiledArt>{};
    try {
      for (final id in def.art) {
        compiled[id] = await CompiledArt.prepare(arts[id]!, t.index, fonts: fonts, trimmed: t.trimmed, slice: slice, pause: pause);
      }
    } catch (e) {
      for (final c in compiled.values) {
        c.dispose();
      }
      throw AliveSchemaError('art', [AliveProblem('', 'the art could not be prepared: $e')]);
    }
    return AliveSceneData._(def, arts, t.ids, t.index, t.parent, t.px, t.py, t.rest, compiled, kits, figures);
  }

  // The layer table (declared layers plus art-only ones), parents and pivots from the art, rest values, and the
  // cross-checks. Throws [AliveSchemaError].
  static ({List<String> ids, Map<String, int> index, Int32List parent, Float64List px, Float64List py, LayerState rest, Set<String> trimmed}) _tables(
      SceneDef def, Map<String, ArtDef> arts, String file) {
    final ids = <String>[...def.layers.map((l) => l.id)];
    final index = <String, int>{...def.layerIndex};
    final artLayers = <String, ({double px, double py, String? parent})>{};
    final problems = <AliveProblem>[];
    for (final id in def.art) {
      final a = arts[id];
      if (a == null) {
        problems.add(AliveProblem('art', 'art "$id" is missing', 'expected art/$id.json next to scene.json'));
        continue;
      }
      for (final e in a.layers.entries) {
        artLayers.putIfAbsent(e.key, () => e.value);
        if (!index.containsKey(e.key)) {
          index[e.key] = ids.length;
          ids.add(e.key);
        }
      }
    }
    for (final l in def.layers) {
      if (!artLayers.containsKey(l.id) && !l.data && !l.live) {
        final keyedBy = [
          for (final c in def.clips.values)
            if (() {
              final k = clipKeys(c);
              for (var j = 0; j < k.layerCount; j++) {
                if (k.layerAt(j) == l.index) return true;
              }
              return false;
            }())
              c.id,
        ];
        problems.add(AliveProblem(
          keyedBy.isEmpty ? jsonKey('layers', l.id) : jsonKey('clips.${keyedBy.first}.tracks', l.id),
          'layer "${l.id}" is not in any of the scene\'s art',
          'mark it "data": true under "layers" if the app only reads its values',
        ));
      }
    }
    bool known(String? id) => id != null && index.containsKey(id);
    void need(String? id, String path) {
      if (id != null && !known(id)) problems.add(AliveProblem(path, 'unknown layer "$id"'));
    }

    for (final e in def.looks.entries) {
      for (final id in [...e.value.show, ...e.value.hide]) {
        need(id, jsonKey('looks', e.key));
      }
    }
    final live = def.live;
    if (live != null) {
      need(live.group, 'live.group');
      for (final id in [...?live.blink?.hide, ...?live.blink?.show]) {
        need(id, 'live.blink');
      }
    }
    for (final w in def.worn.values) {
      need(w.layer, jsonKey('worn', w.layer));
      need(w.on, '${jsonKey('worn', w.layer)}.on');
    }
    final gaze = live?.gaze;
    if (gaze != null) {
      for (final id in gaze.layers.keys) {
        need(id, jsonKey('live.gaze.layers', id));
      }
      need(gaze.from, 'live.gaze.from');
      if (gaze.figure != null && (gaze.figure!.isEmpty ? def.figures.isEmpty : !def.figures.containsKey(gaze.figure))) {
        problems.add(AliveProblem('live.gaze.figure', 'no figure "${gaze.figure!.isEmpty ? '(first)' : gaze.figure}" in the scene'));
      }
    }
    final bf = live?.blink?.figure;
    if (bf != null && (bf.isEmpty ? def.figures.isEmpty : !def.figures.containsKey(bf))) {
      problems.add(AliveProblem('live.blink.figure', 'no figure "${bf.isEmpty ? '(first)' : bf}" in the scene'));
    }
    for (final b in def.bindings) {
      need(b.layer, 'bindings');
    }
    for (final e in def.anchors.entries) {
      need(e.value.layer, '${jsonKey('anchors', e.key)}.layer');
    }
    if (problems.isNotEmpty) throw AliveSchemaError(file, problems);

    final n = ids.length;
    final parent = Int32List(n)..fillRange(0, n, -1);
    final px = Float64List(n), py = Float64List(n);
    for (var i = 0; i < n; i++) {
      final a = artLayers[ids[i]];
      if (a == null) continue;
      px[i] = a.px;
      py[i] = a.py;
      if (a.parent != null) parent[i] = index[a.parent]!;
    }
    final rest = LayerState(n);
    for (var i = 0; i < n; i++) {
      final l = i < def.layers.length ? def.layers[i] : null;
      final r = l?.rest ?? LayerDef.neutralRest();
      for (var p = 0; p < LayerProp.numeric; p++) {
        rest.values[i * LayerProp.numeric + p] = r[p];
      }
      rest.fill[i] = l?.restColours[0] ?? -1;
      rest.stroke[i] = l?.restColours[1] ?? -1;
    }
    // layers whose strokes are trimmed: a clip keys their trimStart or trimEnd, or they rest trimmed
    final ts = LayerProp.trimStart.index, te = LayerProp.trimEnd.index;
    final trimmed = <String>{
      for (final c in def.clips.values)
        for (var j = 0, k = clipKeys(c); j < k.layerCount; j++)
          if (k.trackOf(j, ts) >= 0 || k.trackOf(j, te) >= 0) ids[k.layerAt(j)],
      for (final l in def.layers)
        if (l.rest[ts] != 0 || l.rest[te] != 1) l.id,
    };
    return (ids: ids, index: index, parent: parent, px: px, py: py, rest: rest, trimmed: trimmed);
  }

  /// Art packs of the scene's kit figures, by pack id.
  final Map<String, KitData> kits;

  /// Kit figures by id.
  final Map<String, FigureRig> figures;

  /// Worn items: the scene's, then the kit figures' slots with physics.
  late final List<WornDef> worn = [...def.worn.values, for (final f in figures.values) ...f.worn()];

  /// Pools, with variants that pull from a kit (`"dress": "@looks"`, `"wear": {"held": "@handheld"}`) expanded into
  /// one variant per choice, so "never the last pick" and the run's seed work on them as on any variant.
  late final Map<String, PoolDef> pools = () {
    final first = figures.values.isEmpty ? null : figures.values.first.kit.def;
    if (first == null) return def.pools;
    final out = <String, PoolDef>{};
    for (final e in def.pools.entries) {
      var vs = <Variant>[];
      for (final v in e.value.variants) {
        var list = [v];
        if (v.dress == '@looks') list = [for (final l in first.looks.keys) Variant(v.clip, v.look, l, v.wear)];
        for (final w in v.wear.entries.where((w) => w.value.startsWith('@')).toList()) {
          final tagged = first.tagged(w.key, w.value.substring(1));
          list = [
            for (final x in list)
              for (final t in tagged) Variant(x.clip, x.look, x.dress, {...x.wear, w.key: t}),
          ];
        }
        vs.addAll(list);
      }
      if (vs.isEmpty) vs = e.value.variants;
      out[e.key] = PoolDef.of(e.key, vs);
    }
    return out;
  }();

  /// The scene.
  final SceneDef def;

  /// Its art definitions.
  final Map<String, ArtDef> arts;

  /// Every layer id, by index.
  final List<String> layerIds;

  /// Layer index by id.
  final Map<String, int> layerIndex;

  /// Parent layer index (-1: none), from the art's nesting.
  final Int32List parent;

  /// Pivots, from the art.
  final Float64List pivotX, pivotY;

  /// Every layer at rest.
  final LayerState rest;

  /// Compiled art by id.
  final Map<String, CompiledArt> compiled;

  bool _disposed = false;

  /// Released?
  bool get disposed => _disposed;

  /// Let go of the parsed art trees once the art is prepared ([arts] then hold headers only: id, size, offset, layers).
  /// What draws stays (pictures and the compiled animated nodes). The loader does it for every scene it prepares
  /// unless its cache keeps them ([AliveCache.keepArtTrees]).
  void releaseArtTrees() {
    for (final id in def.art) {
      final c = compiled[id];
      if (c == null) continue;
      c.releaseTree();
      arts[id] = c.def;
    }
  }

  /// Release the pictures.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final c in compiled.values) {
      c.dispose();
    }
    for (final k in kits.values) {
      k.dispose();
    }
  }
}
