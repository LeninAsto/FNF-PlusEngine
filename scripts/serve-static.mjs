import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize } from 'node:path';

const root = join(process.cwd(), 'docs');
const port = Number(process.env.PORT || 4321);
const types = { '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8', '.ico': 'image/x-icon', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.mp4': 'video/mp4', '.png': 'image/png' };

createServer((request, response) => {
  const urlPath = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  const safePath = normalize(urlPath).replace(/^(\.\.[/\\])+/, '');
  let file = join(root, safePath);
  if (!file.startsWith(root)) return response.writeHead(403).end('Forbidden');
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, 'index.html');
  if (!existsSync(file) && !extname(file)) file = join(file, 'index.html');
  if (!existsSync(file) || statSync(file).isDirectory()) return response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end('Not found');
  const size = statSync(file).size;
  const contentType = types[extname(file).toLowerCase()] || 'application/octet-stream';
  const range = request.headers.range?.match(/bytes=(\d*)-(\d*)/);
  if (range) {
    const start = range[1] ? Number(range[1]) : 0;
    const end = range[2] ? Math.min(Number(range[2]), size - 1) : size - 1;
    if (start > end || start >= size) {
      response.writeHead(416, { 'Content-Range': `bytes */${size}` }).end();
      return;
    }
    response.writeHead(206, {
      'Accept-Ranges': 'bytes',
      'Content-Range': `bytes ${start}-${end}/${size}`,
      'Content-Length': end - start + 1,
      'Content-Type': contentType,
      'Cache-Control': 'no-cache'
    });
    createReadStream(file, { start, end }).pipe(response);
    return;
  }
  response.writeHead(200, { 'Accept-Ranges': 'bytes', 'Content-Type': contentType, 'Content-Length': size, 'Cache-Control': 'no-cache' });
  createReadStream(file).pipe(response);
}).listen(port, '127.0.0.1', () => console.log(`Plus Engine docs: http://127.0.0.1:${port}`));
