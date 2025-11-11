#!/usr/bin/env node

/**
 * API Testing Script
 * Tests all the fixed endpoints to verify they're working correctly
 */

const BASE_URL = 'https://tokerrgjik.netlify.app/.netlify/functions';

// Test usernames
const USER1 = 'ArbenChampion790';
const USER2 = 'Gameri';

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testEndpoint(name, method, url, body = null) {
  log(`\n🧪 Testing: ${name}`, 'cyan');
  log(`   ${method} ${url}`, 'blue');
  
  try {
    const options = {
      method,
      headers: { 'Content-Type': 'application/json' },
    };
    
    if (body) {
      options.body = JSON.stringify(body);
      log(`   Body: ${JSON.stringify(body, null, 2)}`, 'blue');
    }
    
    const response = await fetch(url, options);
    const data = await response.json();
    
    if (response.ok) {
      log(`   ✅ SUCCESS (${response.status})`, 'green');
      log(`   Response: ${JSON.stringify(data, null, 2)}`, 'green');
      return { success: true, data };
    } else {
      log(`   ❌ FAILED (${response.status})`, 'red');
      log(`   Error: ${JSON.stringify(data, null, 2)}`, 'red');
      return { success: false, data };
    }
  } catch (error) {
    log(`   ❌ ERROR: ${error.message}`, 'red');
    return { success: false, error: error.message };
  }
}

async function runTests() {
  log('═══════════════════════════════════════════════', 'cyan');
  log('  Tokerrgjik API Testing Suite', 'cyan');
  log('═══════════════════════════════════════════════', 'cyan');
  
  // Test 1: Get user (should exist)
  await testEndpoint(
    'Get User Profile',
    'GET',
    `${BASE_URL}/users/${USER1}`
  );
  
  // Test 2: Update user stats (should handle update_stats action)
  await testEndpoint(
    'Update User Stats (409 fix test)',
    'POST',
    `${BASE_URL}/users`,
    {
      action: 'update_stats',
      userId: 'guest_test',
      username: USER1,
      coins: 250,
      wins: 5,
      losses: 2,
      draws: 1,
      winStreak: 3,
      bestStreak: 5,
      isPro: false,
    }
  );
  
  // Test 3: Get friends list
  await testEndpoint(
    'Get Friends List',
    'GET',
    `${BASE_URL}/friends?username=${USER1}&action=list`
  );
  
  // Test 4: Send challenge (should work even if not friends)
  const sessionId = `test-session-${Date.now()}`;
  await testEndpoint(
    'Send Challenge (no-friends-check test)',
    'POST',
    `${BASE_URL}/challenges`,
    {
      action: 'send',
      from_username: USER1,
      to_username: USER2,
      session_id: sessionId,
    }
  );
  
  // Test 5: Get received challenges
  await testEndpoint(
    'Get Received Challenges',
    'GET',
    `${BASE_URL}/challenges?username=${USER2}&action=received`
  );
  
  // Test 6: Get sent challenges
  await testEndpoint(
    'Get Sent Challenges',
    'GET',
    `${BASE_URL}/challenges?username=${USER1}&action=sent`
  );
  
  // Test 7: Create game session
  await testEndpoint(
    'Create Game Session',
    'POST',
    `${BASE_URL}/games`,
    {
      action: 'create_session',
      host_username: USER1,
      is_private: false,
    }
  );
  
  // Test 8: List game sessions (with cleanup test)
  await testEndpoint(
    'List Game Sessions (cleanup test)',
    'POST',
    `${BASE_URL}/games`,
    {
      action: 'list_sessions',
    }
  );
  
  // Test 9: Get pending friend requests
  await testEndpoint(
    'Get Pending Friend Requests',
    'GET',
    `${BASE_URL}/friends?username=${USER1}&action=pending`
  );
  
  log('\n═══════════════════════════════════════════════', 'cyan');
  log('  Testing Complete!', 'cyan');
  log('═══════════════════════════════════════════════', 'cyan');
  log('\n📝 Check the results above to verify all fixes are working.', 'yellow');
  log('⚠️  If you see 404 or 500 errors, check Netlify function logs.', 'yellow');
  log('🔧 If users don\'t exist, create them first in the app.', 'yellow');
}

// Run the tests
runTests().catch(console.error);
