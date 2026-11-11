// alive/1 scene files, parsed into typed definitions and checked with the same rules as the CLI (tools/lib/schema.mjs).
import 'dart:typed_data';

import 'curves.dart';
import 'errors.dart';
import 'track.dart';

/// The schema this runtime reads.
const String aliveSchema = 'alive/1';

/// This engine's version: a scene stamped with a newer `requires` is refused with a message that says so.
const String aliveVersion = '0.7.0';

/// Compare two versions `a.b.c`: negative, zero or positive.
int compareVersions(String a, String b) {
  final x = a.split('.').map(int.parse).toList(), y = b.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    final c = x[i].compareTo(y[i]);
    if (c != 0) return c;
  }
  return 0;
}

typedef _J = Map<String, dynamic>;

/// Collects problems with their JSON paths while a file is read.
class ProblemSink {
  /// The problems found so far.
  final List<AliveProblem> list = [];

  /// Record a problem.
  void add(String path, String message, [String? hint]) => list.add(AliveProblem(path, message, hint));

  /// No problems?
  bool get ok => list.isEmpty;
}

final RegExp _idRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:#@-]*$');

/// A JSON path step for a map key (dotted when plain, bracketed when it has spaces or dots).
String jsonKey(String path, String k) => _idRe.hasMatch(k) && !k.contains('.') ? '$path.$k' : '$path[${_quote(k)}]';
String _quote(String s) => '"${s.replaceAll('"', r'\"')}"';

double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
String? _str(Object? v) => v is String ? v : null;
_J? _obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;

/// Check the header every alive/1 file has. Returns false when the rest cannot be read.
bool checkHeader(Object? doc, String kind, ProblemSink p) {
  final d = _obj(doc);
  if (d == null) {
    p.add('', 'not a JSON object');
    return false;
  }
  if (d['schema'] != aliveSchema) {
    final legacy = d['format'] == 'fabio-script' || d['tree'] != null;
    p.add('schema', d['schema'] == null ? 'missing "schema"' : 'unsupported schema "${d['schema']}"',
        legacy ? 'this is a legacy file: run `alive upgrade` first' : 'this runtime reads "$aliveSchema"');
    return false;
  }
  if (d['kind'] != kind) {
    p.add('kind', 'expected kind "$kind", found ${d['kind'] is String ? '"${d['kind']}"' : d['kind']}');
    return false;
  }
  final id = d['id'];
  if (id is! String || !_idRe.hasMatch(id)) p.add('id', 'bad id ${id is String ? '"$id"' : id}', 'letters, digits and _ . - only');
  final size = d['size'];
  if (size is! List || size.length != 2 || !size.every((v) => _num(v) != null && (v as num) > 0)) p.add('size', 'size must be [width, height], both above 0');
  return true;
}

/// One layer of a scene: its rest values and what kind of layer it is.
class LayerDef {
  LayerDef._(this.id, this.index, this.rest, this.restColours, {required this.live, required this.data});

  /// The layer id (the art's group names it).
  final String id;

  /// Its index in the scene's layer buffers.
  final int index;

  /// Rest value of every numeric property, by [LayerProp.index].
  final Float64List rest;

  /// Rest colours (fill, stroke) as 0xAARRGGBB, or null when the art's own colour stands.
  final List<int?> restColours;

  /// Driven by the engine's live behaviours or by the app (no clip keys it): e.g. `live:fabio`.
  final bool live;

  /// Values only: no art draws it; the app reads its values (a card drawn by Flutter, timed by the clip).
  final bool data;

  /// Rest values when a layer has no declaration (art-only layers).
  static Float64List neutralRest() {
    final r = Float64List(LayerProp.values.length);
    for (final p in LayerProp.values) {
      r[p.index] = p.neutral;
    }
    return r;
  }
}

/// The tracks a clip has for one layer (a view of the clip's key arrays, built when read).
class LayerTracks {
  LayerTracks._view(this._k, this._j) : layer = _k.layerAt(_j);

  final ClipKeys _k;
  final int _j;

  /// The layer index.
  final int layer;

  /// How many properties this layer keys (two or three of fifteen, usually).
  int get count => _k.endTrack(_j) - _k.firstTrack(_j);

  /// The [LayerProp] index of the i-th keyed property.
  int propAt(int i) => _k.propOf(_k.firstTrack(_j) + i);

  /// The track of the i-th keyed property (a view built on each call).
  Track trackAt(int i) => _k.track(_k.firstTrack(_j) + i);

  /// The [LayerProp] indices this layer keys, in order (a new list each call; [count] and [propAt] read the same).
  Uint8List get props => Uint8List.fromList([for (var i = 0; i < count; i++) propAt(i)]);

  /// Their tracks, in the same order (a new list each call; [trackAt] reads the same).
  List<Track> get tracks => List<Track>.unmodifiable([for (var i = 0; i < count; i++) trackAt(i)]);

  /// The track of a [LayerProp] index, or null.
  Track? track(int prop) {
    final i = _k.trackOf(_j, prop);
    return i < 0 ? null : _k.track(i);
  }

  /// One slot per [LayerProp] (null where not keyed), built on each call.
  List<Track?> get byProp {
    final out = List<Track?>.filled(LayerProp.values.length, null);
    for (var i = 0; i < count; i++) {
      out[propAt(i)] = trackAt(i);
    }
    return out;
  }
}

/// A clip's keys as the player reads them (not exported: the package's own runtime and benchmarks).
ClipKeys clipKeys(ClipDef c) => c._keys;

/// A named mark inside a clip; the controller reports it as an [AliveCue] event when the clip passes it.
class Cue {
  /// A cue at [t] seconds.
  const Cue(this.t, this.name);

  /// Time in seconds from the clip's start.
  final double t;

  /// Its name.
  final String name;
}

/// A speech bubble change: the text (null hides it) and its opacity, from [t] seconds.
class BubbleCue {
  /// A bubble cue.
  const BubbleCue(this.t, this.text, this.opacity);

  /// Time in seconds from the clip's start.
  final double t;

  /// The text, or null for no bubble.
  final String? text;

