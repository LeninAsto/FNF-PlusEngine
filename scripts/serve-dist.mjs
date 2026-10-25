import { createReadStream } from 'node:fs';
import { readFile, stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, resolve, sep } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const dist = resolve(root, 'dist');
const redirectLines = (await readFile(resolve(dist, '_redirects'), 'utf8'))
  .split('\n')
  .map((line) => line.trim())
  .filter((line) => line && !line.startsWith('#'));
const redirects = new Map(redirectLines.map((line) => {
  const [source, target, status] = line.split(/\s+/);
  return [source, { target, status: Number(status) }];
}));
const types = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.mp4': 'video/mp4',
  '.svg': 'image/svg+xml',
  '.xml': 'application/xml; charset=utf-8'
};

createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', 'http://127.0.0.1');
  const redirect = redirects.get(url.pathname);
  if (redirect) {
    response.writeHead(redirect.status, { location: `${redirect.target}${url.search}` });
    response.end();
    return;
  }

  const decoded = decodeURIComponent(url.pathname);
  const relative = decoded.endsWith('/') ? `${decoded}index.html` : decoded;
  let file = resolve(dist, `.${relative}`);
  if (!file.startsWith(`${dist}${sep}`)) {
    response.writeHead(400).end('Bad request');
    return;
  }

  try {
    const details = await stat(file);
    if (details.isDirectory()) file = resolve(file, 'index.html');
    response.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
    createReadStream(file).pipe(response);
  } catch {
    response.writeHead(404, { 'content-type': 'text/html; charset=utf-8' });
    createReadStream(resolve(dist, '404.html')).pipe(response);
  }
}).listen(4321, '127.0.0.1');
