#!/usr/bin/env node

/**
 * Complete status check for TokerrGjik deployment
 */

import { neon } from '@neondatabase/serverless';

const DATABASE_URL = process.env.NEON_DATABASE_URL || process.env.DATABASE_URL;
const API_BASE = 'https://tokerrgjik.netlify.app/.netlify/functions';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m',
};

function log(msg, color = 'reset') {
  console.log(`${colors[color]}${msg}${colors.reset}`);
}

async function checkDatabase() {
  log('\n' + '='.repeat(70), 'cyan');
  log('📊 DATABASE STATUS CHECK', 'bold');
  log('='.repeat(70), 'cyan');
  
  if (!DATABASE_URL) {
    log('\n❌ No database connection configured', 'red');
    log('   Set NEON_DATABASE_URL environment variable', 'yellow');
    return false;
  }
  
  try {
    const sql = neon(DATABASE_URL);
    
    // Connection test
    log('\n🔌 Testing connection...', 'blue');
    await sql`SELECT NOW()`;
    log('   ✅ Database connected', 'green');
    
    // Table check
    log('\n📋 Checking tables...', 'blue');
    const tables = await sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `;
    log(`   ✅ Found ${tables.length} tables`, 'green');
    
    // Critical columns check
    log('\n🔍 Verifying critical columns...', 'blue');
    const checks = [
      { table: 'game_sessions', column: 'updated_at' },
      { table: 'users', column: 'updated_at' },
      { table: 'users', column: 'total_games' },
    ];
    
    let allGood = true;
    for (const check of checks) {
      const result = await sql`
        SELECT EXISTS (
          SELECT 1 
          FROM information_schema.columns 
          WHERE table_name = ${check.table} 
            AND column_name = ${check.column}
        ) as exists
      `;
      
      if (result[0].exists) {
        log(`   ✅ ${check.table}.${check.column}`, 'green');
      } else {
        log(`   ❌ ${check.table}.${check.column} MISSING!`, 'red');
        allGood = false;
      }
    }
    
    // Data check
    log('\n📊 Data summary...', 'blue');
    const users = await sql`SELECT COUNT(*) as count FROM users`;
    const friends = await sql`SELECT COUNT(*) as count FROM friends`;
    const sessions = await sql`SELECT COUNT(*) as count FROM game_sessions`;
    const history = await sql`SELECT COUNT(*) as count FROM game_history`;
    
    log(`   Users: ${users[0].count}`, 'green');
    log(`   Friends: ${friends[0].count}`, 'green');
    log(`   Game Sessions: ${sessions[0].count}`, 'green');
    log(`   Game History: ${history[0].count}`, 'green');
    
    return allGood;
    
  } catch (error) {
    log(`\n❌ Database error: ${error.message}`, 'red');
    return false;
  }
}

async function checkAPI() {
  log('\n' + '='.repeat(70), 'cyan');
  log('🌐 API ENDPOINTS STATUS CHECK', 'bold');
  log('='.repeat(70), 'cyan');
  
  const endpoints = [
    { name: 'Health', path: '/health', method: 'GET' },
    { name: 'Games List', path: '/games?action=list_sessions', method: 'GET' },
    { name: 'Friends', path: '/friends?username=test&action=list', method: 'GET' },
    { name: 'Leaderboard', path: '/leaderboard?limit=5', method: 'GET' },
  ];
  
  let working = 0;
  let failed = 0;
  
  for (const endpoint of endpoints) {
    try {
      const response = await fetch(`${API_BASE}${endpoint.path}`, {
        method: endpoint.method,
        headers: { 'Content-Type': 'application/json' }
      });
      
      if (response.ok) {
        log(`   ✅ ${endpoint.name} (${response.status})`, 'green');
        working++;
      } else {
        log(`   ❌ ${endpoint.name} (${response.status})`, 'red');
        failed++;
      }
    } catch (error) {
      log(`   ❌ ${endpoint.name} - ${error.message}`, 'red');
      failed++;
    }
  }
  
  log(`\n   Total: ${working}/${endpoints.length} working`, working === endpoints.length ? 'green' : 'yellow');
  
  return failed === 0;
}

async function checkNetlifyFunctions() {
  log('\n' + '='.repeat(70), 'cyan');
  log('⚡ NETLIFY FUNCTIONS CHECK', 'bold');
  log('='.repeat(70), 'cyan');
  
  const functions = [
    'achievements', 'ai-move', 'auth', 'avatars', 'email', 'friends',
    'games', 'health', 'leaderboard', 'payments', 'statistics', 'users'
  ];
  
  log('\n📦 Expected functions:', 'blue');
  functions.forEach(fn => log(`   • ${fn}`));
  
  log('\n💡 To verify deployment status:', 'yellow');
  log('   Run: netlify functions:list', 'cyan');
  
  return true;
}

async function showNextSteps(dbOk, apiOk) {
  log('\n' + '='.repeat(70), 'cyan');
  log('📝 NEXT STEPS', 'bold');
  log('='.repeat(70), 'cyan');
  
  if (dbOk && apiOk) {
    log('\n✨ All systems operational!', 'green');
    log('\n🎮 Ready to test from Flutter app:', 'blue');
    log('   1. Create a game session', 'cyan');
    log('   2. Send a friend request', 'cyan');
    log('   3. Check leaderboard', 'cyan');
    log('   4. Play a full game', 'cyan');
  } else {
    log('\n⚠️  Issues detected!', 'yellow');
    
    if (!dbOk) {
      log('\n🔧 Database fixes needed:', 'red');
      log('   Run: cd scripts && node database-inspector.mjs fix', 'cyan');
    }
    
    if (!apiOk) {
      log('\n🚀 Deployment needed:', 'red');
      log('   Run: netlify deploy --prod', 'cyan');
    }
  }
  
  log('\n📖 Documentation:', 'blue');
  log('   • DATABASE-FIX-SUMMARY.md - Complete fix summary', 'cyan');
  log('   • DATABASE-FIX-GUIDE.md - Step-by-step guide', 'cyan');
  log('   • database-setup.sql - Full schema', 'cyan');
  
  log('\n🛠️  Useful commands:', 'blue');
  log('   • node scripts/database-inspector.mjs inspect - Check database', 'cyan');
  log('   • node scripts/test-api.mjs - Test API endpoints', 'cyan');
  log('   • netlify functions:list - Check deployment', 'cyan');
  log('   • netlify functions:log games - View game logs', 'cyan');
}

async function main() {
  log('\n' + '═'.repeat(70), 'cyan');
  log('         🎮 TOKERRGJIK - SYSTEM STATUS CHECK 🎮', 'bold');
  log('═'.repeat(70) + '\n', 'cyan');
  
  const dbOk = await checkDatabase();
  const apiOk = await checkAPI();
  await checkNetlifyFunctions();
  await showNextSteps(dbOk, apiOk);
  
  log('\n' + '═'.repeat(70), 'cyan');
  
  if (dbOk && apiOk) {
    log('                    ✅ ALL SYSTEMS GO! ✅', 'green');
  } else {
    log('                   ⚠️  ACTION REQUIRED ⚠️', 'yellow');
  }
  
  log('═'.repeat(70) + '\n', 'cyan');
}

main().catch(error => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});
