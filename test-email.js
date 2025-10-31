#!/usr/bin/env node

/**
 * Email Function Test Script
 * Tests the email function locally or on Netlify
 */

const BASE_URL = process.env.NETLIFY_URL || 'http://localhost:8888';
const API_URL = `${BASE_URL}/api/email`;

// Test cases
const testCases = [
  {
    name: 'Friend Request',
    data: {
      type: 'friend_request',
      username: 'testuser',
      data: {
        from_username: 'john_doe'
      }
    }
  },
  {
    name: 'Game Invite',
    data: {
      type: 'game_invite',
      username: 'testuser',
      data: {
        from_username: 'jane_smith'
      }
    }
  },
  {
    name: 'Achievement Unlocked',
    data: {
      type: 'achievement_unlocked',
      username: 'testuser',
      data: {
        achievement_title: 'First Win',
        achievement_icon: '🏆',
        achievement_description: 'Won your first game!'
      }
    }
  },
  {
    name: 'Pro Purchase',
    data: {
      type: 'pro_purchase',
      username: 'testuser',
      data: {
        months: 3,
        amount: '€7.99'
      }
    }
  },
  {
    name: 'Password Reset',
    data: {
      type: 'password_reset',
      username: 'testuser',
      data: {
        reset_token: 'test_token_12345'
      }
    }
  }
];

async function testEmail(testCase) {
  console.log(`\n🧪 Testing: ${testCase.name}`);
  console.log('─'.repeat(50));
  
  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testCase.data)
    });
    
    const result = await response.json();
    
    if (response.ok) {
      console.log('✅ SUCCESS');
      console.log('Response:', JSON.stringify(result, null, 2));
    } else {
      console.log('❌ FAILED');
      console.log('Status:', response.status);
      console.log('Error:', JSON.stringify(result, null, 2));
    }
  } catch (error) {
    console.log('❌ ERROR');
    console.log('Message:', error.message);
  }
}

async function runTests() {
  console.log('╔════════════════════════════════════════════════╗');
  console.log('║       EMAIL FUNCTION TEST SUITE                ║');
  console.log('╚════════════════════════════════════════════════╝');
  console.log(`📍 Testing URL: ${API_URL}\n`);
  
  // Check if running locally
  if (BASE_URL.includes('localhost')) {
    console.log('⚠️  Running in LOCAL mode');
    console.log('   Make sure to run: netlify dev\n');
  } else {
    console.log('🌐 Running in PRODUCTION mode\n');
  }
  
  // Run all tests
  for (const testCase of testCases) {
    await testEmail(testCase);
    // Wait a bit between tests
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('\n' + '═'.repeat(50));
  console.log('✅ All tests completed!');
  console.log('═'.repeat(50) + '\n');
}

// Run tests
runTests().catch(console.error);
