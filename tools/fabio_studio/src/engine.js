// ============================================================
// Fabio engine: a one-to-one port of lib/theme/fabio/*.dart.
// Keep formulas identical so Studio previews match the app.
// ============================================================
const TAU = Math.PI * 2;
const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);
const lerp = (a, b, t) => a + (b - a) * t;
function smoothstep(e0, e1, x) { const t = clamp((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t); }
const approach = (c, t, rate, dt) => c + (t - c) * (1 - Math.exp(-rate * dt));
function envelope(u, attack = 0.15, release = 0.2) {
  if (u <= 0 || u >= 1) return 0;
  if (u < attack) return smoothstep(0, attack, u);
  if (u > 1 - release) return 1 - smoothstep(1 - release, 1, u);
  return 1;
}
function outBounce(t) {
  const n1 = 7.5625, d1 = 2.75;
  if (t < 1 / d1) return n1 * t * t;
  if (t < 2 / d1) { t -= 1.5 / d1; return n1 * t * t + 0.75; }
  if (t < 2.5 / d1) { t -= 2.25 / d1; return n1 * t * t + 0.9375; }
  t -= 2.625 / d1; return n1 * t * t + 0.984375;
}
function ease(name, t) {
  t = clamp(t, 0, 1);
  switch (name) {
    case 'linear': return t;
    case 'inQuad': return t * t;
    case 'outQuad': return 1 - (1 - t) * (1 - t);
    case 'inOutQuad': return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
    case 'inCubic': return t * t * t;
    case 'outCubic': return 1 - Math.pow(1 - t, 3);
    case 'inOutSine': return -(Math.cos(Math.PI * t) - 1) / 2;
    case 'outExpo': return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
    case 'inBack': { const c1 = 1.70158; return (c1 + 1) * t * t * t - c1 * t * t; }
    case 'outBack': { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); }
    case 'outElastic': if (t === 0 || t === 1) return t; return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * TAU / 3) + 1;
    case 'outBounce': return outBounce(t);
    default: return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }
}
const EASES = ['inOutCubic', 'linear', 'inQuad', 'outQuad', 'inOutQuad', 'inCubic', 'outCubic', 'inOutSine', 'outExpo', 'inBack', 'outBack', 'outElastic', 'outBounce'];

class Rng {
  constructor(seed = 1) { this.s = seed >>> 0; }
  next() {
    this.s = (this.s + 0x6D2B79F5) >>> 0;
    let t = this.s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  range(lo, hi) { return lo + (hi - lo) * this.next(); }
  pick(a) { return a[Math.floor(this.next() * a.length) % a.length]; }
}

// ---------- vocabulary (fabio_expression.dart) ----------
const FACE_DEFAULT = { eyeOpenLeft: 1, eyeOpenRight: 1, eyeHappy: 0, eyeScale: 1, eyeShape: 'none', mouthOpen: 0.62, mouthSmile: 0.2, mouthWidth: 1, mouthRound: 0, blush: 0, tilt: 0, lookBiasX: 0, lookBiasY: 0 };
const face = (o) => Object.assign({}, FACE_DEFAULT, o);
const EXPRESSIONS = {
  neutral: face({}),
  happy: face({ mouthOpen: 0.8, mouthSmile: 0.6, mouthWidth: 1.05, blush: 0.3 }),
  joyful: face({ eyeHappy: 1, mouthOpen: 1, mouthSmile: 0.8, mouthWidth: 1.2, blush: 0.6 }),
  love: face({ eyeShape: 'heart', eyeScale: 1.1, mouthOpen: 0.45, mouthSmile: 0.7, blush: 0.9 }),
  starstruck: face({ eyeShape: 'star', eyeScale: 1.15, mouthOpen: 1, mouthSmile: 0.7, mouthWidth: 1.1, blush: 0.4 }),
  excited: face({ eyeScale: 1.3, mouthOpen: 1, mouthSmile: 0.9, mouthWidth: 1.2, blush: 0.35 }),
  surprised: face({ eyeScale: 1.35, mouthOpen: 0.8, mouthRound: 1, mouthWidth: 0.75 }),
  curious: face({ eyeScale: 1.12, mouthOpen: 0.12, mouthSmile: 0.1, mouthWidth: 0.7, tilt: 0.14, lookBiasY: -0.2 }),
  listening: face({ eyeScale: 1.08, mouthOpen: 0.3, mouthRound: 0.6, mouthWidth: 0.8, tilt: -0.1, blush: 0.15 }),
  proud: face({ eyeHappy: 1, mouthOpen: 0.25, mouthSmile: 0.9, mouthWidth: 0.95, blush: 0.3, tilt: -0.06, lookBiasY: -0.3 }),
  shy: face({ eyeHappy: 0.45, mouthOpen: 0, mouthSmile: 0.45, mouthWidth: 0.6, blush: 1, tilt: 0.1, lookBiasY: 0.6 }),
  wink: face({ eyeOpenLeft: 0.04, mouthOpen: 0.5, mouthSmile: 0.8, blush: 0.25 }),
  sleepy: face({ eyeOpenLeft: 0.22, eyeOpenRight: 0.22, mouthOpen: 0.15, mouthRound: 0.5, mouthWidth: 0.7, tilt: 0.08, lookBiasY: 0.4 }),
  asleep: face({ eyeOpenLeft: 0, eyeOpenRight: 0, mouthOpen: 0.1, mouthRound: 0.8, mouthWidth: 0.55, tilt: 0.12, lookBiasY: 0.3 }),
  determined: face({ eyeOpenLeft: 0.62, eyeOpenRight: 0.62, eyeScale: 1.05, mouthOpen: 0.1, mouthSmile: -0.15, mouthWidth: 0.95 }),
  sad: face({ eyeOpenLeft: 0.85, eyeOpenRight: 0.85, eyeScale: 0.95, mouthOpen: 0.08, mouthSmile: -0.85, mouthWidth: 0.8, tilt: -0.08, lookBiasY: 0.45 }),
  dizzy: face({ eyeShape: 'spiral', eyeScale: 1.1, mouthOpen: 0.3, mouthSmile: -0.3, mouthWidth: 0.9 }),
  knockedOut: face({ eyeShape: 'cross', mouthOpen: 0.35, mouthRound: 0.7, mouthWidth: 0.8 }),
};
const GESTURES = { bounce: 0.75, hop: 0.45, spin: 0.9, flip: 1.05, shake: 0.9, nod: 0.8, wiggle: 1.0, pop: 0.55, wave: 1.6, cheer: 1.3, shiver: 0.8, squish: 0.75, dizzy: 1.6, laugh: 1.2, yawn: 2.0, startle: 0.7, tada: 1.4, think: 1.8 };
const PROPS = ['sparkle', 'star', 'heart', 'note', 'confetti', 'bubble', 'zzz', 'exclaim', 'question', 'check', 'flower', 'puff', 'drop', 'mic'];
const MODES = ['burst', 'fountain', 'ring', 'float', 'rain', 'orbit', 'trail'];
const MOTION_TYPES = ['fly', 'dash', 'hold', 'orbit', 'figure8', 'hop', 'wander', 'teleport'];

// ---------- pose + rig (fabio_rig.dart) ----------
const BODY_COLOR = '#A8D0FB';
function newPose() {
  return {
    offsetX: 0, offsetY: 0, rotation: 0, scale: 1, stretch: 1, breath: 0,
    dragX: 0, dragY: 0, flare: 0, hemPhase: 0, hemAmp: 1.6, wobble: 0, wobblePhase: 0, tuftX: 0, tuftY: 0,
    facing: 1, lookX: 0, lookY: 0, eyeOpenLeft: 1, eyeOpenRight: 1, eyeHappy: 0, eyeScale: 1,
    eyeShape: 'none', eyeShapeAmount: 0, eyeSpin: 0,
    mouthOpen: 0.62, mouthSmile: 0.2, mouthWidth: 1, mouthRound: 0, blush: 0,
    armLeft: 0, armRight: 0, armLeftAngle: 0, armRightAngle: 0,
    opacity: 1, shine: 0.2, color: BODY_COLOR,
  };
}
const BODY_CUBICS = [
  [63.0013, 0.240728, 55.1218, 1.29124, 30.0286, 9.3728, 17.6638, 14.8682],
  [17.6638, 14.8682, 13.85, 16.5632, 9.33981, 27.8797, 21.4217, 32.5668],
  [21.4217, 32.5668, 21.4217, 62.2652, 5.69657, 118.136, 0.695832, 130.861],
  [0.695832, 130.861, 0.319211, 131.819, 0.669977, 132.91, 1.59468, 133.363],
  [1.59468, 133.363, 9.59124, 137.28, 24.1941, 139.066, 34, 135.5],
  [34, 135.5, 61, 125.68, 59, 143.892, 85.5, 135.5],
  [85.5, 135.5, 111.306, 127.328, 123.835, 141.236, 142.02, 133.197],
  [142.02, 133.197, 142.888, 132.814, 143.335, 131.885, 143.077, 130.972],
  [143.077, 130.972, 139.462, 118.175, 119.647, 52.2539, 107.773, 30.5062],
  [107.773, 30.5062, 92.1758, 1.93786, 72.6142, -1.04087, 63.0013, 0.240728],
];
const dist = (x1, y1, x2, y2) => Math.hypot(x2 - x1, y2 - y1);
const OUTLINE = (() => {
  const pts = [];
  for (const c of BODY_CUBICS) {
    const poly = dist(c[0], c[1], c[2], c[3]) + dist(c[2], c[3], c[4], c[5]) + dist(c[4], c[5], c[6], c[7]);
    const n = Math.max(4, Math.ceil(poly / 2.2));
    for (let i = 0; i < n; i++) {
      const t = i / n, mt = 1 - t;
      const a = mt * mt * mt, b = 3 * mt * mt * t, cc = 3 * mt * t * t, d = t * t * t;
      pts.push([a * c[0] + b * c[2] + cc * c[4] + d * c[6], a * c[1] + b * c[3] + cc * c[5] + d * c[7]]);
    }
  }
  return pts;
})();

function hexToRgb(h) { h = h.replace('#', ''); if (h.length === 8) h = h.slice(2); const n = parseInt(h, 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; }
function mix(a, b, t) { const A = hexToRgb(a), B = hexToRgb(b); return `rgb(${A.map((v, i) => Math.round(lerp(v, B[i], t))).join(',')})`; }
function rgba(h, a) { const [r, g, b] = hexToRgb(h); return `rgba(${r},${g},${b},${clamp(a, 0, 1)})`; }

function makeDeformer(p) {
  const sy = p.stretch * (1 + p.breath * 0.014);
  const sx = (1 + (1 / p.stretch - 1) * 0.9) * (1 + p.breath * 0.008);
  return {
    sx, sy,
    apply(x, y) {
      let dx = 0, dy = 0;
      const hem = smoothstep(96, 134, y);
      if (hem > 0) {
        const a = x * 0.085 - p.hemPhase;
        dy += p.hemAmp * hem * Math.sin(a);
        dx += p.hemAmp * 0.45 * hem * Math.cos(a);
        dx += (x - 72) * hem * p.flare;
      }
      const lag = clamp(y / 138, 0, 1.1), lag2 = lag * lag;
      dx -= p.dragX * lag2 * 16;
      dy -= p.dragY * lag2 * 8;
      const tx = x - 17, ty = y - 23;
      const tuft = Math.exp(-(tx * tx + ty * ty) / 242);
      dx += p.tuftX * tuft; dy += p.tuftY * tuft;
      if (p.wobble !== 0) dx += p.wobble * Math.sin(y * 0.07 + p.wobblePhase) * 7;
      return [72 + (x + dx - 72) * sx, 118 + (y + dy - 118) * sy];
    },
  };
}

function heartPath(r) {
  const p = new Path2D();
  p.moveTo(0, 0.9 * r);
  p.bezierCurveTo(-0.9 * r, 0.25 * r, -1.05 * r, -0.55 * r, -0.5 * r, -0.75 * r);
  p.bezierCurveTo(-0.2 * r, -0.85 * r, 0, -0.6 * r, 0, -0.45 * r);
  p.bezierCurveTo(0, -0.6 * r, 0.2 * r, -0.85 * r, 0.5 * r, -0.75 * r);
  p.bezierCurveTo(1.05 * r, -0.55 * r, 0.9 * r, 0.25 * r, 0, 0.9 * r);
  p.closePath();
  return p;
}
function starPath(outer, inner, points = 5) {
  const p = new Path2D();
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 === 0 ? outer : inner;
    const a = -Math.PI / 2 + i * Math.PI / points;
    i === 0 ? p.moveTo(Math.cos(a) * r, Math.sin(a) * r) : p.lineTo(Math.cos(a) * r, Math.sin(a) * r);
  }
  p.closePath();
  return p;
}
function rrect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y); ctx.lineTo(x + w - r, y); ctx.arcTo(x + w, y, x + w, y + r, r);
  ctx.lineTo(x + w, y + h - r); ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h); ctx.arcTo(x, y + h, x, y + h - r, r);
  ctx.lineTo(x, y + r); ctx.arcTo(x, y, x + r, y, r); ctx.closePath();
}

