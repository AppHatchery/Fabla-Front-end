// One animated property of one layer: sorted keys, typed, sampled without allocating.
import 'dart:typed_data';

import 'curves.dart';

/// Colours as integers (0xAARRGGBB, or -1 for none): an [Int64List] where the platform has one, a fixed-length list on
/// the web, where dart2js has no 64-bit typed lists (a colour is exact in a JavaScript number).
List<int> colourList(int n) => _web ? List<int>.filled(n, 0) : Int64List(n);

/// [colourList] holding [values].
List<int> colourListOf(List<int> values) => _web ? List<int>.of(values, growable: false) : Int64List.fromList(values);

const bool _web = bool.fromEnvironment('dart.library.js_interop');

/// The animatable layer properties of alive/1, in a fixed order (an index into the per-layer value buffers).
enum LayerProp {
  /// Translation x (world units, added to the rest position).
  tx,

  /// Translation y.
  ty,

  /// Rotation in degrees about the layer's pivot (Figma's sign: positive turns counter-clockwise on screen).
  rot,

  /// Scale x about the pivot.
  sx,

  /// Scale y about the pivot.
  sy,

  /// Opacity, 0..1, multiplied into the layer.
  opacity,

  /// Width of a parametric box.
  w,

  /// Height of a parametric box.
  h,

  /// Corner radius of a parametric box.
  r,

  /// Skew along x in degrees, about the pivot, applied before scale and rotation (as CSS `skewX`: x moves by
  /// tan(kx) times y).
  kx,

  /// Skew along y in degrees (as CSS `skewY`: y moves by tan(ky) times x).
  ky,

  /// Where the strokes under this layer start, as a share of each stroke's length (0..1): a progress ring, a tick
  /// drawn on. 0 at rest.
  trimStart,

  /// Where they end (0..1). 1 at rest.
  trimEnd,

  /// Fill colour (a box's fill, or currentColor for a fill colour channel).
  fill,

  /// Stroke colour.
  stroke;

  /// Is this a colour property?
  bool get isColour => this == fill || this == stroke;

  /// The rest value when nothing sets it (NaN for a box's size and radius: the box keeps its own).
  double get neutral => switch (this) { sx || sy || opacity || trimEnd => 1.0, w || h || r => double.nan, _ => 0.0 };

  /// How many numeric properties there are (they come first, colours after).
  static const int numeric = 13;

