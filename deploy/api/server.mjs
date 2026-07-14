// Self-hosted adapter for the Netlify functions in ../netlify/functions.
// Each function exports `handler(event, context)` (classic Netlify signature);
// this server exposes them as /<name> so nginx can proxy /api/<name> here.
import express from 'express';
import { readdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FUNCTIONS_DIR = join(__dirname, 'functions');

const app = express();
app.use(express.text({ type: '*/*', limit: '10mb' }));

const names = readdirSync(FUNCTIONS_DIR)
  .filter((f) => f.endsWith('.mjs'))
  .map((f) => f.replace(/\.mjs$/, ''));

const handlers = {};
for (const name of names) {
  const mod = await import(join(FUNCTIONS_DIR, `${name}.mjs`));
  if (typeof mod.handler === 'function') handlers[name] = mod.handler;
}
console.log(`Loaded functions: ${Object.keys(handlers).join(', ')}`);

const dispatch = async (req, res) => {
  const name = req.params.name;
  const handler = handlers[name];
  if (!handler) return res.status(404).json({ error: 'function not found' });

  // The functions find their sub-route by stripping Netlify's own prefix, e.g.
  //   event.path.replace('/.netlify/functions/leaderboard', '')  -> '/weekly'
  // and they read the query string off `event.rawUrl`, which Netlify supplies as
  // an absolute URL. Reproduce both exactly, or every sub-route resolves to the
  // wrong handler and `new URL(undefined)` throws.
  const subPath = req.path.slice(1 + name.length); // '/weekly', or '' at the root
  const fnPath = `/.netlify/functions/${name}${subPath}`;
  const queryIndex = req.originalUrl.indexOf('?');
  const rawQuery = queryIndex === -1 ? '' : req.originalUrl.slice(queryIndex);
  const proto = req.headers['x-forwarded-proto'] || 'https';
  const host = req.headers['x-forwarded-host'] || req.headers.host || 'localhost';

  const event = {
    httpMethod: req.method,
    path: fnPath,
    rawUrl: `${proto}://${host}${fnPath}${rawQuery}`,
    rawQuery: rawQuery.replace(/^\?/, ''),
    queryStringParameters: req.query,
    headers: req.headers,
    body: typeof req.body === 'string' && req.body.length ? req.body : null,
    isBase64Encoded: false,
  };
  try {
    const result = await handler(event, {});
    res.status(result.statusCode || 200);
    for (const [k, v] of Object.entries(result.headers || {})) res.set(k, v);
    res.send(result.body ?? '');
  } catch (err) {
    console.error(`[${req.params.name}]`, err);
    res.status(500).json({ error: 'internal error' });
  }
};
app.all('/:name', dispatch);
app.all('/:name/*', dispatch);

app.get('/', (_req, res) => res.json({ functions: Object.keys(handlers) }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API adapter on :${PORT}`));