const Rig = {
  paint(ctx, pose, cx, cy, size) {
    if (pose.opacity <= 0.001 || pose.scale <= 0.001) return;
    const k = size / 144 * pose.scale;
    ctx.save();
    ctx.translate(cx + pose.offsetX * k, cy + pose.offsetY * k);
    ctx.rotate(pose.rotation);
    ctx.scale(k, k);
    ctx.translate(-72, -69);
    ctx.globalAlpha = clamp(pose.opacity, 0, 1);
    const d = makeDeformer(pose);
    const grad = ctx.createLinearGradient(40, 0, 100, 140);
    grad.addColorStop(0, mix(pose.color, '#FFFFFF', 0.16));
    grad.addColorStop(0.5, pose.color);
    grad.addColorStop(1, mix(pose.color, '#5B89FF', 0.16));
    this.arms(ctx, pose, d, grad);
    const body = this.bodyPath(d);
    ctx.fillStyle = grad;
    ctx.fill(body);
    if (pose.shine > 0.01) this.shine(ctx, pose, d, body);
    this.face(ctx, pose, d);
    ctx.restore();
  },
  bodyPath(d) {
    const pts = OUTLINE.map(([x, y]) => d.apply(x, y));
    const n = pts.length, path = new Path2D();
    const s = [(pts[n - 1][0] + pts[0][0]) / 2, (pts[n - 1][1] + pts[0][1]) / 2];
    path.moveTo(s[0], s[1]);
    for (let i = 0; i < n; i++) {
      const p = pts[i], q = pts[(i + 1) % n];
      path.quadraticCurveTo(p[0], p[1], (p[0] + q[0]) / 2, (p[1] + q[1]) / 2);
    }
    path.closePath();
    return path;
  },
  arms(ctx, pose, d, grad) {
    ctx.save();
    ctx.strokeStyle = grad; ctx.lineCap = 'round'; ctx.lineWidth = 11;
    const arm = (ext, root, angle) => {
      if (ext <= 0.01) return;
      const dx = Math.cos(angle), dy = Math.sin(angle), len = 4 + 17 * clamp(ext, 0, 1.3);
      ctx.beginPath(); ctx.moveTo(root[0] - dx * 4, root[1] - dy * 4); ctx.lineTo(root[0] + dx * len, root[1] + dy * len); ctx.stroke();
    };
    arm(pose.armRight, d.apply(122, 72), pose.armRightAngle);
    arm(pose.armLeft, d.apply(18, 72), Math.PI - pose.armLeftAngle);
    ctx.restore();
  },
  shine(ctx, pose, d, body) {
    ctx.save();
    ctx.clip(body);
    ctx.fillStyle = rgba('#FFFFFF', pose.shine);
    const c = d.apply(46, 22);
    ctx.save(); ctx.translate(c[0], c[1]); ctx.rotate(-0.5);
    ctx.beginPath(); ctx.ellipse(0, 0, 8.5, 3.5, 0, 0, TAU); ctx.fill(); ctx.restore();
    const dot = d.apply(34, 33);
    ctx.beginPath(); ctx.arc(dot[0], dot[1], 2.2, 0, TAU); ctx.fill();
    ctx.restore();
  },
  face(ctx, pose, d) {
    const fx = 72 + 13 * pose.facing + pose.lookX * 4.5;
    const fy = 41 + pose.lookY * 3.5;
    const spread = 6.55 * (0.9 + 0.1 * Math.abs(pose.facing));
    const eyeL = d.apply(fx - spread, fy - 4.2), eyeR = d.apply(fx + spread, fy - 4.2);
    const mouth = d.apply(fx + pose.lookX * 1.2, fy + 4 + pose.lookY * 1.2);
    if (pose.blush > 0.01) {
      const a = clamp(pose.blush, 0, 1);
      for (const e of [[eyeL[0] - 2, eyeL[1] + 6.4], [eyeR[0] + 2, eyeR[1] + 6.4]]) {
        ctx.fillStyle = rgba('#FF8FAB', 0.3 * a); ctx.beginPath(); ctx.ellipse(e[0], e[1], 4.75, 2.5, 0, 0, TAU); ctx.fill();
        ctx.fillStyle = rgba('#FF8FAB', 0.5 * a); ctx.beginPath(); ctx.ellipse(e[0], e[1], 3.25, 1.6, 0, 0, TAU); ctx.fill();
      }
    }
    this.eye(ctx, pose, d, eyeL, pose.eyeOpenLeft);
    this.eye(ctx, pose, d, eyeR, pose.eyeOpenRight);
    this.mouth(ctx, pose, d, mouth);
  },
  eye(ctx, pose, d, c, open) {
    ctx.save();
    ctx.translate(c[0], c[1]); ctx.scale(d.sx, d.sy);
    const s = pose.eyeScale;
    const shapeA = pose.eyeShape === 'none' ? 0 : clamp(pose.eyeShapeAmount, 0, 1);
    const happy = clamp(pose.eyeHappy, 0, 1);
    const baseA = (1 - happy) * (1 - shapeA), happyA = happy * (1 - shapeA);
    open = clamp(open, 0, 1.2);
    ctx.lineCap = 'round'; ctx.lineWidth = 1.8;
    if (baseA > 0.01) {
      const capA = smoothstep(0.1, 0.3, open) * baseA;
      if (capA > 0.01) {
        const w = 4 * s, h = Math.max(7 * s * open, 1.6), r = Math.min(w, h) / 2;
        ctx.fillStyle = rgba('#000000', capA);
        rrect(ctx, -w / 2, -h / 2, w, h, r); ctx.fill();
        const glint = smoothstep(1.04, 1.3, s) * capA * smoothstep(0.5, 0.9, open);
        if (glint > 0.01) { ctx.fillStyle = rgba('#FFFFFF', glint); ctx.beginPath(); ctx.arc(-0.5 * s, -h / 2 + 1.5 * s, 0.85 * s, 0, TAU); ctx.fill(); }
      }
      const lineA = (1 - smoothstep(0.1, 0.3, open)) * baseA;
      if (lineA > 0.01) {
        ctx.strokeStyle = rgba('#000000', lineA);
        ctx.beginPath(); ctx.moveTo(-2.4 * s, -0.3); ctx.quadraticCurveTo(0, 1.4 * s, 2.4 * s, -0.3); ctx.stroke();
      }
    }
    if (happyA > 0.01) {
      ctx.strokeStyle = rgba('#000000', happyA);
      ctx.beginPath(); ctx.moveTo(-2.8 * s, 1.4 * s); ctx.quadraticCurveTo(0, -2.9 * s, 2.8 * s, 1.4 * s); ctx.stroke();
    }
    if (shapeA > 0.01) {
      const pop = s * (0.35 + 0.65 * ease('outBack', shapeA));
      ctx.scale(pop, pop);
      this.eyeShape(ctx, pose, shapeA);
    }
    ctx.restore();
  },
  eyeShape(ctx, pose, a) {
    switch (pose.eyeShape) {
      case 'heart': ctx.fillStyle = rgba('#FF4F7B', a); ctx.fill(heartPath(4.4)); break;
      case 'star': {
        const st = starPath(5.2, 2.3);
        ctx.fillStyle = rgba('#FFC23D', a); ctx.fill(st);
        ctx.strokeStyle = rgba('#000000', a); ctx.lineJoin = 'round'; ctx.lineWidth = 0.9; ctx.stroke(st); break;
      }
      case 'spiral': {
        ctx.beginPath();
        for (let i = 0; i <= 40; i++) {
          const t = i / 40, ang = t * 2.6 * TAU + pose.eyeSpin, r = 0.3 + t * 3.3;
          i === 0 ? ctx.moveTo(Math.cos(ang) * r, Math.sin(ang) * r) : ctx.lineTo(Math.cos(ang) * r, Math.sin(ang) * r);
        }
        ctx.strokeStyle = rgba('#000000', a); ctx.lineWidth = 1.1; ctx.stroke(); break;
      }
      case 'cross':
        ctx.strokeStyle = rgba('#000000', a); ctx.lineWidth = 1.8;
        ctx.beginPath(); ctx.moveTo(-2.4, -2.4); ctx.lineTo(2.4, 2.4); ctx.moveTo(2.4, -2.4); ctx.lineTo(-2.4, 2.4); ctx.stroke(); break;
    }
  },
  mouth(ctx, pose, d, c) {
    const w = 4.2 * pose.mouthWidth;
    const s = clamp(pose.mouthSmile, -1, 1), o = clamp(pose.mouthOpen, 0, 1.2), r = clamp(pose.mouthRound, 0, 1);
    const cy = -s * 1.8;
    const topC = cy + s * 2.2 * (1 - clamp(o, 0, 1));
    const bot = topC + o * 8.5;
    const dm = [w, cy, w * 0.5, topC, -w * 0.5, topC, -w, cy, -w * 0.95, bot, w * 0.95, bot];
    const a = 2.4 * pose.mouthWidth, b = 1.0 + o * 2.6, ey = b * 0.9 - 0.5, k = b * 4 / 3;
    const om = [a, ey, a, ey - k, -a, ey - k, -a, ey, -a, ey + k, a, ey + k];
    const m = dm.map((v, i) => lerp(v, om[i], r));
    const path = new Path2D();
    path.moveTo(m[0], m[1]);
    path.bezierCurveTo(m[2], m[3], m[4], m[5], m[6], m[7]);
    path.bezierCurveTo(m[8], m[9], m[10], m[11], m[0], m[1]);
    path.closePath();
    ctx.save();
    ctx.translate(c[0], c[1]); ctx.scale(d.sx, d.sy);
    ctx.fillStyle = '#000'; ctx.fill(path);
    ctx.strokeStyle = '#000'; ctx.lineJoin = 'round'; ctx.lineCap = 'round'; ctx.lineWidth = 1.1; ctx.stroke(path);
    const tongue = smoothstep(0.45, 0.9, o) * (1 - r);
    if (tongue > 0.01) {
      ctx.clip(path);
      ctx.fillStyle = rgba('#FF7E9D', tongue);
      ctx.beginPath(); ctx.ellipse(0, lerp(cy, bot, 0.72), w * 0.525, 2.2, 0, 0, TAU); ctx.fill();
    }
    ctx.restore();
  },
};

