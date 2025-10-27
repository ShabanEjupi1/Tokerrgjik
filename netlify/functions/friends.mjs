import { neon } from '@neondatabase/serverless';

const connectionString = process.env.NEON_DATABASE_URL 
  || process.env.NETLIFY_DATABASE_URL 
  || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set NEON_DATABASE_URL in Netlify.');
}

const sql = connectionString ? neon(connectionString) : null;

/**
 * Friends endpoint handler
 * Manages friend relationships using the friends table:
 * - id (UUID)
 * - user_username (VARCHAR 50)
 * - friend_username (VARCHAR 50)
 * - status (VARCHAR 20) - 'pending', 'accepted', 'rejected'
 * - created_at (TIMESTAMP)
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

    // POST - Send friend request or accept/reject
    if (event.httpMethod === 'POST') {
      const data = JSON.parse(event.body);
      const { action, user_username, friend_username } = data;

      if (!user_username || !friend_username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing user_username or friend_username' }),
        };
      }

      // SEND FRIEND REQUEST
      if (action === 'send_request' || !action) {
        // Check if friendship already exists
        const existing = await sql`
          SELECT * FROM friends 
          WHERE (user_username = ${user_username} AND friend_username = ${friend_username})
             OR (user_username = ${friend_username} AND friend_username = ${user_username})
        `;

        if (existing.length > 0) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Friend request already exists' }),
          };
        }

        // Create new friend request
        const result = await sql`
          INSERT INTO friends (user_username, friend_username, status)
          VALUES (${user_username}, ${friend_username}, 'pending')
          RETURNING *
        `;

        return {
          statusCode: 201,
          headers,
          body: JSON.stringify({ message: 'Friend request sent', friend_request: result[0] }),
        };
      }

      // ACCEPT FRIEND REQUEST
      if (action === 'accept') {
        const result = await sql`
          UPDATE friends
          SET status = 'accepted'
          WHERE friend_username = ${user_username} 
            AND user_username = ${friend_username}
            AND status = 'pending'
          RETURNING *
        `;

        if (result.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Friend request not found' }),
          };
        }

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Friend request accepted', friendship: result[0] }),
        };
      }

      // REJECT FRIEND REQUEST
      if (action === 'reject') {
        const result = await sql`
          UPDATE friends
          SET status = 'rejected'
          WHERE friend_username = ${user_username} 
            AND user_username = ${friend_username}
            AND status = 'pending'
          RETURNING *
        `;

        if (result.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Friend request not found' }),
          };
        }

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Friend request rejected' }),
        };
      }

      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid action' }),
      };
    }

    // GET - Get friends list, pending requests, etc.
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

      // GET ALL FRIENDS (accepted only)
      if (action === 'list' || !action) {
        const friends = await sql`
          SELECT 
            f.*,
            u.level as friend_level,
            u.xp as friend_xp,
            u.total_wins as friend_wins,
            u.avatar_url as friend_avatar
          FROM friends f
          LEFT JOIN users u ON (
            CASE 
              WHEN f.user_username = ${username} THEN u.username = f.friend_username
              ELSE u.username = f.user_username
            END
          )
          WHERE (f.user_username = ${username} OR f.friend_username = ${username})
            AND f.status = 'accepted'
          ORDER BY f.created_at DESC
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ friends }),
        };
      }

      // GET PENDING REQUESTS (sent to me)
      if (action === 'pending') {
        const requests = await sql`
          SELECT 
            f.*,
            u.level as sender_level,
            u.xp as sender_xp,
            u.avatar_url as sender_avatar
          FROM friends f
          LEFT JOIN users u ON u.username = f.user_username
          WHERE f.friend_username = ${username} 
            AND f.status = 'pending'
          ORDER BY f.created_at DESC
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ pending_requests: requests }),
        };
      }

      // GET SENT REQUESTS (sent by me)
      if (action === 'sent') {
        const requests = await sql`
          SELECT 
            f.*,
            u.level as recipient_level,
            u.xp as recipient_xp,
            u.avatar_url as recipient_avatar
          FROM friends f
          LEFT JOIN users u ON u.username = f.friend_username
          WHERE f.user_username = ${username} 
            AND f.status = 'pending'
          ORDER BY f.created_at DESC
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ sent_requests: requests }),
        };
      }

      // GET FRIEND COUNT
      if (action === 'count') {
        const result = await sql`
          SELECT COUNT(*) as count
          FROM friends
          WHERE (user_username = ${username} OR friend_username = ${username})
            AND status = 'accepted'
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ friends_count: parseInt(result[0].count) }),
        };
      }

      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid action' }),
      };
    }

    // DELETE - Remove friend or cancel request
    if (event.httpMethod === 'DELETE') {
      const params = new URL(event.rawUrl).searchParams;
      const user_username = params.get('user_username');
      const friend_username = params.get('friend_username');

      if (!user_username || !friend_username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing user_username or friend_username' }),
        };
      }

      // Delete friendship (works for both directions)
      const result = await sql`
        DELETE FROM friends
        WHERE (user_username = ${user_username} AND friend_username = ${friend_username})
           OR (user_username = ${friend_username} AND friend_username = ${user_username})
        RETURNING *
      `;

      if (result.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'Friendship not found' }),
        };
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ message: 'Friendship removed' }),
      };
    }

    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };

  } catch (error) {
    console.error('Friends error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: error.message }),
    };
  }
}
