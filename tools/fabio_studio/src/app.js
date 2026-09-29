// ============================================================
// Fabio Studio app
// ============================================================
const PRESETS = /*PRESETS*/{};
const W = 390, H = 844, STEP = 1 / 60;
const $ = (id) => document.getElementById(id);
const clone = (o) => JSON.parse(JSON.stringify(o));
const TRACKS = [
  { key: 'motion', label: 'Motion', list: 'motion', color: '--t-motion' },
  { key: 'face', label: 'Face', list: 'face', color: '--t-face' },
  { key: 'action', label: 'Gesture', list: 'actions', color: '--t-action' },
  { key: 'look', label: 'Look', list: 'looks', color: '--t-look' },
  { key: 'fx', label: 'Props', list: 'fx', color: '--t-fx' },
  { key: 'speech', label: 'Speech', list: 'speech', color: '--t-speech' },
  { key: 'event', label: 'Events', list: 'events', color: '--t-event' },
];
const TRACK = Object.fromEntries(TRACKS.map((t) => [t.key, t]));
const PRESET_LABELS = { welcome: 'Welcome', goal_complete: 'Goal complete', streak: 'Streak', recording_start: 'Recording start', sleepy: 'Good night', peekaboo: 'Peekaboo', personal_best: 'Personal best' };

const state = {
  raw: null, model: null, selected: null, playing: true, loop: true, speed: 1, acc: 0, endHold: 0,
  drag: null, stageDrag: null, record: false, lastEvent: null,
};
const player = new StagePlayer(W, H, 110);
player.onEvent = (name) => { state.lastEvent = { name, at: performance.now() }; };

// ---------- helpers ----------
function toast(msg) {
  const t = $('toast'); t.textContent = msg; t.hidden = false;
  clearTimeout(toast.timer); toast.timer = setTimeout(() => (t.hidden = true), 2200);
}
function slug(s) { return (s || 'untitled').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').slice(0, 48) || 'untitled'; }
const r3 = (v) => Math.round(v * 1000) / 1000;
const r50 = (v) => Math.max(0, Math.round(v / 50) * 50);
const KEY_ORDER = ['track', 'type', 't', 'd'];
function compact(v) {
  if (Array.isArray(v)) return '[' + v.map(compact).join(', ') + ']';
  if (v && typeof v === 'object') {
    const keys = Object.keys(v).sort((a, b) => {
      const ia = KEY_ORDER.indexOf(a), ib = KEY_ORDER.indexOf(b);
      return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib);
    });
    return '{ ' + keys.map((k) => JSON.stringify(k) + ': ' + compact(v[k])).join(', ') + ' }';
  }
  return JSON.stringify(v);
}
function formatScript(raw) {
  const { clips = [], ...rest } = raw;
  const head = ['version', 'name', 'seed', 'loop', 'duration', 'start', 'props'];
  const keys = [...head.filter((k) => k in rest), ...Object.keys(rest).filter((k) => !head.includes(k))];
  const lines = keys.map((k) => k === 'props' && rest.props && typeof rest.props === 'object' && !Array.isArray(rest.props)
    ? `  "props": {\n${Object.entries(rest.props).map(([n, d]) => `    ${JSON.stringify(n)}: ${compact(d)}`).join(',\n')}\n  }`
    : `  ${JSON.stringify(k)}: ${compact(rest[k])}`);
  const sorted = [...clips].sort((a, b) => (a?.t ?? 0) - (b?.t ?? 0));
  lines.push(`  "clips": [\n${sorted.map((c) => '    ' + compact(c)).join(',\n')}\n  ]`);
  return '{\n' + lines.join(',\n') + '\n}\n';
}
function saveDraft() { try { localStorage.setItem('fabio-studio-draft', JSON.stringify(state.raw)); } catch (e) {} }
function loadDraft() { try { const s = localStorage.getItem('fabio-studio-draft'); return s ? JSON.parse(s) : null; } catch (e) { return null; } }

// ---------- script state ----------
function setScript(raw, { keepTime = false, fromEditor = false, select = null } = {}) {
  if (!Array.isArray(raw.clips)) raw.clips = [];
  raw.version = raw.version ?? 1;
  state.raw = raw;
  state.selected = select;
  commit({ keepTime, fromEditor });
}
function commit({ keepTime = true, fromEditor = false, light = false } = {}) {
  const t = keepTime ? player.playhead : 0;
  state.model = parseScript(state.raw);
  player.load(state.model);
  seek(Math.min(t, state.model.duration));
  if (!keepTime) { state.playing = !matchMedia('(prefers-reduced-motion: reduce)').matches; }
  renderTimeline();
  if (!light) renderInspector();
  if (!fromEditor) $('scriptJson').value = formatScript(state.raw);
  if (document.activeElement !== $('scriptName')) $('scriptName').value = state.raw.name || '';
  renderChecks(); renderDart(); renderPlayButton(); renderScriptProps(); puppet.renderChips();
  $('jsonStatus').textContent = `${state.raw.clips.length} clips · ${state.model.duration.toFixed(2)} s`;
  $('jsonStatus').className = 'status';
  saveDraft();
}
function seek(t) {
  player.reset();
  let guard = 0;
  while (player.playhead < t - 1e-6 && guard++ < 20000) {
    player.step(Math.min(STEP, t - player.playhead));
    if (player.ended) break;
  }
  state.acc = 0; state.endHold = 0;
}

// ---------- render loop ----------
const stage = $('stage'), sctx = stage.getContext('2d');
let stageScale = 1;
function layoutPhone() {
  const wrap = $('phoneWrap'), phone = $('phone');
  const narrow = innerWidth <= 1020;
  const availW = narrow ? Math.min(innerWidth - 32 - 20, 430) : 380;
  const availH = narrow ? 900 : innerHeight - 200;
  stageScale = Math.max(0.3, Math.min(availW / W, availH / H, 1));
  phone.style.transform = `scale(${stageScale})`;
  wrap.style.width = W * stageScale + 'px';
  wrap.style.height = H * stageScale + 'px';
  const dpr = Math.min(devicePixelRatio || 1, 2.5);
  stage.width = Math.round(W * stageScale * dpr); stage.height = Math.round(H * stageScale * dpr);
  stage._k = stageScale * dpr;
}
function drawStage() {
  sctx.setTransform(1, 0, 0, 1, 0, 0);
  sctx.clearRect(0, 0, stage.width, stage.height);
  sctx.setTransform(stage._k, 0, 0, stage._k, 0, 0);
  player.paint(sctx, '"Rubik", system-ui, sans-serif');
  drawOverlay();
}
function handlesFor() {
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  const hs = [];
  if (!sel) {
    const s = state.raw.start || {};
    hs.push({ kind: 'start', n: [s.x ?? 0.5, s.y ?? 0.5], label: 'start' });
    return hs;
  }
  if (sel.track === 'motion') {
    const type = sel.type === 'path' ? 'fly' : sel.type;
    if ((type === 'fly' || type === 'dash' || !MOTION_TYPES.includes(type)) && Array.isArray(sel.path)) sel.path.forEach((p, i) => point(p) && hs.push({ kind: 'path', i, n: point(p), label: String(i + 1) }));
    if (['hold', 'hop', 'teleport'].includes(type) && point(sel.to)) hs.push({ kind: 'to', n: point(sel.to), label: 'to' });
    if (['orbit', 'figure8', 'wander'].includes(type)) hs.push({ kind: 'center', n: point(sel.center) ?? (type === 'orbit' ? [0.5, 0.5] : null), label: 'center' });
  }
  if ((sel.track === 'look' || sel.track === 'fx') && point(sel.at)) hs.push({ kind: 'at', n: point(sel.at), label: sel.track === 'look' ? 'look' : 'at' });
  return hs.filter((h) => h.n);
}
function drawOverlay() {
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  const accent = getComputedStyle(document.documentElement).getPropertyValue('--t-motion').trim() || '#2F86F6';
  sctx.save();
  if (sel && sel.track === 'motion') {
    const seg = player.timeline.segments.find((s) => s.clip.src === state.selected);
    if (seg) {
      sctx.setLineDash([6, 6]); sctx.lineWidth = 2; sctx.strokeStyle = accent; sctx.globalAlpha = 0.85;
      sctx.beginPath();
      for (let i = 0; i <= 80; i++) { const p = player.timeline.sampleSeg(seg, i / 80).position; i ? sctx.lineTo(p[0], p[1]) : sctx.moveTo(p[0], p[1]); }
      sctx.stroke(); sctx.setLineDash([]);
      const f = seg.from; sctx.globalAlpha = 1; sctx.lineWidth = 2; sctx.strokeStyle = accent; sctx.fillStyle = 'rgba(255,255,255,.7)';
      sctx.beginPath(); sctx.arc(f[0], f[1], 5, 0, TAU); sctx.fill(); sctx.stroke();
    }
  }
  sctx.globalAlpha = 1;
  for (const h of handlesFor()) {
    const x = h.n[0] * W, y = h.n[1] * H;
    const cx = clamp(x, 10, W - 10), cy = clamp(y, 10, H - 10), off = cx !== x || cy !== y;
    sctx.fillStyle = '#FFFFFF'; sctx.strokeStyle = accent; sctx.lineWidth = 2.5;
    sctx.beginPath(); sctx.arc(cx, cy, 9, 0, TAU); sctx.fill(); if (off) sctx.setLineDash([3, 3]); sctx.stroke(); sctx.setLineDash([]);
    sctx.fillStyle = '#15233B'; sctx.font = '600 10px "Rubik", system-ui, sans-serif'; sctx.textAlign = 'center'; sctx.textBaseline = 'middle';
    sctx.fillText(h.label.length > 2 ? h.label[0].toUpperCase() : h.label, cx, cy + 0.5);
  }
  if (state.lastEvent && performance.now() - state.lastEvent.at < 1400) {
    const a = 1 - (performance.now() - state.lastEvent.at) / 1400;
    sctx.globalAlpha = a; sctx.fillStyle = '#15233B';
    const label = 'event: ' + state.lastEvent.name;
    sctx.font = '500 12px "JetBrains Mono", monospace';
    const w = sctx.measureText(label).width + 20;
    rrect(sctx, (W - w) / 2, 60, w, 26, 13); sctx.fill();
    sctx.fillStyle = '#FFFFFF'; sctx.textAlign = 'center'; sctx.textBaseline = 'middle'; sctx.fillText(label, W / 2, 73.5);
  }
  sctx.restore();
}
let last = performance.now();
function frame(now) {
  const dt = Math.min(0.1, (now - last) / 1000); last = now;
  if (state.playing && !state.drag) {
    state.acc += dt * state.speed;
    while (state.acc >= STEP) { player.step(STEP); state.acc -= STEP; }
    if (player.ended) {
      state.endHold += dt;
      if (state.loop && state.endHold > 0.9) seek(0);
      else if (!state.loop && player.fx.particles.length === 0) { state.playing = false; renderPlayButton(); }
    }
  }
  drawStage();
  updatePlayhead();
  puppet.tick(dt);
  propPreview.tick(dt);
  requestAnimationFrame(frame);
}