// ---------- sim (fabio_sim.dart) ----------
class GestureFx {
  constructor() {
    Object.assign(this, { dx: 0, dy: 0, rot: 0, stretch: 1, scale: 1, wobble: 0, flare: 0, armLeft: 0, armLeftAngle: 0, armRight: 0, armRightAngle: 0, lookX: 0, lookY: 0, tilt: 0, eyeHappy: 0, eyeOpenMul: 1, eyeScale: 0, eyeShape: null, mouthOpen: 0, mouthSmile: 0, mouthRound: 0, blush: 0 });
  }
  arm(side, ext, angle) {
    if (side >= 0) { if (ext >= this.armRight) { this.armRight = ext; this.armRightAngle = angle; } }
    else if (ext >= this.armLeft) { this.armLeft = ext; this.armLeftAngle = angle; }
  }
  jump(u, height, takeoff = 0.18, landing = 0.82) {
    if (u < takeoff) this.stretch *= 1 - 0.18 * Math.sin(Math.PI * u / takeoff);
    else if (u < landing) {
      const v = (u - takeoff) / (landing - takeoff);
      this.dy -= height * 4 * v * (1 - v);
      this.stretch *= 1 + 0.14 * Math.abs(1 - 2 * v) * smoothstep(0, 0.12, v) * (1 - smoothstep(0.88, 1, v));
      this.flare += 0.05 * (1 - v);
    } else {
      const v = (u - landing) / (1 - landing);
      this.stretch *= 1 - 0.16 * Math.sin(Math.PI * v);
    }
  }
}
const vlen = (v) => Math.hypot(v[0], v[1]);
const vclamp = (v, max) => { const d = vlen(v); return d > max ? [v[0] / d * max, v[1] / d * max] : v; };
const vapproach = (c, t, rate, dt) => { const k = 1 - Math.exp(-rate * dt); return [c[0] + (t[0] - c[0]) * k, c[1] + (t[1] - c[1]) * k]; };