  /// Opacity 0..1.
  final double opacity;
}

/// One designed moment: keyed layers, cues, bubble and channels.
class ClipDef {
  ClipDef._(this.id, this.duration, this.loop, this.still, this._keys, this.cues, this.bubble, this.channels, this.note, this.art);

  /// The clip id.
  final String id;

  /// Length in seconds.
  final double duration;

  /// Does it loop?
  final bool loop;

  /// The pose shown when the OS asks for reduced motion (seconds into the clip).
  final double still;

  /// Keyed layers (views of the clip's key arrays, built on each call: the player reads the arrays).
  List<LayerTracks> get tracks => List<LayerTracks>.unmodifiable([for (var j = 0; j < _keys.layerCount; j++) LayerTracks._view(_keys, j)]);

  // every key of the clip in plain arrays (no object per track)
  final ClipKeys _keys;

  /// Named marks, sorted by time.
  final List<Cue> cues;

  /// Bubble changes, sorted by time.
  final List<BubbleCue> bubble;

  /// Step channels (face, lamp, ...): sorted (seconds, value) lists.
  final Map<String, List<(double, Object?)>> channels;

  /// What the moment is, in words (from the designer).
  final String? note;

  /// The art drawn while it plays (null: all of the scene's art). Variants whose art differs (V1, V2, V3) share a scene.
  final List<String>? art;

  /// The value of a step channel at t seconds: its last entry at or before t. Null before its first entry (0.7.0:
  /// a `slot:` or `face` channel then shows the look's own part, as the tools draw it; before, the first value held
  /// from 0), and when the clip has no such channel.
  Object? channelAt(String name, double t) {
    final list = channels[name];
    if (list == null || list.isEmpty) return null;
    Object? v;
    for (final e in list) {
      if (e.$1 <= t) {
        v = e.$2;
      } else {
        break;
      }
    }
    return v;
  }
}

/// A variant of a pool: a clip, optionally with a look, a kit look and parts to wear.
class Variant {
  /// A variant.
  const Variant(this.clip, [this.look, this.dress, this.wear = const {}]);

  /// The clip it plays.
  final String clip;

  /// The look it wears, if any.
  final String? look;

  /// A look of the kit its figure dresses in (`"explorer"`; `"@looks"` in a file: one variant per look of the kit).
  final String? dress;

  /// Parts its figure wears, slot to part (`{"held": "prop-mic"}`; `"@handheld"` in a file: one variant per part of
  /// that slot with the tag).
  final Map<String, String> wear;

  /// The key remembered as "the last pick".
  String get key {
    var k = look == null ? clip : '$clip+$look';
    if (dress != null) k = '$k/$dress';
    for (final e in (wear.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
      k = '$k/${e.key}=${e.value}';
    }
    return k;
  }
}

/// A kit figure in a scene: Fabio (or another mascot) composed at run time from an art pack, so his look can change
/// and every clip keyed on the figure's bones and slots plays on any look.
class FigureDef {
  FigureDef._(this.id, this.kit, this.look, this.parts, this.x, this.y, this.scale, this.flip, this.physics);

  /// Figure id: an id in the scene's `art` (where he is drawn among the scene's art) and the prefix of his layers
  /// (`fabio`, `fabio.body`, `fabio:hat`).
  final String id;

  /// The art pack (`kits/<kit>/kit.json`).
  final String kit;

  /// The look he starts in (a look of the pack), and parts on top of it.
  final String? look;

  /// Parts on top of [look], slot to part id or name.
  final Map<String, String?> parts;

  /// Where his canvas origin sits in the scene, and his size (1 = kit units).
  final double x, y, scale;

  /// Facing left (the whole figure mirrored; lettered items read the right way).
  final bool flip;

  /// Slots with physics ride it (hats, accessories, paws lag and settle).
  final bool physics;
}

/// A pool of variants ("fresh every run": a new one each time, never the last one).
class PoolDef {
  PoolDef._(this.id, this.variants);

  /// A pool (the loader expands variants that pull from a kit into one per choice).
  PoolDef.of(this.id, this.variants);

  /// The pool id (play it like a clip).
  final String id;

  /// Its variants.
  final List<Variant> variants;
}

/// An app state: the clip played on entering it, and the clip it rests in.
class StateDef {
  StateDef._(this.id, this.enter, this.idle);

  /// The state id.
  final String id;

  /// Clip or pool played on entering the state.
  final String? enter;

  /// Clip or pool played after [enter] ends, and after any event clip.
  final String? idle;
}

/// What a tap or an event does: play something, go to a state, or both.
class ActionDef {
  ActionDef._(this.play, this.state);

  /// Clip or pool to play.
  final String? play;

  /// State to enter.
  final String? state;
}

/// A look: layers shown and hidden for a run (an outfit, a prop swap).
class LookDef {
  LookDef._(this.show, this.hide);

  /// Layers forced visible.
  final List<String> show;

  /// Layers forced hidden.
  final List<String> hide;
}

/// Breathing: the live group scales by 1 + amp * sin(2 pi t / period).
class BreathDef {
  BreathDef._(this.amp, this.period);

  /// Scale amplitude.
  final double amp;

  /// Period in seconds.
  final double period;
}

/// Blinking: every [every] seconds for [duration] seconds, while the face channel is [face], hide and show layers.
class BlinkDef {
  BlinkDef._(this.every, this.duration, this.phase, this.face, this.hide, this.show, [this.figure]);

  /// Seconds between blinks.
  final double every;

  /// Seconds the eyes stay closed.
  final double duration;

  /// Offset in seconds.
  final double phase;

  /// Blink only while the clip's face channel has this value (null: always).
  final String? face;

  /// Layers hidden during a blink.
  final List<String> hide;

  /// Layers shown during a blink.
  final List<String> show;

  /// A kit figure that blinks through its eyes slot (`"figure": "fabio"`, or `true` for the scene's first figure):
  /// its open eyes swap to the pack's `blink-half` and `blink-closed` parts (`-wide` for wide eyes) for the blink.
  final String? figure;
}

/// His eyes following a point the app gives (`controller.lookAt`): a text caret, a button. Layers in [layers] move
/// toward it, each by at most its [x, y]; a kit figure's open eyes swap to the pack's `look-<direction>` parts.
class GazeDef {
  GazeDef._(this.layers, this.from, this.reach, this.follow, this.figure, this.dead);