// ---------- transport ----------
const ICON_PLAY = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
const ICON_PAUSE = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 5h4v14H7zM13 5h4v14h-4z"/></svg>';
function renderPlayButton() { $('play').innerHTML = state.playing ? ICON_PAUSE : ICON_PLAY; $('play').setAttribute('aria-label', state.playing ? 'Pause' : 'Play'); }
function togglePlay() {
  if (!state.playing && (player.ended || player.playhead >= state.model.duration - 0.01)) seek(0);
  state.playing = !state.playing; renderPlayButton();
}
$('play').onclick = togglePlay;
$('restart').onclick = () => { seek(0); state.playing = true; renderPlayButton(); };
$('loop').onchange = (e) => (state.loop = e.target.checked);
$('speed').onchange = (e) => (state.speed = Number(e.target.value));
$('backdrop').onchange = (e) => document.querySelectorAll('.mock').forEach((m) => (m.hidden = m.dataset.backdrop !== e.target.value));
(() => { const w = $('recWave'); for (let i = 0; i < 34; i++) { const b = document.createElement('i'); b.style.height = (18 + Math.abs(Math.sin(i * 1.7) * 60 + Math.sin(i * 0.6) * 20)) + '%'; w.append(b); } })();

// ---------- timeline ----------
function clipDisplay(c, i) {
  const m = state.model;
  const t = (c.t ?? 0) / 1000;
  let d = c.d != null ? c.d / 1000 : null, kind = 'span';
  switch (c.track) {
    case 'action': d = d ?? GESTURES[c.gesture] ?? 0.8; break;
    case 'face':
      if (d == null) {
        const next = m.face.find((f) => f.t > t + 1e-6);
        d = (next ? next.t : m.duration) - t; kind = 'hold';
      }
      break;
    case 'fx': if (d == null) { kind = 'point'; d = 0; } break;
    case 'event': kind = 'point'; d = 0; break;
    default: d = d ?? 1;
  }
  const labels = {
    motion: () => c.type || 'fly', face: () => c.expression, action: () => c.gesture,
    look: () => (c.at ? 'at point' : c.target || 'forward'), fx: () => `${c.prop} ${c.mode || 'burst'}`,
    speech: () => `“${c.text}”`, event: () => c.name,
  };
  return { i, t, d, kind, label: (labels[c.track] || (() => c.track))() || '?' };
}
function layoutLanes(items) {
  const lanes = [];
  for (const it of items.sort((a, b) => a.t - b.t)) {
    const end = it.t + Math.max(it.d, it.kind === 'point' ? 0.25 : 0.35);
    let lane = lanes.findIndex((l) => l <= it.t + 1e-6);
    if (lane < 0) { lane = lanes.length; lanes.push(0); }
    lanes[lane] = end; it.lane = lane;
  }
  return Math.max(lanes.length, 1);
}
function renderTimeline() {
  const el = $('timeline'), m = state.model, D = Math.max(m.duration, 1);
  el.innerHTML = '';
  const ruler = document.createElement('div'); ruler.className = 'tl-row';
  ruler.innerHTML = '<div class="tl-label"></div>';
  const rl = document.createElement('div'); rl.className = 'ruler'; rl.id = 'ruler';
  for (let s = 0; s <= D + 1e-6; s += 0.5) {
    const tick = document.createElement('i'); tick.style.left = (s / D * 100) + '%'; tick.style.height = Number.isInteger(s) ? '8px' : '4px'; rl.append(tick);
    if (Number.isInteger(s)) { const lab = document.createElement('em'); lab.textContent = s + 's'; lab.style.left = (s / D * 100) + '%'; rl.append(lab); }
  }
  ruler.append(rl); el.append(ruler);
  for (const tr of TRACKS) {
    const row = document.createElement('div'); row.className = 'tl-row';
    const items = state.raw.clips.map((c, i) => (c && c.track === tr.key ? clipDisplay(c, i) : null)).filter(Boolean);
    const lanes = layoutLanes(items);
    row.innerHTML = `<div class="tl-label"><span><i class="sw" style="background:var(${tr.color})"></i>${tr.label}</span><button class="tl-add" data-add="${tr.key}" title="Add ${tr.label.toLowerCase()} clip at playhead" aria-label="Add ${tr.label.toLowerCase()} clip at playhead">+</button></div>`;
    const lane = document.createElement('div'); lane.className = 'tl-lane'; lane.style.height = (lanes * 28 + 6) + 'px';
    for (const it of items) {
      const c = document.createElement('div');
      c.className = 'clip' + (it.kind === 'hold' ? ' hold' : '') + (it.kind === 'point' ? ' point' : '') + (it.i === state.selected ? ' sel' : '');
      c.style.setProperty('--c', `var(${tr.color})`);
      c.style.left = (it.t / D * 100) + '%';
      c.style.top = (3 + it.lane * 28) + 'px';
      if (it.kind !== 'point') c.style.width = `max(${(it.d / D * 100)}%, 18px)`;
      c.dataset.i = it.i; c.title = `${it.label} · ${it.t.toFixed(2)}s` + (it.kind === 'point' ? '' : ` → ${(it.t + it.d).toFixed(2)}s`);
      c.tabIndex = 0;
      if (it.kind !== 'point') c.textContent = it.label;
      if (it.kind === 'span' && tr.key !== 'event') { const rz = document.createElement('span'); rz.className = 'rz'; c.append(rz); }
      lane.append(c);
    }
    row.append(lane); el.append(row);
  }
  const ph = document.createElement('div'); ph.className = 'playhead'; ph.id = 'playhead'; el.append(ph);
  const counts = TRACKS.map((t) => [t.label, state.raw.clips.filter((c) => c?.track === t.key).length]).filter(([, n]) => n);
  $('tlSummary').textContent = counts.map(([l, n]) => `${n} ${l.toLowerCase()}`).join(' · ') || 'No clips yet. Use + on a track, the Puppet, or Direct Fabio.';
  updatePlayhead();
}
function laneMetrics() {
  const r = $('ruler').getBoundingClientRect();
  return { left: r.left, width: r.width, D: Math.max(state.model.duration, 1) };
}
function updatePlayhead() {
  const ph = $('playhead'), rl = $('ruler');
  if (!ph || !rl) return;
  const D = Math.max(state.model.duration, 1);
  const labelW = rl.offsetLeft;
  ph.style.left = (labelW + clamp(player.playhead / D, 0, 1) * rl.offsetWidth) + 'px';
  $('time').innerHTML = `<b>${player.playhead.toFixed(2)}</b> / ${state.model.duration.toFixed(2)} s`;
}
$('timeline').addEventListener('pointerdown', (e) => {
  const add = e.target.closest('[data-add]');
  if (add) { addClip(add.dataset.add); return; }
  const clipEl = e.target.closest('.clip');
  if (e.target.closest('#ruler')) {
    const scrub = (ev) => { const mt = laneMetrics(); seek(clamp((ev.clientX - mt.left) / mt.width, 0, 1) * mt.D); };
    scrub(e); state.playing = false; renderPlayButton();
    const move = (ev) => scrub(ev);
    const up = () => { removeEventListener('pointermove', move); removeEventListener('pointerup', up); };
    addEventListener('pointermove', move); addEventListener('pointerup', up);
    return;
  }
  if (!clipEl) return;
  e.preventDefault();
  const i = Number(clipEl.dataset.i), c = state.raw.clips[i];
  const resize = !!e.target.closest('.rz');
  const disp = clipDisplay(c, i);
  state.drag = { i, x0: e.clientX, t0: c.t ?? 0, d0: c.d ?? Math.round(disp.d * 1000), resize, moved: false };
  if (state.selected !== i) { state.selected = i; renderInspector(); renderTimeline(); }
  const move = (ev) => {
    const dr = state.drag; if (!dr) return;
    const mt = laneMetrics(), dms = (ev.clientX - dr.x0) / mt.width * mt.D * 1000;
    if (Math.abs(ev.clientX - dr.x0) > 3) dr.moved = true;
    if (!dr.moved) return;
    if (dr.resize) state.raw.clips[dr.i].d = Math.max(50, r50(dr.d0 + dms));
    else state.raw.clips[dr.i].t = r50(dr.t0 + dms);
    commit({ keepTime: true, light: true });
  };
  const up = () => {
    removeEventListener('pointermove', move); removeEventListener('pointerup', up);
    const dr = state.drag; state.drag = null;
    if (dr && dr.moved) commit({ keepTime: true });
    else if (dr) { seek((state.raw.clips[dr.i].t ?? 0) / 1000); }
  };
  addEventListener('pointermove', move); addEventListener('pointerup', up);
});
$('timeline').addEventListener('keydown', (e) => {
  const clipEl = e.target.closest('.clip');
  if (clipEl && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); state.selected = Number(clipEl.dataset.i); renderInspector(); renderTimeline(); }
});
const DEFAULT_CLIPS = {
  motion: () => ({ track: 'motion', type: 'fly', d: 1200, path: [[0.5, 0.35], [0.5, 0.5]] }),
  face: () => ({ track: 'face', expression: 'happy', d: 1500 }),
  action: () => ({ track: 'action', gesture: 'bounce' }),
  look: () => ({ track: 'look', d: 1500, target: 'viewer' }),
  fx: () => ({ track: 'fx', prop: 'sparkle', mode: 'burst', count: 12 }),
  speech: () => ({ track: 'speech', d: 2000, text: 'Nice work today!' }),
  event: () => ({ track: 'event', name: 'my_event' }),
};
function addClip(track, extra = {}) {
  const c = Object.assign(DEFAULT_CLIPS[track](), { t: r50(player.playhead * 1000) }, extra);
  state.raw.clips.push(c);
  state.selected = state.raw.clips.length - 1;
  commit({ keepTime: true });
}