class Sim {
  constructor(expression = 'neutral', seed = 7) {
    this.pose = newPose(); this.rng = new Rng(seed); this.time = 0;
    this.expression = expression; this.velocity = [0, 0]; this.lookTarget = null; this.hover = 1; this.autoBlink = true;
    this.flash = null; this.flashUntil = 0;
    this.vel = [0, 0]; this.drag = [0, 0]; this.look = [0, 0]; this.saccade = [0, 0]; this.nextSaccade = 1;
    this.tuft = [0, 0]; this.tuftVel = [0, 0]; this.wobbleEnergy = 0; this.facingTarget = 1;
    this.nextBlink = 1.5; this.blinkStart = -10; this.doubleBlink = false;
    this.eyeOpenLeft = 1; this.eyeOpenRight = 1; this.tilt = 0; this.gestures = [];
  }
  get currentExpression() { return this.flash ?? this.expression; }
  flashExpression(e, seconds) { this.flash = e; this.flashUntil = this.time + seconds; }
  play(g, duration) { this.gestures.push({ g, start: this.time, duration: duration ?? GESTURES[g], side: this.pose.facing >= 0 ? 1 : -1 }); }
  face(dir) { this.facingTarget = Math.sign(dir) === 0 ? 1 : Math.sign(dir); }
  static blinkCurve(e) { const d = 0.16; if (e < 0 || e > d) return 0; return Math.sin(Math.PI * e / d); }
  update(dt) {
    dt = clamp(dt, 0, 1 / 20); if (dt === 0) return;
    this.time += dt;
    const p = this.pose, time = this.time;
    if (this.flash && time >= this.flashUntil) this.flash = null;
    const f = EXPRESSIONS[this.currentExpression] || EXPRESSIONS.neutral;
    const fx = new GestureFx();
    this.gestures = this.gestures.filter((g) => time - g.start < g.duration);
    for (const g of this.gestures) this.applyGesture(g, (time - g.start) / g.duration, time - g.start, fx);

    const prevVel = this.vel;
    this.vel = vapproach(this.vel, this.velocity, 10, dt);
    const accel = vlen([this.vel[0] - prevVel[0], this.vel[1] - prevVel[1]]) / dt;
    this.wobbleEnergy = Math.min(this.wobbleEnergy + accel * 0.0025 * dt * 60, 0.9);
    this.wobbleEnergy *= Math.exp(-3.5 * dt);
    const speed = vlen(this.vel);
    this.drag = vapproach(this.drag, vclamp([this.vel[0] * 0.22, this.vel[1] * 0.22], 1.2), 5, dt);

    const look = this.lookTarget;
    if (look && Math.abs(look[0]) > 0.35) this.facingTarget = Math.sign(look[0]);
    else if (Math.abs(this.vel[0]) > 0.35) this.facingTarget = Math.sign(this.vel[0]);
    p.facing = approach(p.facing, this.facingTarget, 8, dt);

    let desired;
    if (look) desired = look;
    else if (speed > 0.4) { const m = Math.min(speed / 2.5, 1); desired = [this.vel[0] / speed * m, this.vel[1] / speed * m]; }
    else {
      if (time >= this.nextSaccade) {
        const wide = this.rng.next() < 0.35;
        this.saccade = [this.rng.range(-1, 1) * (wide ? 0.75 : 0.3), this.rng.range(-1, 1) * (wide ? 0.5 : 0.2)];
        this.nextSaccade = time + this.rng.range(0.7, 2.8);
      }
      desired = this.saccade;
    }
    desired = [desired[0] + f.lookBiasX + fx.lookX, desired[1] + f.lookBiasY + fx.lookY];
    this.look = vapproach(this.look, vclamp(desired, 1), 14, dt);
    p.lookX = clamp(this.look[0], -1, 1); p.lookY = clamp(this.look[1], -1, 1);

    if (this.autoBlink && time >= this.nextBlink) {
      this.blinkStart = time;
      this.doubleBlink = this.rng.next() < 0.18;
      this.nextBlink = time + this.rng.range(2.0, 5.5) + (this.doubleBlink ? 0.4 : 0);
    }
    let blink = Sim.blinkCurve(time - this.blinkStart);
    if (this.doubleBlink) blink = Math.max(blink, Sim.blinkCurve(time - this.blinkStart - 0.24));

    const rate = 11;
    this.eyeOpenLeft = approach(this.eyeOpenLeft, f.eyeOpenLeft * fx.eyeOpenMul, rate, dt);
    this.eyeOpenRight = approach(this.eyeOpenRight, f.eyeOpenRight * fx.eyeOpenMul, rate, dt);
    p.eyeOpenLeft = this.eyeOpenLeft * (1 - blink);
    p.eyeOpenRight = this.eyeOpenRight * (1 - blink);
    p.eyeHappy = approach(p.eyeHappy, clamp(f.eyeHappy + fx.eyeHappy, 0, 1), rate, dt);
    p.eyeScale = approach(p.eyeScale, Math.max(0.5, f.eyeScale + fx.eyeScale), 14, dt);
    const shape = fx.eyeShape ?? f.eyeShape;
    if (p.eyeShape !== shape) {
      p.eyeShapeAmount -= dt * 9;
      if (p.eyeShapeAmount <= 0) { p.eyeShapeAmount = 0; p.eyeShape = shape; }
    } else if (shape !== 'none') p.eyeShapeAmount = Math.min(1, p.eyeShapeAmount + dt * 5);
    p.eyeSpin += dt * 7;
    p.mouthOpen = approach(p.mouthOpen, clamp(f.mouthOpen + fx.mouthOpen, 0, 1.2), rate, dt);
    p.mouthSmile = approach(p.mouthSmile, clamp(f.mouthSmile + fx.mouthSmile, -1, 1), rate, dt);
    p.mouthWidth = approach(p.mouthWidth, f.mouthWidth, rate, dt);
    p.mouthRound = approach(p.mouthRound, clamp(f.mouthRound + fx.mouthRound, 0, 1), rate, dt);
    p.blush = approach(p.blush, clamp(f.blush + fx.blush, 0, 1), 5, dt);
    this.tilt = approach(this.tilt, f.tilt + fx.tilt, 8, dt);

    const bob = Math.sin(time * 2.1) * 2.6 * this.hover;
    const lean = clamp(this.vel[0] * 0.07, -0.4, 0.4);
    p.rotation = lean + this.tilt + Math.sin(time * 1.05 + 0.4) * 0.025 * this.hover + fx.rot;
    p.offsetX = fx.dx; p.offsetY = bob + fx.dy;
    p.stretch = (1 + clamp(Math.abs(this.vel[1]) * 0.035 - Math.abs(this.vel[0]) * 0.012, -0.08, 0.14)) * fx.stretch;
    p.scale = fx.scale;
    p.breath = Math.sin(time * 1.6);
    p.dragX = this.drag[0]; p.dragY = this.drag[1];
    p.flare = clamp(-this.vel[1] * 0.03, -0.06, 0.12) + fx.flare;
    p.hemAmp = 1.4 + Math.min(speed * 0.5, 3.2);
    p.hemPhase += dt * (3.2 + Math.min(speed, 6) * 1.1);
    p.wobble = this.wobbleEnergy + fx.wobble;
    p.wobblePhase += dt * 16;

    const tt = [clamp(-this.vel[0] * 2.2 + Math.sin(time * 1.7) * 0.6, -7, 7), clamp(-this.vel[1] * 1.5 + Math.cos(time * 1.3) * 0.4, -7, 7)];
    const force = [(tt[0] - this.tuft[0]) * 90 - this.tuftVel[0] * 9, (tt[1] - this.tuft[1]) * 90 - this.tuftVel[1] * 9];
    this.tuftVel = [this.tuftVel[0] + force[0] * dt, this.tuftVel[1] + force[1] * dt];
    this.tuft = [this.tuft[0] + this.tuftVel[0] * dt, this.tuft[1] + this.tuftVel[1] * dt];
    p.tuftX = this.tuft[0]; p.tuftY = this.tuft[1];

    p.armLeft = fx.armLeft; p.armRight = fx.armRight;
    if (fx.armLeft > 0) p.armLeftAngle = fx.armLeftAngle;
    if (fx.armRight > 0) p.armRightAngle = fx.armRightAngle;
  }
  applyGesture(g, u, e, fx) {
    const env = envelope(u), bell = Math.sin(Math.PI * u), side = g.side;
    switch (g.g) {
      case 'bounce': fx.jump(u, 24); break;
      case 'hop': fx.jump(u, 11, 0.12, 0.85); break;
      case 'spin': fx.rot += TAU * ease('inOutCubic', u) * side; fx.stretch *= 1 + 0.06 * bell; fx.dy -= 6 * bell; fx.eyeHappy += 0.6 * env; break;
      case 'flip': {
        fx.jump(u, 32, 0.15, 0.85);
        const air = clamp((u - 0.15) / 0.7, 0, 1);
        fx.rot -= TAU * ease('inOutSine', air) * side; fx.eyeHappy += env; fx.mouthOpen += 0.4 * env; break;
      }
      case 'shake': { const w = Math.sin(u * Math.PI * 6) * bell; fx.lookX += w * 0.9; fx.rot += w * 0.07; fx.mouthSmile -= 0.3 * bell; break; }
      case 'nod': { const w = Math.sin(u * Math.PI * 4) * bell; fx.lookY += w * 0.7; fx.dy += w * 2.2; fx.rot += w * 0.03; fx.mouthSmile += 0.2 * bell; break; }
      case 'wiggle': fx.wobble += 0.9 * bell; fx.stretch *= 1 + 0.04 * Math.sin(u * Math.PI * 8); fx.eyeHappy += 0.5 * env; break;
      case 'pop': fx.scale *= 1 + 0.55 * Math.exp(-5 * u) * Math.sin(u * Math.PI * 3.2); fx.eyeScale += 0.25 * env; break;
      case 'wave': {
        const a = envelope(u, 0.12, 0.18);
        fx.arm(side, a, -1.0 + 0.5 * Math.sin(e * 13));
        fx.eyeHappy += 0.9 * a; fx.mouthOpen += 0.25 * a; fx.mouthSmile += 0.4 * a; fx.rot += 0.06 * a * side; break;
      }
      case 'cheer': {
        const a = envelope(u, 0.1, 0.2);
        fx.arm(1, a, -1.15 + 0.3 * Math.sin(e * 16)); fx.arm(-1, a, -1.15 + 0.3 * Math.sin(e * 16 + 1.4));
        fx.dy -= 12 * Math.abs(Math.sin(TAU * u)) * a; fx.stretch *= 1 + 0.05 * Math.sin(4 * Math.PI * u);
        fx.eyeHappy += a; fx.mouthOpen += 0.5 * a; fx.mouthSmile += 0.5 * a; break;
      }
      case 'shiver': fx.dx += Math.sin(e * 85) * 1.6 * env; fx.stretch *= 1 - 0.03 * env; fx.mouthSmile -= 0.5 * env; fx.mouthOpen -= 0.4 * env; fx.eyeScale -= 0.1 * env; break;
      case 'squish': {
        const at = smoothstep(0, 0.06, u);
        fx.stretch *= 1 - 0.34 * Math.exp(-5 * u) * Math.cos(u * Math.PI * 5) * at;
        fx.eyeOpenMul *= 1 - 0.75 * Math.exp(-6 * u) * at; fx.eyeHappy += 0.6 * env; fx.blush += 0.4 * env; break;
      }
      case 'dizzy': {
        const a = envelope(u, 0.1, 0.25);
        fx.rot += Math.sin(e * 9) * 0.16 * a; fx.dx += Math.cos(e * 9) * 5 * a;
        if (u < 0.85) fx.eyeShape = 'spiral';
        fx.mouthSmile -= 0.4 * a; fx.mouthOpen += 0.2 * a; break;
      }
      case 'laugh':
        fx.dy -= Math.abs(Math.sin(e * 20)) * 3.2 * env; fx.eyeHappy += env; fx.mouthOpen += 0.6 * env; fx.mouthSmile += 0.6 * env;
        fx.stretch *= 1 + 0.035 * Math.sin(e * 40) * env; fx.rot += Math.sin(e * 10) * 0.04 * env; fx.blush += 0.3 * env; break;
      case 'yawn': {
        const a = envelope(u, 0.3, 0.3);
        fx.stretch *= 1 + 0.09 * a; fx.eyeOpenMul *= 1 - 0.92 * a; fx.mouthRound += a; fx.mouthOpen += 0.9 * a;
        fx.arm(1, 0.75 * a, -1.3); fx.arm(-1, 0.75 * a, -1.3); fx.tilt += 0.08 * a * side; break;
      }
      case 'startle': {
        const jolt = Math.sin(Math.PI * clamp(u / 0.5, 0, 1));
        fx.dy -= 14 * jolt; fx.stretch *= 1 + 0.16 * Math.sin(Math.PI * clamp(u / 0.3, 0, 1));
        fx.eyeScale += 0.45 * envelope(u, 0.05, 0.4); fx.mouthRound += env; fx.mouthOpen += 0.5 * env; fx.dx += Math.sin(e * 70) * env;
        fx.armLeft = Math.max(fx.armLeft, 0.6 * jolt); fx.armRight = Math.max(fx.armRight, 0.6 * jolt);
        fx.armLeftAngle = fx.armRightAngle = -0.9; break;
      }
      case 'tada': {
        const a = envelope(u, 0.12, 0.2);
        fx.arm(1, a, -0.6); fx.arm(-1, a, -0.6); fx.scale *= 1 + 0.12 * a;
        fx.dy -= 8 * Math.sin(Math.PI * clamp(u / 0.3, 0, 1)); fx.eyeHappy += a; fx.mouthOpen += 0.6 * a; fx.mouthSmile += 0.6 * a; break;
      }
      case 'think': {
        const a = envelope(u, 0.2, 0.2);
        fx.lookX += 0.55 * a * side; fx.lookY -= 0.8 * a; fx.tilt += 0.14 * a * side;
        fx.mouthSmile -= 0.2 * a; fx.mouthOpen -= 0.45 * a; fx.arm(side, 0.55 * a, -2.2); break;
      }
    }
  }
}

