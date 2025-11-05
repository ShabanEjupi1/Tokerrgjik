import { neon } from '@neondatabase/serverless';

// Try multiple environment variable names
const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

// Initialize Neon client (null if no connection string)
const sql = connectionString ? neon(connectionString) : null;

/**
 * User endpoints handler
 * Handles user registration, retrieval, and search
 */
export async function handler(event, context) {
  // Enable CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Content-Type': 'application/json',
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  const path = event.path.replace('/.netlify/functions/users', '');
  const method = event.httpMethod;

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

    // GET /users/:username - Get user by username
    if (method === 'GET' && path.startsWith('/') && !path.includes('search')) {
      const username = path.substring(1);
      
      const result = await sql`
        SELECT * FROM users 
        WHERE username = ${username}
        LIMIT 1
      `;

      if (result.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found' }),
        };
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result[0]),
      };
    }

    // GET /users/search?q=query - Search users by username
    if (method === 'GET' && path.includes('search')) {
      const query = new URL(event.rawUrl).searchParams.get('q') || '';
      
      const results = await sql`
        SELECT username, coins, total_wins, level 
        FROM users 
        WHERE username ILIKE ${'%' + query + '%'}
        ORDER BY total_wins DESC
        LIMIT 20
      `;

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ users: results }),
      };
    }

    // POST /users - Create new user
    if (method === 'POST') {
      const data = JSON.parse(event.body);
      const { username, email, password } = data;

      if (!username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Username is required' }),
        };
      }

      // Check if user exists
      const existing = await sql`
        SELECT username FROM users WHERE username = ${username} LIMIT 1
      `;

      if (existing.length > 0) {
        return {
          statusCode: 409,
          headers,
          body: JSON.stringify({ error: 'Username already exists' }),
        };
      }

      // Create user
      const result = await sql`
        INSERT INTO users (username, email, password, coins, level, xp, total_wins, total_losses, total_draws, created_at)
        VALUES (${username}, ${email || null}, ${password || null}, 100, 1, 0, 0, 0, 0, NOW())
        RETURNING *
      `;

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(result[0]),
      };
    }

    // PUT /users/:username/stats - Update user stats
    if (method === 'PUT' && path.includes('/stats')) {
      const username = path.split('/')[1];
      const data = JSON.parse(event.body);

      // Get current user first
      const currentUser = await sql`SELECT * FROM users WHERE username = ${username} LIMIT 1`;
      if (currentUser.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found' }),
        };
      }

      const user = currentUser[0];
      
      // Calculate new values
      const newWins = user.total_wins + (data.wins || 0);
      const newLosses = user.total_losses + (data.losses || 0);
      const newDraws = user.total_draws + (data.draws || 0);
      const newCoins = user.coins + (data.coins || 0);
      const newXP = user.xp + (data.xp || 0);
      const newLevel = data.level !== undefined ? data.level : user.level;
      const newWinStreak = data.current_win_streak !== undefined ? data.current_win_streak : user.current_win_streak || 0;
      const newBestStreak = data.best_win_streak !== undefined ? data.best_win_streak : user.best_win_streak || 0;

      const result = await sql`
        UPDATE users 
        SET total_wins = ${newWins},
            total_losses = ${newLosses},
            total_draws = ${newDraws},
            coins = ${newCoins},
            xp = ${newXP},
            level = ${newLevel},
            current_win_streak = ${newWinStreak},
            best_win_streak = ${newBestStreak},
            updated_at = NOW()
        WHERE username = ${username}
        RETURNING *
      `;

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result[0]),
      };
    }

    // PUT /users/profile - Update user profile (username, email, avatar, isPro)
    if (method === 'PUT' && path === '/profile') {
      const data = JSON.parse(event.body);
      const { old_username, new_username, email, avatar_url, is_pro, pro_expires_at } = data;

      if (!old_username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'old_username is required' }),
        };
      }

      // Check if user exists
      const existingUser = await sql`SELECT * FROM users WHERE username = ${old_username} LIMIT 1`;
      if (existingUser.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found' }),
        };
      }

      const user = existingUser[0];

      // If changing username, check if new username is already taken
      if (new_username && new_username !== old_username) {
        const usernameCheck = await sql`SELECT username FROM users WHERE username = ${new_username} LIMIT 1`;
        if (usernameCheck.length > 0) {
          return {
            statusCode: 409,
            headers,
            body: JSON.stringify({ error: 'Username already taken' }),
          };
        }
      }

      // Use provided values or keep existing
      const finalUsername = new_username || old_username;
      const finalEmail = email !== undefined ? email : user.email;
      const finalAvatar = avatar_url !== undefined ? avatar_url : user.avatar_url;
      const finalIsPro = is_pro !== undefined ? is_pro : user.is_pro;
      const finalProExpires = pro_expires_at !== undefined ? pro_expires_at : user.pro_expires_at;

      // If username is changing, update game_history first to maintain referential integrity
      if (new_username && new_username !== old_username) {
        try {
          await sql`
            UPDATE game_history 
            SET username = ${finalUsername}
            WHERE username = ${old_username}
          `;
        } catch (historyError) {
          console.error('Error updating game_history:', historyError);
          // Continue anyway - game history update is not critical
        }
      }

      const result = await sql`
        UPDATE users 
        SET username = ${finalUsername},
            email = ${finalEmail},
            avatar_url = ${finalAvatar},
            is_pro = ${finalIsPro},
            pro_expires_at = ${finalProExpires},
            updated_at = NOW()
        WHERE username = ${old_username}
        RETURNING *
      `;

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ 
          success: true, 
          user: result[0],
          message: 'Profile updated successfully' 
        }),
      };
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Endpoint not found' }),
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
