// Builds Fabio Studio into a single self-contained HTML page.
//
//   node tools/fabio_studio/build.mjs
//
// Outputs (git-ignored):
//   dist/fabio-studio.html  the page to publish as a claude.ai Artifact. It has
//                           no <html>/<head>/<body>; the Artifact host wraps it.
//   dist/preview.html       the same page wrapped in an equivalent skeleton, for
//                           opening locally (serve it over http, not file://).
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '../..');
const src = (f) => readFileSync(join(here, 'src', f), 'utf8');

// Every bundled app script becomes a built-in preset in the Studio.
const scriptsDir = join(repo, 'assets/fabio/scripts');
const presets = {};
for (const f of readdirSync(scriptsDir).filter((f) => f.endsWith('.json')).sort()) {
  presets[f.replace(/\.json$/, '')] = JSON.parse(readFileSync(join(scriptsDir, f), 'utf8'));
}

const app = src('app.js');
if (!app.includes('/*PRESETS*/{}')) throw new Error('app.js lost its /*PRESETS*/{} placeholder');
const page = `${src('shell.html')}\n<script>\n${src('engine.js')}\n${app.replace('/*PRESETS*/{}', JSON.stringify(presets))}\n</script>\n`;

// Fail the build on a script syntax error rather than shipping a blank page.
new Function(page.split('<script>\n')[1].split('</script>')[0]);

const skeleton = (body) =>
  '<!doctype html><html><head><meta charset=utf8>' +
  '<meta name=viewport content="width=device-width,initial-scale=1,viewport-fit=cover">' +
  '<style>:root{color-scheme:light}body{margin:0;font:14px system-ui;background:#fafafa}' +
  'img{max-width:100%}[hidden]{display:none!important}</style></head><body>' +
  body + '</body></html>';

mkdirSync(join(here, 'dist'), { recursive: true });
writeFileSync(join(here, 'dist/fabio-studio.html'), page);
writeFileSync(join(here, 'dist/preview.html'), skeleton(page));
console.log(`Built dist/fabio-studio.html (${(page.length / 1024).toFixed(0)} KB, ${Object.keys(presets).length} presets)`);