  /// Layer id to the largest offset [x, y] (world units) it moves toward the target.
  final Map<String, (double, double)> layers;

  /// The layer whose pivot is where he looks from (default: the first of [layers], or the figure's eyes slot).
  final String? from;

  /// Distance (world units) at which the gaze is full; nearer, it is less.
  final double reach;

  /// Seconds: how quickly the gaze follows (a critically damped approach); 0 jumps.
  final double follow;

  /// A kit figure whose eyes swap to `look-left`, `look-up-right`... (null: none).
  final String? figure;

  /// Share of the full gaze under which a kit figure's eyes look ahead (no swap).
  final double dead;
}

/// Nodding at the end of a loud stretch of an input (the mic): he dips [depth] units and comes back.
class NodDef {
  NodDef._(this.input, this.threshold, this.minLoud, this.cooldown, this.depth, this.down, this.gap, this.up, this.ease, this.states, this.afterClip);

  /// The input that drives it.
  final String input;

  /// Level above which the input counts as loud.
  final double threshold;

  /// Seconds of loudness needed before a nod.
  final double minLoud;

  /// Seconds between nods, at least.
  final double cooldown;

  /// Depth in world units.
  final double depth;

  /// Seconds going down.
  final double down;

  /// Seconds held at the bottom.
  final double gap;

  /// Seconds coming back up.
  final double up;

  /// The ease of both moves.
  final Ease ease;

  /// App states in which he nods (null: any).
  final Set<String>? states;

  /// Nod only once the current clip has ended (he does not nod over a designed move).
  final bool afterClip;
}

/// The live layer behaviours: breath, blink and nod, on the [group] layer.
class LiveDef {
  LiveDef._(this.group, this.breath, this.blink, this.nod, [this.gaze]);

  /// The live wrapper layer the behaviours move (e.g. `live:fabio`).
  final String? group;

  /// Breathing, if any.
  final BreathDef? breath;

  /// Blinking, if any.
  final BlinkDef? blink;

  /// Nodding, if any.
  final NodDef? nod;

  /// Following a point with his eyes, if any.
  final GazeDef? gaze;
}

/// Physics on a worn item: a damped spring that lets it lag behind the layer it sits on and settle.
class WornDef {
  WornDef._(this.layer, this.on, this.stiffness, this.damping, this.mass, this.tilt, this.max);

  /// A worn item of a kit figure (a slot with physics).
  WornDef.figure(this.layer, this.on, this.stiffness, this.damping, this.mass, this.tilt, this.max);

  /// The worn layer.
  final String layer;

  /// The layer it sits on (null: its parent in the art).
  final String? on;

  /// Spring stiffness (1/s^2 per unit mass).
  final double stiffness;

  /// Damping.
  final double damping;

  /// Mass (how much it is thrown by its anchor's acceleration).
  final double mass;

  /// Degrees of tilt per unit of sideways lag.
  final double tilt;

  /// Largest lag in world units.
  final double max;
}

/// An input bound to a layer property: the input's [from] range maps onto the property's [to] range.
class BindingDef {
  BindingDef._(this.input, this.layer, this.prop, this.from0, this.from1, this.to0, this.to1);

  /// The input name.
  final String input;

  /// The layer id.
  final String layer;

  /// The numeric property set.
  final LayerProp prop;

  /// Input range.
  final double from0, from1;

  /// Property range.
  final double to0, to1;
}

/// A named point in the world, optionally moving with a layer.
class AnchorDef {
  AnchorDef._(this.x, this.y, this.layer);

  /// World point at rest.
  final double x, y;

  /// The layer it moves with, if any.
  final String? layer;
}

/// Accessibility: a label for the stage, per-state labels, or decorative (excluded from semantics).
class SemanticsDef {
  const SemanticsDef._({this.label, this.decorative = true, this.states = const {}});

  /// The default label.
  final String? label;

  /// Excluded from the semantics tree when true and no label is given by the app.
  final bool decorative;

  /// Labels by app state.
  final Map<String, String> states;
}

/// A scene: what moves, how it is driven and how it reads to assistive tech.
class SceneDef {
  SceneDef._({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.art,
    required this.layers,
    required this.layerIndex,
    required this.clips,
    required this.pools,
    required this.states,
    required this.on,
    required this.looks,
    required this.initialClip,
    required this.initialState,
    required this.live,
    required this.worn,
    required this.bindings,
    required this.anchors,
    required this.semantics,
    required this.inputSmoothing,
    required this.roles,
    required this.meta,
    this.figures = const {},
    this.shared = const [],
    this.placement,
    this.fabioSize,
  });

  /// Scene id.
  final String id;

  /// Human name.
  final String? name;

  /// World size.
  final double width, height;

  /// Art ids, drawn in this order.
  final List<String> art;

  /// Declared layers (the loader adds art-only layers after these).
  final List<LayerDef> layers;

  /// Layer index by id.
  final Map<String, int> layerIndex;

  /// Clips by id.
  final Map<String, ClipDef> clips;

  /// Pools by id.
  final Map<String, PoolDef> pools;

  /// States by id.
  final Map<String, StateDef> states;

  /// Event actions by event name (`tap:fabio`, `saved`, ...).
  final Map<String, ActionDef> on;

  /// Looks by id.
  final Map<String, LookDef> looks;

  /// What plays first.
  final String? initialClip, initialState;

  /// Live behaviours.
  final LiveDef? live;

  /// Worn items by layer id.
  final Map<String, WornDef> worn;

  /// Input bindings.
  final List<BindingDef> bindings;

  /// Anchors by name.
  final Map<String, AnchorDef> anchors;

  /// Accessibility.
  final SemanticsDef semantics;

  /// Input smoothing time constants in seconds, by input name.
  final Map<String, double> inputSmoothing;

