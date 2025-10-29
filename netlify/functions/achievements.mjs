import { neon } from '@neondatabase/serverless';

const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

const sql = connectionString ? neon(connectionString) : null;

// Achievements te paradefinuara (shembuj)
const ACHIEVEMENT_DEFINITIONS = [
  { type: 'first_win', title: 'Fitorja e parë', description: 'Fitoni lojën tuaj të parë', icon: '🏆' },
  { type: 'win_streak_5', title: 'Seri fitore 5', description: 'Fitoni 5 lojëra në seri', icon: '🔥' },
  { type: 'win_streak_10', title: 'Seri fitore 10', description: 'Fitoni 10 lojëra në seri', icon: '⚡' },
  { type: 'games_100', title: 'Veteran', description: 'Luani 100 lojëra', icon: '🎮' },
  { type: 'games_500', title: 'Mjeshtër', description: 'Luani 500 lojëra', icon: '👑' },
  { type: 'level_10', title: 'Nivel 10', description: 'Arrini nivelin 10', icon: '⭐' },
  { type: 'level_50', title: 'Nivel 50', description: 'Arrini nivelin 50', icon: '💎' },
  { type: 'pro_member', title: 'Anëtar PRO', description: 'Blini pajtimin PRO', icon: '👔' },
  { type: 'coins_1000', title: 'I pasur', description: 'Mblidhni 1000 monedha', icon: '💰' },
  { type: 'friend_10', title: 'Popullor', description: 'Shtoni 10 miq', icon: '👥' },
];

/**
 * Achievements endpoint handler
 * Works with the achievements table: id, username, achievement_type, unlocked_at
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }
  
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

    // GET: Fetch user achievements
    if (event.httpMethod === 'GET') {
      const params = new URL(event.rawUrl).searchParams;
      const username = params.get('username');
      const action = params.get('action');
      
      if (!username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Username required' }),
        };
      }
      
      // Get all unlocked achievements for this user
      const unlockedAchievements = await sql`
        SELECT achievement_type, unlocked_at
        FROM achievements
        WHERE username = ${username}
        ORDER BY unlocked_at DESC
      `;
      
      const unlockedTypes = new Set(unlockedAchievements.map(a => a.achievement_type));
      
      // Combine with definitions
      const achievements = ACHIEVEMENT_DEFINITIONS.map(definition => ({
        type: definition.type,
        title: definition.title,
        description: definition.description,
        icon: definition.icon,
        is_unlocked: unlockedTypes.has(definition.type),
        unlocked_at: unlockedAchievements.find(a => a.achievement_type === definition.type)?.unlocked_at || null,
      }));
      
      // If requesting progress
      if (action === 'progress') {
        const total = ACHIEVEMENT_DEFINITIONS.length;
        const unlocked = unlockedTypes.size;
        const percentage = Math.round((unlocked / total) * 100);
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ total, unlocked, percentage, achievements }),
        };
      }
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ achievements }),
      };
    }
    
    // POST: Unlock achievements
    if (event.httpMethod === 'POST') {
      const data = JSON.parse(event.body);
      const { 
        action, 
        username, 
        achievement_type,
        total_wins, 
        current_win_streak, 
        total_games, 
        user_level, 
        coins, 
        friends_count, 
        is_pro
      } = data;
      
      // Manually unlock a specific achievement
      if (action === 'unlock') {
        if (!username || !achievement_type) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing username or achievement_type' }),
          };
        }
        
        // Check if already unlocked
        const existing = await sql`
          SELECT * FROM achievements
          WHERE username = ${username} AND achievement_type = ${achievement_type}
        `;
        
        if (existing.length > 0) {
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'Achievement already unlocked' }),
          };
        }
        
        // Unlock achievement
        const result = await sql`
          INSERT INTO achievements (username, achievement_type)
          VALUES (${username}, ${achievement_type})
          RETURNING *
        `;
        
        return {
          statusCode: 201,
          headers,
          body: JSON.stringify({ message: 'Achievement unlocked', achievement: result[0] }),
        };
      }
      
      // Check and unlock achievements based on stats
      if (action === 'check_unlock') {
        if (!username) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Username required' }),
          };
        }
        
        // Get currently unlocked achievements
        const unlocked = await sql`
          SELECT achievement_type FROM achievements
          WHERE username = ${username}
        `;
        const unlockedTypes = new Set(unlocked.map(a => a.achievement_type));
        
        const newlyUnlocked = [];
        
        // Check each achievement condition and unlock if met
        if (total_wins >= 1 && !unlockedTypes.has('first_win')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'first_win')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'first_win'));
        }
        
        if (current_win_streak >= 5 && !unlockedTypes.has('win_streak_5')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'win_streak_5')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'win_streak_5'));
        }
        
        if (current_win_streak >= 10 && !unlockedTypes.has('win_streak_10')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'win_streak_10')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'win_streak_10'));
        }
        
        if (total_games >= 100 && !unlockedTypes.has('games_100')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'games_100')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'games_100'));
        }
        
        if (total_games >= 500 && !unlockedTypes.has('games_500')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'games_500')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'games_500'));
        }
        
        if (user_level >= 10 && !unlockedTypes.has('level_10')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'level_10')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'level_10'));
        }
        
        if (user_level >= 50 && !unlockedTypes.has('level_50')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'level_50')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'level_50'));
        }
        
        if (is_pro && !unlockedTypes.has('pro_member')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'pro_member')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'pro_member'));
        }
        
        if (coins >= 1000 && !unlockedTypes.has('coins_1000')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'coins_1000')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'coins_1000'));
        }
        
        if (friends_count >= 10 && !unlockedTypes.has('friend_10')) {
          await sql`INSERT INTO achievements (username, achievement_type) VALUES (${username}, 'friend_10')`;
          newlyUnlocked.push(ACHIEVEMENT_DEFINITIONS.find(a => a.type === 'friend_10'));
        }
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            newly_unlocked: newlyUnlocked,
            message: `${newlyUnlocked.length} new achievement(s) unlocked`
          }),
        };
      }
      
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid action' }),
      };
    }
    
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
    
  } catch (error) {
    console.error('Achievements error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