// ---------- props (fabio_fx.dart) ----------
const CONFETTI = ['#4396FE', '#FEB954', '#FF6F91', '#7ED7A8', '#A8D0FB', '#F59241'];
const PROP_COLORS = { sparkle: '#FFD84D', star: '#FFC23D', heart: '#FF5C8A', note: '#4396FE', confetti: '#4396FE', bubble: '#69ABFE', zzz: '#5B89FF', exclaim: '#F59241', question: '#4396FE', check: '#34C38F', flower: '#FF8FAB', puff: '#FFFFFF', drop: '#69ABFE', mic: '#4396FE' };
const PHYS = { sparkle: [0, 2.5, 0, 0], star: [260, 1, 4, 0], heart: [-60, 1.5, 0, 10], note: [-80, 1.5, 0, 14], confetti: [380, 1.3, 8, 18], bubble: [-90, 1.2, 0, 12], zzz: [-50, 1, 0, 12], exclaim: [0, 3, 0, 0], question: [0, 3, 0, 0], check: [0, 3, 0, 0], flower: [150, 1.5, 3, 10], puff: [-20, 3, 0, 0], drop: [500, 0.5, 0, 0], mic: [0, 3, 0.5, 0] };

// ---------- custom props (fabio_custom_prop.dart) ----------
// [gravity, drag, spin, sway, life, flip, pulse]. Custom props obey these in every mode.
const PHYS_PRESETS = { float: [-140, 1.2, 0, 16, 1.6, false, false], rise: [-380, 0.8, 0, 10, 1.3, false, false], fall: [520, 0.6, 5, 0, 1.4, false, false], flutter: [160, 2.2, 6, 60, 1.8, true, false], drift: [0, 3.5, 0, 22, 1.6, false, true], still: [0, 10, 0, 0, 1.4, false, false], drop: [1100, 0.3, 0, 0, 1.2, false, false] };
function svgColor(v) {
  if (typeof v !== 'string') return null;
  const s = v.trim().toLowerCase();
  if (s === 'black') return [0, 0, 0, 1];
  if (s === 'white') return [255, 255, 255, 1];
  if (!s.startsWith('#')) return null;
  let h = s.slice(1);
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  if (h.length === 6) h += 'ff';
  if (h.length !== 8 || !/^[0-9a-f]{8}$/.test(h)) return null;
  const n = parseInt(h, 16);
  return [(n >>> 24) & 255, (n >>> 16) & 255, (n >>> 8) & 255, (n & 255) / 255];
}
const cssColor = (c, a) => `rgba(${c[0]},${c[1]},${c[2]},${clamp(c[3] * a, 0, 1)})`;
function compileProp(name, json) {
  if (!json || typeof json !== 'object') return null;
  const base = PHYS_PRESETS[json.physics] || PHYS_PRESETS.float;
  const phys = [num(json.gravity) ?? base[0], num(json.drag) ?? base[1], num(json.spin) ?? base[2], num(json.sway) ?? base[3], clamp(num(json.life) ?? base[4], 0.2, 5), typeof json.flip === 'boolean' ? json.flip : base[5], typeof json.pulse === 'boolean' ? json.pulse : base[6]];
  const color = svgColor(json.color) ? json.color : '#4396FE';
  const size = clamp(num(json.size) ?? 1, 0.2, 5);
  if (json.kind === 'glyph' || (json.kind == null && typeof json.text === 'string')) {
    if (typeof json.text !== 'string' || !json.text) return null;
    return { name, text: json.text, phys, color, size };
  }
  let vb = [0, 0, 24, 24];
  if (Array.isArray(json.viewBox) && json.viewBox.length === 4 && json.viewBox.every((v) => num(v) != null) && json.viewBox[2] > 0 && json.viewBox[3] > 0) vb = json.viewBox;
  const paths = [];
  for (const p of Array.isArray(json.paths) ? json.paths : []) {
    if (!p || typeof p.d !== 'string') continue;
    const fill = 'fill' in p ? p.fill : (p.stroke == null ? 'currentColor' : 'none');
    paths.push({ path: new Path2D(p.d), fill: fill === 'currentColor' ? 'current' : svgColor(fill), stroke: p.stroke === 'currentColor' ? 'current' : svgColor(p.stroke), strokeWidth: num(p.strokeWidth) ?? 1, opacity: clamp(num(p.opacity) ?? 1, 0, 1) });
  }
  if (!paths.length) return null;
  return { name, viewBox: vb, paths, phys, color, size };
}
function paintCustom(ctx, def, r, tint, alpha) {
  const t = svgColor(tint) || [67, 150, 254, 1];
  ctx.save();
  if (def.text != null) {
    ctx.font = '64px system-ui, "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif';
    const w = ctx.measureText(def.text).width, k = 2 * r / Math.max(w, 64);
    ctx.scale(k, k); ctx.globalAlpha *= alpha; ctx.fillStyle = cssColor(t, 1);
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(def.text, 0, 2);
    ctx.restore(); return;
  }
  const [vx, vy, vw, vh] = def.viewBox, k = 2 * r / Math.max(vw, vh);
  ctx.scale(k, k); ctx.translate(-(vx + vw / 2), -(vy + vh / 2));
  ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  for (const p of def.paths) {
    const a = alpha * p.opacity;
    const fill = p.fill === 'current' ? t : p.fill;
    if (fill) { ctx.fillStyle = cssColor(fill, a); ctx.fill(p.path); }
    const stroke = p.stroke === 'current' ? t : p.stroke;
    if (stroke && p.strokeWidth > 0) { ctx.strokeStyle = cssColor(stroke, a); ctx.lineWidth = p.strokeWidth; ctx.stroke(p.path); }
  }
  ctx.restore();
}