  /// Named groups of layers (e.g. `fabio`: every layer that is part of him), for checks and tools.
  final Map<String, List<String>> roles;

  /// Free-form data the scene carries for the app (`meta` in the file: where a cut sat on its board, sizes...).
  final Map<String, Object?> meta;

  /// Kit figures by id (each is also an id in [art]).
  final Map<String, FigureDef> figures;

  /// Shared art its art files use (`alive pack --share`): fragment ids, files `_shared/<id>.json` beside the scene
  /// folders, put back into the art when it loads.
  final List<String> shared;

  /// Where the scene sits in the app, by name (`page`, `panel`, `card`, `dialog`, `inline`, `custom`, or one a team
  /// adds to standards/placements.json), when the scene says; `AlivePlacement` lays it out by it (0.7.0).
  final String? placement;

  /// How big Fabio is meant to be on screen: a tier name (`XS` to `XXL`, a [String]) or his body height in on-screen
  /// points (a [double]), when the scene says. The tools check it (`alive lint`); the runtime only carries it.
  final Object? fabioSize;

  /// Parse and check a scene. Throws [AliveSchemaError] listing every problem.
  static SceneDef parse(Object? doc, {String file = 'scene.json'}) {
    final p = ProblemSink();
    if (!checkHeader(doc, 'scene', p)) throw AliveSchemaError(file, p.list);
    final d = _obj(doc)!;
    // first: a scene made for a newer engine says so (`requires`, stamped by the CLI): say what to update
    final req = d['requires'];
    if (req != null) {
      if (req is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(req)) {
        p.add('requires', 'requires is an engine version, "0.5.0"');
      } else if (compareVersions(req, aliveVersion) > 0) {
        p.add('requires', 'this scene needs alive $req; this app has alive $aliveVersion', 'update the engine in the app (packages/alive), or export the scene again without the newer features');
      }
    }
    final art = <String>[];
    if (d['art'] is List && (d['art'] as List).isNotEmpty && (d['art'] as List).every((a) => a is String && _idRe.hasMatch(a))) {
      art.addAll((d['art'] as List).cast<String>());
    } else {
      p.add('art', 'art must list one or more art ids');
    }

    // layers
    final layers = <LayerDef>[], index = <String, int>{};
    final ld = d['layers'];
    if (ld != null && _obj(ld) == null) p.add('layers', 'layers must be an object');
    for (final e in (_obj(ld) ?? const <String, dynamic>{}).entries) {
      final lp = jsonKey('layers', e.key);
      final l = _obj(e.value);
      if (l == null) {
        p.add(lp, 'a layer is an object');
        continue;
      }
      final rest = LayerDef.neutralRest();
      final colours = List<int?>.filled(2, null);
      final r = l['rest'];
      if (r != null && _obj(r) == null) p.add('$lp.rest', 'rest must be an object');
      for (final re in (_obj(r) ?? const <String, dynamic>{}).entries) {
        final prop = LayerProp.byName(re.key);
        if (prop == null) {
          p.add('$lp.rest.${re.key}', 'unknown property "${re.key}"', 'one of ${LayerProp.values.map((x) => x.name).join(', ')}');
        } else if (prop.isColour) {
          final c = re.value is String ? parseHex(re.value as String) : null;
          if (c == null) {
            p.add('$lp.rest.${re.key}', 'bad value ${re.value}');
          } else {
            colours[prop == LayerProp.fill ? 0 : 1] = c;
          }
        } else {
          final v = _num(re.value);
          if (v == null) {
            p.add('$lp.rest.${re.key}', 'bad value ${re.value}');
          } else {
            rest[prop.index] = v;
          }
        }
      }
      if (l['data'] != null && l['data'] is! bool) p.add('$lp.data', 'data is true or false');
      index[e.key] = layers.length;
      layers.add(LayerDef._(e.key, layers.length, rest, colours, live: l['live'] == true || e.key.startsWith('live:'), data: l['data'] == true));
    }

    // clips
    final clips = <String, ClipDef>{};
    final cd = _obj(d['clips']);
    if (cd == null || cd.isEmpty) p.add('clips', 'a scene needs at least one clip');
    // a clip may key a layer the scene does not declare (an art layer): it is declared here with rest values, and the
    // loader checks that some art draws it
    int ensureLayer(String id) => index[id] ??= (layers..add(LayerDef._(id, layers.length, LayerDef.neutralRest(), List<int?>.filled(2, null), live: id.startsWith('live:'), data: false))).length - 1;
    for (final e in (cd ?? const <String, dynamic>{}).entries) {
      final c = _parseClip(e.key, e.value, jsonKey('clips', e.key), ensureLayer, p, art);
      if (c != null) clips[e.key] = c;
    }

    // pools, states, events, looks
    final looks = <String, LookDef>{};
    for (final e in (_obj(d['looks']) ?? const <String, dynamic>{}).entries) {
      final l = _obj(e.value) ?? const <String, dynamic>{};
      List<String> ids(String k) {
        final v = l[k];
        if (v == null) return const [];
        if (v is! List) {
          p.add('${jsonKey('looks', e.key)}.$k', '$k lists layer ids');
          return const [];
        }
        final out = <String>[];
        for (var i = 0; i < v.length; i++) {
          if (v[i] is String && index.containsKey(v[i])) {
            out.add(v[i] as String);
          } else if (v[i] is String) {
            out.add(v[i] as String); // may be an art-only layer; checked again once the art is loaded
          } else {
            p.add('${jsonKey('looks', e.key)}.$k[$i]', 'a layer id');
          }
        }
        return out;
      }

      looks[e.key] = LookDef._(ids('show'), ids('hide'));
    }
    final pools = <String, PoolDef>{};
    final pd = d['pools'];
    if (pd != null && _obj(pd) == null) p.add('pools', 'pools must be an object');
    for (final e in (_obj(pd) ?? const <String, dynamic>{}).entries) {
      final pp = jsonKey('pools', e.key);
      final raw = e.value;
      final vr = _obj(raw)?['variants'];
      final list = raw is List ? raw : (vr is List ? vr : null);
      if (list == null || list.isEmpty) {
        p.add(pp, 'a pool lists one or more variants');
        continue;
      }
      final vs = <Variant>[];
      for (var i = 0; i < list.length; i++) {
        final x = list[i];
        final clip = x is String ? x : _obj(x)?['clip'];
        final look = _obj(x)?['look'];
        final dress = _obj(x)?['dress'];
        final wear = _obj(_obj(x)?['wear']);
        if ((dress != null && dress is! String) || (_obj(x)?['wear'] != null && (wear == null || !wear.values.every((v) => v is String)))) {
          p.add('$pp[$i]', 'dress names a look of the kit, wear maps slots to parts');
          continue;
        }
        if (clip is! String || !clips.containsKey(clip)) {
          p.add('$pp[$i]', 'variant ${x is String ? '"$x"' : x} is not a clip of this scene');
          continue;
        }
        if (look != null && (look is! String || !looks.containsKey(look))) {
          p.add('$pp[$i].look', 'unknown look "$look"');
          continue;
        }
        vs.add(Variant(clip, look as String?, dress as String?, wear == null ? const {} : wear.cast<String, String>()));
      }
      if (vs.isNotEmpty) pools[e.key] = PoolDef._(e.key, vs);
    }
    bool playable(Object? v) => v is String && (clips.containsKey(v) || pools.containsKey(v));
    final states = <String, StateDef>{};
    for (final e in (_obj(d['states']) ?? const <String, dynamic>{}).entries) {
      final sp = jsonKey('states', e.key);
      final s = _obj(e.value);
      if (s == null) {
        p.add(sp, 'a state is an object');
        continue;
      }
      for (final k in ['enter', 'idle']) {
        if (s[k] != null && !playable(s[k])) p.add('$sp.$k', '"${s[k]}" is not a clip or pool');
      }
      states[e.key] = StateDef._(e.key, playable(s['enter']) ? s['enter'] as String : null, playable(s['idle']) ? s['idle'] as String : null);
    }
    final on = <String, ActionDef>{};
    for (final e in (_obj(d['on']) ?? const <String, dynamic>{}).entries) {
      final op = jsonKey('on', e.key);
      final a = _obj(e.value);
      if (a == null) {
        p.add(op, 'an action is {"play": ...} or {"state": ...}');
        continue;
      }
      if (a['play'] != null && !playable(a['play'])) p.add('$op.play', '"${a['play']}" is not a clip or pool');
      if (a['state'] != null && !states.containsKey(a['state'])) p.add('$op.state', 'unknown state "${a['state']}"');
      if (a['play'] == null && a['state'] == null) p.add(op, 'an action needs "play" or "state"');
      on[e.key] = ActionDef._(playable(a['play']) ? a['play'] as String : null, states.containsKey(a['state']) ? a['state'] as String : null);
    }
    String? initialClip, initialState;
    final ini = d['initial'];
    if (ini != null) {
      final i = _obj(ini);
      if (i == null) {
        p.add('initial', 'initial is {"clip": ...} or {"state": ...}');
      } else {
        if (i['clip'] != null && !playable(i['clip'])) p.add('initial.clip', '"${i['clip']}" is not a clip or pool');
        if (i['state'] != null && !states.containsKey(i['state'])) p.add('initial.state', 'unknown state "${i['state']}"');
        initialClip = playable(i['clip']) ? i['clip'] as String : null;
        initialState = states.containsKey(i['state']) ? i['state'] as String : null;
      }
    }

    // live behaviours, worn items, bindings, anchors, semantics, inputs
    LiveDef? live;
    final lv = d['live'];
    if (lv != null && _obj(lv) == null) p.add('live', 'live must be an object');
    if (_obj(lv) != null) live = _parseLive(_obj(lv)!, p);
    final worn = <String, WornDef>{};
    for (final e in (_obj(d['worn']) ?? const <String, dynamic>{}).entries) {
      final wp = jsonKey('worn', e.key);
      final w = _obj(e.value);
      if (w == null) {
        p.add(wp, 'a worn item is an object');
        continue;
      }
      double need(String k) {
        final v = _num(w[k]);
        if (v == null || v <= 0) p.add('$wp.$k', '$k must be a number above 0');
        return v ?? 1;
      }

      final k = need('stiffness'), c = need('damping');
      worn[e.key] = WornDef._(e.key, _str(w['on']), k, c, _num(w['mass']) ?? 1, _num(w['tilt']) ?? 0, _num(w['max']) ?? 6);
    }
    final bindings = <BindingDef>[];
    final bl = d['bindings'];
    if (bl is List) {
      for (var i = 0; i < bl.length; i++) {
        final b = _obj(bl[i]);
        final prop = b == null ? null : LayerProp.byName('${b['prop']}');
        final from = b?['from'], to = b?['to'];
        if (b == null || b['input'] is! String || b['layer'] is! String || prop == null || prop.isColour || from is! List || to is! List || from.length != 2 || to.length != 2) {
          p.add('bindings[$i]', 'a binding is {input, layer, prop, from: [a, b], to: [c, d]} on a numeric property');
          continue;
        }
        bindings.add(BindingDef._(b['input'] as String, b['layer'] as String, prop, _num(from[0]) ?? 0, _num(from[1]) ?? 1, _num(to[0]) ?? 0, _num(to[1]) ?? 1));
      }
    }
    final anchors = <String, AnchorDef>{};
    for (final e in (_obj(d['anchors']) ?? const <String, dynamic>{}).entries) {
      final a = _obj(e.value);
      final at = a?['at'];
      if (a == null || at is! List || at.length != 2 || _num(at[0]) == null || _num(at[1]) == null) {
        p.add(jsonKey('anchors', e.key), 'an anchor is {"at": [x, y], "layer"?: id}');
        continue;
      }
      anchors[e.key] = AnchorDef._(_num(at[0])!, _num(at[1])!, _str(a['layer']));
    }
    // the size system (optional, 0.7.0)
    final placementRaw = d['placement'];
    String? placement;
    if (placementRaw != null) {
      if (placementRaw is String && RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(placementRaw)) {
        placement = placementRaw;
      } else {
        p.add('placement', 'placement is a name: page, panel, card, dialog, inline, custom, or one a standards file adds (lower case, digits, -)');
      }
    }
    final sizeRaw = d['fabioSize'];
    Object? fabioSize;
    if (sizeRaw != null) {
      if (sizeRaw is String && RegExp(r'^[A-Za-z0-9-]+$').hasMatch(sizeRaw)) {
        fabioSize = sizeRaw;
      } else if (sizeRaw is num && sizeRaw.isFinite && sizeRaw > 0) {
        fabioSize = sizeRaw.toDouble();
      } else {
        p.add('fabioSize', "fabioSize is a tier name (XS, S, M, L, XL, XXL) or Fabio's body height in on-screen points");
      }
    }
    var semantics = const SemanticsDef._();
    final sd = d['semantics'];
    if (sd != null) {
      final s = _obj(sd);
      if (s == null || (s['label'] != null && s['label'] is! String)) {
        p.add('semantics', 'semantics is {"label"?: text, "decorative"?: bool, "states"?: {state: text}}');
      } else {
        semantics = SemanticsDef._(
          label: _str(s['label']),
          decorative: s['decorative'] is bool ? s['decorative'] as bool : s['label'] == null,
          states: {for (final e in (_obj(s['states']) ?? const <String, dynamic>{}).entries) if (e.value is String) e.key: e.value as String},
        );
      }
    }
    final smoothing = <String, double>{};
    for (final e in (_obj(d['inputs']) ?? const <String, dynamic>{}).entries) {
      final ms = _num(_obj(e.value)?['smooth']);
      if (ms != null) smoothing[e.key] = ms / 1000;
    }
    if (d['meta'] != null && _obj(d['meta']) == null) p.add('meta', 'meta is an object');
    final roles = <String, List<String>>{
      for (final e in (_obj(d['roles']) ?? const <String, dynamic>{}).entries)
        if (e.value is List) e.key: (e.value as List).whereType<String>().toList(),
    };

    final sh = d['shared'];
    final shared = <String>[];
    if (sh != null) {
      if (sh is List && sh.every((x) => x is String && x.isNotEmpty)) {
        shared.addAll(sh.cast<String>());
      } else {
        p.add('shared', 'shared lists fragment ids (files in _shared beside the scene folders)');
      }
    }
    if (!p.ok) throw AliveSchemaError(file, p.list);
    final size = d['size'] as List;
    // kit figures: composed at load from an art pack (lib/src/kit)
    final figures = <String, FigureDef>{};
    final fd = d['figures'];
    if (fd != null && _obj(fd) == null) p.add('figures', 'figures must be an object');
    for (final e in (_obj(fd) ?? const <String, dynamic>{}).entries) {
      final fp = jsonKey('figures', e.key);
      final f = _obj(e.value);
      if (f == null || f['kit'] is! String) {
        p.add(fp, 'a figure is {"kit": pack, "look"?: look, "parts"?: {slot: part}, "at"?: [x, y], "scale"?: n, "flip"?: bool, "physics"?: bool}');
        continue;
      }
      if (!_idRe.hasMatch(e.key) || e.key.contains(':')) p.add(fp, 'a figure id is letters, digits and _ - only (its layers are <id>, <id>.<bone>, <id>:<slot>)');
      if (!art.contains(e.key)) p.add(fp, 'figure "${e.key}" is not in art', 'list it in "art" where he is drawn among the scene\'s art');
      final at = f['at'];
      if (at != null && (at is! List || at.length != 2 || _num(at[0]) == null || _num(at[1]) == null)) p.add('$fp.at', 'at is [x, y]');
      final parts = _obj(f['parts']);
      if (f['parts'] != null && (parts == null || !parts.values.every((v) => v == null || v is String))) p.add('$fp.parts', 'parts maps slots to part ids or names');
      figures[e.key] = FigureDef._(
        e.key,
        f['kit'] as String,
        _str(f['look']),
        parts == null ? const {} : parts.cast<String, String?>(),
        at is List && at.length == 2 ? _num(at[0]) ?? 0 : 0,
        at is List && at.length == 2 ? _num(at[1]) ?? 0 : 0,
        _num(f['scale']) ?? 1,
        f['flip'] == true,
        f['physics'] == true,
      );
    }

    return SceneDef._(
      id: d['id'] as String,
      name: _str(d['name']),
      width: (size[0] as num).toDouble(),
      height: (size[1] as num).toDouble(),
      art: art,
      layers: layers,
      layerIndex: index,
      clips: clips,
      pools: pools,
      states: states,
      on: on,
      looks: looks,
      initialClip: initialClip,
      initialState: initialState,
      live: live,
      worn: worn,
      bindings: bindings,
      anchors: anchors,
      semantics: semantics,
      inputSmoothing: smoothing,
      roles: roles,
      meta: Map<String, Object?>.unmodifiable(_obj(d['meta']) ?? const <String, Object?>{}),
      figures: figures,
      shared: shared,
      placement: placement,
      fabioSize: fabioSize,
    );
  }
}

ClipDef? _parseClip(String id, Object? raw, String cp, int Function(String layer) layerOf, ProblemSink p, List<String> sceneArt) {
  final c = _obj(raw);
  if (c == null) {
    p.add(cp, 'a clip is an object');
    return null;
  }
  final before = p.list.length;
  final dur = _num(c['duration']);
  if (dur == null || dur < 0) p.add('$cp.duration', 'duration (ms) must be a number, 0 or more');
  if (c['loop'] != null && c['loop'] is! bool) p.add('$cp.loop', 'loop is true or false');
  final art = c['art'];
  if (art != null && (art is! List || !art.every((a) => a is String && sceneArt.contains(a)))) p.add('$cp.art', 'art lists art ids of this scene (the art drawn while the clip plays)');
  final still = c['still'] == null ? null : _num(c['still']);
  if (c['still'] != null && (still == null || still < 0 || (dur != null && still > dur))) p.add('$cp.still', 'still (ms) must lie inside the clip');
  final tracks = <(int, List<Track>)>[];
  final tr = c['tracks'];
  if (tr != null && _obj(tr) == null) p.add('$cp.tracks', 'tracks must be an object of layers');
  for (final e in (_obj(tr) ?? const <String, dynamic>{}).entries) {
    final tp = jsonKey('$cp.tracks', e.key);
    final li = layerOf(e.key);
    final props = _obj(e.value);
    if (props == null) {
      p.add(tp, 'a track is an object of properties');
      continue;
    }
    final by = List<Track?>.filled(LayerProp.values.length, null);
    for (final pe in props.entries) {
      final prop = LayerProp.byName(pe.key);
      if (prop == null) {
        p.add('$tp.${pe.key}', 'unknown property "${pe.key}"', 'one of ${LayerProp.values.map((x) => x.name).join(', ')}');
        continue;
      }
      final t = _parseKeys(pe.value, '$tp.${pe.key}', prop, p);
      if (t != null) by[prop.index] = t;
    }
    tracks.add((li, by.whereType<Track>().toList(growable: false)));
  }
  List<T> stepList<T>(Object? v, String path, T? Function(List<dynamic> e, String ep) read) {
    if (v == null) return const [];
    if (v is! List) {
      p.add(path, 'must be a list of [ms, ...]');
      return const [];
    }
    final out = <T>[];
    var last = double.negativeInfinity;
    for (var i = 0; i < v.length; i++) {
      final e = v[i];
      final ep = '$path[$i]';
      if (e is! List || e.isEmpty || _num(e[0]) == null) {
        p.add(ep, 'an entry is [ms, ...]');
        continue;
      }
      final t = _num(e[0])!;
      if (t < last) p.add(ep, 'entries are sorted by time');
      last = t;
      final x = read(e, ep);
      if (x != null) out.add(x);
    }
    return out;
  }

  final cues = stepList<Cue>(c['cues'], '$cp.cues', (e, ep) {
    if (e.length < 2 || e[1] is! String || (e[1] as String).isEmpty) {
      p.add(ep, 'a cue is [ms, "name"]');
      return null;
    }
    return Cue(_num(e[0])! / 1000, e[1] as String);
  });
  final bubble = stepList<BubbleCue>(c['bubble'], '$cp.bubble', (e, ep) {
    if (e.length < 2 || !(e[1] == null || e[1] is String) || (e.length > 2 && _num(e[2]) == null)) {
      p.add(ep, 'a bubble entry is [ms, text or null, opacity]');
      return null;
    }
    return BubbleCue(_num(e[0])! / 1000, e[1] as String?, e.length > 2 ? _num(e[2])! : 1);
  });
  final channels = <String, List<(double, Object?)>>{};
  final ch = c['channels'];
  if (ch != null && _obj(ch) == null) p.add('$cp.channels', 'channels must be an object');
  for (final e in (_obj(ch) ?? const <String, dynamic>{}).entries) {
    channels[e.key] = stepList<(double, Object?)>(e.value, jsonKey('$cp.channels', e.key), (x, ep) {
      if (x.length != 2 || !(x[1] == null || x[1] is num || x[1] is String)) {
        p.add(ep, 'a channel entry is [ms, value]');
        return null;
      }
      return (_num(x[0])! / 1000, x[1] is num ? (x[1] as num).toDouble() : x[1]);
    });
  }
  if (p.list.length != before) return null;
  final d = dur! / 1000;
  // the clip's keys in plain arrays: one buffer of numbers, four ints a track (a clip of the recording scene has
  // hundreds of tracks)
  final keys = tracks.isEmpty ? ClipKeys.none : ClipKeys.of(tracks);
  return ClipDef._(id, d, c['loop'] == true, still == null ? d : still / 1000, keys, cues, bubble, channels, _str(c['note']),
      art is List ? List<String>.unmodifiable(art.cast<String>()) : null);
}

// the compact form (0.6.0): {"dt": [ms, ...], "v": [...]}, every segment linear; times summed to a thousandth of a
// millisecond (so they are the list form's numbers exactly)
Track? _parseCompactKeys(Map<String, dynamic> raw, String path, LayerProp prop, ProblemSink p) {
  final before = p.list.length;
  for (final k in raw.keys) {
    if (k != 'dt' && k != 'v') {
      p.add(path, 'unknown field "$k" in compact keys', 'compact keys are {"dt": [ms, ...], "v": [values]}');
      break;
    }
  }
  final dt = raw['dt'], v = raw['v'];
  if (dt is! List || dt.isEmpty || !dt.every((x) => x is num)) {
    p.add('$path.dt', "dt must be a non-empty list of ms (the first key's time, then the time since the key before)");
    return null;
  }
  for (var i = 1; i < dt.length; i++) {
    if ((dt[i] as num) < 0) p.add('$path.dt[$i]', 'a key cannot come before the one before it (dt 0 or more)');
  }
  if (v is! List || v.length != dt.length) {
    p.add('$path.v', 'v must list one value per entry of dt');
    return null;
  }
  final n = dt.length;
  final times = Float64List(n);
  final nums = prop.isColour ? null : Float64List(n);
  final cols = prop.isColour ? colourList(n) : null;
  var ms = 0.0;
  for (var i = 0; i < n; i++) {
    ms = i == 0 ? (dt[0] as num).toDouble() : (((ms + (dt[i] as num)) * 1000).round() / 1000);
    times[i] = ms / 1000;
    final x = v[i];
    if (cols != null) {
      final c = x is String ? parseHex(x) : null;
      if (c == null) {
        p.add('$path.v[$i]', '${prop.name} must be a colour like "#A8D0FB"');
      } else {
        cols[i] = c;
      }
    } else if (x is num) {
      nums![i] = x.toDouble();
    } else {
      p.add('$path.v[$i]', '${prop.name} must be a number');
    }
  }
  if (p.list.length != before) return null;
  final eases = List<Ease>.filled(n, Ease.linear);
  return cols != null ? Track.colours(prop, times, cols, eases) : Track.numbers(prop, times, nums!, eases);
}

Track? _parseKeys(Object? raw, String path, LayerProp prop, ProblemSink p) {
  if (raw is Map) return _parseCompactKeys(_obj(raw)!, path, prop, p);
  if (raw is! List || raw.isEmpty) {
    p.add(path, 'keys must be a non-empty list of [ms, value, ease?] (or {"dt": [...], "v": [...]})');
    return null;
  }
  final n = raw.length;
  final times = Float64List(n);
  final nums = prop.isColour ? null : Float64List(n);
  final cols = prop.isColour ? colourList(n) : null;
  final eases = List<Ease>.filled(n, Ease.linear);
  var last = double.negativeInfinity;
  final before = p.list.length;
  for (var i = 0; i < n; i++) {
    final k = raw[i];
    final kp = '$path[$i]';
    if (k is! List || k.length < 2 || k.length > 3) {
      p.add(kp, 'a key is [ms, value] or [ms, value, ease]');
      continue;
    }
    final t = _num(k[0]);
    if (t == null) {
      p.add(kp, 'time must be a number (ms)');
    } else {
      if (t < last) p.add(kp, 'time $t comes before the previous key ($last)', 'keys are sorted by time');
      last = t;
      times[i] = t / 1000;
    }
    if (cols != null) {
      final c = k[1] is String ? parseHex(k[1] as String) : null;
      if (c == null) {
        p.add(kp, '${prop.name} must be a colour like "#A8D0FB"');
      } else {
        cols[i] = c;
      }
    } else {
      final v = _num(k[1]);
      if (v == null) {
        p.add(kp, '${prop.name} must be a number');
      } else {
        nums![i] = v;
      }
    }
    if (k.length == 3) {
      final e = Ease.parse(k[2]);
      if (e == null) {
        p.add(kp, 'unknown ease ${k[2]}', 'one of ${Ease.names.join(', ')}, [x1, y1, x2, y2] or {"spring": {...}}');
      } else {
        eases[i] = e;
      }
    }
  }
  if (p.list.length != before) return null;
  return cols != null ? Track.colours(prop, times, cols, eases) : Track.numbers(prop, times, nums!, eases);
}

LiveDef _parseLive(_J lv, ProblemSink p) {
  double need(_J? o, String path, String k, [double? def]) {
    final v = _num(o?[k]);
    if (v == null && def == null) p.add('$path.$k', '$k must be a number');
    return v ?? def ?? 0;
  }

  List<String> ids(_J o, String path, String k) {
    final v = o[k];
    if (v == null) return const [];
    if (v is! List || !v.every((x) => x is String)) {
      p.add('$path.$k', '$k lists layer ids');
      return const [];
    }
    return v.cast<String>();
  }

  BreathDef? breath;
  final b = _obj(lv['breath']);
  if (lv['breath'] != null) breath = BreathDef._(need(b, 'live.breath', 'amp'), need(b, 'live.breath', 'period') / 1000);
  BlinkDef? blink;
  final k = _obj(lv['blink']);
  if (lv['blink'] != null && k != null) {
    final fig = k['figure'];
    if (fig != null && fig is! String && fig is! bool) p.add('live.blink.figure', 'figure is a figure id, or true for the first figure');
    blink = BlinkDef._(need(k, 'live.blink', 'every') / 1000, need(k, 'live.blink', 'for') / 1000, need(k, 'live.blink', 'phase', 0) / 1000, _str(k['face']), ids(k, 'live.blink', 'hide'),
        ids(k, 'live.blink', 'show'), fig is String ? fig : (fig == true ? '' : null));
  } else if (lv['blink'] != null) {
    p.add('live.blink', 'blink is an object');
  }
  NodDef? nod;
  final n = _obj(lv['nod']);
  if (lv['nod'] != null && n != null) {
    final ease = Ease.parse(n['ease'] ?? const [0.65, 0.0, 0.35, 1.0]);
    if (ease == null) p.add('live.nod.ease', 'unknown ease ${n['ease']}');
    final st = n['states'];
    nod = NodDef._(
      n['input'] is String ? n['input'] as String : 'mic',
      need(n, 'live.nod', 'threshold'),
      need(n, 'live.nod', 'minLoud', 900) / 1000,
      need(n, 'live.nod', 'cooldown', 2200) / 1000,
      need(n, 'live.nod', 'depth'),
      need(n, 'live.nod', 'down', 140) / 1000,
      need(n, 'live.nod', 'gap', 20) / 1000,
      need(n, 'live.nod', 'up', 260) / 1000,
      ease ?? Ease.linear,
      st is List ? st.whereType<String>().toSet() : null,
      n['afterClip'] != false,
    );
  } else if (lv['nod'] != null) {
    p.add('live.nod', 'nod is an object');
  }
  GazeDef? gaze;
  final g = _obj(lv['gaze']);
  if (lv['gaze'] != null && g == null) p.add('live.gaze', 'gaze is an object');
  if (g != null) {
    final layers = <String, (double, double)>{};
    final gl = g['layers'];
    if (gl != null && _obj(gl) == null) p.add('live.gaze.layers', 'layers maps a layer id to [x, y]');
    for (final e in (_obj(gl) ?? const <String, dynamic>{}).entries) {
      final v = e.value;
      if (v is List && v.length == 2 && _num(v[0]) != null && _num(v[1]) != null) {
        layers[e.key] = (_num(v[0])!, _num(v[1])!);
      } else {
        p.add(jsonKey('live.gaze.layers', e.key), 'the largest offset is [x, y]');
      }
    }
    final fig = g['figure'];
    if (fig != null && fig is! String && fig is! bool) p.add('live.gaze.figure', 'figure is a figure id, or true for the first figure');
    if (layers.isEmpty && fig == null) p.add('live.gaze', 'gaze moves layers ("layers") or a kit figure\'s eyes ("figure")');
    gaze = GazeDef._(layers, _str(g['from']), need(g, 'live.gaze', 'reach', 80), need(g, 'live.gaze', 'follow', 120) / 1000, fig is String ? fig : (fig == true ? '' : null),
        need(g, 'live.gaze', 'dead', 0.35));
  }
  return LiveDef._(_str(lv['group']), breath, blink, nod, gaze);
}
