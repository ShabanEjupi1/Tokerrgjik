import { neon } from '@neondatabase/serverless';

const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

const sql = connectionString ? neon(connectionString) : null;

/**
 * Challenges endpoint handler
 * Manages game challenges between friends
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  try {
    if (!sql) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Database not configured. Set NEON_DATABASE_URL in Netlify environment variables.' 
        }),
      };
    }

    // POST - Send or respond to challenge
    if (event.httpMethod === 'POST') {
      const data = JSON.parse(event.body);
      const { action, from_username, to_username, challenge_id, session_id } = data;

      // SEND CHALLENGE
      if (action === 'send' || !action) {
        if (!from_username || !to_username) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing from_username or to_username' }),
          };
        }

        // Verify both users exist and are friends
        const friendship = await sql`
          SELECT * FROM friends 
          WHERE ((user_username = ${from_username} AND friend_username = ${to_username})
             OR (user_username = ${to_username} AND friend_username = ${from_username}))
            AND status = 'accepted'
        `;

        if (friendship.length === 0) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Users are not friends' }),
          };
        }

        // Check if there's already a pending challenge
        const existingChallenge = await sql`
          SELECT * FROM challenges
          WHERE from_username = ${from_username} 
            AND to_username = ${to_username}
            AND status = 'pending'
        `;

        if (existingChallenge.length > 0) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ 
              error: 'Challenge already sent',
              challenge_id: existingChallenge[0].id 
            }),
          };
        }

        // Create challenge
        const challenge = await sql`
          INSERT INTO challenges (from_username, to_username, status, session_id, created_at)
          VALUES (${from_username}, ${to_username}, 'pending', ${session_id || null}, NOW())
          RETURNING *
        `;

        console.log(`✅ Challenge sent from ${from_username} to ${to_username}`);

        return {
          statusCode: 201,
          headers,
          body: JSON.stringify({ 
            success: true,
            message: 'Challenge sent successfully',
            challenge: challenge[0]
          }),
        };
      }

      // ACCEPT CHALLENGE
      if (action === 'accept') {
        if (!challenge_id || !to_username) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing challenge_id or to_username' }),
          };
        }

        const result = await sql`
          UPDATE challenges
          SET status = 'accepted', responded_at = NOW()
          WHERE id = ${challenge_id} 
            AND to_username = ${to_username}
            AND status = 'pending'
          RETURNING *
        `;

        if (result.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Challenge not found or already responded' }),
          };
        }

        console.log(`✅ Challenge ${challenge_id} accepted by ${to_username}`);

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            message: 'Challenge accepted',
            challenge: result[0]
          }),
        };
      }

      // DECLINE CHALLENGE
      if (action === 'decline') {
        if (!challenge_id || !to_username) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing challenge_id or to_username' }),
          };
        }

        const result = await sql`
          UPDATE challenges
          SET status = 'declined', responded_at = NOW()
          WHERE id = ${challenge_id} 
            AND to_username = ${to_username}
            AND status = 'pending'
          RETURNING *
        `;

        if (result.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Challenge not found or already responded' }),
          };
        }

        console.log(`✅ Challenge ${challenge_id} declined by ${to_username}`);

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            message: 'Challenge declined'
          }),
        };
      }

      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid action' }),
      };
    }

    // GET - Get challenges for a user
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

      // GET RECEIVED CHALLENGES (pending)
      if (action === 'received' || !action) {
        const challenges = await sql`
          SELECT 
            c.*,
            u.level as from_level,
            u.avatar_url as from_avatar,
            u.total_wins as from_wins
          FROM challenges c
          LEFT JOIN users u ON c.from_username = u.username
          WHERE c.to_username = ${username} 
            AND c.status = 'pending'
          ORDER BY c.created_at DESC
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            challenges
          }),
        };
      }

      // GET SENT CHALLENGES
      if (action === 'sent') {
        const challenges = await sql`
          SELECT 
            c.*,
            u.level as to_level,
            u.avatar_url as to_avatar,
            u.total_wins as to_wins
          FROM challenges c
          LEFT JOIN users u ON c.to_username = u.username
          WHERE c.from_username = ${username} 
            AND c.status = 'pending'
          ORDER BY c.created_at DESC
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            challenges
          }),
        };
      }

      // GET CHALLENGE COUNT
      if (action === 'count') {
        const result = await sql`
          SELECT COUNT(*) as count
          FROM challenges
          WHERE to_username = ${username}
            AND status = 'pending'
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            count: parseInt(result[0].count)
          }),
        };
      }

      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid action' }),
      };
    }

    // DELETE - Cancel challenge
    if (event.httpMethod === 'DELETE') {
      const params = new URL(event.rawUrl).searchParams;
      const challenge_id = params.get('challenge_id');
      const username = params.get('username');

      if (!challenge_id || !username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing challenge_id or username' }),
        };
      }

      // Only the sender can cancel
      const result = await sql`
        DELETE FROM challenges
        WHERE id = ${challenge_id}
          AND from_username = ${username}
          AND status = 'pending'
        RETURNING *
      `;

      if (result.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'Challenge not found or cannot be cancelled' }),
        };
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ 
          success: true,
          message: 'Challenge cancelled'
        }),
      };
    }

    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };

  } catch (error) {
    console.error('Challenges error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error', 
        message: error.message 
      }),
    };
  }
}