class Fx {
  constructor(seed = 11) { this.particles = []; this.rng = new Rng(seed); this.unit = 1; this.bounds = { w: 0, h: 0 }; this.anchor = [0, 0]; }
  emit(prop, mode, at, { count = 12, color = null, spread = 1, sizeScale = 1, life = null, custom = null } = {}) {
    const [g0, drag0, spin0, sway0, life0 = 1] = custom ? custom.phys : PHYS[prop];
    const honor = !!custom;
    const base = color ?? (custom ? custom.color : PROP_COLORS[prop]);
    if (custom) sizeScale *= custom.size;
    const u = this.unit, rng = this.rng;
    for (let i = 0; i < count; i++) {
      if (this.particles.length >= 400) this.particles.shift();
      let angle, speed, gravity = g0 * u, drag = drag0, px = at[0], py = at[1];
      let plife = life ?? rng.range(0.9, 1.6);
      let size = 15 * u * sizeScale * rng.range(0.75, 1.25);
      let front = true;
      switch (mode) {
        case 'burst': angle = rng.range(0, TAU); speed = rng.range(140, 330) * u * spread; break;
        case 'fountain': angle = -Math.PI / 2 + rng.range(-0.55, 0.55) * spread; speed = rng.range(260, 440) * u; if (!honor) gravity = Math.max(gravity, 0) + 520 * u; plife = life ?? rng.range(1.2, 1.9); break;
        case 'ring': angle = i / count * TAU; speed = 230 * u * spread; if (!honor) { drag = 3; gravity = 0; } plife = life ?? 0.9; break;
        case 'float':
          angle = -Math.PI / 2 + rng.range(-0.3, 0.3); speed = rng.range(30, 50) * u; if (!honor) { gravity = 0; drag = 0.5; } plife = life ?? 1.8; size *= 1.35;
          px += rng.range(-8, 8) * u * (count > 1 ? spread * 3 : 0); break;
        case 'rain':
          px = rng.range(0, Math.max(this.bounds.w, 1));
          if (!honor || g0 > 0) {
            py = -20 * u - rng.range(0, this.bounds.h * 0.3); angle = Math.PI / 2; speed = rng.range(120, 260) * u;
            if (!honor) { gravity = Math.abs(gravity) * 0.3 + 40 * u; drag = 0.2; } else speed *= 0.5;
            plife = life ?? (this.bounds.h / (speed + 1) + 1.2);
          } else if (g0 < 0) {
            py = this.bounds.h + 20 * u + rng.range(0, this.bounds.h * 0.3); angle = -Math.PI / 2; speed = rng.range(60, 160) * u;
            plife = life ?? (this.bounds.h / (speed + 1) + 1.2);
          } else {
            py = rng.range(0.1, 0.9) * this.bounds.h; angle = rng.range(0, TAU); speed = rng.range(10, 30) * u; plife = life ?? rng.range(1.2, 2);
          }
          break;
        case 'orbit': angle = 0; speed = 0; plife = life ?? 2; break;
        default: angle = rng.range(0, TAU); speed = rng.range(8, 36) * u; gravity *= honor ? 0.5 : 0.25; plife = life ?? rng.range(0.5, 0.9); size *= 0.7; front = false;
      }
      if (life == null) plife *= life0;
      const pc = !custom && prop === 'confetti' && color == null ? rng.pick(CONFETTI) : base;
      const p = {
        prop, custom, x: px, y: py, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, gravity, drag,
        rot: spin0 === 0 ? 0 : rng.range(-Math.PI, Math.PI), spin: spin0 * rng.range(-1, 1), size, life: plife, age: 0,
        color: pc, swayPhase: rng.range(0, TAU), swayAmp: sway0 * u, front, orbitAngle: null, orbitRadius: 0, orbitSpeed: 0,
      };
      if (mode === 'orbit') { p.orbitAngle = i / count * TAU; p.orbitRadius = 88 * u * spread; p.orbitSpeed = 3.2; }
      this.particles.push(p);
    }
  }
  update(dt) {
    for (const p of this.particles) {
      p.age += dt;
      if (p.orbitAngle != null) {
        const a = p.orbitAngle + p.orbitSpeed * p.age, r = p.orbitRadius * ease('outBack', clamp(p.age / 0.4, 0, 1));
        p.x = this.anchor[0] + Math.cos(a) * r; p.y = this.anchor[1] + Math.sin(a) * r * 0.55; continue;
      }
      const k = Math.exp(-p.drag * dt);
      p.vx *= k; p.vy = p.vy * k + p.gravity * dt;
      p.x += p.vx * dt + Math.cos(p.age * 3 + p.swayPhase) * p.swayAmp * dt;
      p.y += p.vy * dt; p.rot += p.spin * dt;
    }
    this.particles = this.particles.filter((p) => p.age < p.life);
  }
  clear() { this.particles = []; }
  paint(ctx, front) {
    for (const p of this.particles) {
      if (p.front !== front) continue;
      const t = p.age / p.life, popIn = ease('outBack', clamp(p.age / 0.18, 0, 1));
      let alpha = 1 - smoothstep(0.7, 1, t), scale = popIn;
      if (!p.custom && p.prop === 'puff') { scale = popIn * (1 + t * 0.9); alpha = 1 - t; }
      if (!p.custom && p.prop === 'sparkle') scale *= 0.75 + 0.25 * Math.sin(p.age * 18);
      if (alpha <= 0.01 || scale <= 0.01) continue;
      if (p.orbitAngle != null && Math.sin(p.orbitAngle + p.orbitSpeed * p.age) < 0) alpha *= 0.55;
      if (p.custom && p.custom.phys[6]) scale *= 1 + 0.12 * Math.sin(p.age * 5 + p.swayPhase);
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.rot);
      if (p.custom && p.custom.phys[5]) ctx.scale(Math.cos(p.age * 7 + p.swayPhase), 1);
      if (p.custom) paintCustom(ctx, p.custom, p.size / 2 * scale, p.color, alpha);
      else Fx.paintProp(ctx, p.prop, p.size / 2 * scale, p.color, alpha, p.age);
      ctx.restore();
    }
  }
  static paintProp(ctx, prop, r, color, alpha, age) {
    const fill = (c, a = 1) => { ctx.fillStyle = rgba(c, alpha * a); };
    const stroke = (c, w) => { ctx.strokeStyle = rgba(c, alpha); ctx.lineWidth = w; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; };
    const circle = (x, y, rr) => { ctx.beginPath(); ctx.arc(x, y, rr, 0, TAU); ctx.fill(); };
    const line = (x1, y1, x2, y2) => { ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); };
    switch (prop) {
      case 'sparkle': {
        const c = r * 0.14; ctx.beginPath(); ctx.moveTo(0, -r); ctx.quadraticCurveTo(c, -c, r, 0); ctx.quadraticCurveTo(c, c, 0, r);
        ctx.quadraticCurveTo(-c, c, -r, 0); ctx.quadraticCurveTo(-c, -c, 0, -r); ctx.closePath(); fill(color); ctx.fill();
        fill('#FFFFFF', 0.9); circle(0, 0, r * 0.18); break;
      }
      case 'star': { const s = starPath(r, r * 0.48); fill(color); ctx.fill(s); stroke('#E09A00', r * 0.12); ctx.stroke(s); break; }
      case 'heart': fill(color); ctx.fill(heartPath(r)); fill('#FFFFFF', 0.8); ctx.beginPath(); ctx.ellipse(-r * 0.42, -r * 0.4, r * 0.17, r * 0.11, 0, 0, TAU); ctx.fill(); break;
      case 'note':
        ctx.save(); ctx.translate(-r * 0.3, r * 0.55); ctx.rotate(-0.4); fill(color); ctx.beginPath(); ctx.ellipse(0, 0, r * 0.475, r * 0.34, 0, 0, TAU); ctx.fill(); ctx.restore();
        stroke(color, r * 0.18); line(r * 0.12, r * 0.5, r * 0.12, -r * 0.85);
        ctx.beginPath(); ctx.moveTo(r * 0.12, -r * 0.85); ctx.bezierCurveTo(r * 0.3, -r * 0.55, r * 0.8, -r * 0.5, r * 0.6, -r * 0.1); ctx.stroke(); break;
      case 'confetti': ctx.scale(Math.cos(age * 9 + r), 1); fill(color); rrect(ctx, -r * 0.6, -r * 0.3, r * 1.2, r * 0.6, r * 0.12); ctx.fill(); break;
      case 'bubble':
        fill(color, 0.16); circle(0, 0, r); stroke(color, r * 0.12); ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.stroke();
        stroke('#FFFFFF', r * 0.14); ctx.beginPath(); ctx.arc(0, 0, r * 0.62, -2.6, -1.7); ctx.stroke(); break;
      case 'zzz': stroke(color, r * 0.24); ctx.beginPath(); ctx.moveTo(-r * 0.5, -r * 0.5); ctx.lineTo(r * 0.5, -r * 0.5); ctx.lineTo(-r * 0.5, r * 0.5); ctx.lineTo(r * 0.5, r * 0.5); ctx.stroke(); break;
      case 'exclaim': stroke(color, r * 0.4); line(0, -r, 0, r * 0.3); fill(color); circle(0, r * 0.82, r * 0.22); break;
      case 'question':
        stroke(color, r * 0.3); ctx.beginPath(); ctx.moveTo(-r * 0.45, -r * 0.4); ctx.bezierCurveTo(-r * 0.45, -r * 1.05, r * 0.55, -r * 1.05, r * 0.5, -r * 0.4);
        ctx.bezierCurveTo(r * 0.45, -r * 0.05, 0, -r * 0.05, 0, r * 0.3); ctx.stroke(); fill(color); circle(0, r * 0.82, r * 0.19); break;
      case 'check':
        fill(color); circle(0, 0, r); stroke('#FFFFFF', r * 0.24);
        ctx.beginPath(); ctx.moveTo(-r * 0.45, 0); ctx.lineTo(-r * 0.1, r * 0.35); ctx.lineTo(r * 0.5, -r * 0.35); ctx.stroke(); break;
      case 'flower':
        fill(color); for (let i = 0; i < 5; i++) { const a = i / 5 * TAU; circle(Math.cos(a) * r * 0.55, Math.sin(a) * r * 0.55, r * 0.45); }
        fill('#FFD84D'); circle(0, 0, r * 0.36); break;
      case 'puff': fill(color, 0.9); circle(-r * 0.45, r * 0.12, r * 0.5); circle(r * 0.42, r * 0.16, r * 0.5); circle(0, -r * 0.22, r * 0.62); break;
      case 'drop':
        fill(color); ctx.beginPath(); ctx.moveTo(0, -r); ctx.bezierCurveTo(r * 0.9, 0, r * 0.75, r, 0, r); ctx.bezierCurveTo(-r * 0.75, r, -r * 0.9, 0, 0, -r); ctx.closePath(); ctx.fill();
        fill('#FFFFFF', 0.8); circle(-r * 0.25, r * 0.3, r * 0.16); break;
      case 'mic':
        fill(color); rrect(ctx, -r * 0.45, -r * 0.975, r * 0.9, r * 1.25, r * 0.45); ctx.fill();
        stroke('#FFFFFF', r * 0.08); for (let i = 0; i < 3; i++) { const y = -r * 0.7 + i * r * 0.28; line(-r * 0.22, y, r * 0.22, y); }
        stroke('#242424', r * 0.12); ctx.beginPath(); ctx.ellipse(0, -r * 0.1, r * 0.675, r * 0.6, 0, 0.15, Math.PI - 0.15); ctx.stroke();
        line(0, r * 0.5, 0, r * 0.85); line(-r * 0.35, r * 0.88, r * 0.35, r * 0.88); break;
    }
  }
}

