// Where scenes come from, and the cache that shares them between screens and releases them when he leaves.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;

import '../kit/figure.dart';
import '../kit/kit_def.dart';
import '../render/art_renderer.dart';
import '../runtime/player.dart';
import '../runtime/scene_data.dart';
import '../schema/art_def.dart';
import '../schema/errors.dart';
import '../schema/scene_def.dart';

/// A source of alive/1 files: the app's assets, or files in memory (tests, previews).
abstract class AliveLibrary {
  /// Scenes in the app's assets under [root] (`<root>/<scene>/scene.json`, `<root>/<scene>/art/<id>.json`).
  ///
  /// With [background] (the default) files of [backgroundMinBytes] or more are decoded and parsed off the UI thread
  /// (in a short-lived isolate, as AssetBundle already does for large text), their path data read into drawing
  /// commands there, and the art prepared in slices between frames (see [AliveCache.prepareSlice]), so a scene
  /// loading while a page opens does not hold up its frames. The isolate is real asynchronous work, like the asset
  /// read itself: widget tests on fake time let it finish with `tester.runAsync` between pumps (the slices go on with
  /// the pumped frames), or pass `background: false` (everything on the UI thread in one go, as before 0.5.0).
  const factory AliveLibrary.assets({String root, AssetBundle? bundle, AliveFonts fonts, bool background, int backgroundMinBytes}) = _AssetLibrary;

  /// Scenes from memory: paths (as above, without a root) to JSON text or decoded JSON.
  factory AliveLibrary.memory(Map<String, Object> files, {AliveFonts fonts}) = _MemoryLibrary;

  /// Fonts for the art's text boxes.
  AliveFonts get fonts;

  /// Read and decode one file. Throws [AliveLoadError].
  Future<Object?> loadJson(String path);

  /// A value that identifies the library for caching (equal libraries share loaded scenes).
  Object get cacheKey;
}

class _AssetLibrary implements AliveLibrary {
  const _AssetLibrary({this.root = 'assets/alive', this.bundle, this.fonts = const AliveFonts(), this.background = true, this.backgroundMinBytes = 16 * 1024});
  final String root;
  final AssetBundle? bundle;
  final bool background;
  final int backgroundMinBytes;
  @override
  final AliveFonts fonts;

  @override
  Object get cacheKey => ('assets', root, bundle, fonts);

  @override
  Future<Object?> loadJson(String path) async {
    final full = '$root/$path';
    final String text;
    try {
      // cache: false, so the bundle keeps no copy of the text once the scene is parsed
      text = await (bundle ?? rootBundle).loadString(full, cache: false);
    } catch (e) {
      throw AliveLoadError(full, 'cannot read $full (is it listed under flutter: assets: in pubspec.yaml?)', e);
    }
    try {
      return jsonDecode(text);
    } on FormatException catch (e) {
      throw AliveLoadError(full, '$full is not valid JSON: ${e.message}', e);
    }
  }

  /// A file's bytes, undecoded.
  Future<Uint8List> loadBytes(String path) async {
    final full = '$root/$path';
    try {
      final data = await (bundle ?? rootBundle).load(full);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (e) {
      throw AliveLoadError(full, 'cannot read $full (is it listed under flutter: assets: in pubspec.yaml?)', e);
    }
  }
}

/// Decode a file's bytes as JSON. Throws [AliveLoadError].
Object? _decode(Uint8List bytes, String full) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException catch (e) {
    throw AliveLoadError(full, '$full is not valid JSON: ${e.message}', e);
  }
}

SceneDef _parseScene(Object? json, String file) => SceneDef.parse(json, file: file);
ArtDef _parseArt(Object? json, String file) => ArtDef.parse(json, file: file, prepare: true);

KitDef _parseKit(Object? json, String file) => KitDef.parse(json, file: file);

/// Between slices of preparing a scene: while frames are coming (a page opening, he moving on another screen), wait
/// until the next one has been drawn, so each slice runs in the time after a frame; when no frame is due, go straight
/// on (null).
Future<void>? _untilNextFrame() {
  final b = SchedulerBinding.instance;
  if (!b.hasScheduledFrame && b.schedulerPhase == SchedulerPhase.idle) return null;
  return b.endOfFrame;
}

/// Draw a loaded scene once into a picture that is thrown away: its first pose, every plane of every art. What the
/// first paint would do once (lay out texts that follow a layer's colour, compile the parts kit figures wear) is done
/// here, while it loads, instead of in the first frame he is on screen.
void _warm(AliveSceneData data) {
  final p = AlivePlayer(data)..start();
  p.evaluate();
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  for (final id in data.def.art) {
    final a = data.compiled[id];
    if (a == null) continue;
    for (final plane in a.planes) {
      a.paint(c, p.state, plane: plane);
    }
  }
  rec.endRecording().dispose();
}

