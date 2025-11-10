#!/usr/bin/env node

/**
 * Test deployed Netlify functions
 */

const BASE_URL = 'https://tokerrgjik.netlify.app/.netlify/functions';

async function test(endpoint, method = 'GET', body = null) {
  const url = `${BASE_URL}${endpoint}`;
  console.log(`\n🧪 Testing ${method} ${url}`);
  
  try {
    const options = {
      method,
      headers: { 'Content-Type': 'application/json' }
    };
    
    if (body) {
      options.body = JSON.stringify(body);
    }
    
    const response = await fetch(url, options);
    const data = await response.json();
    
    if (response.ok) {
      console.log(`✅ Status: ${response.status}`);
      console.log(`📦 Response:`, JSON.stringify(data, null, 2).substring(0, 200));
      return true;
    } else {
      console.log(`❌ Status: ${response.status}`);
      console.log(`⚠️  Error:`, data);
      return false;
    }
  } catch (error) {
    console.log(`❌ Failed: ${error.message}`);
    return false;
  }
}

async function runTests() {
  console.log('🚀 TESTING TOKERRGJIK API ENDPOINTS\n');
  console.log('Base URL:', BASE_URL);
  console.log('='.repeat(60));
  
  let passed = 0;
  let failed = 0;
  
  // Test 1: Health check
  if (await test('/health')) passed++; else failed++;
  
  // Test 2: List available game sessions
  if (await test('/games?action=list_sessions')) passed++; else failed++;
  
  // Test 3: Get pending friend requests (will be empty for test user)
  if (await test('/friends?username=TestUser&action=pending')) passed++; else failed++;
  
  // Test 4: Leaderboard
  if (await test('/leaderboard?limit=10')) passed++; else failed++;
  
  console.log('\n' + '='.repeat(60));
  console.log(`\n📊 RESULTS: ${passed} passed, ${failed} failed`);
  
  if (failed === 0) {
    console.log('\n✅ All API endpoints are working!');
  } else {
    console.log('\n⚠️  Some endpoints need attention');
  }
}

runTests().catch(console.error);