// ---------- script + timeline (fabio_script.dart) ----------
const num = (v) => (typeof v === 'number' && isFinite(v) ? v : null);
const ms = (v) => (num(v) == null ? null : v / 1000);
function point(v) {
  if (Array.isArray(v) && v.length >= 2 && num(v[0]) != null && num(v[1]) != null) return [v[0], v[1]];
  if (v && typeof v === 'object' && num(v.x) != null && num(v.y) != null) return [v.x, v.y];
  return null;
}
function parseScript(json) {
  const m = { motion: [], face: [], actions: [], looks: [], fx: [], speech: [], events: [], skipped: [], customProps: {}, propIssues: [] };
  if (json.props && typeof json.props === 'object' && !Array.isArray(json.props)) {
    for (const [name, def] of Object.entries(json.props)) {
      if (PROPS.includes(name)) { m.propIssues.push(`Prop "${name}" has a built-in name and is ignored. Rename it.`); continue; }
      const c = compileProp(name, def);
      if (c) m.customProps[name] = c; else m.propIssues.push(`Prop "${name}" has nothing to draw and is ignored.`);
    }
  }
  const clips = Array.isArray(json.clips) ? json.clips : [];
  clips.forEach((c, src) => {
    if (!c || typeof c !== 'object') return;
    const t = ms(c.t) ?? 0, d = ms(c.d);
    const skip = (why) => m.skipped.push({ src, why });
    switch (c.track) {
      case 'motion': {
        const typeName = c.type === 'path' ? 'fly' : c.type;
        const type = MOTION_TYPES.includes(typeName) ? typeName : 'fly';
        if (!MOTION_TYPES.includes(typeName)) skip(`unknown motion type "${c.type}", played as fly`);
        let path = (Array.isArray(c.path) ? c.path : []).map(point).filter(Boolean);
        const to = point(c.to);
        if (!path.length && to) path = [to];
        m.motion.push({ src, t, d: Math.max(d ?? 1, 0.05), type, path, to: to ?? (path.length ? path[path.length - 1] : null), center: point(c.center), radius: num(c.radius), radiusTo: num(c.radiusTo), turns: num(c.turns) ?? 1, hops: clamp(Math.round(num(c.hops) ?? 3), 1, 20), height: num(c.height) ?? 0.08, ease: typeof c.ease === 'string' ? c.ease : null, scale: num(c.scale) });
        break;
      }
      case 'face': EXPRESSIONS[c.expression] ? m.face.push({ src, t, d, expression: c.expression }) : skip(`unknown expression "${c.expression}"`); break;
      case 'action': GESTURES[c.gesture] ? m.actions.push({ src, t, d, gesture: c.gesture }) : skip(`unknown gesture "${c.gesture}"`); break;
      case 'look': m.looks.push({ src, t, d: d ?? 1, at: point(c.at), target: typeof c.target === 'string' ? c.target : null }); break;
      case 'fx': {
        const custom = m.customProps[c.prop] || null;
        if (!PROPS.includes(c.prop) && !custom) { skip(`unknown prop "${c.prop}"`); break; }
        const mode = MODES.includes(c.mode) ? c.mode : 'burst';
        m.fx.push({ src, t, d, prop: c.prop, custom, mode, count: Math.round(num(c.count) ?? 12), at: point(c.at), spread: num(c.spread) ?? 1, rate: num(c.rate) ?? 18, size: num(c.size) ?? 1, color: typeof c.color === 'string' ? (c.color.startsWith('#') ? c.color : '#' + c.color) : null, continuous: mode === 'trail' || mode === 'rain' });
        break;
      }
      case 'speech': typeof c.text === 'string' && c.text ? m.speech.push({ src, t, d: d ?? 2, text: c.text }) : skip('speech without text'); break;
      case 'event': typeof c.name === 'string' ? m.events.push({ src, t, name: c.name }) : skip('event without name'); break;
      default: skip(`unknown track "${c.track}"`);
    }
  });
  for (const k of ['motion', 'face', 'actions', 'looks', 'fx', 'speech', 'events']) m[k].sort((a, b) => a.t - b.t);
  const s = json.start && typeof json.start === 'object' ? json.start : {};
  m.name = typeof json.name === 'string' ? json.name : 'Untitled';
  m.seed = Math.round(num(json.seed) ?? 7);
  m.loop = json.loop === true;
  m.start = { position: [num(s.x) ?? 0.5, num(s.y) ?? 0.5], scale: num(s.scale) ?? 1, expression: EXPRESSIONS[s.expression] ? s.expression : 'neutral', facing: (num(s.facing) ?? 1) < 0 ? -1 : 1 };
  let end = 0;
  for (const c of m.motion) end = Math.max(end, c.t + c.d);
  for (const c of m.face) end = Math.max(end, c.t + (c.d ?? 0));
  for (const c of m.actions) end = Math.max(end, c.t + (c.d ?? GESTURES[c.gesture]));
  for (const c of m.looks) end = Math.max(end, c.t + c.d);
  for (const c of m.fx) end = Math.max(end, c.t + (c.d ?? 0) + 0.8);
  for (const c of m.speech) end = Math.max(end, c.t + c.d);
  for (const c of m.events) end = Math.max(end, c.t);
  m.duration = ms(json.duration) ?? end + 0.4;
  return m;
}

class Spline {
  constructor(pts) {
    if (pts.length === 1) pts = [pts[0], pts[0]];
    this.lut = []; this.len = [0];
    const cr = (p0, p1, p2, p3, t) => {
      const t2 = t * t, t3 = t2 * t;
      return [0, 1].map((i) => 0.5 * (2 * p1[i] + (p2[i] - p0[i]) * t + (2 * p0[i] - 5 * p1[i] + 4 * p2[i] - p3[i]) * t2 + (3 * p1[i] - p0[i] - 3 * p2[i] + p3[i]) * t3));
    };
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[Math.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(i + 2, pts.length - 1)];
      for (let j = 0; j < 24; j++) this.lut.push(cr(p0, p1, p2, p3, j / 24));
    }
    this.lut.push(pts[pts.length - 1]);
    let total = 0;
    for (let i = 1; i < this.lut.length; i++) { total += dist(this.lut[i][0], this.lut[i][1], this.lut[i - 1][0], this.lut[i - 1][1]); this.len.push(total); }
  }
  at(u) {
    const total = this.len[this.len.length - 1];
    if (total <= 0.0001) return this.lut[0];
    const target = clamp(u, 0, 1) * total;
    let lo = 0, hi = this.len.length - 1;
    while (hi - lo > 1) { const mid = (lo + hi) >> 1; if (this.len[mid] < target) lo = mid; else hi = mid; }
    const span = this.len[hi] - this.len[lo], f = span <= 0 ? 0 : (target - this.len[lo]) / span;
    return [lerp(this.lut[lo][0], this.lut[hi][0], f), lerp(this.lut[lo][1], this.lut[hi][1], f)];
  }
}

class Timeline {
  constructor(model, size) {
    this.m = model; this.size = size; this.segments = []; this.derivedFx = [];
    this.resolve();
  }
  get minSide() { return Math.max(1, Math.min(this.size.w, this.size.h)); }
  px(n) { return [n[0] * this.size.w, n[1] * this.size.h]; }
  resolve() {
    let pos = this.px(this.m.start.position), scale = this.m.start.scale;
    const rng = new Rng(this.m.seed);
    for (const c of this.m.motion) {
      const seg = { clip: c, from: pos, fromScale: scale, toScale: c.scale ?? scale, at: () => pos, alpha: null, scaleMul: null, defaultEase: 'inOutCubic' };
      const from = pos;
      switch (c.type) {
        case 'fly': case 'dash': {
          const sp = new Spline([from, ...c.path.map((p) => this.px(p))]);
          seg.at = (u) => sp.at(u); seg.defaultEase = c.type === 'dash' ? 'outExpo' : 'inOutCubic'; break;
        }
        case 'hold': { const to = c.to ? this.px(c.to) : from; seg.at = (u) => [lerp(from[0], to[0], u), lerp(from[1], to[1], u)]; break; }
        case 'orbit': {
          const center = c.center ? this.px(c.center) : this.px([0.5, 0.5]);
          const r1 = (c.radius ?? 0.25) * this.minSide, r2 = (c.radiusTo ?? c.radius ?? 0.25) * this.minSide;
          const r0 = dist(from[0], from[1], center[0], center[1]), a0 = Math.atan2(from[1] - center[1], from[0] - center[0]);
          seg.at = (u) => { const a = a0 + c.turns * TAU * u, r = lerp(r0, lerp(r1, r2, u), smoothstep(0, 0.25, u)); return [center[0] + Math.cos(a) * r, center[1] + Math.sin(a) * r]; };
          seg.defaultEase = 'inOutSine'; break;
        }
        case 'figure8': {
          const s = (c.radius ?? 0.3) * this.minSide, center = c.center ? this.px(c.center) : from;
          seg.at = (u) => { const th = TAU * c.turns * u, p = [center[0] + Math.sin(th) * s, center[1] + Math.sin(2 * th) * s * 0.35], k = smoothstep(0, 0.15, u); return [lerp(from[0], p[0], k), lerp(from[1], p[1], k)]; };
          seg.defaultEase = 'inOutSine'; break;
        }
        case 'hop': {
          const to = c.to ? this.px(c.to) : from, h = c.height * this.minSide;
          seg.at = (u) => [lerp(from[0], to[0], u), lerp(from[1], to[1], u) - h * Math.abs(Math.sin(Math.PI * c.hops * u))];
          seg.defaultEase = 'linear'; break;
        }
        case 'wander': {
          const center = c.center ? this.px(c.center) : from, r = (c.radius ?? 0.15) * this.minSide;
          const p1 = rng.range(0, 6.28), p2 = rng.range(0, 6.28), p3 = rng.range(0, 6.28), p4 = rng.range(0, 6.28), secs = c.d;
          seg.at = (u) => {
            const s = u * secs;
            const n = [Math.sin(s * 1.3 + p1) * 0.65 + Math.sin(s * 2.9 + p2) * 0.35, Math.sin(s * 1.7 + p3) * 0.6 + Math.sin(s * 3.3 + p4) * 0.4];
            const k = smoothstep(0, 0.2, u);
            return [lerp(from[0], center[0] + n[0] * r, k), lerp(from[1], center[1] + n[1] * r, k)];
          };
          seg.defaultEase = 'linear'; break;
        }
        case 'teleport': {
          const to = c.to ? this.px(c.to) : from;
          seg.at = (u) => (u < 0.5 ? from : to);
          seg.alpha = (u) => (u < 0.4 ? 1 - smoothstep(0.1, 0.4, u) : u < 0.6 ? 0 : smoothstep(0.6, 0.85, u));
          seg.scaleMul = (u) => (u < 0.4 ? 1 - ease('inBack', clamp(u / 0.4, 0, 1)) * 0.9 : u < 0.6 ? 0.1 : 0.1 + 0.9 * ease('outBack', (u - 0.6) / 0.4));
          seg.defaultEase = 'linear';
          this.derivedFx.push({ t: c.t + c.d * 0.3, prop: 'puff', mode: 'burst', count: 7, at: [from[0] / this.size.w, from[1] / this.size.h], spread: 0.45, size: 1, color: null, continuous: false });
          this.derivedFx.push({ t: c.t + c.d * 0.62, prop: 'puff', mode: 'burst', count: 7, at: [to[0] / this.size.w, to[1] / this.size.h], spread: 0.45, size: 1, color: null, continuous: false });
          break;
        }
      }
      this.segments.push(seg);
      pos = this.sampleSeg(seg, 1).position;
      scale = seg.toScale;
    }
    this.derivedFx.sort((a, b) => a.t - b.t);
    this.endPosition = pos;
  }
  sampleSeg(seg, u) {
    u = clamp(u, 0, 1);
    const e = ease(seg.clip.ease ?? seg.defaultEase, u);
    return { position: seg.at(e), scale: lerp(seg.fromScale, seg.toScale, e) * (seg.scaleMul ? seg.scaleMul(u) : 1), alpha: seg.alpha ? seg.alpha(u) : 1 };
  }
  motionAt(t) {
    let last = null;
    for (const s of this.segments) { if (t < s.clip.t) break; last = s; }
    if (!last) return { position: this.px(this.m.start.position), scale: this.m.start.scale, alpha: 1 };
    return this.sampleSeg(last, (t - last.clip.t) / last.clip.d);
  }
  expressionAt(t) {
    let held = this.m.start.expression, current = held;
    for (const c of this.m.face) {
      if (c.t > t) break;
      if (c.d == null) { held = c.expression; current = held; } else current = t < c.t + c.d ? c.expression : held;
    }
    return current;
  }
  activeAt(list, t) { let a = null; for (const c of list) { if (c.t > t) break; if (t < c.t + c.d) a = c; } return a; }
}

