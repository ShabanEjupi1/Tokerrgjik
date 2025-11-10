#!/usr/bin/env node

/**
 * Quick fix for remaining database issues
 */

import { neon } from '@neondatabase/serverless';

const DATABASE_URL = process.env.NEON_DATABASE_URL || process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('❌ Set NEON_DATABASE_URL first!');
  process.exit(1);
}

const sql = neon(DATABASE_URL);

async function quickFix() {
  console.log('🔧 Applying quick fixes...\n');
  
  try {
    // Fix 1: Add total_games to users
    console.log('Adding users.total_games column...');
    await sql`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0
    `;
    console.log('✅ users.total_games added\n');
    
    // Fix 2: Add updated_at to transactions if table exists
    console.log('Checking transactions table...');
    const hasTransactions = await sql`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'transactions'
      )
    `;
    
    if (hasTransactions[0].exists) {
      console.log('Adding transactions.updated_at column...');
      await sql`
        ALTER TABLE transactions 
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()
      `;
      console.log('✅ transactions.updated_at added\n');
    } else {
      console.log('⚠️  transactions table does not exist (OK for now)\n');
    }
    
    // Fix 3: Update total_games for existing users based on game_history
    console.log('Updating total_games counts from game_history...');
    await sql`
      UPDATE users 
      SET total_games = (
        SELECT COUNT(*) 
        FROM game_history 
        WHERE game_history.username = users.username
      )
      WHERE total_games = 0
    `;
    console.log('✅ total_games updated\n');
    
    // Verify
    console.log('📊 Verification:');
    const result = await sql`
      SELECT 
        COUNT(*) as user_count,
        SUM(total_games) as total_games_played
      FROM users
    `;
    console.log(`   Users: ${result[0].user_count}`);
    console.log(`   Total games played: ${result[0].total_games_played}`);
    
    console.log('\n✅ All fixes applied successfully!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

quickFix();