// ---------- inspector ----------
const FIELD_CHIPS = {
  motion: [['type', MOTION_TYPES], ['ease', EASES]],
  face: [['expression', Object.keys(EXPRESSIONS)]],
  action: [['gesture', Object.keys(GESTURES)]],
  look: [['target', ['viewer', 'forward']]],
  fx: [['prop', PROPS], ['mode', MODES]],
};
const MOTION_HELP = {
  fly: 'Smooth curve through the numbered points. Drag them on the stage; double-click the stage to add one, Alt-click a point to remove it.',
  dash: 'Like fly but fast out of the gate (outExpo). Good for entrances.',
  hold: 'Stays put, or glides to "to". Use it to rest between moves.',
  orbit: 'Circles "center" with "radius" (fraction of screen width). Negative "turns" goes counter-clockwise; "radiusTo" spirals.',
  figure8: 'Figure-eight around where Fabio is. "radius" sets its size, "turns" the number of loops.',
  hop: 'Bounces to "to" in "hops" arcs of "height".',
  wander: 'Drifts organically around where Fabio is, within "radius". Great for idle moments.',
  teleport: 'Vanishes in a puff and reappears at "to".',
};
function renderInspector() {
  const el = $('inspector');
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  if (!sel) {
    const s = state.raw.start || {};
    el.innerHTML = `<header><h2>Script</h2></header>
      <p class="hint" style="margin:0 0 6px">Select a clip on the timeline to edit it. With nothing selected, drag the <b>S</b> handle on the stage to move Fabio's starting point.</p>
      <div class="chips-label">Starting expression</div><div class="chips" id="startExpr"></div>
      <div class="actions"><label class="toggle"><input type="checkbox" id="scriptLoop" ${state.raw.loop ? 'checked' : ''}> Loop in the app</label>
      <label class="toggle">Seed <input type="text" id="scriptSeed" value="${state.raw.seed ?? 7}" style="width:64px" inputmode="numeric"></label>
      <label class="toggle">Start facing <select id="scriptFacing"><option value="1">right</option><option value="-1" ${(s.facing ?? 1) < 0 ? 'selected' : ''}>left</option></select></label></div>`;
    const box = $('startExpr');
    for (const e of Object.keys(EXPRESSIONS)) {
      const b = document.createElement('button'); b.className = 'chip' + ((s.expression || 'neutral') === e ? ' on' : ''); b.textContent = e;
      b.onclick = () => { state.raw.start = Object.assign({ x: 0.5, y: 0.5 }, state.raw.start, { expression: e }); commit(); };
      box.append(b);
    }
    $('scriptLoop').onchange = (e) => { state.raw.loop = e.target.checked || undefined; if (!state.raw.loop) delete state.raw.loop; commit(); };
    $('scriptSeed').onchange = (e) => { const n = parseInt(e.target.value, 10); if (!isNaN(n)) { state.raw.seed = n; commit(); } };
    $('scriptFacing').onchange = (e) => { state.raw.start = Object.assign({ x: 0.5, y: 0.5 }, state.raw.start, { facing: Number(e.target.value) }); commit(); };
    return;
  }
  const tr = TRACK[sel.track] || { label: sel.track, color: '--t-event' };
  const disp = clipDisplay(sel, state.selected);
  el.innerHTML = `<div class="insp-title" style="--c:var(${tr.color})"><span class="tag">${tr.label}</span><b></b><span class="when">${disp.t.toFixed(2)} s${disp.kind === 'point' ? '' : ' → ' + (disp.t + disp.d).toFixed(2) + ' s'}</span></div>
    <div id="fieldChips"></div>
    <p class="hint" id="clipHelp" style="margin:10px 0 0"></p>
    <textarea class="code" id="clipJson" spellcheck="false" aria-label="Selected clip JSON"></textarea>
    <div class="actions"><button class="btn" id="applyClip">Apply JSON</button><button class="btn" id="dupClip">Duplicate</button><button class="btn danger" id="delClip">Delete</button><button class="btn ghost" id="deselect">Done</button><span class="status" id="clipStatus"></span></div>`;
  el.querySelector('.insp-title b').textContent = disp.label;
  const fc = $('fieldChips');
  const groups = (FIELD_CHIPS[sel.track] || []).map(([f, v]) => (f === 'prop' ? [f, [...v, ...Object.keys(state.model.customProps)]] : [f, v]));
  for (const [field, values] of groups) {
    const lab = document.createElement('div'); lab.className = 'chips-label'; lab.textContent = field; fc.append(lab);
    const box = document.createElement('div'); box.className = 'chips';
    const current = sel[field] ?? (field === 'ease' ? null : field === 'mode' ? 'burst' : field === 'type' ? 'fly' : field === 'target' ? 'forward' : null);
    for (const v of values) {
      const b = document.createElement('button'); b.className = 'chip' + (current === v ? ' on' : ''); b.textContent = v;
      b.onclick = () => {
        const c = state.raw.clips[state.selected];
        c[field] = v;
        if (field === 'target') delete c.at;
        if (field === 'type') normalizeMotion(c);
        if (field === 'mode' && (v === 'trail' || v === 'rain' || v === 'orbit') && c.d == null) c.d = 1500;
        commit({ keepTime: true });
      };
      box.append(b);
    }
    fc.append(box);
  }
  const help = sel.track === 'motion' ? MOTION_HELP[sel.type === 'path' ? 'fly' : sel.type] || '' :
    sel.track === 'look' ? 'Set "at" to a point to look at it (drag the L handle), or target "viewer" to look out of the screen.' :
    sel.track === 'fx' ? 'Omit "at" to spawn at Fabio. trail and rain emit "rate" props per second for "d" ms; orbit props circle Fabio for "d" ms.' :
    sel.track === 'face' ? 'Without "d" the expression holds until the next face clip.' :
    sel.track === 'event' ? 'The app receives this name through onEvent, so a screen can reveal real UI in sync with Fabio.' : '';
  $('clipHelp').textContent = help;
  $('clipJson').value = JSON.stringify(sel, null, 2);
  $('applyClip').onclick = () => {
    try { const c = JSON.parse($('clipJson').value); if (!c || typeof c !== 'object' || Array.isArray(c)) throw new Error('A clip must be a JSON object.'); state.raw.clips[state.selected] = c; commit({ keepTime: true }); }
    catch (err) { $('clipStatus').textContent = err.message; $('clipStatus').className = 'status err'; }
  };
  $('dupClip').onclick = () => { const c = clone(sel); c.t = r50((sel.t ?? 0) + (disp.d * 1000 || 500)); state.raw.clips.push(c); state.selected = state.raw.clips.length - 1; commit({ keepTime: true }); };
  let armed = false;
  $('delClip').onclick = (e) => {
    if (!armed) { armed = true; e.currentTarget.textContent = 'Delete this clip?'; return; }
    deleteSelected();
  };
  $('deselect').onclick = () => { state.selected = null; renderInspector(); renderTimeline(); };
}
function deleteSelected() {
  if (state.selected == null) return;
  state.raw.clips.splice(state.selected, 1); state.selected = null; commit({ keepTime: true });
}
function normalizeMotion(c) {
  const t = c.type;
  const endPoint = point(c.to) || (Array.isArray(c.path) && point(c.path[c.path.length - 1])) || [0.5, 0.5];
  if ((t === 'fly' || t === 'dash') && !Array.isArray(c.path)) c.path = [endPoint];
  if (['hold', 'hop', 'teleport'].includes(t) && !c.to) c.to = endPoint;
  if (t === 'orbit' && !c.center) { c.center = [0.5, 0.45]; c.radius = c.radius ?? 0.2; }
  if (t === 'figure8') c.radius = c.radius ?? 0.3;
  if (t === 'wander') c.radius = c.radius ?? 0.05;
}

// ---------- stage handles ----------
function stagePoint(e) { const r = stage.getBoundingClientRect(); return [(e.clientX - r.left) / r.width * W, (e.clientY - r.top) / r.height * H]; }
stage.addEventListener('pointerdown', (e) => {
  const [x, y] = stagePoint(e);
  const hit = handlesFor().find((h) => Math.hypot(clamp(h.n[0] * W, 10, W - 10) - x, clamp(h.n[1] * H, 10, H - 10) - y) < 16);
  if (!hit) return;
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  if (e.altKey && hit.kind === 'path' && sel.path.length > 1) { sel.path.splice(hit.i, 1); commit({ keepTime: true }); return; }
  e.preventDefault(); stage.setPointerCapture(e.pointerId);
  state.stageDrag = hit;
});
stage.addEventListener('pointermove', (e) => {
  const h = state.stageDrag; if (!h) return;
  const [x, y] = stagePoint(e), n = [r3(clamp(x / W, -0.4, 1.4)), r3(clamp(y / H, -0.3, 1.3))];
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  if (h.kind === 'start') { state.raw.start = Object.assign({}, state.raw.start, { x: n[0], y: n[1] }); }
  else if (h.kind === 'path') sel.path[h.i] = n;
  else sel[h.kind] = n;
  h.n = n;
  commit({ keepTime: true, light: true });
});
const endStageDrag = () => { if (state.stageDrag) { state.stageDrag = null; commit({ keepTime: true }); } };
stage.addEventListener('pointerup', endStageDrag);
stage.addEventListener('pointercancel', endStageDrag);
stage.addEventListener('dblclick', (e) => {
  const sel = state.selected == null ? null : state.raw.clips[state.selected];
  if (!sel || sel.track !== 'motion' || !['fly', 'dash', 'path', undefined].includes(sel.type)) return;
  const [x, y] = stagePoint(e);
  sel.path = Array.isArray(sel.path) ? sel.path : [];
  sel.path.push([r3(x / W), r3(y / H)]);
  commit({ keepTime: true });
});