// ---------- stage player (fabio_stage.dart) ----------
class StagePlayer {
  constructor(w, h, fabioSize = 110) { this.size = { w, h }; this.fabioSize = fabioSize; }
  load(model) { this.model = model; this.timeline = new Timeline(model, this.size); this.reset(); }
  reset() {
    const m = this.model;
    this.sim = new Sim(m.start.expression, m.seed); this.sim.face(m.start.facing); this.sim.pose.facing = m.start.facing;
    this.fx = new Fx(m.seed + 1);
    this.playhead = 0; this.fired = -1; this.prevPos = null; this.debt = new Map();
    this.pos = this.timeline.px(m.start.position); this.scale = m.start.scale; this.alpha = 0;
    this.playing = true; this.ended = false;
  }
  get unit() { return this.fabioSize / 110; }
  step(dt) {
    const tl = this.timeline, m = this.model;
    if (this.playing) {
      const prev = this.playhead;
      this.playhead += dt;
      this.fire(prev, this.playhead);
      this.updateFabio(dt);
      if (this.playhead >= m.duration) {
        if (m.loop) { this.playhead = 0; this.fired = -1; } else { this.playing = false; this.ended = true; }
      }
    }
    this.sim.update(dt);
    this.fx.unit = this.unit; this.fx.bounds = this.size; this.fx.anchor = this.pos;
    this.fx.update(dt);
  }
  updateFabio(dt) {
    const tl = this.timeline, s = tl.motionAt(this.playhead);
    this.pos = s.position; this.scale = s.scale; this.alpha = s.alpha;
    const px = this.fabioSize * Math.max(this.scale, 0.2);
    const prev = this.prevPos;
    if (prev && dt > 0 && this.alpha > 0.5) {
      let v = [(this.pos[0] - prev[0]) / dt / px, (this.pos[1] - prev[1]) / dt / px];
      this.sim.velocity = vclamp(v, 14);
    } else this.sim.velocity = [0, 0];
    this.prevPos = this.pos;
    this.sim.expression = tl.expressionAt(this.playhead);
    const look = tl.activeAt(this.model.looks, this.playhead);
    if (!look || (!look.at && look.target !== 'viewer')) this.sim.lookTarget = null;
    else if (!look.at) this.sim.lookTarget = [0, 0];
    else {
      const p = tl.px(look.at), d = [(p[0] - this.pos[0]) / (px * 1.2), (p[1] - this.pos[1]) / (px * 1.2)];
      this.sim.lookTarget = vclamp(d, 1);
    }
    for (const c of this.model.fx) {
      if (!c.continuous) continue;
      const end = c.t + (c.d ?? 1);
      if (this.playhead < c.t || this.playhead >= end) continue;
      let debt = (this.debt.get(c) ?? 0) + c.rate * dt;
      while (debt >= 1) {
        debt -= 1;
        if (c.mode === 'rain') this.fx.emit(c.prop, c.mode, [0, 0], { count: 1, color: c.color, sizeScale: c.size, custom: c.custom });
        else {
          const v = this.sim.velocity, l = vlen(v);
          const behind = l > 0.1 ? [v[0] / l * -px * 0.3, v[1] / l * -px * 0.3] : [0, 0];
          this.fx.emit(c.prop, c.mode, [this.pos[0] + behind[0], this.pos[1] + behind[1] + px * 0.25], { count: 1, color: c.color, sizeScale: c.size, custom: c.custom });
        }
      }
      this.debt.set(c, debt);
    }
  }
  fire(from, to) {
    const crossed = (t) => t > this.fired && t <= to;
    const m = this.model, tl = this.timeline;
    for (const c of m.actions) if (crossed(c.t)) this.sim.play(c.gesture, c.d ?? undefined);
    for (const c of [...m.fx, ...tl.derivedFx]) {
      if (c.continuous || !crossed(c.t)) continue;
      const at = c.at ? tl.px(c.at) : this.pos;
      this.fx.emit(c.prop, c.mode, at, { count: c.count, color: c.color, spread: c.spread, sizeScale: c.size, life: c.mode === 'orbit' ? (c.d ?? 2) : null, custom: c.custom || null });
    }
    for (const c of m.events) if (crossed(c.t)) this.onEvent?.(c.name);
    this.fired = to;
  }
  paint(ctx, font) {
    this.fx.paint(ctx, false);
    const visible = this.playing;
    if (visible) {
      this.sim.pose.opacity = this.alpha;
      Rig.paint(ctx, this.sim.pose, this.pos[0], this.pos[1], this.fabioSize * this.scale);
    }
    this.fx.paint(ctx, true);
    const sp = visible ? this.timeline.activeAt(this.model.speech, this.playhead) : null;
    if (sp) this.paintSpeech(ctx, sp, font);
  }
  paintSpeech(ctx, clip, font) {
    const elapsed = this.playhead - clip.t, remaining = clip.t + clip.d - this.playhead;
    const pop = ease('outBack', clamp(elapsed / 0.22, 0, 1)) * (1 - smoothstep(0, 1, 1 - clamp(remaining / 0.15, 0, 1)));
    if (pop <= 0.01) return;
    const shown = Math.min(clip.text.length, Math.floor(elapsed * 40));
    ctx.save();
    ctx.font = `500 15px ${font}`;
    const maxW = Math.min(240, this.size.w - 48), lh = 19.5;
    const words = clip.text.split(' '), lines = [];
    let cur = '';
    for (const w of words) { const t = cur ? cur + ' ' + w : w; if (ctx.measureText(t).width > maxW && cur) { lines.push(cur); cur = w; } else cur = t; }
    if (cur) lines.push(cur);
    const tw = Math.max(...lines.map((l) => ctx.measureText(l).width));
    const padH = 14, padV = 10, margin = 12, w = tw + padH * 2, h = lines.length * lh + padV * 2;
    const half = this.fabioSize * this.scale * 0.55;
    let above = true, top = this.pos[1] - half - 14 - h;
    if (top < margin + 47) { above = false; top = this.pos[1] + half + 14; }
    const left = clamp(this.pos[0] - w / 2, margin, Math.max(margin, this.size.w - w - margin));
    const tailX = clamp(this.pos[0], left + 18, left + w - 18);
    const ay = above ? top + h + 10 : top - 10;
    ctx.translate(tailX, ay); ctx.scale(pop, pop); ctx.translate(-tailX, -ay);
    ctx.beginPath();
    rrect(ctx, left, top, w, h, 16);
    ctx.shadowColor = 'rgba(1,71,160,0.22)'; ctx.shadowBlur = 12; ctx.shadowOffsetY = 3;
    ctx.fillStyle = '#FFFFFF'; ctx.fill();
    ctx.beginPath();
    if (above) { ctx.moveTo(tailX - 8, top + h - 1); ctx.lineTo(tailX + 2, top + h + 10); ctx.lineTo(tailX + 8, top + h - 1); }
    else { ctx.moveTo(tailX - 8, top + 1); ctx.lineTo(tailX + 2, top - 10); ctx.lineTo(tailX + 8, top + 1); }
    ctx.fill();
    ctx.shadowColor = 'transparent';
    ctx.fillStyle = '#242424'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    let left2 = shown;
    lines.forEach((l, i) => {
      const vis = l.slice(0, Math.max(0, left2)); left2 -= l.length + 1;
      const lw = ctx.measureText(l).width;
      ctx.textAlign = 'left';
      ctx.fillText(vis, left + padH + (tw - lw) / 2, top + padV + lh * (i + 0.5));
    });
    ctx.restore();
  }
}
