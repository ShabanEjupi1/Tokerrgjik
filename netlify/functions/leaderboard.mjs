import { neon } from './db.mjs';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set DATABASE_URL.');
}

const sql = connectionString ? neon(connectionString) : null;

/**
 * Leaderboard endpoint handler
 * Returns top players sorted by wins
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  const path = event.path.replace('/.netlify/functions/leaderboard', '');
  const params = new URL(event.rawUrl).searchParams;

  try {
    // Check if database is configured
    if (!sql) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Database not configured. Set DATABASE_URL.' 
        }),
      };
    }

    // GET /leaderboard - Get global leaderboard
    if (event.httpMethod === 'GET' && !path.includes('rank')) {
      const limit = parseInt(params.get('limit') || '100');
      const offset = parseInt(params.get('offset') || '0');

      const results = await sql`
        SELECT 
          username,
          coins,
          total_wins,
          total_losses,
          total_draws,
          level,
          xp,
          is_pro,
          avatar_url,
          CASE 
            WHEN (total_wins + total_losses) > 0 
            THEN ROUND((total_wins::numeric / (total_wins + total_losses)) * 100, 1)
            ELSE 0 
          END as win_rate
        FROM users
        WHERE username NOT LIKE 'guest_%'
        ORDER BY total_wins DESC, level DESC, xp DESC
        LIMIT ${limit}
        OFFSET ${offset}
      `;

      // Add rank numbers and ensure proper data types
      const leaderboard = results.map((user, index) => ({
        username: user.username,
        coins: parseInt(user.coins) || 0,
        total_wins: parseInt(user.total_wins) || 0,
        total_losses: parseInt(user.total_losses) || 0,
        total_draws: parseInt(user.total_draws) || 0,
        level: parseInt(user.level) || 1,
        xp: parseInt(user.xp) || 0,
        is_pro: user.is_pro || false,
        avatar_url: user.avatar_url || null,
        win_rate: parseFloat(user.win_rate) || 0,
        rank: offset + index + 1,
      }));

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ leaderboard }),
      };
    }

    // GET /leaderboard/rank/:username - Get user's rank
    if (event.httpMethod === 'GET' && path.includes('rank')) {
      const username = path.split('/')[2];

      const result = await sql`
        WITH ranked_users AS (
          SELECT 
            username,
            ROW_NUMBER() OVER (ORDER BY total_wins DESC, level DESC, xp DESC) as rank
          FROM users
          WHERE username NOT LIKE 'guest_%'
        )
        SELECT rank FROM ranked_users WHERE username = ${username}
      `;

      if (result.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found', rank: 0 }),
        };
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ rank: parseInt(result[0].rank) || 0 }),
      };
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Endpoint not found' }),
    };

  } catch (error) {
    console.error('Leaderboard error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