// ---------- checks ----------
function renderChecks() {
  const m = state.model, tl = player.timeline, out = [];
  const end = tl.endPosition, half = 60;
  const onScreen = end[0] > -half && end[0] < W + half && end[1] > -half && end[1] < H + half;
  if (onScreen) out.push(['warn', 'Ends on screen: in the app Fabio disappears when the script ends. Finish with an exit off-screen.']);
  for (const msg of m.propIssues) out.push(['warn', msg]);
  for (const s of m.skipped.slice(0, 3)) out.push(['warn', `Clip ${s.src + 1}: ${s.why}`]);
  const mo = [...m.motion].sort((a, b) => a.t - b.t);
  for (let i = 1; i < mo.length; i++) if (mo[i].t < mo[i - 1].t + mo[i - 1].d - 0.01) { out.push(['warn', `Motion clips overlap at ${mo[i].t.toFixed(2)} s; the later one takes over.`]); break; }
  if (m.speech.some((s) => s.text.length > 60)) out.push(['warn', 'Long speech bubble: keep lines under 60 characters so they read at a glance.']);
  if (m.duration > 14) out.push(['warn', `Runs ${m.duration.toFixed(1)} s. Performances over 10 s start to feel like they block the screen.`]);
  if (!out.length) out.push(['ok', 'Ready for the app']);
  $('checks').innerHTML = '';
  for (const [k, msg] of out) { const c = document.createElement('span'); c.className = 'check ' + k; c.textContent = msg; $('checks').append(c); }
}

// ---------- editor + hand off ----------
let editTimer;
$('scriptJson').addEventListener('input', () => {
  clearTimeout(editTimer);
  editTimer = setTimeout(() => {
    try {
      const raw = JSON.parse($('scriptJson').value);
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('The script must be a JSON object with a "clips" array.');
      state.raw = raw; if (!Array.isArray(raw.clips)) raw.clips = [];
      if (state.selected != null && state.selected >= raw.clips.length) state.selected = null;
      commit({ keepTime: true, fromEditor: true });
    } catch (err) {
      $('jsonStatus').textContent = 'Not applied: ' + err.message; $('jsonStatus').className = 'status err';
    }
  }, 450);
});
$('scriptName').addEventListener('input', (e) => { state.raw.name = e.target.value; $('scriptJson').value = formatScript(state.raw); renderDart(); saveDraft(); });
function renderDart() {
  const s = slug(state.raw.name);
  const events = [...new Set(state.model.events.map((e) => e.name))];
  const lines = [
    `// 1. Export this script to assets/fabio/scripts/${s}.json`,
    `// 2. Play it over the current screen:`,
    `final script = await FabioScript.load('assets/fabio/scripts/${s}.json');`,
  ];
  if (events.length) {
    lines.push(`await showFabioScript(context, script, onEvent: (name) {`);
    lines.push(`  switch (name) {`);
    for (const e of events) lines.push(`    case '${e}': // sync your UI here`);
    lines.push(`  }`, `});`);
  } else lines.push(`await showFabioScript(context, script);`);
  lines.push('', `// Or keep Fabio on a screen and drive him yourself:`, `final fabio = FabioController(expression: FabioExpression.happy);`, `Fabio(size: 120, controller: fabio);`, `fabio.play(FabioGesture.wave);`);
  $('dartSnippet').textContent = lines.join('\n');
}
function setTab(json) {
  $('tabJson').setAttribute('aria-selected', json); $('tabDart').setAttribute('aria-selected', !json);
  $('paneJson').hidden = !json; $('paneDart').hidden = json;
}
$('tabJson').onclick = () => setTab(true);
$('tabDart').onclick = () => setTab(false);
async function copyText(text, label) {
  try { await navigator.clipboard.writeText(text); toast(label + ' copied'); }
  catch (e) { setTab(true); $('scriptJson').focus(); $('scriptJson').select(); toast('Copy blocked here. The JSON is selected, press Ctrl+C or Cmd+C.'); }
}
$('copyJson').onclick = () => copyText(formatScript(state.raw), 'Script JSON');
$('copyDart').onclick = () => copyText($('dartSnippet').textContent, 'Snippet');
let downloads = null;
$('exportJson').onclick = async () => {
  const text = formatScript(state.raw), filename = slug(state.raw.name) + '.json';
  if (!downloads) return copyText(text, 'Script JSON');
  try { const r = await downloads.save({ filename, data: text }); if (r.status === 'saved') toast('Saved ' + filename); }
  catch (e) { if (e.code !== 'declined') copyText(text, 'Script JSON'); }
};

// ---------- presets ----------
function fillPresets(extra) {
  const sel = $('preset'); sel.innerHTML = '<option value="" disabled selected>Choose…</option>';
  const g = document.createElement('optgroup'); g.label = 'Built in';
  for (const k of Object.keys(PRESETS)) { const o = document.createElement('option'); o.value = 'preset:' + k; o.textContent = PRESET_LABELS[k] || k; g.append(o); }
  const blank = document.createElement('option'); blank.value = 'blank'; blank.textContent = 'Blank script'; g.append(blank);
  sel.append(g);
}
$('preset').onchange = (e) => {
  const v = e.target.value;
  if (v === 'blank') setScript({ version: 1, name: 'Untitled', seed: 7, start: { x: 0.5, y: 0.45, expression: 'neutral' }, clips: [] });
  else if (v.startsWith('preset:')) setScript(clone(PRESETS[v.slice(7)]));
  e.target.value = '';
};

// ---------- puppet ----------
const puppet = (() => {
  const cv = $('puppet'), ctx = cv.getContext('2d');
  const sim = new Sim('happy', 3), fx = new Fx(4);
  let size = { w: 300, h: 230 }, pointer = null;
  function resize() {
    const r = cv.getBoundingClientRect(), dpr = Math.min(devicePixelRatio || 1, 2.5);
    size = { w: r.width || 300, h: 230 };
    cv.width = Math.round(size.w * dpr); cv.height = Math.round(size.h * dpr); cv._k = dpr;
  }
  const center = () => [size.w / 2, size.h * 0.5];
  const fabioSize = () => Math.min(size.w * 0.55, 150);
  cv.addEventListener('pointermove', (e) => {
    const r = cv.getBoundingClientRect(), c = center(), s = fabioSize();
    sim.lookTarget = vclamp([(e.clientX - r.left - c[0]) / (s * 0.9), (e.clientY - r.top - c[1]) / (s * 0.9)], 1);
  });
  cv.addEventListener('pointerleave', () => (sim.lookTarget = null));
  const reactions = [
    () => { sim.play('squish'); sim.flashExpression('joyful', 1); burst('heart', 'fountain', 5); },
    () => { sim.play('laugh'); sim.flashExpression('joyful', 1.2); burst('note', 'float', 3); },
    () => { sim.play('spin'); sim.flashExpression('excited', 1); burst('sparkle', 'ring', 10); },
    () => { sim.play('bounce'); sim.flashExpression('happy', 1); burst('star', 'fountain', 8); },
    () => { sim.play('wave'); sim.flashExpression('happy', 1.6); },
    () => { sim.play('pop'); sim.flashExpression('love', 1.4); burst('heart', 'float', 3); },
  ];
  let ri = 0;
  cv.addEventListener('click', () => reactions[ri++ % reactions.length]());
  function burst(prop, mode, count) { fx.emit(prop, mode, center(), { count, custom: state.model?.customProps[prop] || null }); }
  function chips(boxId, items, onClick, isOn) {
    const box = $(boxId); box.innerHTML = '';
    for (const it of items) { const b = document.createElement('button'); b.className = 'chip' + (isOn?.(it) ? ' on' : ''); b.textContent = it; b.onclick = () => onClick(it, b); box.append(b); }
  }
  function renderChips() {
    chips('pExpr', Object.keys(EXPRESSIONS), (e) => { sim.expression = e; sim.flash = null; renderChips(); if (state.record) addClip('face', { expression: e, d: 1500 }); }, (e) => sim.expression === e);
    chips('pGest', Object.keys(GESTURES), (g) => { sim.play(g); if (state.record) addClip('action', { gesture: g }); });
    const customs = state.model ? state.model.customProps : {};
    chips('pProp', [...PROPS, ...Object.keys(customs)], (p) => {
      const c = customs[p];
      let mode, count;
      if (c) { const sc = showcaseFor(state.raw.props?.[p]?.physics); mode = sc.mode; count = sc.count; }
      else { mode = ['exclaim', 'question', 'mic', 'zzz', 'check'].includes(p) ? 'float' : 'burst'; count = mode === 'float' ? 1 : 12; }
      burst(p, mode, count); if (state.record) addClip('fx', { prop: p, mode, count });
    });
  }
  function tick(dt) {
    if (!cv._k) resize();
    sim.update(dt); fx.unit = fabioSize() / 110; fx.bounds = size; fx.anchor = center(); fx.update(dt);
    ctx.setTransform(cv._k, 0, 0, cv._k, 0, 0); ctx.clearRect(0, 0, size.w, size.h);
    const c = center(), s = fabioSize();
    const lift = clamp(-sim.pose.offsetY / 40, 0, 1), sw = s * 0.62 * (1 - lift * 0.35) * sim.pose.scale;
    ctx.fillStyle = `rgba(1,71,160,${0.12 * (1 - lift * 0.5)})`;
    ctx.beginPath(); ctx.ellipse(c[0], c[1] + s * 0.5, sw / 2, sw * 0.08, 0, 0, TAU); ctx.fill();
    fx.paint(ctx, false); Rig.paint(ctx, sim.pose, c[0], c[1], s); fx.paint(ctx, true);
  }
  renderChips();
  addEventListener('resize', resize);
  return { tick, resize, renderChips };
})();
$('record').onchange = (e) => (state.record = e.target.checked);

