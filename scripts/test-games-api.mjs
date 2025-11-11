/**
 * Test Games API functionality
 * Tests session creation, listing, joining, and challenges
 */

import 'dotenv/config';

const API_BASE = process.env.NETLIFY_URL || 'https://tokerrgjik.netlify.app';
const TEST_HOST = process.env.TEST_USERNAME || 'ArbenChampion790';
const TEST_GUEST = 'TestGuest123';

console.log('🎮 Testing Games API Functionality');
console.log('================================');
console.log(`API: ${API_BASE}`);
console.log(`Host: ${TEST_HOST}`);
console.log(`Guest: ${TEST_GUEST}`);
console.log('');

let testSessionId = null;

async function testAPI(name, endpoint, method = 'POST', body = null) {
  console.log(`\n📡 Testing: ${name}`);
  console.log('─'.repeat(50));
  console.log(`   Endpoint: ${endpoint}`);
  console.log(`   Method: ${method}`);
  if (body) {
    console.log(`   Payload:`, JSON.stringify(body, null, 2));
  }
  
  try {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    
    if (body && method !== 'GET') {
      options.body = JSON.stringify(body);
    }
    
    const response = await fetch(endpoint, options);
    const result = await response.json();
    
    console.log(`   Status: ${response.status}`);
    
    if (response.ok) {
      console.log('   ✅ SUCCESS');
      console.log('   Response:', JSON.stringify(result, null, 2));
      return result;
    } else {
      console.log('   ❌ FAILED');
      console.log('   Error:', JSON.stringify(result, null, 2));
      return null;
    }
  } catch (error) {
    console.log('   ❌ ERROR');
    console.log('   Message:', error.message);
    return null;
  }
}

async function runTests() {
  console.log('Starting games API tests...\n');
  
  // Test 1: Health check
  const health = await testAPI(
    'Health Check',
    `${API_BASE}/.netlify/functions/health`,
    'GET'
  );
  
  if (!health) {
    console.log('\n❌ API is not responding. Check deployment.');
    return;
  }
  
  // Test 2: List sessions (POST)
  await testAPI(
    'List Sessions (POST)',
    `${API_BASE}/.netlify/functions/games`,
    'POST',
    { action: 'list_sessions' }
  );
  
  // Test 3: List sessions (GET)
  await testAPI(
    'List Sessions (GET)',
    `${API_BASE}/.netlify/functions/games?action=list_sessions`,
    'GET'
  );
  
  // Test 4: Create session
  const createResult = await testAPI(
    'Create Game Session',
    `${API_BASE}/.netlify/functions/games`,
    'POST',
    {
      action: 'create_session',
      host_username: TEST_HOST,
      is_private: false
    }
  );
  
  if (createResult && createResult.session_id) {
    testSessionId = createResult.session_id;
    console.log(`\n   💾 Saved session ID: ${testSessionId}`);
    
    // Test 5: Get session state
    await testAPI(
      'Get Session State',
      `${API_BASE}/.netlify/functions/games?action=get_state&session_id=${testSessionId}`,
      'GET'
    );
    
    // Test 6: List sessions again (should show our new session)
    await testAPI(
      'List Sessions (should include new session)',
      `${API_BASE}/.netlify/functions/games`,
      'POST',
      { action: 'list_sessions' }
    );
    
    // Test 7: Join session (would need a different user)
    console.log(`\n   ℹ️  Skipping join test (requires different user)`);
    
    // Test 8: Leave session
    await testAPI(
      'Leave Session',
      `${API_BASE}/.netlify/functions/games`,
      'POST',
      {
        action: 'leave_session',
        session_id: testSessionId
      }
    );
  }
  
  // Test 9: Save game result
  await testAPI(
    'Save Game Result',
    `${API_BASE}/.netlify/functions/games`,
    'POST',
    {
      username: TEST_HOST,
      game_mode: 'multiplayer',
      result: 'win',
      opponent_username: TEST_GUEST,
      score: 1000,
      duration: 180,
      moves_count: 25,
      played_at: new Date().toISOString()
    }
  );
  
  // Test 10: Get game history
  await testAPI(
    'Get Game History',
    `${API_BASE}/.netlify/functions/games/${TEST_HOST}?limit=5`,
    'GET'
  );
  
  console.log('\n================================');
  console.log('🏁 Games API tests completed!');
  console.log('\n📝 Summary:');
  console.log('   - If you see 404 errors, functions may not be deployed');
  console.log('   - If you see 500 errors, check database connection');
  console.log('   - If you see 404 user not found, create users first');
  console.log('\n💡 To fix deployment:');
  console.log('   1. Run: .\\scripts\\deploy-fix.ps1');
  console.log('   2. Run: netlify deploy --prod');
  console.log('   3. Check: netlify functions:list');
}

// Run tests
runTests().catch(console.error);
