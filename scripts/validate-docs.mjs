import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const errors = [];
const notices = [];
const statuses = new Set(['verified', 'needs-review', 'unsupported', 'deprecated']);
const origins = new Set(['psych-upstream', 'plus-added', 'plus-modified']);

async function json(path) {
  return JSON.parse(await readFile(resolve(root, path), 'utf8'));
}

const collections = [];
for (const origin of ['psych', 'plus']) {
  const directory = resolve(root, `src/data/api/${origin}`);
  const files = (await readdir(directory)).filter((file) => file.endsWith('.json')).sort();
  for (const file of files) {
    const name = `${origin}/${file.slice(0, -5)}`;
    collections.push([name, await json(`src/data/api/${name}.json`)]);
  }
}

function hasTranslation(value) {
  if (typeof value === 'string') return Boolean(value.trim());
  return Boolean(value && typeof value === 'object' && typeof value.description === 'string' && value.description.trim());
}

for (const [name, collection] of collections) {
  if (collection.kind === 'variables') {
    const sectionIds = new Set();
    for (const section of collection.sections ?? []) {
      if (!section.id || sectionIds.has(section.id)) errors.push(`${name}: invalid or duplicate variable section ${section.id}`);
      sectionIds.add(section.id);
      if (!Array.isArray(section.items) || section.items.length === 0) errors.push(`${name}/${section.id}: empty variable section`);
    }
    for (const locale of ['en', 'es-LA']) {
      const translations = await json(`src/data/translations/${locale}/${name}.json`);
      if (!Array.isArray(translations.sections) || translations.sections.length !== collection.sections.length) {
        errors.push(`${locale}/${name}: variable sections do not match source data`);
        continue;
      }
      collection.sections.forEach((section, index) => {
        for (const item of section.items) {
          if (!translations.sections[index].descriptions?.[item.id]?.trim()) errors.push(`${locale}/${name}: missing description for ${item.id}`);
        }
      });
    }
    continue;
  }

  if (collection.kind === 'links') {
    for (const group of collection.groups ?? []) {
      for (const link of group.links ?? []) {
        if (!/^https:\/\//.test(link.href)) errors.push(`${name}/${group.id}: external link must use HTTPS`);
      }
    }
    for (const locale of ['en', 'es-LA']) {
      const translations = await json(`src/data/translations/${locale}/${name}.json`);
      if (!Array.isArray(translations.groups) || translations.groups.length !== collection.groups.length) {
        errors.push(`${locale}/${name}: link groups do not match source data`);
      }
    }
    continue;
  }

  if (collection.kind === 'glossary') {
    const groupIds = new Set();
    for (const group of collection.groups ?? []) {
      if (!group.id || groupIds.has(group.id)) errors.push(`${name}: invalid or duplicate glossary group ${group.id}`);
      groupIds.add(group.id);
      if (!Array.isArray(group.items) || group.items.length === 0) errors.push(`${name}/${group.id}: empty glossary group`);
    }
    for (const locale of ['en', 'es-LA']) {
      const translations = await json(`src/data/translations/${locale}/${name}.json`);
      if (!translations.intro?.trim()) errors.push(`${locale}/${name}: missing glossary intro`);
      if (!Array.isArray(translations.groups) || translations.groups.length !== collection.groups.length) {
        errors.push(`${locale}/${name}: glossary group translations do not match source groups`);
      }
    }
    continue;
  }

  const ids = new Set();
  const entries = collection.functions ?? collection.items ?? [];
  for (const entry of entries) {
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(entry.id)) errors.push(`${name}: invalid id ${entry.id}`);
    if (ids.has(entry.id)) errors.push(`${name}: duplicate id ${entry.id}`);
    ids.add(entry.id);
    if (!statuses.has(entry.status)) errors.push(`${name}/${entry.id}: invalid status ${entry.status}`);
    if (!origins.has(entry.origin)) errors.push(`${name}/${entry.id}: invalid origin ${entry.origin}`);
    if (collection.kind !== 'modifiers' && !entry.signature?.startsWith(entry.id)) errors.push(`${name}/${entry.id}: signature does not start with its id`);
    if (!Array.isArray(entry.sourceLinks) || entry.sourceLinks.length === 0) errors.push(`${name}/${entry.id}: missing source links`);
    if (name.startsWith('psych/') && entry.sourceLinks.some(({ url }) => url.includes('/blob/main/'))) {
      errors.push(`${name}/${entry.id}: upstream source link must use a pinned commit`);
    }
    if (entry.status === 'verified' && (!entry.testedAtCommit || entry.available.length === 0)) {
      errors.push(`${name}/${entry.id}: verified entries require testedAtCommit and available versions`);
    }
  }

  for (const locale of ['en', 'es-LA']) {
    const translations = await json(`src/data/translations/${locale}/${name}.json`);
    let missing = 0;
    for (const id of ids) {
      if (hasTranslation(translations[id])) continue;
      if (locale === 'es-LA' && name.startsWith('psych/')) missing += 1;
      else errors.push(`${locale}/${name}: missing translation for ${id}`);
    }
    if (missing) notices.push(`${locale}/${name}: ${missing} entries intentionally fall back to English`);
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
  .filter((line) => line && !line.startsWith('#'));
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
if (notices.length) console.log(`${notices.length} localized collections contain explicit English fallbacks.`);
