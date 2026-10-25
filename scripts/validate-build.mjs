import { access, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const required = [
  'index.html',
  'es-LA/index.html',
  'guides/create-mod/index.html',
  'es-LA/guides/create-mod/index.html',
  'api/psych/playstate/index.html',
  'es-LA/api/psych/playstate/index.html',
  'api/plus/modifiers/index.html',
  'es-LA/api/plus/modifiers/index.html',
  '_redirects',
  'language-entry.js'
];

for (const file of required) await access(resolve(root, 'dist', file));

try {
  await access(resolve(root, 'dist/es-la'));
  throw new Error('Unexpected lowercase locale route dist/es-la exists.');
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}

const english = await readFile(resolve(root, 'dist/api/psych/playstate/index.html'), 'utf8');
const spanish = await readFile(resolve(root, 'dist/es-LA/api/psych/playstate/index.html'), 'utf8');

const assertions = [
  [english.includes('<html lang="en"'), 'English page has lang="en"'],
  [spanish.includes('<html lang="es-LA"'), 'Spanish page has lang="es-LA"'],
  [english.includes('https://psych-plus-engine.cc/api/psych/playstate/'), 'English canonical URL exists'],
  [spanish.includes('https://psych-plus-engine.cc/es-LA/api/psych/playstate/'), 'Spanish canonical URL exists'],
  [english.includes('hreflang="es-LA"'), 'English page links to Spanish alternate'],
  [spanish.includes('hreflang="en"'), 'Spanish page links to English alternate']
];

const failures = assertions.filter(([passed]) => !passed).map(([, label]) => label);
if (failures.length) throw new Error(`Build validation failed:\n- ${failures.join('\n- ')}`);

console.log(`Validated ${required.length} build artifacts, exact locale casing, canonical URLs, and hreflang links.`);
