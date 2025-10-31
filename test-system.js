#!/usr/bin/env node

/**
 * Complete System Test for Login, Statistics, and Leaderboard
 * Tests all the fixes applied to the database and auth system
 */

const BASE_URL = process.env.NETLIFY_URL || 'https://tokerrgjik.netlify.app';

// Test configuration
const TEST_USER = {
  username: `testuser_${Date.now()}`,
  password: 'testpass123',
  email: `test${Date.now()}@example.com`
};

let authToken = null;

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function log(message, color = colors.reset) {
  console.log(color + message + colors.reset);
}

function success(message) {
  log('✅ ' + message, colors.green);
}

function error(message) {
  log('❌ ' + message, colors.red);
}

function info(message) {
  log('ℹ️  ' + message, colors.cyan);
}

function warn(message) {
  log('⚠️  ' + message, colors.yellow);
}

// Test 1: Register New User
async function testRegister() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 1: USER REGISTRATION', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'register',
        username: TEST_USER.username,
        password: TEST_USER.password,
        email: TEST_USER.email,
      }),
    });
    
    const result = await response.json();
    
    if (response.ok && result.user) {
      success('User registered successfully');
      info(`Username: ${result.user.username}`);
      info(`User ID: ${result.user.id}`);
      authToken = result.token;
      return true;
    } else {
      error('Registration failed');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('Registration error: ' + err.message);
    return false;
  }
}

// Test 2: Login with Correct Credentials
async function testLogin() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 2: USER LOGIN (Correct Credentials)', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'login',
        username: TEST_USER.username,
        password: TEST_USER.password,
      }),
    });
    
    const result = await response.json();
    
    if (response.ok && result.user) {
      success('Login successful');
      info(`Logged in as: ${result.user.username}`);
      info(`Token received: ${result.token ? 'Yes' : 'No'}`);
      
      // Verify username matches
      if (result.user.username === TEST_USER.username) {
        success('Username matches - No random user bug!');
      } else {
        error(`Username mismatch! Expected: ${TEST_USER.username}, Got: ${result.user.username}`);
      }
      
      authToken = result.token;
      return true;
    } else {
      error('Login failed');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('Login error: ' + err.message);
    return false;
  }
}

// Test 3: Login with Wrong Credentials
async function testLoginFail() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 3: USER LOGIN (Wrong Credentials)', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'login',
        username: TEST_USER.username,
        password: 'wrongpassword',
      }),
    });
    
    const result = await response.json();
    
    if (response.status === 401) {
      success('Login correctly rejected invalid credentials');
      return true;
    } else {
      error('Should have rejected invalid credentials!');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('Login error test failed: ' + err.message);
    return false;
  }
}

// Test 4: Get User Statistics
async function testStatistics() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 4: USER STATISTICS', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/statistics/${TEST_USER.username}`);
    const result = await response.json();
    
    if (response.ok && result.user) {
      success('Statistics retrieved successfully');
      info(`Username: ${result.user.username}`);
      info(`Coins: ${result.user.coins}`);
      info(`Level: ${result.user.level}`);
      info(`Wins: ${result.user.total_wins}`);
      info(`Losses: ${result.user.total_losses}`);
      info(`Win Rate: ${result.user.win_rate}%`);
      
      // Verify win rate calculation (should be 0 for new user)
      if (result.user.win_rate === 0 || result.user.win_rate === 0.0) {
        success('Win rate calculation correct for new user (0%)');
      } else {
        warn(`Win rate should be 0% for new user, got ${result.user.win_rate}%`);
      }
      
      return true;
    } else {
      error('Failed to get statistics');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('Statistics error: ' + err.message);
    return false;
  }
}

// Test 5: Get Leaderboard
async function testLeaderboard() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 5: LEADERBOARD', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/leaderboard?limit=10`);
    const result = await response.json();
    
    if (response.ok && result.leaderboard) {
      success('Leaderboard retrieved successfully');
      info(`Total entries: ${result.leaderboard.length}`);
      
      // Check if guest users are filtered out
      const hasGuests = result.leaderboard.some(user => user.username.startsWith('guest_'));
      if (!hasGuests) {
        success('Guest users correctly filtered out');
      } else {
        error('Guest users still appearing in leaderboard!');
      }
      
      // Display top 5
      info('\nTop 5 Players:');
      result.leaderboard.slice(0, 5).forEach((user, index) => {
        console.log(`  ${index + 1}. ${user.username} - ${user.total_wins} wins (${user.win_rate}% win rate)`);
      });
      
      return true;
    } else {
      error('Failed to get leaderboard');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('Leaderboard error: ' + err.message);
    return false;
  }
}

// Test 6: Get User Rank
async function testUserRank() {
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST 6: USER RANK', colors.bright);
  log('='.repeat(60), colors.bright);
  
  try {
    const response = await fetch(`${BASE_URL}/.netlify/functions/leaderboard/rank/${TEST_USER.username}`);
    const result = await response.json();
    
    if (response.ok && result.rank !== undefined) {
      success('User rank retrieved successfully');
      info(`Rank: ${result.rank}`);
      return true;
    } else {
      error('Failed to get user rank');
      console.log('Response:', result);
      return false;
    }
  } catch (err) {
    error('User rank error: ' + err.message);
    return false;
  }
}

// Main test runner
async function runAllTests() {
  log('\n' + '╔' + '═'.repeat(58) + '╗', colors.cyan);
  log('║  TOKERRGJIK SYSTEM TEST SUITE                           ║', colors.cyan);
  log('╚' + '═'.repeat(58) + '╝', colors.cyan);
  info(`Testing against: ${BASE_URL}`);
  
  const results = {
    passed: 0,
    failed: 0,
  };
  
  // Run tests sequentially
  const tests = [
    { name: 'Registration', fn: testRegister },
    { name: 'Login (Valid)', fn: testLogin },
    { name: 'Login (Invalid)', fn: testLoginFail },
    { name: 'Statistics', fn: testStatistics },
    { name: 'Leaderboard', fn: testLeaderboard },
    { name: 'User Rank', fn: testUserRank },
  ];
  
  for (const test of tests) {
    const passed = await test.fn();
    if (passed) {
      results.passed++;
    } else {
      results.failed++;
    }
    await new Promise(resolve => setTimeout(resolve, 500)); // Small delay between tests
  }
  
  // Final summary
  log('\n' + '='.repeat(60), colors.bright);
  log('TEST SUMMARY', colors.bright);
  log('='.repeat(60), colors.bright);
  success(`Passed: ${results.passed}/${tests.length}`);
  if (results.failed > 0) {
    error(`Failed: ${results.failed}/${tests.length}`);
  }
  
  if (results.failed === 0) {
    log('\n🎉 ALL TESTS PASSED! 🎉\n', colors.green + colors.bright);
  } else {
    log('\n⚠️  SOME TESTS FAILED - CHECK LOGS ABOVE\n', colors.yellow + colors.bright);
  }
}

// Run tests
runAllTests().catch(err => {
  error('Test suite error: ' + err.message);
  console.error(err);
  process.exit(1);
});