  /// Look a property up by its alive/1 name.
  static LayerProp? byName(String name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Keys of one property: times in seconds, values (numbers, or colours as 0xAARRGGBB in [colours]), the ease of the
/// segment that ends at each key.
class Track {
  /// A numeric track.
  Track.numbers(this.prop, Float64List times, Float64List values, List<Ease> eases)
      : colours = null,
        _d = Float64List(2 * times.length)
          ..setRange(0, times.length, times)
          ..setRange(times.length, 2 * times.length, values),
        _t = 0,
        _vo = times.length,
        n = times.length,
        _eases = _compact(eases),
        assert(times.length == values.length && times.length == eases.length && times.isNotEmpty);

  /// A colour track.
  Track.colours(this.prop, Float64List times, List<int> this.colours, List<Ease> eases)
      : _d = times,
        _t = 0,
        _vo = -1,
        n = times.length,
        _eases = _compact(eases),
        assert(times.length == colours.length && times.length == eases.length && times.isNotEmpty);

  // The same keys, their numbers in [pool] (times at [t], values at [v], [n] each): a view of a clip's [ClipKeys].
  Track._pooled(this.prop, Float64List pool, int t, int? v, this.n, this.colours, this._eases)
      : _d = pool,
        _t = t,
        _vo = v ?? -1;

  // times at _d[_t.._t + n), values (numeric tracks) at _d[_vo.._vo + n); _vo < 0 for a colour track
  final Float64List _d;
  final int _t;
  final int _vo;

  /// Number of keys.
  final int n;

  // every segment linear (the board exports' sampled keys): nothing kept
  static List<Ease>? _compact(List<Ease> e) {
    for (var i = 1; i < e.length; i++) {
      if (!identical(e[i], Ease.linear)) return e;
    }
    return null;
  }

  /// The property this track drives.
  final LayerProp prop;

  /// Key times in seconds, sorted (a view of the clip's buffer).
  Float64List get times => Float64List.sublistView(_d, _t, _t + n);

  /// Numeric values (null for a colour track; a view of the clip's buffer).
  Float64List? get values => _vo < 0 ? null : Float64List.sublistView(_d, _vo, _vo + n);

  /// Colour values as 0xAARRGGBB (null for a numeric track).
  final List<int>? colours;

  /// Ease of the segment that ends at key i (eases[0] is unused). A track whose segments are all linear keeps no
  /// list; this builds one for readers.
  List<Ease> get eases => _eases ?? List<Ease>.filled(n, Ease.linear);
  final List<Ease>? _eases;

  int _cursor = 1; // a hint only: tracks are shared by every player of a scene

  /// The segment index i (keys i-1 and i) that contains t, for t strictly inside the keys.
  int _segment(double t) {
    final d = _d, o = _t;
    final i = _cursor;
    if (i > 0 && i < n && d[o + i - 1] <= t && t < d[o + i]) return i;
    if (i < n - 1 && d[o + i] <= t && t < d[o + i + 1]) return _cursor = i + 1;
    var lo = 1, hi = n - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (d[o + mid] <= t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return _cursor = lo;
  }

  // the segment found by the last sample: _seg (keys _seg - 1 and _seg) and its eased progress _k; or a key index
  // when t lies outside the keys (_seg < 0: key -1 - _seg). Kept in statics (a sample is read at once, on one
  // isolate), not returned as a record, so sampling allocates nothing and a track carries no scratch.
  static int _seg = 0;
  static double _k = 0;

  void _locate(double t) {
    final d = _d, o = _t;
    if (t <= d[o] || n == 1) {
      _seg = -1;
      return;
    }
    if (t >= d[o + n - 1]) {
      _seg = -n;
      return;
    }
    final i = _segment(t);
    final t0 = d[o + i - 1], span = d[o + i] - t0;
    final u = span <= 0 ? 1.0 : (t - t0) / span;
    _seg = i;
    final e = _eases;
    _k = e == null ? u : e[i].at(u, span);
  }

  /// A numeric value at t seconds.
  double number(double t) {
    final v = _d, o = _vo;
    _locate(t);
    final i = _seg;
    if (i < 0) return v[o - 1 - i];
    return v[o + i - 1] + (v[o + i] - v[o + i - 1]) * _k;
  }

  /// A colour value (0xAARRGGBB) at t seconds, channels mixed and rounded as the old engine did.
  int colour(double t) {
    final c = colours!;
    _locate(t);
    final i = _seg;
    if (i < 0) return c[-1 - i];
    return mixColour(c[i - 1], c[i], _k);
  }

  /// The value at t as a double (colours as their int value), for generic readers.
  double valueAt(double t) => _vo >= 0 ? number(t) : colour(t).toDouble();

  /// The time of the last key, in seconds.
  double get end => _d[_t + n - 1];
}

/// A clip's keyed properties as plain arrays (what the player samples): every key number in one buffer, five ints a
/// track and two a keyed layer, no object per track. Tracks whose keys fall at the same times (a clip's sampled moves
/// mostly do) share one list of times. [Track] and the clip's `LayerTracks` are views built for readers.
final class ClipKeys {
  ClipKeys._(this.keys, this.info, this.layers, this.eases) : cursor = Int32List(info.length ~/ _row)..fillRange(0, info.length ~/ _row, 1);

  /// The keys of [tracks] (per keyed layer: its layer index and its tracks in [LayerProp] order) as arrays.
  factory ClipKeys.of(List<(int layer, List<Track> tracks)> tracks) {
    // times shared: the first track with a list of times writes it, the others with the same times point at it
    final timesAt = <int>[]; // per track, where its times start
    final byHash = <int, List<int>>{}; // a hash of the times -> tracks whose times are written
    final all = [for (final (_, ts) in tracks) ...ts];
    var size = 0;
    for (var i = 0; i < all.length; i++) {
      final t = all[i], n = t.n;
      var h = n;
      for (var k = 0; k < n; k++) {
        h = 0x1fffffff & (h * 31 + t._d[t._t + k].hashCode);
      }
      var at = -1;
      for (final j in byHash[h] ?? const <int>[]) {
        final u = all[j];
        if (u.n != n) continue;
        var same = true;
        for (var k = 0; k < n && same; k++) {
          same = u._d[u._t + k] == t._d[t._t + k];
        }
        if (same) {
          at = timesAt[j];
          break;
        }
      }
      if (at < 0) {
        (byHash[h] ??= []).add(i);
        at = size;
        size += n;
      }
      timesAt.add(at);
    }
    final valuesAt = size;
    for (final t in all) {
      size += t.n;
    }
    final keys = Float64List(size);
    final info = Int32List(_row * all.length);
    final layers = Int32List(2 * tracks.length);
    final eases = <List<Ease>>[];
    var v = valuesAt, i = 0, j = 0;
    for (final (li, ts) in tracks) {
      layers[2 * j] = li;
      layers[2 * j + 1] = i;
      j++;
      for (final t in ts) {
        final n = t.n, at = timesAt[i];
        for (var k = 0; k < n; k++) {
          keys[at + k] = t._d[t._t + k];
        }
        final c = t.colours;
        for (var k = 0; k < n; k++) {
          keys[v + k] = c != null ? c[k].toDouble() : t._d[t._vo + k];
        }
        final e = t._eases;
        info
          ..[_row * i] = t.prop.index
          ..[_row * i + 1] = at
          ..[_row * i + 2] = v
          ..[_row * i + 3] = n
          ..[_row * i + 4] = e == null ? -1 : eases.length;
        if (e != null) eases.add(e);
        v += n;
        i++;
      }
    }
    return ClipKeys._(keys, info, layers, List.unmodifiable(eases));
  }

  /// No keys.
  static final ClipKeys none = ClipKeys.of(const []);

  // ints per track in [info]
  static const int _row = 5;

  /// Every distinct list of key times, then every track's values (numbers, or colours 0xAARRGGBB as doubles).
  final Float64List keys;

  /// Per track i: `[5i]` its [LayerProp] index, `[5i + 1]` where its times start in [keys], `[5i + 2]` where its
  /// values start, `[5i + 3]` its key count, `[5i + 4]` its eases in [eases] (-1: every segment linear).
  final Int32List info;

  /// Per keyed layer j: `[2j]` the layer index, `[2j + 1]` its first track (its tracks run to the next layer's first).
  final Int32List layers;

  /// The eases of the tracks that have a non-linear segment (ease of the segment that ends at each key).
  final List<List<Ease>> eases;

  /// Per track, the segment the last sample found (a hint only: every player of a scene shares the clip).
  final Int32List cursor;

  /// Tracks in all.
  int get trackCount => info.length ~/ _row;

  /// Keyed layers.
  int get layerCount => layers.length >> 1;

  /// The layer index of keyed layer [j].
  int layerAt(int j) => layers[2 * j];

  /// The first track of keyed layer [j].
  int firstTrack(int j) => layers[2 * j + 1];

  /// One past the last track of keyed layer [j].
  int endTrack(int j) => 2 * j + 3 < layers.length ? layers[2 * j + 3] : trackCount;

  /// The [LayerProp] index of track [i].
  int propOf(int i) => info[_row * i];

  /// The track of keyed layer [j] for [LayerProp] index [prop], or -1.
  int trackOf(int j, int prop) {
    for (var i = layers[2 * j + 1], e = endTrack(j); i < e; i++) {
      if (info[_row * i] == prop) return i;
    }
    return -1;
  }

  /// Track [i] as a [Track] (a view of [keys]; colours copied), for readers.
  Track track(int i) {
    final r = _row * i;
    final t = info[r + 1], v = info[r + 2], n = info[r + 3], ei = info[r + 4];
    final prop = LayerProp.values[info[r]];
    final cols = prop.isColour ? colourListOf([for (var k = 0; k < n; k++) keys[v + k].toInt()]) : null;
    return Track._pooled(prop, keys, t, cols == null ? v : null, n, cols, ei < 0 ? null : eases[ei]);
  }

  /// The time of the last key of track [i].
  double end(int i) => keys[info[_row * i + 1] + info[_row * i + 3] - 1];

  // as Track._locate, for track i: sets Track._seg and Track._k
  void _locate(int i, double t) {
    final r = _row * i;
    final d = keys, o = info[r + 1], n = info[r + 3];
    if (t <= d[o] || n == 1) {
      Track._seg = -1;
      return;
    }
    if (t >= d[o + n - 1]) {
      Track._seg = -n;
      return;
    }
    var s = cursor[i];
    if (!(s > 0 && s < n && d[o + s - 1] <= t && t < d[o + s])) {
      if (s < n - 1 && d[o + s] <= t && t < d[o + s + 1]) {
        s++;
      } else {
        var lo = 1, hi = n - 1;
        while (lo < hi) {
          final mid = (lo + hi) >> 1;
          if (d[o + mid] <= t) {
            lo = mid + 1;
          } else {
            hi = mid;
          }
        }
        s = lo;
      }
      cursor[i] = s;
    }
    final t0 = d[o + s - 1], span = d[o + s] - t0;
    final u = span <= 0 ? 1.0 : (t - t0) / span;
    Track._seg = s;
    final ei = info[r + 4];
    Track._k = ei < 0 ? u : eases[ei][s].at(u, span);
  }

  /// Track [i]'s numeric value at t seconds (as [Track.number]).
  double number(int i, double t) {
    _locate(i, t);
    final v = keys, o = info[_row * i + 2], s = Track._seg;
    if (s < 0) return v[o - 1 - s];
    return v[o + s - 1] + (v[o + s] - v[o + s - 1]) * Track._k;
  }

  /// Track [i]'s colour (0xAARRGGBB) at t seconds (as [Track.colour]).
  int colour(int i, double t) {
    _locate(i, t);
    final v = keys, o = info[_row * i + 2], s = Track._seg;
    if (s < 0) return v[o - 1 - s].toInt();
    return mixColour(v[o + s - 1].toInt(), v[o + s].toInt(), Track._k);
  }

  /// Bytes of its arrays (keys, track rows, layer rows, cursors), for the benchmark.
  int get bytes => keys.lengthInBytes + info.lengthInBytes + layers.lengthInBytes + cursor.lengthInBytes;
}

int _round(double v) => (v + 0.5).floor().clamp(0, 255);

/// Mix two colours channel by channel (half rounds up, as JavaScript's Math.round).
int mixColour(int a, int b, double k) {
  if (k == 0) return a;
  int ch(int c, int s) => (c >> s) & 0xFF;
  double lerp(int x, int y) => x + (y - x) * k;
  final al = lerp(ch(a, 24), ch(b, 24));
  return (_round(al) << 24) | (_round(lerp(ch(a, 16), ch(b, 16))) << 16) | (_round(lerp(ch(a, 8), ch(b, 8))) << 8) | _round(lerp(ch(a, 0), ch(b, 0)));
}

/// '#RRGGBB' or '#RRGGBBAA' to 0xAARRGGBB; null when it is not a colour.
int? parseHex(String s) {
  if (s.length != 7 && s.length != 9 || !s.startsWith('#')) return null;
  final rgb = int.tryParse(s.substring(1, 7), radix: 16);
  final a = s.length == 9 ? int.tryParse(s.substring(7, 9), radix: 16) : 0xFF;
  if (rgb == null || a == null) return null;
  return (a << 24) | rgb;
}
