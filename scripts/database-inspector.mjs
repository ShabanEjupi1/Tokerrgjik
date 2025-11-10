#!/usr/bin/env node

/**
 * Database Inspector & Fixer
 * Inspects the Neon database structure and applies fixes
 */

import { neon } from '@neondatabase/serverless';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load database URL from environment
const DATABASE_URL = process.env.NEON_DATABASE_URL || process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('❌ ERROR: NEON_DATABASE_URL environment variable not set!');
  console.log('\n💡 Set it using:');
  console.log('   $env:NEON_DATABASE_URL="your-neon-connection-string"');
  process.exit(1);
}

const sql = neon(DATABASE_URL);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(msg, color = 'reset') {
  console.log(`${colors[color]}${msg}${colors.reset}`);
}

/**
 * Inspect database structure
 */
async function inspectDatabase() {
  log('\n🔍 INSPECTING DATABASE STRUCTURE\n', 'cyan');
  
  try {
    // Get all tables
    const tables = await sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `;
    
    log(`📊 Found ${tables.length} tables:`, 'blue');
    tables.forEach(t => log(`   ✓ ${t.table_name}`, 'green'));
    
    // Check each important table structure
    const criticalTables = ['users', 'game_sessions', 'friends', 'game_history'];
    
    for (const tableName of criticalTables) {
      const tableExists = tables.some(t => t.table_name === tableName);
      
      if (!tableExists) {
        log(`\n⚠️  Table "${tableName}" does NOT exist!`, 'red');
        continue;
      }
      
      log(`\n📋 Table: ${tableName}`, 'yellow');
      
      const columns = await sql`
        SELECT 
          column_name, 
          data_type, 
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_name = ${tableName}
        ORDER BY ordinal_position
      `;
      
      columns.forEach(col => {
        const nullable = col.is_nullable === 'YES' ? '(nullable)' : '(NOT NULL)';
        const defaultVal = col.column_default ? ` [default: ${col.column_default}]` : '';
        log(`   • ${col.column_name}: ${col.data_type} ${nullable}${defaultVal}`);
      });
    }
    
    // Check for specific missing columns
    await checkMissingColumns();
    
    // Check sample data
    await checkSampleData();
    
    return true;
  } catch (error) {
    log(`\n❌ Error inspecting database: ${error.message}`, 'red');
    console.error(error);
    return false;
  }
}

/**
 * Check for missing columns that are causing errors
 */
async function checkMissingColumns() {
  log('\n🔎 CHECKING FOR MISSING COLUMNS\n', 'cyan');
  
  const checks = [
    { table: 'game_sessions', column: 'updated_at', type: 'TIMESTAMP' },
    { table: 'users', column: 'updated_at', type: 'TIMESTAMP' },
    { table: 'transactions', column: 'updated_at', type: 'TIMESTAMP' },
  ];
  
  for (const check of checks) {
    try {
      const result = await sql`
        SELECT EXISTS (
          SELECT 1 
          FROM information_schema.columns 
          WHERE table_name = ${check.table} 
            AND column_name = ${check.column}
        ) as exists
      `;
      
      if (result[0].exists) {
        log(`   ✅ ${check.table}.${check.column} exists`, 'green');
      } else {
        log(`   ❌ ${check.table}.${check.column} MISSING!`, 'red');
      }
    } catch (error) {
      log(`   ⚠️  Could not check ${check.table}.${check.column}`, 'yellow');
    }
  }
}

/**
 * Check sample data in tables
 */
async function checkSampleData() {
  log('\n📊 CHECKING SAMPLE DATA\n', 'cyan');
  
  try {
    const userCount = await sql`SELECT COUNT(*) as count FROM users`;
    log(`   Users: ${userCount[0].count}`, userCount[0].count > 0 ? 'green' : 'yellow');
    
    if (userCount[0].count > 0) {
      const sampleUsers = await sql`SELECT username, email, level, total_games FROM users LIMIT 5`;
      sampleUsers.forEach(u => {
        log(`      • ${u.username} (level ${u.level}, ${u.total_games} games)`);
      });
    }
    
    const friendsCount = await sql`SELECT COUNT(*) as count FROM friends`;
    log(`   Friends: ${friendsCount[0].count}`, friendsCount[0].count > 0 ? 'green' : 'yellow');
    
    const sessionsCount = await sql`SELECT COUNT(*) as count FROM game_sessions`;
    log(`   Game Sessions: ${sessionsCount[0].count}`, sessionsCount[0].count > 0 ? 'green' : 'yellow');
    
    const historyCount = await sql`SELECT COUNT(*) as count FROM game_history`;
    log(`   Game History: ${historyCount[0].count}`, historyCount[0].count > 0 ? 'green' : 'yellow');
    
  } catch (error) {
    log(`   ⚠️  Error checking data: ${error.message}`, 'yellow');
  }
}

/**
 * Fix missing columns in database
 */
async function fixDatabase() {
  log('\n🔧 FIXING DATABASE ISSUES\n', 'cyan');
  
  try {
    // Fix 1: Add updated_at to game_sessions if missing
    log('📝 Adding missing columns...', 'yellow');
    
    await sql`
      DO $$ 
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='game_sessions' AND column_name='updated_at'
        ) THEN
          ALTER TABLE game_sessions ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
          RAISE NOTICE 'Added updated_at to game_sessions';
        END IF;
      END $$;
    `;
    log('   ✅ game_sessions.updated_at checked/added', 'green');
    
    await sql`
      DO $$ 
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='users' AND column_name='updated_at'
        ) THEN
          ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
          RAISE NOTICE 'Added updated_at to users';
        END IF;
      END $$;
    `;
    log('   ✅ users.updated_at checked/added', 'green');
    
    // Fix 2: Create triggers for auto-updating updated_at
    log('\n📝 Creating/updating triggers...', 'yellow');
    
    await sql`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
      END;
      $$ language 'plpgsql';
    `;
    
    await sql`
      DROP TRIGGER IF EXISTS update_game_sessions_updated_at ON game_sessions;
      CREATE TRIGGER update_game_sessions_updated_at 
          BEFORE UPDATE ON game_sessions 
          FOR EACH ROW 
          EXECUTE FUNCTION update_updated_at_column();
    `;
    log('   ✅ game_sessions trigger created', 'green');
    
    await sql`
      DROP TRIGGER IF EXISTS update_users_updated_at ON users;
      CREATE TRIGGER update_users_updated_at 
          BEFORE UPDATE ON users 
          FOR EACH ROW 
          EXECUTE FUNCTION update_updated_at_column();
    `;
    log('   ✅ users trigger created', 'green');
    
    log('\n✅ Database fixes applied successfully!', 'green');
    return true;
    
  } catch (error) {
    log(`\n❌ Error fixing database: ${error.message}`, 'red');
    console.error(error);
    return false;
  }
}

/**
 * Run full database setup SQL script
 */
async function runFullSetup() {
  log('\n🚀 RUNNING FULL DATABASE SETUP\n', 'cyan');
  
  try {
    const sqlPath = join(__dirname, '..', 'database-setup.sql');
    log(`📄 Reading SQL file: ${sqlPath}`, 'blue');
    
    const setupSQL = readFileSync(sqlPath, 'utf8');
    
    // Split by semicolons but keep multi-line statements together
    const statements = setupSQL
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));
    
    log(`📝 Executing ${statements.length} SQL statements...\n`, 'yellow');
    
    let successCount = 0;
    let errorCount = 0;
    
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.length < 10) continue; // Skip empty/comment lines
      
      try {
        // For DO blocks and CREATE statements, execute directly
        if (statement.includes('DO $$') || statement.startsWith('CREATE') || 
            statement.startsWith('DROP') || statement.startsWith('INSERT')) {
          await sql.unsafe(statement);
          successCount++;
          if (statement.includes('CREATE TABLE') || statement.includes('CREATE TRIGGER')) {
            const match = statement.match(/CREATE (?:TABLE|TRIGGER|FUNCTION|VIEW|INDEX).*?(\w+)/i);
            if (match) {
              log(`   ✓ Created/updated: ${match[1]}`, 'green');
            }
          }
        }
      } catch (error) {
        errorCount++;
        if (error.message.includes('already exists')) {
          // Ignore "already exists" errors
          log(`   ℹ️  Already exists (skipped)`, 'blue');
        } else {
          log(`   ⚠️  Error: ${error.message.substring(0, 80)}...`, 'yellow');
        }
      }
    }
    
    log(`\n📊 Setup completed:`, 'cyan');
    log(`   ✅ Successful: ${successCount}`, 'green');
    log(`   ⚠️  Errors/Skipped: ${errorCount}`, errorCount > 0 ? 'yellow' : 'green');
    
    return true;
    
  } catch (error) {
    log(`\n❌ Error running setup: ${error.message}`, 'red');
    console.error(error);
    return false;
  }
}

/**
 * Test database connectivity
 */
async function testConnection() {
  log('\n🔌 TESTING DATABASE CONNECTION\n', 'cyan');
  
  try {
    const result = await sql`SELECT NOW() as current_time, version() as pg_version`;
    log(`   ✅ Connection successful!`, 'green');
    log(`   ⏰ Server time: ${result[0].current_time}`);
    log(`   🐘 PostgreSQL version: ${result[0].pg_version.split(',')[0]}`);
    return true;
  } catch (error) {
    log(`   ❌ Connection failed: ${error.message}`, 'red');
    return false;
  }
}

/**
 * Main menu
 */
async function main() {
  log('\n' + '='.repeat(60), 'cyan');
  log('   🗄️  TOKERRGJIK DATABASE INSPECTOR & FIXER', 'cyan');
  log('='.repeat(60) + '\n', 'cyan');
  
  const args = process.argv.slice(2);
  const command = args[0] || 'inspect';
  
  // Test connection first
  const connected = await testConnection();
  if (!connected) {
    log('\n❌ Cannot proceed without database connection!', 'red');
    process.exit(1);
  }
  
  switch (command) {
    case 'inspect':
    case 'check':
      await inspectDatabase();
      break;
      
    case 'fix':
      await fixDatabase();
      log('\n🔍 Re-inspecting after fixes...', 'blue');
      await inspectDatabase();
      break;
      
    case 'setup':
    case 'full':
      await runFullSetup();
      log('\n🔍 Inspecting database after setup...', 'blue');
      await inspectDatabase();
      break;
      
    case 'all':
      await inspectDatabase();
      log('\n' + '='.repeat(60) + '\n');
      await fixDatabase();
      log('\n' + '='.repeat(60) + '\n');
      await inspectDatabase();
      break;
      
    default:
      log('❌ Unknown command: ' + command, 'red');
      log('\n📖 Usage:', 'yellow');
      log('   node database-inspector.mjs [command]');
      log('\n📋 Commands:', 'yellow');
      log('   inspect (default) - Inspect database structure');
      log('   fix              - Fix missing columns and triggers');
      log('   setup            - Run full database setup script');
      log('   all              - Inspect + Fix + Re-inspect');
      process.exit(1);
  }
  
  log('\n✨ Done!\n', 'green');
}

// Run the script
main().catch(error => {
  console.error('\n❌ Fatal error:', error);
  process.exit(1);
});
