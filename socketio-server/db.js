// Postgres access for the self-hosted multiplayer server (CommonJS twin of
// netlify/functions/db.mjs).
//
// server.js was written against @neondatabase/serverless, whose `neon()` returns
// a tagged-template function resolving to an array of rows. This exposes the
// identical shape on top of a normal `pg` TCP pool, so every call site keeps
// working unchanged while the data lives on our own Postgres.
const pg = require('pg');

let pool = null;

const getPool = (connectionString) => {
  if (!pool) {
    pool = new pg.Pool({
      connectionString,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000,
      // Our Postgres is a container on the same docker network, not on the
      // public internet, so TLS buys nothing here.
      ssl: /\bsslmode=require\b/.test(connectionString)
        ? { rejectUnauthorized: false }
        : false,
    });
    pool.on('error', (err) => console.error('[db] idle client error', err));
  }
  return pool;
};

/// Returns a tagged-template query function: await sql`SELECT ... ${value}`.
/// Interpolated values become $1..$n bind parameters, never string-concatenated,
/// so this is parameterised exactly as the Neon driver was.
const neon = (connectionString) => {
  const p = getPool(connectionString);

  return async (strings, ...values) => {
    const text = strings.reduce(
      (acc, part, i) => acc + part + (i < values.length ? `$${i + 1}` : ''),
      '',
    );
    const { rows } = await p.query(text, values);
    return rows;
  };
};

module.exports = { neon };