/// The shared fragments a scene's art uses (`alive pack --share`), read once per scene: bytes from an assets library
/// (decoded with each art, off the UI thread), decoded JSON otherwise.
Future<Map<String, Object?>> _readFragments(AliveLibrary library, List<String> ids) async {
  if (ids.isEmpty) return const {};
  if (library is _AssetLibrary && library.background) {
    final list = await Future.wait([for (final id in ids) library.loadBytes('_shared/$id.json')]);
    return {for (var i = 0; i < ids.length; i++) ids[i]: list[i]};
  }
  final list = await Future.wait([for (final id in ids) library.loadJson('_shared/$id.json')]);
  return {for (var i = 0; i < ids.length; i++) ids[i]: list[i]};
}

/// Read and parse one art file of a scene with its shared [fragments] put back: off the UI thread when the library
/// allows it and the files are large.
Future<ArtDef> _readArt(AliveLibrary library, String path, Map<String, Object?> fragments) async {
  if (fragments.isEmpty) return _read(library, path, _parseArt);
  if (library is _AssetLibrary && library.background) {
    final bytes = await library.loadBytes(path);
    final root = library.root;
    ArtDef parse() {
      final f = {for (final e in fragments.entries) e.key: _decode(e.value! as Uint8List, '$root/_shared/${e.key}.json')};
      return _parseArt(ArtDef.splice(_decode(bytes, '$root/$path'), f, file: path), path);
    }

    final size = bytes.length + fragments.values.fold<int>(0, (n, b) => n + (b! as Uint8List).length);
    return size >= library.backgroundMinBytes ? Isolate.run(parse, debugName: 'alive: $path') : parse();
  }
  return _parseArt(ArtDef.splice(await library.loadJson(path), fragments, file: path), path);
}

/// Read and parse one file of [library]: off the UI thread when the library allows it and the file is large.
Future<T> _read<T>(AliveLibrary library, String path, T Function(Object? json, String file) parse) async {
  if (library is _AssetLibrary && library.background) {
    final bytes = await library.loadBytes(path);
    final full = '${library.root}/$path';
    if (bytes.length >= library.backgroundMinBytes) {
      return Isolate.run(() => parse(_decode(bytes, full), path), debugName: 'alive: $path');
    }
    return parse(_decode(bytes, full), path);
  }
  return parse(await library.loadJson(path), path);
}

class _MemoryLibrary implements AliveLibrary {
  _MemoryLibrary(this.files, {this.fonts = const AliveFonts()});
  final Map<String, Object> files;
  @override
  final AliveFonts fonts;

  @override
  Object get cacheKey => this;

  @override
  Future<Object?> loadJson(String path) async {
    final f = files[path];
    if (f == null) throw AliveLoadError(path, 'no file $path');
    if (f is String) {
      try {
        return jsonDecode(f);
      } on FormatException catch (e) {
        throw AliveLoadError(path, '$path is not valid JSON: ${e.message}', e);
      }
    }
    return f;
  }
}

/// A scene held by one user (a controller). Call [release] when done; the last release frees the scene.
class AliveSceneHandle {
  AliveSceneHandle._(this._entry);
  final _Entry _entry;
  bool _released = false;

  /// The loaded scene.
  AliveSceneData get data => _entry.data!;

  /// Let go of the scene.
  void release() {
    if (_released) return;
    _released = true;
    _entry.cache._release(_entry);
  }
}

class _Entry {
  _Entry(this.cache, this.key, this.future);
  final AliveCache cache;
  final Object key;
  Future<AliveSceneData> future;
  AliveSceneData? data;
  int refs = 0;

  /// Preloads holding it, each until its time runs out or a controller takes the scene over.
  final List<(AliveSceneHandle, Timer)> preloads = [];

  /// A controller took it: the preloads let go (the controller's handle keeps it).
  void handOver() {
    if (preloads.isEmpty) return;
    final list = List.of(preloads);
    preloads.clear();
    for (final (h, t) in list) {
      t.cancel();
      h.release();
    }
    cache._unwatchIfIdle();
  }
}

class _PressureWatch with WidgetsBindingObserver {
  _PressureWatch(this.cache);
  final AliveCache cache;
  @override
  void didHaveMemoryPressure() => cache.releasePreloads();
}

/// Loads scenes once and shares them while any screen shows them; frees them when the last one lets go.
class AliveCache {
  /// A cache. Scenes it loads from the app's assets ([AliveLibrary.assets] with `background`) are prepared in slices
  /// of about [prepareSlice] on the UI thread, each after a frame while frames are coming, so a page that opens or
  /// moves while a large scene is prepared keeps its frames.
  AliveCache({this.prepareSlice = const Duration(milliseconds: 4), this.keepArtTrees = false});

