import { neon } from './db.mjs';

const connectionString = process.env.DATABASE_URL;

const sql = connectionString ? neon(connectionString) : null;

// PayPal Credentials (MUST be set in Netlify environment variables)
const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID;
const PAYPAL_SECRET = process.env.PAYPAL_SECRET;
const PAYPAL_API_URL = process.env.PAYPAL_MODE === 'production' 
  ? 'https://api-m.paypal.com' 
  : 'https://api-m.sandbox.paypal.com';

/**
 * PayPal Payment Verification Handler
 * 
 * IMPORTANT: This function verifies payments SERVER-SIDE to prevent fraud
 * Never trust client-side payment confirmations!
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    // Check if database is configured
    if (!sql) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ error: 'Database not configured' }),
      };
    }

    // Check if PayPal is configured
    if (!PAYPAL_CLIENT_ID || !PAYPAL_SECRET) {
      console.error('❌ PayPal not configured! Set PAYPAL_CLIENT_ID and PAYPAL_SECRET');
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'PayPal payment system is not configured. Please contact support.',
          debug: {
            hasClientId: !!PAYPAL_CLIENT_ID,
            hasSecret: !!PAYPAL_SECRET,
            mode: process.env.PAYPAL_MODE || 'sandbox'
          }
        }),
      };
    }

    const { action, order_id, username, package_id } = JSON.parse(event.body || '{}');

    // ===== VERIFY PAYMENT =====
    if (action === 'verify_payment') {
      if (!order_id || !username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing order_id or username' }),
        };
      }

      // Step 1: Get PayPal Access Token
      console.log('Requesting PayPal access token...');
      
      // Create base64 encoded credentials for Basic Auth
      // Note: btoa() works in serverless edge functions, Buffer.from() doesn't
      const credentials = btoa(`${PAYPAL_CLIENT_ID}:${PAYPAL_SECRET}`);
      
      const authResponse = await fetch(`${PAYPAL_API_URL}/v1/oauth2/token`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      });

      if (!authResponse.ok) {
        const errorData = await authResponse.text();
        console.error('Failed to get PayPal token:', errorData);
        return {
          statusCode: 500,
          headers,
          body: JSON.stringify({ 
            error: 'Payment verification failed - Could not authenticate with PayPal',
            details: 'Check PayPal credentials in Netlify environment variables'
          }),
        };
      }

      const authData = await authResponse.json();
      const accessToken = authData.access_token;
      console.log('PayPal access token obtained successfully');

      // Step 2: Verify order with PayPal
      console.log(`Verifying PayPal order: ${order_id}`);
      const orderResponse = await fetch(`${PAYPAL_API_URL}/v2/checkout/orders/${order_id}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (!orderResponse.ok) {
        const errorData = await orderResponse.text();
        console.error('Failed to verify order with PayPal:', errorData);
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ 
            error: 'Invalid payment order',
            details: 'Order verification failed with PayPal'
          }),
        };
      }

      const orderData = await orderResponse.json();
      console.log('PayPal order status:', orderData.status);

      // Step 3: Verify payment was completed
      if (orderData.status !== 'COMPLETED') {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ 
            error: 'Payment not completed',
            status: orderData.status 
          }),
        };
      }

      // Step 4: Check amount matches package price
      const amount = parseFloat(orderData.purchase_units[0].amount.value);
      const packagePrices = {
        'pro_monthly': 4.99,
        'pro_yearly': 39.99,
        'coins_100': 0.99,
        'coins_500': 3.99,
        'coins_1000': 6.99,
      };

      const expectedPrice = packagePrices[package_id];
      if (!expectedPrice || Math.abs(amount - expectedPrice) > 0.01) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ 
            error: 'Payment amount mismatch',
            expected: expectedPrice,
            received: amount,
          }),
        };
      }

      // Step 5: Update user in database
      if (package_id === 'pro_monthly' || package_id === 'pro_yearly') {
        // Grant Pro access
        const expiresAt = new Date();
        expiresAt.setMonth(expiresAt.getMonth() + (package_id === 'pro_yearly' ? 12 : 1));

        await sql`
          UPDATE users 
          SET is_pro = true, 
              pro_expires_at = ${expiresAt.toISOString()},
              updated_at = NOW()
          WHERE username = ${username}
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            message: 'Pro membership activated!',
            expires_at: expiresAt.toISOString(),
          }),
        };
      } else {
        // Grant coins
        const coinAmounts = {
          'coins_100': 100,
          'coins_500': 500,
          'coins_1000': 1000,
        };

        const coinsToAdd = coinAmounts[package_id];

        const result = await sql`
          UPDATE users 
          SET coins = coins + ${coinsToAdd},
              updated_at = NOW()
          WHERE username = ${username}
          RETURNING coins
        `;

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ 
            success: true,
            message: `${coinsToAdd} coins added!`,
            new_balance: result[0].coins,
          }),
        };
      }
    }

    // ===== CHECK PRO STATUS =====
    if (action === 'check_pro_status') {
      if (!username) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing username' }),
        };
      }

      const user = await sql`
        SELECT is_pro, pro_expires_at 
        FROM users 
        WHERE username = ${username}
        LIMIT 1
      `;

      if (user.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: 'User not found' }),
        };
      }

      const isPro = user[0].is_pro && 
        (user[0].pro_expires_at ? new Date(user[0].pro_expires_at) > new Date() : false);

      // Update if expired
      if (user[0].is_pro && !isPro) {
        await sql`
          UPDATE users 
          SET is_pro = false
          WHERE username = ${username}
        `;
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ 
          is_pro: isPro,
          expires_at: user[0].pro_expires_at,
        }),
      };
    }

    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ error: 'Invalid action' }),
    };

  } catch (error) {
    console.error('Payment handler error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error.message,
      }),
    };
  }
}
