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
          console.error('❌ CREATE SESSION FAILED: Missing host_username');
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing host_username' }),
          };
        }
        
        console.log(`🎮 Creating game session for host: ${host_username}`);
        
        // Ensure host user exists in users table
        try {
          const existingUser = await sql`
            SELECT username FROM users WHERE username = ${host_username} LIMIT 1
          `;
          
          if (existingUser.length === 0) {
            console.error(`❌ Host user not found: ${host_username}`);
            return {
              statusCode: 404,
              headers,
              body: JSON.stringify({ 
                error: 'Host user not found. Please login first.',
                debug: { host_username }
              }),
            };
          }
          
          console.log(`✅ Host user verified: ${host_username}`);
          
          // Verify guest user exists if provided
          if (guest_username) {
            const guestExists = await sql`
              SELECT username FROM users WHERE username = ${guest_username} LIMIT 1
            `;
            
            if (guestExists.length === 0) {
              console.error(`❌ Guest user not found: ${guest_username}`);
              return {
                statusCode: 404,
                headers,
                body: JSON.stringify({ error: 'Guest user not found' }),
              };
            }
            console.log(`✅ Guest user verified: ${guest_username}`);
          }
        } catch (userError) {
          console.error('❌ Error checking user existence:', userError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to verify users', 
              details: userError.message,
              hint: 'Database might not be properly configured'
            }),
          };
        }
        
        // Create game session with proper initial state
        try {
          console.log('📝 Inserting game session into database...');
          
          const boardState = JSON.stringify({
            board: [],
            phase: 'placing',
            turn: 1,
            pieces: { host: [], guest: [] }
          });
          
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
              ${boardState},
              ${host_username}, 
              NOW(),
              NOW()
            )
            RETURNING *
          `;
          
          console.log(`✅ Game session created successfully! ID: ${session[0].id}`);
          
          return {
            statusCode: 201,
            headers,
            body: JSON.stringify({ 
              success: true,
              message: 'Game session created successfully',
              session_id: session[0].id,
              session: session[0] 
            }),
          };
        } catch (sessionError) {
          console.error('❌ Error creating game session:', sessionError);
          console.error('Error details:', {
            message: sessionError.message,
            code: sessionError.code,
            detail: sessionError.detail
          });
          
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to create game session', 
              details: sessionError.message,
              hint: sessionError.code === '42P01' 
                ? 'Table game_sessions does not exist. Run setup-database.sql first.'
                : 'Check database connection and table structure'
            }),
          };
        }
      }

      // JOIN SESSION
      if (action === 'join_session') {
        const { session_id, username } = data;
        
        if (!session_id || !username) {
          console.error('❌ JOIN SESSION FAILED: Missing required fields');
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing session_id or username' }),
          };
        }
        
        console.log(`🎮 User ${username} attempting to join session ${session_id}`);
        
        try {
          // Check if session exists and is available
          const existingSession = await sql`
            SELECT * FROM game_sessions 
            WHERE id = ${session_id} 
            LIMIT 1
          `;
          
          if (existingSession.length === 0) {
            console.error(`❌ Session ${session_id} not found`);
            return {
              statusCode: 404,
              headers,
              body: JSON.stringify({ error: 'Game session not found' }),
            };
          }
          
          const session = existingSession[0];
          
          // Validate session status
          if (session.status !== 'waiting') {
            console.error(`❌ Session ${session_id} is not available (status: ${session.status})`);
            return {
              statusCode: 400,
              headers,
              body: JSON.stringify({ 
                error: 'Game session is not available',
                status: session.status 
              }),
            };
          }
          
          // Prevent host from joining own game
          if (session.host_username === username) {
            console.error(`❌ Host ${username} cannot join own game`);
            return {
              statusCode: 400,
              headers,
              body: JSON.stringify({ error: 'Cannot join your own game session' }),
            };
          }
          
          // Update session with guest
          const updated = await sql`
            UPDATE game_sessions
            SET guest_username = ${username}, 
                status = 'active',
                updated_at = NOW()
            WHERE id = ${session_id}
            RETURNING *
          `;
          
          console.log(`✅ User ${username} joined session ${session_id} successfully`);
          
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
              success: true,
              message: 'Successfully joined game session', 
              session_id,
              session: updated[0]
            }),
          };
        } catch (joinError) {
          console.error('❌ Error joining session:', joinError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to join game session',
              details: joinError.message
            }),
          };
        }
      }

      // LIST AVAILABLE SESSIONS (POST support)
      if (action === 'list_sessions') {
        try {
          console.log('📋 Fetching available game sessions...');
          
          const sessions = await sql`
            SELECT 
              gs.*,
              u.level as host_level,
              u.total_wins as host_wins
            FROM game_sessions gs
            JOIN users u ON gs.host_username = u.username
            WHERE gs.status = 'waiting'
            ORDER BY gs.created_at DESC
            LIMIT 20
          `;
          
          console.log(`✅ Found ${sessions.length} available sessions`);
          
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
              success: true,
              count: sessions.length,
              sessions 
            }),
          };
        } catch (listError) {
          console.error('❌ Error listing sessions:', listError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to list game sessions',
              details: listError.message,
              hint: listError.code === '42P01' 
                ? 'Table game_sessions does not exist. Run setup-database.sql first.'
                : null
            }),
          };
        }
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
        
        if (!sessionId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing session_id parameter' }),
          };
        }
        
        try {
          const session = await sql`
            SELECT 
              gs.*,
              h.level as host_level,
              h.avatar_url as host_avatar,
              g.level as guest_level,
              g.avatar_url as guest_avatar
            FROM game_sessions gs
            LEFT JOIN users h ON gs.host_username = h.username
            LEFT JOIN users g ON gs.guest_username = g.username
            WHERE gs.id = ${sessionId}
            LIMIT 1
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
            body: JSON.stringify({ 
              success: true,
              session: session[0] 
            }),
          };
        } catch (stateError) {
          console.error('❌ Error getting session state:', stateError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to get session state',
              details: stateError.message
            }),
          };
        }
      }

      // LIST AVAILABLE SESSIONS
      if (action === 'list_sessions') {
        try {
          console.log('📋 Fetching available game sessions (GET)...');
          
          const sessions = await sql`
            SELECT 
              gs.*,
              u.level as host_level,
              u.total_wins as host_wins,
              u.avatar_url as host_avatar
            FROM game_sessions gs
            JOIN users u ON gs.host_username = u.username
            WHERE gs.status = 'waiting'
            ORDER BY gs.created_at DESC
            LIMIT 20
          `;
          
          console.log(`✅ Found ${sessions.length} available sessions`);
          
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
              success: true,
              count: sessions.length,
              sessions 
            }),
          };
        } catch (listError) {
          console.error('❌ Error listing sessions:', listError);
          return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
              error: 'Failed to list game sessions',
              details: listError.message
            }),
          };
        }
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
