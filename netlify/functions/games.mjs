import { neon } from '@neondatabase/serverless';

const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

const sql = connectionString ? neon(connectionString) : null;

/**
 * Games endpoint handler
 * Saves game results and retrieves game history
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

  const path = event.path.replace('/.netlify/functions/games', '');

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

    // POST /games - Multiple actions
    if (event.httpMethod === 'POST') {
      const data = JSON.parse(event.body);
      const { action } = data;

      // CREATE MULTIPLAYER SESSION
      if (action === 'create_session') {
        const { host_username, guest_username, is_private } = data;
        
        if (!host_username) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing host_username' }),
          };
        }
        
        // Ensure host user exists in users table
        try {
          const existingUser = await sql`
            SELECT username FROM users WHERE username = ${host_username}
          `;
          
          if (existingUser.length === 0) {
            return {
              statusCode: 404,
              headers,
              body: JSON.stringify({ error: 'Host user not found. Please login first.' }),
            };
          }
          
          // Verify guest user exists if provided
          if (guest_username) {
            const guestExists = await sql`
              SELECT username FROM users WHERE username = ${guest_username}
            `;
            
            if (guestExists.length === 0) {
              return {
                statusCode: 404,
                headers,
                body: JSON.stringify({ error: 'Guest user not found' }),
              };
            }
          }
        } catch (userError) {
          console.error('Error checking user existence:', userError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: 'Failed to verify users', details: userError.message }),
          };
        }
        
        // Create game session with proper initial state
        try {
          const session = await sql`
            INSERT INTO game_sessions (
              host_username, 
              guest_username, 
              status, 
              board_state, 
              current_turn, 
              created_at,
              updated_at
            )
            VALUES (
              ${host_username}, 
              ${guest_username || null}, 
              'waiting', 
              '{"board": [], "phase": "placing", "turn": 1}',
              ${host_username}, 
              NOW(),
              NOW()
            )
            RETURNING *
          `;
          
          return {
            statusCode: 201,
            headers,
            body: JSON.stringify({ 
              success: true,
              message: 'Game session created',
              session_id: session[0].id,
              session: session[0] 
            }),
          };
        } catch (sessionError) {
          console.error('Error creating game session:', sessionError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to create game session', 
              details: sessionError.message 
            }),
          };
        }
      }

      // JOIN SESSION
      if (action === 'join_session') {
        const { session_id, username } = data;
        
        await sql`
          UPDATE game_sessions
          SET guest_username = ${username}, status = 'active'
          WHERE id = ${session_id}
        `;
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Joined session', session_id }),
        };
      }

      // LIST AVAILABLE SESSIONS (POST support)
      if (action === 'list_sessions') {
        const sessions = await sql`
          SELECT * FROM game_sessions 
          WHERE status = 'waiting'
          ORDER BY created_at DESC
          LIMIT 20
        `;
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ sessions }),
        };
      }

      // MAKE MOVE
      if (action === 'make_move') {
        const { session_id, position, move_action, timestamp } = data;
        
        // Get current session
        const session = await sql`SELECT * FROM game_sessions WHERE id = ${session_id}`;
        if (session.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Session not found' }),
          };
        }

        // Update board state (simplified - in production, validate moves)
        const currentBoard = session[0].board_state || {};
        currentBoard[`move_${Date.now()}`] = { position, action: move_action, timestamp };
        
        // Toggle turn
        const newTurn = session[0].current_turn === session[0].host_username 
          ? session[0].guest_username 
          : session[0].host_username;
        
        await sql`
          UPDATE game_sessions
          SET board_state = ${JSON.stringify(currentBoard)}, 
              current_turn = ${newTurn}
          WHERE id = ${session_id}
        `;
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Move recorded', current_turn: newTurn }),
        };
      }

      // LEAVE SESSION
      if (action === 'leave_session') {
        const { session_id } = data;
        
        await sql`
          UPDATE game_sessions
          SET status = 'cancelled'
          WHERE id = ${session_id}
        `;
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Left session' }),
        };
      }

      // SAVE GAME RESULT (original functionality)
      const {
        username,
        game_mode,
        result,
        opponent_username,
        score,
        duration,
        moves_count,
        played_at,
      } = data;

      if (!username || !game_mode || !result) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing required fields' }),
        };
      }

      // Save game
      const gameResult = await sql`
        INSERT INTO game_history (
          username, game_mode, result, opponent_username, 
          score, duration, moves_count, played_at, created_at
        )
        VALUES (
          ${username}, ${game_mode}, ${result}, ${opponent_username || null},
          ${score || 0}, ${duration || 0}, ${moves_count || 0}, 
          ${played_at || new Date().toISOString()}, NOW()
        )
        RETURNING *
      `;

      // Update user stats
      if (result === 'win') {
        await sql`
          UPDATE users 
          SET total_wins = total_wins + 1, xp = xp + 10, coins = coins + 5
          WHERE username = ${username}
        `;
      } else if (result === 'loss') {
        await sql`
          UPDATE users 
          SET total_losses = total_losses + 1, xp = xp + 2
          WHERE username = ${username}
        `;
      } else if (result === 'draw') {
        await sql`
          UPDATE users 
          SET total_draws = total_draws + 1, xp = xp + 5, coins = coins + 2
          WHERE username = ${username}
        `;
      }

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(gameResult[0]),
      };
    }

    // GET /games - Multiple queries
    if (event.httpMethod === 'GET') {
      const params = new URL(event.rawUrl).searchParams;
      const action = params.get('action');
      
      // GET SESSION STATE (for polling)
      if (action === 'get_state') {
        const sessionId = params.get('session_id');
        
        const session = await sql`
          SELECT * FROM game_sessions WHERE id = ${sessionId}
        `;
        
        if (session.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Session not found' }),
          };
        }
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify(session[0]),
        };
      }

      // LIST AVAILABLE SESSIONS
      if (action === 'list_sessions') {
        const sessions = await sql`
          SELECT * FROM game_sessions 
          WHERE status = 'waiting'
          ORDER BY created_at DESC
          LIMIT 20
        `;
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ sessions }),
        };
      }

      // GET GAME HISTORY (original functionality)
      const username = path.substring(1).split('?')[0];
      if (username) {
        const limit = parseInt(params.get('limit') || '50');
        const offset = parseInt(params.get('offset') || '0');

        const results = await sql`
          SELECT * FROM game_history
          WHERE username = ${username}
          ORDER BY played_at DESC
          LIMIT ${limit}
          OFFSET ${offset}
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ games: results }),
        };
      }
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Endpoint not found' }),
    };

  } catch (error) {
    console.error('Games error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
