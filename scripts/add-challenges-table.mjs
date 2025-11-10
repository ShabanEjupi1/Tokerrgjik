#!/usr/bin/env node

/**
 * Add challenges table to database
 */

import { neon } from '@neondatabase/serverless';

const DATABASE_URL = process.env.NEON_DATABASE_URL || process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('❌ Set NEON_DATABASE_URL first!');
  console.error('   Run this via Netlify CLI: netlify env:import .env');
  process.exit(1);
}

const sql = neon(DATABASE_URL);

async function addChallengesTable() {
  console.log('🔧 Adding challenges table...\n');
  
  try {
    // Create challenges table
    console.log('Creating challenges table...');
    await sql`
      CREATE TABLE IF NOT EXISTS challenges (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        from_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
        to_username VARCHAR(50) NOT NULL REFERENCES users(username) ON DELETE CASCADE,
        session_id UUID REFERENCES game_sessions(id) ON DELETE SET NULL,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
        created_at TIMESTAMP DEFAULT NOW(),
        responded_at TIMESTAMP
      )
    `;
    console.log('✅ challenges table created\n');
    
    // Create indexes
    console.log('Creating indexes...');
    await sql`CREATE INDEX IF NOT EXISTS idx_challenges_from ON challenges(from_username)`;
    await sql`CREATE INDEX IF NOT EXISTS idx_challenges_to ON challenges(to_username)`;
    await sql`CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status)`;
    await sql`CREATE INDEX IF NOT EXISTS idx_challenges_created ON challenges(created_at DESC)`;
    console.log('✅ Indexes created\n');
    
    // Verify
    console.log('📊 Verification:');
    const result = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns
      WHERE table_name = 'challenges'
      ORDER BY ordinal_position
    `;
    
    console.log('Challenges table structure:');
    result.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type}`);
    });
    
    console.log('\n✅ Challenges table added successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Deploy the updated Netlify functions');
    console.log('   2. Test challenge sending from the mobile app');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\nNote: If table already exists, this is expected.');
    process.exit(1);
  }
}

addChallengesTable();
