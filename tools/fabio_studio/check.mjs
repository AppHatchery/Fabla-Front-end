// Sanity checks for the Studio engine, runnable without a browser.
//
//   node tools/fabio_studio/check.mjs
//
// 1. The seeded RNG must match the Dart one. The same numbers are pinned in
//    test/theme/fabio/fabio_test.dart ("matches the Fabio Studio sequence").
// 2. Custom prop physics must change how props move in every spawn mode
//    (the regression behind "How it moves does nothing").
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const engine = readFileSync(join(here, 'src/engine.js'), 'utf8');
// engine.js only needs Path2D for vector props; glyph props are enough here.
const E = new Function(`${engine}; return { Rng, Fx, compileProp, PHYS_PRESETS };`)();

let failed = 0;
const check = (ok, msg) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${msg}`); if (!ok) failed++; };

const r = new E.Rng(7);
const seq = [r.next(), r.next(), r.next()].map((v) => v.toFixed(12));
check(seq.join(',') === '0.011704753153,0.061958257575,0.976907632779', `RNG seed 7 → ${seq.join(', ')}`);

function travel(physics, mode) {
  const c = E.compileProp('p', { kind: 'glyph', text: 'x', physics });
  const fx = new E.Fx(3);
  fx.bounds = { w: 390, h: 844 };
  fx.emit('p', mode, [195, 422], { count: 30, custom: c });
  const start = new Map(fx.particles.map((p) => [p, p.y]));
  for (let i = 0; i < 48; i++) fx.update(1 / 60);
  const alive = fx.particles.filter((p) => start.has(p));
  return alive.reduce((s, p) => s + p.y - start.get(p), 0) / alive.length;
}
for (const mode of ['burst', 'float']) {
  const rise = travel('rise', mode), fall = travel('fall', mode), still = travel('still', mode);
  check(rise < -80 && fall > 80 && Math.abs(still) < 10, `${mode}: rise ${rise.toFixed(0)}px, fall ${fall.toFixed(0)}px, still ${still.toFixed(0)}px`);
}
check(travel('float', 'rain') < 0 && travel('fall', 'rain') > 0, 'rain showers floating props upward and falling props downward');

process.exit(failed ? 1 : 0);