// ---------- logo ----------
(() => {
  const cv = $('logo'), ctx = cv.getContext('2d'), p = newPose();
  p.eyeHappy = 1; p.mouthOpen = 0.9; p.mouthSmile = 0.7; p.blush = 0.5; p.shine = 0.25;
  ctx.scale(2, 2); Rig.paint(ctx, p, 17, 18, 32);
})();

// ---------- keyboard ----------
addEventListener('keydown', (e) => {
  const typing = /INPUT|TEXTAREA|SELECT/.test(document.activeElement?.tagName || '');
  if (typing) return;
  if (e.code === 'Space') { e.preventDefault(); togglePlay(); }
  if ((e.key === 'Delete' || e.key === 'Backspace') && state.selected != null) { e.preventDefault(); deleteSelected(); }
  if (e.key === 'Escape' && state.selected != null) { state.selected = null; renderInspector(); renderTimeline(); }
});
addEventListener('resize', () => { layoutPhone(); updatePlayhead(); });

// ---------- Direct Fabio (sample) ----------
const EXAMPLES = [
  'Swoop in from the top left, loop around the goal ring, then cheer while confetti rains down.',
  'Nervously peek up from the bottom edge, notice the viewer, get excited and throw stars.',
  'Goodnight: yawn, drift down slowly, fall asleep with floating zzz, then fade away.',
  'Fly a figure eight leaving a trail of hearts, then blow a kiss and zoom off to the right.',
  'Nudge the user to record today: fly to the record button, point at it, say "Got a minute to share?"',
  'Celebrate a 7-day streak with a star fountain, a flip and a proud little speech.',
];
function vocabulary() {
  return [
    `EXPRESSIONS: ${Object.keys(EXPRESSIONS).join(', ')}`,
    `GESTURES (default ms): ${Object.entries(GESTURES).map(([k, v]) => `${k} ${Math.round(v * 1000)}`).join(', ')}`,
    `PROPS: ${PROPS.join(', ')}`,
    `FX MODES: burst (explodes), fountain (shoots up), ring, float (single prop drifting up, for !, ?, zzz, mic), rain (showers across the whole screen for d at rate per second: from the top, or up from the bottom for custom props that float), orbit (circles Fabio for d), trail (behind Fabio while he moves, needs d and rate)`,
    `EASES: ${EASES.join(', ')}`,
    ...(state.raw && state.raw.props && Object.keys(state.raw.props).length ? [`CUSTOM PROPS already in this script: ${Object.keys(state.raw.props).join(', ')}`] : []),
  ].join('\n');
}
function buildPrompt(request, current) {
  return `You choreograph Fabio, the friendly ghost mascot of Fabla, a research app where people keep short audio diaries. Write ONE animation script as JSON.

STAGE: a portrait phone screen, 390x844 points. Positions are normalised [x, y]: [0,0] is top-left, [1,1] bottom-right. Values outside 0..1 are off-screen; use them for entrances and exits. Fabio is about 110 points wide at scale 1 (0.28 of the width). Keep him below y=0.12 while visible (status bar). The home screen has a goal ring near [0.3,0.37] and a record button at [0.5,0.84].
TIME: "t" (start) and "d" (duration) are milliseconds.

SCRIPT SHAPE:
{"version":1,"name":"Short title","seed":<int>,"start":{"x":..,"y":..,"scale":1,"expression":EXPR,"facing":1 or -1},"clips":[...]}

CLIP TRACKS:
- motion: {"track":"motion","type":TYPE,"t","d",...}. Motion clips run one after another and must not overlap; each begins where the previous ended. Optional on every type: "ease", "scale" (target scale, eased).
  fly: "path":[[x,y],...] smooth curve through the points. dash: like fly, fast start. hold: stay, or glide to "to". orbit: "center","radius"(fraction of width),"turns"(negative = counter-clockwise),"radiusTo"(optional spiral). figure8: "radius","turns" around the current position. hop: "to","hops","height". wander: organic drift within "radius" (0.03-0.08) around the current position, for alive idle moments. teleport: "to", vanishes in a puff and reappears.
- face: {"track":"face","expression":EXPR,"t","d"?}; without d it holds until the next face clip.
- action: {"track":"action","gesture":GESTURE,"t","d"?}; one-shot body performance, may overlap motion.
- look: {"track":"look","t","d","at":[x,y]} or {"track":"look","t","d","target":"viewer"}.
- fx: {"track":"fx","prop":PROP,"mode":MODE,"t","count"?,"at"?:[x,y] (omit to spawn at Fabio),"d"?,"rate"?,"spread"?,"size"?,"color"?:"#RRGGBB"}.
- speech: {"track":"speech","text":"under 40 characters","t","d"}.
- event: {"track":"event","name":"snake_case","t"}; lets the app sync its real UI (for example show a badge).

CUSTOM PROPS: when no built-in prop fits, define new ones in a top-level "props" map and use their names in fx clips. Names are snake_case and must not reuse a built-in name. Two kinds:
  {"kind":"glyph","text":"one emoji","physics":PHYSICS}
  {"kind":"vector","viewBox":[0,0,24,24],"paths":[{"d":"SVG path data","fill":"currentColor" or "#RRGGBB" or "none","stroke"?:"#RRGGBB","strokeWidth"?:1.5,"opacity"?:0.6}],"physics":PHYSICS,"color":"#RRGGBB"}
  PHYSICS: float (drifts up), rise (up fast), fall (falls, spins), flutter (like confetti), drift (hangs), still (stays), drop (drops fast). Keep existing props of the current script.

${vocabulary()}

CRAFT:
- 4 to 10 seconds. Enter from off-screen and end with an exit off-screen, because the app removes Fabio when the script ends.
- Make him feel alive: pair every move with an expression change, a gesture or a prop. Add a trail during big flights. Use wander or hold between beats instead of freezing.
- Stagger beats about 150-400 ms apart so they read one at a time. Gestures land best right after a motion arrives.
- Speech is warm, brief and supportive, with no emoji. Only use exact names from the lists above.

${current ? `CURRENT SCRIPT (modify it as requested, keep what was not mentioned):\n${JSON.stringify(current)}\n\n` : `EXAMPLE of the format and quality bar:\n${JSON.stringify(PRESETS.welcome)}\n\n`}REQUEST: ${request}

Reply with only the JSON object.`;
}
let sample = null, genCtl = null, genBlocked = false;
function setGenStatus(text, cls = '') { const s = $('genStatus'); s.className = 'status ' + cls; s.textContent = text; }
$('generate').onclick = async () => {
  const request = $('prompt').value.trim();
  if (!request) { setGenStatus('Describe what Fabio should do first.', 'err'); $('prompt').focus(); return; }
  if (!sample) return;
  const edit = document.querySelector('input[name="gmode"]:checked').value === 'edit';
  genCtl = new AbortController();
  $('generate').disabled = true; $('stopGen').hidden = false;
  setGenStatus('Thinking'); $('genStatus').classList.add('dots');
  try {
    const result = await sample.json(buildPrompt(request, edit ? state.raw : null), {
      signal: genCtl.signal, cache: false,
      onText: ({ text }) => { const n = (text.match(/"track"/g) || []).length; $('genStatus').classList.remove('dots'); setGenStatus(`Writing the script · ${n} clip${n === 1 ? '' : 's'} so far`); },
    });
    if (!result || typeof result !== 'object' || !Array.isArray(result.clips)) throw { code: 'invalid_json', message: 'no clips' };
    result.version = 1;
    if (!result.name) result.name = request.slice(0, 40);
    setScript(result);
    const m = state.model;
    setGenStatus(`Done · ${result.clips.length} clips · ${m.duration.toFixed(1)} s` + (m.skipped.length ? ` · ${m.skipped.length} skipped, see the checks under the stage` : ''), 'good');
  } catch (e) {
    const code = e && e.code;
    const copy = {
      cancelled: 'Stopped.',
      not_granted: 'Generating needs your permission to use Claude. Reload the page to be asked again.',
      sampling_disabled: 'Claude is not available for this account.',
      rate_limited: 'Too many requests right now. Wait a minute, then try again.',
      invalid_json: 'The reply was not a valid script. Try again, or make the request more specific.',
      refused: 'Claude declined this request. Try rewording it.',
      session_expired: 'Your session expired. Sign in again, then retry.',
    }[code] || 'Something went wrong while generating. Try again.';
    setGenStatus(copy, code === 'cancelled' ? '' : 'err');
    if (['not_granted', 'sampling_disabled', 'not_declared', 'capability_disabled', 'capability_removed'].includes(code)) genBlocked = true;
  } finally {
    $('genStatus').classList.remove('dots');
    $('generate').disabled = !sample || genBlocked;
    $('stopGen').hidden = true; genCtl = null;
  }
};
$('stopGen').onclick = () => genCtl?.abort();
(() => {
  const box = $('examples');
  for (const ex of EXAMPLES) { const b = document.createElement('button'); b.className = 'example'; b.textContent = ex; b.onclick = () => { $('prompt').value = ex; $('prompt').focus(); }; box.append(b); }
})();

