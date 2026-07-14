// Postgres access for the self-hosted backend.
//
// The functions were written against @neondatabase/serverless, whose `neon()`
// returns a tagged-template function that resolves to an array of rows. This
// exposes the identical shape on top of a normal `pg` TCP pool, so the call
// sites keep working unchanged while the data lives on our own Postgres.
import pg from 'pg';

let pool = null;

const getPool = (connectionString) => {
  if (!pool) {
    pool = new pg.Pool({
      connectionString,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000,
      // Our Postgres is a container on the same host, reached over the docker
      // network - not over the public internet - so TLS buys nothing here.
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
export const neon = (connectionString) => {
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

export default neon;