  /// The longest stretch of preparing a scene's art before the next frame may run.
  final Duration prepareSlice;

  /// Keep each loaded scene's parsed art trees ([AliveSceneData.arts] with their nodes) for tools that read them.
  /// Off by default: once prepared, the trees are released ([AliveSceneData.releaseArtTrees]).
  final bool keepArtTrees;

  /// The cache controllers use unless given another.
  static final AliveCache shared = AliveCache();

  final Map<Object, _Entry> _entries = {};

  /// Scenes held right now (for tests and the benchmark).
  int get liveScenes => _entries.values.where((e) => e.data != null).length;

  /// Ids of scenes held right now.
  List<String> get liveSceneIds => [for (final e in _entries.values) if (e.data != null) e.data!.def.id];

  /// The scene, if it is loaded already (preloaded, or on another screen): a handle at once, with no frame between.
  /// Null when it is not loaded (yet).
  AliveSceneHandle? tryAcquire(AliveLibrary library, String scene) {
    if (_disposed) return null;
    final e = _entries[(library.cacheKey, scene)];
    if (e == null || e.data == null || e.data!.disposed) return null;
    e.refs++;
    e.handOver();
    return AliveSceneHandle._(e);
  }

  /// Load [scenes] ahead of the screens that show them (on the page before, while the user reads it) and hold each
  /// until a controller takes it over, or for [keep] if none does. A controller made after the preload finished is
  /// ready in its constructor, with nothing left to load. Each scene is decoded and parsed off the UI thread
  /// (with [AliveLibrary.assets]), prepared and drawn once off screen. Completes when all are loaded; the scenes that
  /// could not be are returned (nothing is thrown). Preloading a loaded scene again holds it longer.
  Future<List<AliveError>> preload(AliveLibrary library, Iterable<String> scenes, {Duration keep = const Duration(seconds: 30)}) async {
    final ids = scenes.toSet();
    if (_disposed) return [for (final id in ids) _disposedError(id)];
    _watchPressure();
    _preloading++;
    final failed = <AliveError>[];
    try {
      await Future.wait([
        for (final id in ids)
          _acquire(library, id, preload: true).then((h) {
            if (_disposed) {
              // disposed while it loaded: nothing is held
              h.release();
              failed.add(_disposedError(id));
              return;
            }
            final e = h._entry;
            late final (AliveSceneHandle, Timer) hold;
            hold = (h, Timer(keep, () {
              e.preloads.remove(hold);
              h.release();
              _unwatchIfIdle();
            }));
            e.preloads.add(hold);
          }, onError: (Object e) {
            failed.add(e is AliveError ? e : AliveLoadError('$id/scene.json', 'could not preload "$id": $e', e));
          }),
      ]);
    } finally {
      _preloading--;
      _unwatchIfIdle();
    }
    return failed;
  }

  /// Let go of every preload hold now: scenes no screen shows are released (a screen's scene stays). The cache does
  /// it by itself when the system reports memory pressure, while it holds preloads.
  int releasePreloads() {
    var n = 0;
    for (final e in List.of(_entries.values)) {
      if (e.preloads.isEmpty) continue;
      final list = List.of(e.preloads);
      e.preloads.clear();
      for (final (h, t) in list) {
        t.cancel();
        h.release();
        n++;
      }
    }
    _unwatchIfIdle();
    return n;
  }

  /// Is the cache listening for the system's memory pressure now? Only while it holds preloads or loads them: the
  /// listener is removed when the last preload is taken over, runs out of time or is released, and by [dispose], so
  /// the app's binding never keeps a cache that has nothing to let go.
  bool get watchesMemoryPressure => _pressure != null;

  /// Has [dispose] run?
  bool get isDisposed => _disposed;
  bool _disposed = false;

  /// Let go of every preload and stop listening for memory pressure. Scenes that screens hold stay until those
  /// screens let go; new loads are refused ([acquire] throws an [AliveLoadError], [preload] returns one per scene,
  /// [tryAcquire] gives null). For a cache an app or a test made itself; [shared] lives as long as the app and
  /// throws a [StateError] here. A second call does nothing.
  void dispose() {
    if (identical(this, shared)) throw StateError('AliveCache.shared lives as long as the app: release its preloads with releasePreloads()');
    if (_disposed) return;
    _disposed = true;
    releasePreloads();
    _unwatch();
  }

  AliveLoadError _disposedError(String id) => AliveLoadError('$id/scene.json', 'could not load "$id": the cache was disposed');

  _PressureWatch? _pressure;
  int _preloading = 0; // preload calls not finished yet