// ---------- team library (db) ----------
let libCol = null, libDocs = [];
function relTime(ts) {
  const s = Math.round((Date.now() - ts) / 1000);
  if (s < 60) return 'just now'; if (s < 3600) return Math.round(s / 60) + ' min ago'; if (s < 86400) return Math.round(s / 3600) + ' h ago';
  return new Date(ts).toLocaleDateString();
}
function renderLibrary() {
  const el = $('library'); el.innerHTML = '';
  if (!libDocs.length) { el.innerHTML = '<p class="hint" style="margin:0">No saved scripts yet. Use <b>Save to library</b> in the top bar to share one with your team.</p>'; return; }
  for (const d of libDocs) {
    const row = document.createElement('div'); row.className = 'lib-item';
    const info = document.createElement('div');
    const b = document.createElement('b'); b.textContent = d.name || d.id;
    const sm = document.createElement('small'); sm.textContent = `${d.clipCount ?? '?'} clips · ${(d.duration ?? 0).toFixed(1)} s · ${d.updatedAt ? relTime(d.updatedAt) : ''}`;
    info.append(b, sm);
    const act = document.createElement('div'); act.className = 'actions';
    const load = document.createElement('button'); load.className = 'btn'; load.textContent = 'Open';
    load.onclick = () => { try { setScript(JSON.parse(d.json)); toast('Opened ' + (d.name || d.id)); } catch (e) { toast('This saved script is damaged and cannot be opened.'); } };
    const del = document.createElement('button'); del.className = 'btn ghost danger'; del.textContent = 'Delete';
    let armed = false;
    del.onclick = async () => {
      if (!armed) { armed = true; del.textContent = 'Confirm delete'; return; }
      try { await libCol.doc(d.id).delete(); toast('Deleted'); } catch (e) { toast('Could not delete. You may not have edit access.'); }
    };
    act.append(load, del); row.append(info, act); el.append(row);
  }
}
$('saveLib').onclick = async () => {
  if (!libCol) return;
  const name = state.raw.name || 'Untitled', id = slug(name);
  try {
    await libCol.doc(id).set({ name, json: JSON.stringify(state.raw), clipCount: state.raw.clips.length, duration: state.model.duration, updatedAt: Date.now() });
    toast(libDocs.some((d) => d.id === id) ? 'Updated in library' : 'Saved to library');
  } catch (e) {
    toast(e.code === 'quota_exceeded' ? 'The library is full. Delete a few scripts first.' : 'Could not save. You may only have view access.');
  }
};

// ---------- prop maker ----------
const EMOJI_PICKS = ['🎈', '🚀', '🌈', '☀️', '🔥', '🎧', '📓', '🍀', '🌙', '💬', '🎁', '👏', '🌸', '💙'];
const VECTOR_STARTERS = {
  balloon: '<svg viewBox="0 0 24 31"><path d="M12 2C6.5 2 3 6.4 3 11.2c0 5.6 4.6 10.3 8 11.3l-1 2h4l-1-2c3.4-1 8-5.7 8-11.3C21 6.4 17.5 2 12 2z" fill="currentColor"/><path d="M8 7.5c.8-1.6 2.2-2.6 3.6-2.9" fill="none" stroke="#FFFFFF" stroke-width="1.6" opacity="0.7"/><path d="M12 24.5c-1.5 2 1.5 3.2 0 5.5" fill="none" stroke="#5C6B84" stroke-width="1"/></svg>',
  trophy: '<svg viewBox="0 0 24 24"><path d="M7 5H4.5a2.5 2.5 0 0 0 2.5 4.5M17 5h2.5A2.5 2.5 0 0 1 17 9.5" fill="none" stroke="#E09A00" stroke-width="1.6"/><path d="M7 3h10v5a5 5 0 0 1-10 0z" fill="#FFC23D"/><path d="M10.5 13h3v4h-3zM8 17.5h8a1 1 0 0 1 1 1V21H7v-2.5a1 1 0 0 1 1-1z" fill="#E09A00"/><path d="M9.5 5v3" fill="none" stroke="#FFFFFF" stroke-width="1.4" opacity="0.7"/></svg>',
  bolt: '<svg viewBox="0 0 24 24"><path d="M13.5 2 5 13.5h6L9.5 22 19 10h-6.2L13.5 2z" fill="#FFC23D" stroke="#E09A00" stroke-width="1.2"/></svg>',
  moon: '<svg viewBox="0 0 24 24"><path d="M15.5 3.2a9 9 0 1 0 5.3 12.6A7.2 7.2 0 0 1 15.5 3.2z" fill="#FFD84D"/></svg>',
  leaf: '<svg viewBox="0 0 24 24"><path d="M20 4C11 4 4 9 4 17c0 1.2.2 2.2.5 3 1.6-5 5.3-8.6 10-10.5-4 2.6-7 6.2-8.2 10.5 9.2 1.2 13.7-6 13.7-16z" fill="#7ED7A8"/></svg>',
  cloud: '<svg viewBox="0 0 24 24"><path d="M7 18h10.5a4.5 4.5 0 0 0 .6-8.96A6 6 0 0 0 6.6 10.1 4 4 0 0 0 7 18z" fill="#FFFFFF" stroke="#8EC0FE" stroke-width="1.2"/></svg>',
  gift: '<svg viewBox="0 0 24 24"><rect x="4" y="10" width="16" height="11" rx="1.5" fill="currentColor"/><rect x="3" y="7" width="18" height="4" rx="1.2" fill="currentColor"/><path d="M12 7v14" fill="none" stroke="#FFFFFF" stroke-width="2"/><path d="M12 7c-2-3.5-6-3.5-5.2-1 .5 1.4 3 1 5.2 1zm0 0c2-3.5 6-3.5 5.2-1-.5 1.4-3 1-5.2 1z" fill="#FFC23D"/></svg>',
};
const STARTER_PHYSICS = { balloon: 'rise', trophy: 'still', bolt: 'fall', moon: 'drift', leaf: 'flutter', cloud: 'float', gift: 'fall' };
const PHYS_LABELS = { float: 'Floats up', rise: 'Rises fast', fall: 'Falls and spins', flutter: 'Flutters', drift: 'Hangs in the air', still: 'Stays put', drop: 'Drops fast' };
const pm = { kind: 'glyph', physics: 'rise', color: '#4396FE', size: 1, def: null, compiled: null };
const NAME_RE = /^[a-z][a-z0-9_]{0,31}$/;
// The spawn pattern that shows each motion off best, used by the preview,
// "Add and drop at playhead" and the Puppet.
const SHOWCASE = {
  float: { mode: 'float', count: 4, at: [0.5, 0.78] },
  rise: { mode: 'float', count: 5, at: [0.5, 0.88] },
  fall: { mode: 'fountain', count: 7, at: [0.5, 0.7] },
  flutter: { mode: 'fountain', count: 9, at: [0.5, 0.75] },
  drop: { mode: 'fountain', count: 5, at: [0.5, 0.85] },
  drift: { mode: 'burst', count: 7, spread: 0.35, at: [0.5, 0.5] },
  still: { mode: 'float', count: 1, at: [0.5, 0.5] },
};
const showcaseFor = (physics) => SHOWCASE[physics] || SHOWCASE.float;

