/**
 * Test email functionality locally
 * Tests all email types to ensure they work correctly
 */

import 'dotenv/config';

const API_BASE = process.env.NETLIFY_URL || 'https://tokerrgjik.netlify.app';
const TEST_USERNAME = process.env.TEST_USERNAME || 'ArbenChampion790';

console.log('🧪 Testing Email Functionality');
console.log('================================');
console.log(`API: ${API_BASE}`);
console.log(`Test User: ${TEST_USERNAME}`);
console.log('');

// Test email types
const emailTests = [
  {
    name: 'Friend Request',
    type: 'friend_request',
    data: {
      from_username: 'TestFriend123'
    }
  },
  {
    name: 'Friend Request Accepted',
    type: 'friend_request_accepted',
    data: {
      accepted_by: 'TestFriend123'
    }
  },
  {
    name: 'Game Invite',
    type: 'game_invite',
    data: {
      from_username: 'ChallengerPlayer'
    }
  },
  {
    name: 'Achievement Unlocked',
    type: 'achievement_unlocked',
    data: {
      achievement_title: 'First Victory',
      achievement_icon: '🏆',
      achievement_description: 'Win your first game'
    }
  },
  {
    name: 'PRO Purchase',
    type: 'pro_purchase',
    data: {
      months: 1,
      amount: '€2.99'
    }
  },
  {
    name: 'Coins Purchase',
    type: 'coins_purchase',
    data: {
      coins: 500,
      amount: '€4.99'
    }
  },
  {
    name: 'Password Reset',
    type: 'password_reset',
    data: {
      reset_token: 'test_token_123456'
    }
  }
];

async function testEmail(emailType) {
  console.log(`\n📧 Testing: ${emailType.name}`);
  console.log('─'.repeat(50));
  
  try {
    const response = await fetch(`${API_BASE}/.netlify/functions/email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        username: TEST_USERNAME,
        type: emailType.type,
        data: emailType.data
      })
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
  console.log('Starting email tests...\n');
  
  // Test each email type
  for (const test of emailTests) {
    await testEmail(test);
    
    // Wait a bit between requests
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  console.log('\n================================');
  console.log('🏁 Email tests completed!');
  console.log('\nNOTE: Check Netlify function logs for email output.');
  console.log('If APP_PASSWORD is not set, emails will be logged to console only.');
}

// Run tests
runTests().catch(console.error);
