/// The vocabulary Fabio can perform: facial expressions, one-shot gestures
/// and the props that can be spawned around him.
///
/// Every enum value's [Enum.name] is the string used in choreography JSON, so
/// renaming a value is a breaking change for saved scripts and for Fabio
/// Studio (the web dashboard mirrors these names exactly).
library;

/// Special eye shapes that replace the default capsule eyes.
enum FabioEyeShape { none, heart, star, spiral, cross }

/// Target values for Fabio's face. The sim eases the live pose toward these.
class FabioFace {
  final double eyeOpenLeft;
  final double eyeOpenRight;

  /// 0 = capsule eyes, 1 = happy "^" arcs.
  final double eyeHappy;
  final double eyeScale;
  final FabioEyeShape eyeShape;

  /// 0 = closed line, 1 = the open "D" mouth from the original artwork.
  final double mouthOpen;

  /// -1 = frown, 1 = big smile.
  final double mouthSmile;
  final double mouthWidth;

  /// 0 = "D" mouth, 1 = round "O" mouth.
  final double mouthRound;
  final double blush;

  /// Head tilt in radians, added to the body rotation.
  final double tilt;

  /// Bias added to where Fabio is looking (-1..1 on each axis).
  final double lookBiasX;
  final double lookBiasY;

  const FabioFace({
    this.eyeOpenLeft = 1,
    this.eyeOpenRight = 1,
    this.eyeHappy = 0,
    this.eyeScale = 1,
    this.eyeShape = FabioEyeShape.none,
    this.mouthOpen = 0.62,
    this.mouthSmile = 0.2,
    this.mouthWidth = 1,
    this.mouthRound = 0,
    this.blush = 0,
    this.tilt = 0,
    this.lookBiasX = 0,
    this.lookBiasY = 0,
  });
}

enum FabioExpression {
  /// Matches the original static artwork.
  neutral(FabioFace()),
  happy(FabioFace(mouthOpen: 0.8, mouthSmile: 0.6, mouthWidth: 1.05, blush: 0.3)),
  joyful(FabioFace(
      eyeHappy: 1, mouthOpen: 1, mouthSmile: 0.8, mouthWidth: 1.2, blush: 0.6)),
  love(FabioFace(
      eyeShape: FabioEyeShape.heart,
      eyeScale: 1.1,
      mouthOpen: 0.45,
      mouthSmile: 0.7,
      blush: 0.9)),
  starstruck(FabioFace(
      eyeShape: FabioEyeShape.star,
      eyeScale: 1.15,
      mouthOpen: 1,
      mouthSmile: 0.7,
      mouthWidth: 1.1,
      blush: 0.4)),
  excited(FabioFace(
      eyeScale: 1.3, mouthOpen: 1, mouthSmile: 0.9, mouthWidth: 1.2, blush: 0.35)),
  surprised(FabioFace(
      eyeScale: 1.35, mouthOpen: 0.8, mouthRound: 1, mouthWidth: 0.75)),
  curious(FabioFace(
      eyeScale: 1.12,
      mouthOpen: 0.12,
      mouthSmile: 0.1,
      mouthWidth: 0.7,
      tilt: 0.14,
      lookBiasY: -0.2)),
  listening(FabioFace(
      eyeScale: 1.08,
      mouthOpen: 0.3,
      mouthRound: 0.6,
      mouthWidth: 0.8,
      tilt: -0.1,
      blush: 0.15)),
  proud(FabioFace(
      eyeHappy: 1,
      mouthOpen: 0.25,
      mouthSmile: 0.9,
      mouthWidth: 0.95,
      blush: 0.3,
      tilt: -0.06,
      lookBiasY: -0.3)),
  shy(FabioFace(
      eyeHappy: 0.45,
      mouthOpen: 0,
      mouthSmile: 0.45,
      mouthWidth: 0.6,
      blush: 1,
      tilt: 0.1,
      lookBiasY: 0.6)),
  wink(FabioFace(
      eyeOpenLeft: 0.04, mouthOpen: 0.5, mouthSmile: 0.8, blush: 0.25)),
  sleepy(FabioFace(
      eyeOpenLeft: 0.22,
      eyeOpenRight: 0.22,
      mouthOpen: 0.15,
      mouthRound: 0.5,
      mouthWidth: 0.7,
      tilt: 0.08,
      lookBiasY: 0.4)),
  asleep(FabioFace(
      eyeOpenLeft: 0,
      eyeOpenRight: 0,
      mouthOpen: 0.1,
      mouthRound: 0.8,
      mouthWidth: 0.55,
      tilt: 0.12,
      lookBiasY: 0.3)),
  determined(FabioFace(
      eyeOpenLeft: 0.62,
      eyeOpenRight: 0.62,
      eyeScale: 1.05,
      mouthOpen: 0.1,
      mouthSmile: -0.15,
      mouthWidth: 0.95)),
  sad(FabioFace(
      eyeOpenLeft: 0.85,
      eyeOpenRight: 0.85,
      eyeScale: 0.95,
      mouthOpen: 0.08,
      mouthSmile: -0.85,
      mouthWidth: 0.8,
      tilt: -0.08,
      lookBiasY: 0.45)),
  dizzy(FabioFace(
      eyeShape: FabioEyeShape.spiral,
      eyeScale: 1.1,
      mouthOpen: 0.3,
      mouthSmile: -0.3,
      mouthWidth: 0.9)),
  knockedOut(FabioFace(
      eyeShape: FabioEyeShape.cross,
      mouthOpen: 0.35,
      mouthRound: 0.7,
      mouthWidth: 0.8));

  final FabioFace face;
  const FabioExpression(this.face);

  static FabioExpression? tryParse(Object? name) {
    for (final e in values) {
      if (e.name == name) return e;
    }
    return null;
  }
}

/// One-shot body performances layered on top of whatever Fabio is doing.
enum FabioGesture {
  bounce(0.75),
  hop(0.45),
  spin(0.9),
  flip(1.05),
  shake(0.9),
  nod(0.8),
  wiggle(1.0),
  pop(0.55),
  wave(1.6),
  cheer(1.3),
  shiver(0.8),
  squish(0.75),
  dizzy(1.6),
  laugh(1.2),
  yawn(2.0),
  startle(0.7),
  tada(1.4),
  think(1.8);

  /// Default duration in seconds.
  final double duration;
  const FabioGesture(this.duration);

  static FabioGesture? tryParse(Object? name) {
    for (final g in values) {
      if (g.name == name) return g;
    }
    return null;
  }
}

/// Props that can be spawned as particles around Fabio.
enum FabioProp {
  sparkle,
  star,
  heart,
  note,
  confetti,
  bubble,
  zzz,
  exclaim,
  question,
  check,
  flower,
  puff,
  drop,
  mic;

  static FabioProp? tryParse(Object? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}
