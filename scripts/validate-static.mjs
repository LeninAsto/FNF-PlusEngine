import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { extname, join, relative, resolve } from 'node:path';

const root = resolve('docs');
const errors = [];
const required = ['index.html', 'es/index.html', 'psych/index.html', 'plus/index.html', 'community/index.html', 'es/community/index.html', 'data/ports.json', 'assets/community-ports.js', 'assets/site.css', 'assets/site.js', 'assets/pluslogo.png', 'assets/logo.png', 'assets/videos/reverse.mp4', 'assets/videos/drunk.mp4', 'assets/videos/tipsy.mp4', 'assets/videos/beat.mp4'];
for (const item of required) {
  const file = join(root, item);
  if (!existsSync(file) || statSync(file).size === 0) errors.push(`Missing or empty: docs/${item}`);
}

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => entry.isDirectory() ? walk(join(dir, entry.name)) : [join(dir, entry.name)]);
}

const files = walk(root);
for (const file of files.filter((item) => extname(item) === '.json')) {
  try { JSON.parse(readFileSync(file, 'utf8').replace(/^\uFEFF/, '')); }
  catch (error) { errors.push(`Invalid JSON: ${relative(root, file)} (${error.message})`); }
}
for (const file of files.filter((item) => extname(item) === '.html')) {
  const html = readFileSync(file, 'utf8');
  if (!html.includes('assets/site.css')) errors.push(`Missing shared CSS: ${relative(root, file)}`);
  if (/Astro|Starlight/.test(html)) errors.push(`Framework reference remains: ${relative(root, file)}`);
  for (const match of html.matchAll(/(?:src|href)="([^"#?]+)"/g)) {
    const target = match[1];
    if (/^(?:https?:|mailto:|tel:|#)/.test(target) || target.endsWith('/')) continue;
    const diskPath = resolve(join(file, '..', target));
    if (diskPath.startsWith(root) && !existsSync(diskPath)) errors.push(`Broken local asset in ${relative(root, file)}: ${target}`);
  }
}
if (errors.length) {
  console.error(errors.map((item) => `- ${item}`).join('\n'));
  process.exit(1);
}
console.log(`Validated ${files.length} static files in docs/ (${files.filter((file) => file.endsWith('.html')).length} pages).`);
