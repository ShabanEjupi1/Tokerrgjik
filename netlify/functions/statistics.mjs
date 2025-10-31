import { neon } from '@neondatabase/serverless';

const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

const sql = connectionString ? neon(connectionString) : null;

/**
 * Statistics endpoint handler
 * Returns comprehensive user statistics
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

  // Handle both direct function calls and /api/ redirects
  const path = event.path
    .replace('/.netlify/functions/statistics', '')
    .replace('/api/statistics', '');
  
  // Also check query parameters for userId (backward compatibility)
  const params = event.queryStringParameters || {};
  const usernameFromPath = path.substring(1); // Remove leading /
  const username = usernameFromPath || params.username || params.userId;

  try {
    // Check if database is configured
    if (!sql) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Database not configured. Set NEON_DATABASE_URL in Netlify environment variables.' 
        }),
      };
    }

    // GET /statistics/:username or /statistics?username=xxx - Get user statistics
    if (event.httpMethod === 'GET') {
      if (!username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Username is required' }),
        };
      }

      // Get user data
      const userResult = await sql`
        SELECT 
          username,
          email,
          coins,
          level,
          xp,
          total_wins,
          total_losses,
          total_draws,
          is_pro,
          avatar_url,
          created_at,
          last_login_at
        FROM users 
        WHERE username = ${username} 
        LIMIT 1
      `;

      if (userResult.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found' }),
        };
      }

      const user = userResult[0];

      // Get game statistics
      const gameStats = await sql`
        SELECT 
          game_mode,
          COUNT(*) as total_games,
          SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) as wins,
          SUM(CASE WHEN result = 'loss' THEN 1 ELSE 0 END) as losses,
          SUM(CASE WHEN result = 'draw' THEN 1 ELSE 0 END) as draws,
          AVG(duration) as avg_duration,
          AVG(moves_count) as avg_moves
        FROM game_history
        WHERE username = ${username}
        GROUP BY game_mode
      `;

      // Get recent games
      const recentGames = await sql`
        SELECT * FROM game_history
        WHERE username = ${username}
        ORDER BY played_at DESC
        LIMIT 10
      `;

      // Calculate win rate (handle division by zero)
      const totalGames = (user.total_wins || 0) + (user.total_losses || 0) + (user.total_draws || 0);
      const winRate = totalGames > 0 ? ((user.total_wins || 0) / totalGames * 100).toFixed(1) : '0.0';

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          user: {
            username: user.username,
            coins: user.coins || 0,
            level: user.level || 1,
            xp: user.xp || 0,
            total_wins: user.total_wins || 0,
            total_losses: user.total_losses || 0,
            total_draws: user.total_draws || 0,
            win_rate: parseFloat(winRate),
            is_pro: user.is_pro || false,
            avatar_url: user.avatar_url || null,
            created_at: user.created_at,
            last_login_at: user.last_login_at,
          },
          game_stats: gameStats.map(stat => ({
            ...stat,
            total_games: parseInt(stat.total_games) || 0,
            wins: parseInt(stat.wins) || 0,
            losses: parseInt(stat.losses) || 0,
            draws: parseInt(stat.draws) || 0,
            avg_duration: parseFloat(stat.avg_duration) || 0,
            avg_moves: parseFloat(stat.avg_moves) || 0,
          })),
          recent_games: recentGames,
        }),
      };
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Endpoint not found' }),
    };

  } catch (error) {
    console.error('Statistics error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