  void _watchPressure() {
    if (_pressure != null) return;
    try {
      final w = _PressureWatch(this);
      WidgetsBinding.instance.addObserver(w);
      _pressure = w;
    } catch (_) {
      // no binding (a plain Dart test): nothing to watch
    }
  }

  void _unwatchIfIdle() {
    if (_pressure == null || _preloading > 0) return;
    for (final e in _entries.values) {
      if (e.preloads.isNotEmpty) return;
    }
    _unwatch();
  }

  void _unwatch() {
    final w = _pressure;
    if (w == null) return;
    _pressure = null;
    try {
      WidgetsBinding.instance.removeObserver(w);
    } catch (_) {
      // no binding: nothing was added
    }
  }

  /// Is [scene] loaded and held (by a screen or a preload)?
  bool isLoaded(AliveLibrary library, String scene) => _entries[(library.cacheKey, scene)]?.data != null;

  /// Load (or share) a scene. Throws [AliveError] when it cannot be loaded.
  Future<AliveSceneHandle> acquire(AliveLibrary library, String scene) => _acquire(library, scene);

  Future<AliveSceneHandle> _acquire(AliveLibrary library, String scene, {bool preload = false}) async {
    if (_disposed) throw _disposedError(scene);
    final key = (library.cacheKey, scene);
    var e = _entries[key];
    if (e == null) {
      e = _Entry(this, key, _load(this, library, scene));
      _entries[key] = e;
    }
    e.refs++;
    try {
      e.data = await e.future;
    } catch (_) {
      e.refs--;
      if (identical(_entries[key], e)) _entries.remove(key); // a failed load is not cached: a retry reads again
      rethrow;
    }
    if (!preload) e.handOver();
    return AliveSceneHandle._(e);
  }

  void _release(_Entry e) {
    e.refs--;
    if (e.refs > 0) return;
    if (identical(_entries[e.key], e)) _entries.remove(e.key);
    e.data?.dispose();
    e.data = null;
  }

  static Future<AliveSceneData> _load(AliveCache cache, AliveLibrary library, String scene) async {
    final sceneFile = '$scene/scene.json';
    final def = await _read(library, sceneFile, _parseScene);
    // kit figures: their packs (kits/<pack>/kit.json, shared by every figure of the pack) and their rigs
    final kits = <String, KitData>{};
    for (final f in def.figures.values) {
      if (kits.containsKey(f.kit)) continue;
      kits[f.kit] = KitData(await _read(library, 'kits/${f.kit}/kit.json', _parseKit), fonts: library.fonts);
    }
    final rigs = {for (final f in def.figures.values) f.id: FigureRig(f, kits[f.kit]!)};
    final arts = <String, ArtDef>{};
    final fragments = await _readFragments(library, def.shared);
    await Future.wait([
      for (final id in def.art)
        if (!rigs.containsKey(id)) _readArt(library, '$scene/art/$id.json', fragments).then((a) => arts[id] = a),
    ]);
    for (final r in rigs.values) {
      arts[r.id] = ArtDef.parse(r.artJson(), file: 'figure ${r.id} (kit ${r.kit.def.id})');
    }
    final first = rigs.values.isEmpty ? null : rigs.values.first;
    for (final r in rigs.values) {
      await loadKitParts(library, r.kit, partsNeeded(def, r, def.pools, first: identical(r, first)));
    }
    // with the assets library, in slices between frames; from memory (tests, previews) in one go, as before
    final data = library is _AssetLibrary && library.background
        ? await AliveSceneData.prepare(def, arts, fonts: library.fonts, file: sceneFile, kits: kits, figures: rigs, slice: cache.prepareSlice, pause: _untilNextFrame)
        : Timeline.timeSync('alive: prepare $scene', () => AliveSceneData(def, arts, fonts: library.fonts, file: sceneFile, kits: kits, figures: rigs));
    // draw it once off screen, so the first frame on screen only replays: texts laid out, worn parts compiled
    Timeline.timeSync('alive: warm $scene', () => _warm(data));
    if (!cache.keepArtTrees) data.releaseArtTrees();
    return data;
  }

  /// Load parts of a pack that are not loaded yet (`kits/<pack>/parts/<id>.json`). Throws [AliveError] on a bad file.
  static Future<void> loadKitParts(AliveLibrary library, KitData kit, Iterable<String> ids) async {
    final missing = {for (final id in ids) if (id.isNotEmpty && !kit.has(id) && kit.def.parts.containsKey(id)) id};
    await Future.wait([
      for (final id in missing) _read(library, 'kits/${kit.def.id}/parts/$id.json', _parseArt).then((a) => kit.art[id] = a),
    ]);
  }
}
