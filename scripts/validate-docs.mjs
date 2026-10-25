import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const errors = [];
const statuses = new Set(['verified', 'needs-review', 'unsupported', 'deprecated']);
const origins = new Set(['psych-upstream', 'plus-added', 'plus-modified']);

async function json(path) {
  return JSON.parse(await readFile(resolve(root, path), 'utf8'));
}

const collections = [
  ['psych/playstate', await json('src/data/api/psych/playstate.json')],
  ['plus/modifiers', await json('src/data/api/plus/modifiers.json')]
];

for (const [name, collection] of collections) {
  const ids = new Set();
  for (const entry of collection.functions) {
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(entry.id)) errors.push(`${name}: invalid id ${entry.id}`);
    if (ids.has(entry.id)) errors.push(`${name}: duplicate id ${entry.id}`);
    ids.add(entry.id);
    if (!statuses.has(entry.status)) errors.push(`${name}/${entry.id}: invalid status ${entry.status}`);
    if (!origins.has(entry.origin)) errors.push(`${name}/${entry.id}: invalid origin ${entry.origin}`);
    if (!entry.signature?.startsWith(entry.id)) errors.push(`${name}/${entry.id}: signature does not start with its id`);
    if (!Array.isArray(entry.sourceLinks) || entry.sourceLinks.length === 0) errors.push(`${name}/${entry.id}: missing source links`);
    if (entry.status === 'verified' && (!entry.testedAtCommit || entry.available.length === 0)) {
      errors.push(`${name}/${entry.id}: verified entries require testedAtCommit and available versions`);
    }
  }

  for (const locale of ['en', 'es-LA']) {
    const translations = await json(`src/data/translations/${locale}/${name}.json`);
    for (const id of ids) if (!translations[id]?.trim()) errors.push(`${locale}/${name}: missing translation for ${id}`);
    for (const id of Object.keys(translations)) if (!ids.has(id)) errors.push(`${locale}/${name}: unknown translation key ${id}`);
  }
}

async function collectMdx(directory, prefix = '') {
  const entries = await readdir(directory, { withFileTypes: true });
  const paths = [];
  for (const entry of entries) {
    const key = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) paths.push(...await collectMdx(resolve(directory, entry.name), key));
    else if (entry.name.endsWith('.mdx')) paths.push(key);
  }
  return paths;
}

const docsRoot = resolve(root, 'src/content/docs');
const pages = await collectMdx(docsRoot);
const englishPages = pages.filter((path) => !path.startsWith('es-LA/'));
for (const path of englishPages) {
  const localized = `es-LA/${path}`;
  if (!pages.includes(localized)) errors.push(`missing Spanish page for ${path}`);
}

const redirects = (await readFile(resolve(root, 'public/_redirects'), 'utf8'))
  .split('\n')
  .map((line) => line.trim())
  .filter(Boolean);
for (const redirect of redirects) {
  const [, target] = redirect.split(/\s+/);
  const normalized = target.replace(/^\//, '').replace(/\/$/, '');
  const relative = normalized === '' ? 'index' : normalized === 'es-LA' ? 'es-LA/index' : normalized;
  const candidates = [`${relative}.mdx`, `${relative}/index.mdx`];
  if (!candidates.some((candidate) => pages.includes(candidate))) errors.push(`redirect target has no content page: ${target}`);
}

if (errors.length) {
  console.error(errors.map((error) => `- ${error}`).join('\n'));
  process.exit(1);
}

console.log(`Validated ${collections.length} API collections, 2 locales, ${pages.length} pages, and ${redirects.length} redirects.`);
