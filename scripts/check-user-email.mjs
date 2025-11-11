/**
 * Check if test user exists and has email
 */

import { neon } from '@neondatabase/serverless';
import 'dotenv/config';

const sql = neon(process.env.NEON_DATABASE_URL);

const TEST_USERNAME = 'ArbenChampion790';

console.log('🔍 Checking user:', TEST_USERNAME);
console.log('');

try {
  const user = await sql`
    SELECT id, username, email, created_at 
    FROM users 
    WHERE username = ${TEST_USERNAME}
  `;
  
  if (user.length === 0) {
    console.log('❌ User not found!');
    console.log('');
    console.log('Available users:');
    const users = await sql`SELECT username, email FROM users LIMIT 10`;
    console.table(users);
  } else {
    console.log('✅ User found:');
    console.table(user);
    
    if (!user[0].email) {
      console.log('');
      console.log('⚠️  WARNING: User has no email address!');
      console.log('This is why emails show "to": null');
      console.log('');
      console.log('To fix: Update user with email address');
    } else {
      console.log('');
      console.log('✅ User has email:', user[0].email);
    }
  }
} catch (error) {
  console.error('❌ Error:', error.message);
}