let svgHost = null;
function pathBBox(d) {
  if (!svgHost) {
    svgHost = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svgHost.setAttribute('aria-hidden', 'true');
    svgHost.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden;left:-9999px';
    document.body.append(svgHost);
  }
  const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  p.setAttribute('d', d); svgHost.append(p);
  try { return p.getBBox(); } catch (e) { return null; } finally { p.remove(); }
}
const colorProbe = document.createElement('canvas').getContext('2d');
function normColor(v, warnings) {
  if (v == null) return null;
  v = String(v).trim();
  if (v === 'none' || v === 'transparent') return 'none';
  if (v === 'currentColor') return 'currentColor';
  if (/^url\(/.test(v)) { warnings.add('Gradients and patterns became the prop color. Flat fills work best.'); return 'currentColor'; }
  colorProbe.fillStyle = '#010203'; colorProbe.fillStyle = v;
  const out = colorProbe.fillStyle;
  if (out === '#010203' && v.toLowerCase() !== '#010203') { warnings.add(`Unknown color "${v}" became the prop color.`); return 'currentColor'; }
  if (out.startsWith('#')) return out;
  const m = out.match(/rgba?\(([^)]+)\)/);
  if (!m) return 'currentColor';
  const [r, g, b, a = 1] = m[1].split(',').map((x) => parseFloat(x));
  return '#' + [r, g, b].map((x) => Math.round(x).toString(16).padStart(2, '0')).join('') + (a < 1 ? Math.round(a * 255).toString(16).padStart(2, '0') : '');
}
function styled(el, prop, stop) {
  for (let n = el; n && n !== stop.parentNode && n.getAttribute; n = n.parentNode) {
    const st = n.getAttribute('style') || '';
    const m = st.match(new RegExp('(?:^|;)\\s*' + prop + '\\s*:\\s*([^;]+)'));
    if (m) return m[1].trim();
    const a = n.getAttribute(prop);
    if (a != null) return a;
  }
  return null;
}
function shapeToD(el) {
  const f = (k) => parseFloat(el.getAttribute(k)) || 0;
  switch (el.tagName.toLowerCase()) {
    case 'path': return el.getAttribute('d');
    case 'circle': { const cx = f('cx'), cy = f('cy'), r = f('r'); return r > 0 ? `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0Z` : null; }
    case 'ellipse': { const cx = f('cx'), cy = f('cy'), rx = f('rx'), ry = f('ry'); return rx > 0 && ry > 0 ? `M${cx - rx} ${cy}a${rx} ${ry} 0 1 0 ${2 * rx} 0a${rx} ${ry} 0 1 0 ${-2 * rx} 0Z` : null; }
    case 'rect': {
      const x = f('x'), y = f('y'), w = f('width'), h = f('height');
      if (w <= 0 || h <= 0) return null;
      let rx = f('rx'), ry = f('ry'); rx = rx || ry; ry = ry || rx;
      rx = Math.min(rx, w / 2); ry = Math.min(ry, h / 2);
      if (!rx) return `M${x} ${y}h${w}v${h}h${-w}Z`;
      return `M${x + rx} ${y}h${w - 2 * rx}a${rx} ${ry} 0 0 1 ${rx} ${ry}v${h - 2 * ry}a${rx} ${ry} 0 0 1 ${-rx} ${ry}h${-(w - 2 * rx)}a${rx} ${ry} 0 0 1 ${-rx} ${-ry}v${-(h - 2 * ry)}a${rx} ${ry} 0 0 1 ${rx} ${-ry}Z`;
    }
    case 'polygon': case 'polyline': {
      const n = (el.getAttribute('points') || '').trim().split(/[\s,]+/).map(Number).filter((v) => !isNaN(v));
      if (n.length < 4) return null;
      let d = `M${n[0]} ${n[1]}`; for (let i = 2; i + 1 < n.length; i += 2) d += `L${n[i]} ${n[i + 1]}`;
      return el.tagName.toLowerCase() === 'polygon' ? d + 'Z' : d;
    }
    case 'line': return `M${f('x1')} ${f('y1')}L${f('x2')} ${f('y2')}`;
  }
  return null;
}
function svgToVector(src) {
  src = src.trim();
  if (!src) throw new Error('Paste SVG markup or path data first, or pick a starter.');
  if (!src.startsWith('<')) {
    const bb = pathBBox(src);
    if (!bb || (!bb.width && !bb.height)) throw new Error('That path data draws nothing. Check it starts with M.');
    const pad = Math.max(bb.width, bb.height) * 0.04;
    return { viewBox: [bb.x - pad, bb.y - pad, bb.width + 2 * pad, bb.height + 2 * pad].map(r3), paths: [{ d: src, fill: 'currentColor' }], warnings: [] };
  }
  const doc = new DOMParser().parseFromString(src, 'image/svg+xml');
  const svg = doc.documentElement;
  if (doc.querySelector('parsererror') || !svg || svg.tagName.toLowerCase() !== 'svg') throw new Error('That SVG markup could not be read. Check that it is complete, from <svg> to </svg>.');
  const warnings = new Set(), paths = [];
  let sawTransform = false;
  for (const el of svg.querySelectorAll('path,circle,ellipse,rect,polygon,polyline,line')) {
    if (el.closest('defs,clipPath,mask,symbol,pattern')) continue;
    const d = shapeToD(el); if (!d) continue;
    for (let n = el; n && n !== svg; n = n.parentNode) if (n.getAttribute && n.getAttribute('transform')) sawTransform = true;
    const p = { d };
    const fill = normColor(styled(el, 'fill', svg) ?? '#000000', warnings);
    const stroke = normColor(styled(el, 'stroke', svg), warnings);
    p.fill = fill;
    if (stroke && stroke !== 'none') { p.stroke = stroke; p.strokeWidth = r3(parseFloat(styled(el, 'stroke-width', svg)) || 1); }
    const op = (parseFloat(styled(el, 'opacity', svg) ?? '1') || 1) * (parseFloat(styled(el, 'fill-opacity', svg) ?? '1') || 1);
    if (op < 1) p.opacity = r3(op);
    if (p.fill === 'none' && !p.stroke) continue;
    paths.push(p);
  }
  if (sawTransform) warnings.add('Transforms are ignored. Flatten or outline them in your editor before exporting.');
  if (!paths.length) throw new Error('No drawable shapes found. Outline text and strokes in your editor, then export again.');
  let vb = (svg.getAttribute('viewBox') || '').trim().split(/[\s,]+/).map(Number);
  if (vb.length !== 4 || vb.some(isNaN) || vb[2] <= 0 || vb[3] <= 0) {
    const w = parseFloat(svg.getAttribute('width')), h = parseFloat(svg.getAttribute('height'));
    if (w > 0 && h > 0) vb = [0, 0, w, h];
    else {
      let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
      for (const p of paths) { const b = pathBBox(p.d); if (b) { x0 = Math.min(x0, b.x); y0 = Math.min(y0, b.y); x1 = Math.max(x1, b.x + b.width); y1 = Math.max(y1, b.y + b.height); } }
      vb = isFinite(x0) ? [x0, y0, x1 - x0, y1 - y0].map(r3) : [0, 0, 24, 24];
    }
  }
  if (paths.length > 40) warnings.add(`${paths.length} shapes is a lot for a particle. Simpler icons animate more smoothly.`);
  return { viewBox: vb, paths, warnings: [...warnings] };
}
function vectorToMarkup(def) {
  const esc = (v) => String(v).replace(/&/g, '&amp;').replace(/"/g, '&quot;');
  const lines = (def.paths || []).map((p) => {
    let a = `  <path d="${esc(p.d)}"`;
    if (p.fill != null) a += ` fill="${esc(p.fill)}"`;
    if (p.stroke) a += ` stroke="${esc(p.stroke)}" stroke-width="${p.strokeWidth ?? 1}"`;
    if (p.opacity != null && p.opacity < 1) a += ` opacity="${p.opacity}"`;
    return a + '/>';
  });
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${(def.viewBox || [0, 0, 24, 24]).join(' ')}">\n${lines.join('\n')}\n</svg>`;
}
function setPropStatus(text, cls = '') { const s = $('propStatus'); s.textContent = text; s.className = 'status ' + cls; }
function currentKind() { return document.querySelector('input[name="pkind"]:checked').value; }
function refreshDraft() {
  const kind = currentKind();
  $('glyphFields').hidden = kind !== 'glyph'; $('vectorFields').hidden = kind !== 'vector';
  pm.def = null; pm.compiled = null;
  try {
    let def;
    if (kind === 'glyph') {
      const text = $('propText').value.trim();
      if (!text) throw new Error('Type an emoji or a short piece of text.');
      def = { kind: 'glyph', text };
    } else {
      const v = svgToVector($('propSvg').value);
      def = { kind: 'vector', viewBox: v.viewBox, paths: v.paths };
      if (v.warnings.length) setPropStatus(v.warnings.join(' '), 'err'); else setPropStatus(`${v.paths.length} shape${v.paths.length === 1 ? '' : 's'} · viewBox ${v.viewBox.join(' ')}`);
    }
    def.physics = pm.physics;
    def.color = $('propColor').value.toUpperCase();
    const size = Number($('propSize').value);
    if (size !== 1) def.size = size;
    pm.def = def; pm.compiled = compileProp('draft', def);
    if (kind === 'glyph') setPropStatus('');
  } catch (e) { setPropStatus(e.message, 'err'); }
  $('propSizeVal').textContent = Number($('propSize').value).toFixed(1) + '×';
  const name = $('propName').value.trim();
  const inScript = !!(state.raw?.props && state.raw.props[name]);
  $('delProp').hidden = !inScript;
  $('addProp').textContent = inScript ? 'Update in script' : 'Add to script';
}
function validPropName() {
  const name = $('propName').value.trim();
  if (!NAME_RE.test(name)) { setPropStatus('Name it in lowercase snake_case, starting with a letter, e.g. paper_plane.', 'err'); $('propName').focus(); return null; }
  if (PROPS.includes(name)) { setPropStatus(`"${name}" is a built-in prop. Pick another name.`, 'err'); $('propName').focus(); return null; }
  return name;
}
function putPropInScript() {
  const name = validPropName(); if (!name) return null;
  if (!pm.def) { refreshDraft(); if (!pm.def) return null; }
  const existed = !!state.raw.props?.[name];
  state.raw.props = Object.assign({}, state.raw.props, { [name]: clone(pm.def) });
  commit({ keepTime: true });
  refreshDraft();
  setPropStatus(`${existed ? 'Updated' : 'Added'} "${name}". Use it from the Props track, the inspector or the Puppet.`, 'good');
  return name;
}
function loadPropIntoEditor(name, def) {
  $('propName').value = name;
  const kind = def.kind === 'glyph' || (def.kind == null && typeof def.text === 'string') ? 'glyph' : 'vector';
  document.querySelector(`input[name="pkind"][value="${kind}"]`).checked = true;
  if (kind === 'glyph') $('propText').value = def.text || ''; else $('propSvg').value = vectorToMarkup(def);
  pm.physics = PHYS_PRESETS[def.physics] ? def.physics : 'float';
  $('propColor').value = (svgColor(def.color) ? def.color : '#4396FE').slice(0, 7).toLowerCase();
  $('propSize').value = def.size ?? 1;
  renderPhysChips(); refreshDraft();
}
function renderPhysChips() {
  const box = $('physChips'); box.innerHTML = '';
  for (const [k, label] of Object.entries(PHYS_LABELS)) {
    const b = document.createElement('button'); b.className = 'chip' + (pm.physics === k ? ' on' : ''); b.textContent = label; b.title = k;
    b.onclick = () => { pm.physics = k; renderPhysChips(); refreshDraft(); propPreview.burst(); };
    box.append(b);
  }
}
function propChip(name, def, onClick) {
  const b = document.createElement('button'); b.className = 'chip prop-chip';
  const cv = document.createElement('canvas'); cv.width = 44; cv.height = 44;
  const c = compileProp(name, def);
  if (c) { const x = cv.getContext('2d'); x.translate(22, 22); paintCustom(x, c, 18, c.color, 1); }
  const t = document.createElement('span'); t.textContent = name;
  b.append(cv, t); b.onclick = onClick; return b;
}
function renderScriptProps() {
  const box = $('scriptProps'); if (!box) return; box.innerHTML = '';
  const props = state.raw.props || {};
  const names = Object.keys(props);
  if (!names.length) { box.innerHTML = '<span class="hint">None yet. Make one on the left.</span>'; return; }
  for (const n of names) box.append(propChip(n, props[n], () => loadPropIntoEditor(n, props[n])));
}
let teamProps = [], propCol = null;
function renderTeamProps() {
  const box = $('teamProps'); box.innerHTML = '';
  $('teamPropsLabel').hidden = !propCol;
  if (!propCol) return;
  if (!teamProps.length) { box.innerHTML = '<span class="hint">Nothing shared yet. Save a prop to reuse it in any script.</span>'; return; }
  for (const d of teamProps) {
    let def; try { def = JSON.parse(d.def); } catch (e) { continue; }
    box.append(propChip(d.id, def, () => { loadPropIntoEditor(d.id, def); setPropStatus(`Loaded team prop "${d.id}". Add it to this script to use it.`); }));
  }
}
const propPreview = (() => {
  const cv = $('propCanvas'), ctx = cv.getContext('2d'), fx = new Fx(21);
  let size = { w: 300, h: 220 }, k = 1, timer = 0, t = 0;
  function resize() { const r = cv.getBoundingClientRect(); k = Math.min(devicePixelRatio || 1, 2.5); size = { w: r.width || 300, h: 220 }; cv.width = Math.round(size.w * k); cv.height = Math.round(size.h * k); }
  function burst() {
    if (!pm.compiled) return;
    const sc = showcaseFor(pm.physics);
    fx.emit('draft', sc.mode, [size.w * sc.at[0], size.h * sc.at[1]], { count: sc.count, spread: sc.spread ?? 1, custom: pm.compiled });
  }
  cv.addEventListener('click', burst);
  function tick(dt) {
    if (!cv.width || !cv.getBoundingClientRect().width) { if (cv.getBoundingClientRect().width) resize(); else return; }
    t += dt; timer += dt;
    if (timer > 2.2 || (fx.particles.length === 0 && timer > 0.4)) { timer = 0; burst(); }
    fx.unit = 0.75; fx.bounds = size; fx.update(dt);
    ctx.setTransform(k, 0, 0, k, 0, 0); ctx.clearRect(0, 0, size.w, size.h);
    fx.paint(ctx, false); fx.paint(ctx, true);
    if (pm.compiled) {
      // Actual in-app size swatch, so the preview never suggests a bigger prop.
      ctx.fillStyle = 'rgba(255,255,255,.75)'; rrect(ctx, 10, 10, 64, 64, 12); ctx.fill();
      ctx.save(); ctx.translate(42, 42); paintCustom(ctx, pm.compiled, 7.5 * (pm.compiled.size || 1) * 1.35, pm.compiled.color, 1); ctx.restore();
      ctx.fillStyle = '#5C6B84'; ctx.font = '500 11px "Rubik", system-ui, sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';
      ctx.fillText(`${PHYS_LABELS[pm.physics]} · shown with ${showcaseFor(pm.physics).mode}`, 84, 24);
    }
  }
  addEventListener('resize', resize);
  return { tick, burst, resize };
})();
(() => {
  for (const e of EMOJI_PICKS) { const b = document.createElement('button'); b.className = 'chip emoji-pick'; b.textContent = e; b.setAttribute('aria-label', 'Use ' + e); b.onclick = () => { $('propText').value = e; refreshDraft(); propPreview.burst(); }; $('emojiPicks').append(b); }
  for (const [n, markup] of Object.entries(VECTOR_STARTERS)) {
    const b = document.createElement('button'); b.className = 'chip'; b.textContent = n;
    b.onclick = () => { $('propSvg').value = markup; if (!$('propName').value.trim() || Object.keys(VECTOR_STARTERS).includes($('propName').value.trim())) $('propName').value = n; pm.physics = STARTER_PHYSICS[n]; renderPhysChips(); refreshDraft(); propPreview.burst(); };
    $('vectorStarters').append(b);
  }
  document.querySelectorAll('input[name="pkind"]').forEach((r) => r.addEventListener('change', () => { refreshDraft(); propPreview.burst(); }));
  let t; const later = () => { clearTimeout(t); t = setTimeout(refreshDraft, 250); };
  ['propText', 'propSvg', 'propName'].forEach((id) => $(id).addEventListener('input', later));
  $('propColor').addEventListener('input', refreshDraft);
  $('propSize').addEventListener('input', refreshDraft);
  $('propFile').addEventListener('change', async (e) => {
    const f = e.target.files && e.target.files[0]; if (!f) return;
    if (f.size > 512 * 1024) { setPropStatus('That SVG is over 512 KB. Simplify it before importing.', 'err'); return; }
    $('propSvg').value = await f.text();
    if (!$('propName').value.trim()) $('propName').value = slug(f.name.replace(/\.svg$/i, '')).slice(0, 32).replace(/^[^a-z]+/, '') || 'prop';
    e.target.value = ''; refreshDraft(); propPreview.burst();
  });
  $('addProp').onclick = () => { if (putPropInScript()) propPreview.burst(); };
  $('addPropClip').onclick = () => {
    const name = putPropInScript(); if (!name) return;
    const sc = showcaseFor(pm.physics);
    addClip('fx', Object.assign({ prop: name, mode: sc.mode, count: sc.count }, sc.spread ? { spread: sc.spread } : {}));
    setPropStatus(`Added "${name}" and dropped it at ${player.playhead.toFixed(2)} s.`, 'good');
  };
  let armed = false;
  $('delProp').onclick = () => {
    const name = $('propName').value.trim();
    const uses = state.raw.clips.filter((c) => c && c.track === 'fx' && c.prop === name).length;
    if (!armed) { armed = true; $('delProp').textContent = uses ? `Remove it and its ${uses} clip${uses === 1 ? '' : 's'}?` : 'Remove it?'; setTimeout(() => { armed = false; $('delProp').textContent = 'Remove from script'; }, 4000); return; }
    armed = false; $('delProp').textContent = 'Remove from script';
    const props = Object.assign({}, state.raw.props); delete props[name];
    state.raw.props = props; if (!Object.keys(props).length) delete state.raw.props;
    state.raw.clips = state.raw.clips.filter((c) => !(c && c.track === 'fx' && c.prop === name));
    state.selected = null; commit({ keepTime: true }); refreshDraft();
    setPropStatus(`Removed "${name}".`, 'good');
  };
  $('saveProp').onclick = async () => {
    const name = validPropName(); if (!name || !pm.def || !propCol) return;
    try { await propCol.doc(name).set({ name, def: JSON.stringify(pm.def), updatedAt: Date.now() }); setPropStatus(`Saved "${name}" to team props.`, 'good'); }
    catch (e) { setPropStatus(e.code === 'quota_exceeded' ? 'Team props are full. Delete some first.' : 'Could not save. You may only have view access.', 'err'); }
  };
  $('drawProp').onclick = async () => {
    const idea = $('propIdea').value.trim();
    if (!idea) { setPropStatus('Describe the prop first, e.g. a tiny paper airplane.', 'err'); $('propIdea').focus(); return; }
    if (!sample) { setPropStatus('Drawing works when this page is open in Claude.', 'err'); return; }
    $('drawProp').disabled = true; setPropStatus('Drawing'); $('propStatus').classList.add('dots');
    try {
      const r = await sample.json(`Design one small flat vector icon for a friendly pastel mascot app (a light-blue ghost named Fabio): ${idea}.
Rules: viewBox [0,0,24,24]. 1 to 6 paths using only SVG path data commands M L H V C S Q T A Z. Chunky, rounded, readable at 16 pixels. Flat colors, no gradients, no text. The main shape uses "currentColor" so the app can tint it; accents may use fixed hex colors; a white highlight (#FFFFFF with opacity 0.6) is welcome.
Also choose how it moves once spawned, one of: float, rise, fall, flutter, drift, still, drop; and its main color.
Reply with only JSON: {"name":"snake_case","viewBox":[0,0,24,24],"paths":[{"d":"...","fill":"currentColor"}],"physics":"float","color":"#RRGGBB"}. Path entries may also have "stroke" (hex), "strokeWidth" and "opacity".`, { cache: false });
      if (!r || !Array.isArray(r.paths) || !r.paths.length) throw { code: 'invalid_json' };
      document.querySelector('input[name="pkind"][value="vector"]').checked = true;
      $('propSvg').value = vectorToMarkup({ viewBox: Array.isArray(r.viewBox) ? r.viewBox : [0, 0, 24, 24], paths: r.paths.filter((p) => p && typeof p.d === 'string') });
      if (typeof r.name === 'string' && NAME_RE.test(r.name) && !PROPS.includes(r.name)) $('propName').value = r.name;
      if (PHYS_PRESETS[r.physics]) pm.physics = r.physics;
      if (svgColor(r.color)) $('propColor').value = r.color.slice(0, 7).toLowerCase();
      renderPhysChips(); $('propStatus').classList.remove('dots'); refreshDraft(); propPreview.burst();
      if (pm.def) setPropStatus('Drawn. Tweak the SVG, color or motion, then add it to the script.', 'good');
    } catch (e) {
      $('propStatus').classList.remove('dots');
      setPropStatus(e && e.code === 'cancelled' ? 'Stopped.' : e && e.code === 'rate_limited' ? 'Too many requests right now. Try again in a minute.' : e && e.code === 'not_granted' ? 'Drawing needs your permission to use Claude.' : 'Could not draw that. Try describing it differently.', 'err');
    } finally { $('drawProp').disabled = false; }
  };
  renderPhysChips();
})();

// ---------- boot ----------
function boot() {
  layoutPhone(); fillPresets();
  const draft = loadDraft();
  setScript(draft && Array.isArray(draft.clips) ? draft : clone(PRESETS.welcome));
  renderPlayButton(); refreshDraft();
  requestAnimationFrame((t) => { last = t; frame(t); });
  document.fonts?.ready?.then(() => { layoutPhone(); renderTimeline(); });
  if (window.claude?.use) {
    claude.use('sample').then((s) => {
      sample = s;
      if (!s) { $('generate').disabled = true; setGenStatus('Generating works when this page is open in Claude.'); }
    });
    claude.use('downloads').then((d) => (downloads = d));
    claude.use('db').then((db) => {
      if (!db) { $('libHint').textContent = 'Available when this page is open in Claude'; $('library').innerHTML = '<p class="hint" style="margin:0">Sign in on claude.ai to see scripts your team saved.</p>'; return; }
      propCol = db.collection('props'); $('saveProp').hidden = false; renderTeamProps();
      propCol.orderBy('updatedAt', 'desc').limit(100).onSnapshot((snap) => { teamProps = snap.docs.map((d) => ({ id: d.id, ...d.data() })); renderTeamProps(); }, () => {});
      libCol = db.collection('scripts'); $('saveLib').hidden = false; $('libHint').textContent = 'Shared with everyone who can open this page';
      libCol.orderBy('updatedAt', 'desc').limit(100).onSnapshot((snap) => { libDocs = snap.docs.map((d) => ({ id: d.id, ...d.data() })); renderLibrary(); },
        () => { $('libHint').textContent = 'Library unavailable right now'; });
    });
  } else {
    $('generate').disabled = true; setGenStatus('Generating works when this page is open in Claude.');
    $('libHint').textContent = 'Available when this page is open in Claude';
  }
}
boot();
