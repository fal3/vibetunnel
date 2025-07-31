#!/usr/bin/env node

/**
 * VibeTunnel Notification System Test
 * 
 * This script tests all components of the notification system:
 * 1. Server health and configuration
 * 2. VAPID key status
 * 3. Push notification endpoint
 * 4. Client-side service worker
 * 5. Browser notification permissions
 */

const https = require('https');
const http = require('http');

const SERVER_URL = 'http://localhost:4020';

async function testServerHealth() {
  console.log('🔍 Testing server health...');
  
  try {
    const response = await fetch(`${SERVER_URL}/api/health`);
    const data = await response.json();
    
    console.log('✅ Server is running');
    console.log(`   Version: ${data.version}`);
    console.log(`   Mode: ${data.mode}`);
    console.log(`   Uptime: ${data.uptime.toFixed(2)}s`);
    
    return true;
  } catch (error) {
    console.log('❌ Server health check failed:', error.message);
    return false;
  }
}

async function testPushNotificationEndpoint() {
  console.log('\n🔍 Testing push notification endpoint...');
  
  try {
    const response = await fetch(`${SERVER_URL}/api/push/test`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'Test notification from CLI script',
      }),
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    }
    
    const result = await response.json();
    console.log('✅ Push notification endpoint working');
    console.log(`   Sent: ${result.sent} notifications`);
    console.log(`   Failed: ${result.failed} notifications`);
    
    return true;
  } catch (error) {
    console.log('❌ Push notification endpoint failed:', error.message);
    return false;
  }
}

async function testVapidConfiguration() {
  console.log('\n🔍 Testing VAPID configuration...');
  
  try {
    const response = await fetch(`${SERVER_URL}/api/push/vapid-public-key`);
    const data = await response.json();
    
    if (data.publicKey) {
      console.log('✅ VAPID keys configured');
      console.log(`   Public key: ${data.publicKey.substring(0, 20)}...`);
      return true;
    } else {
      console.log('❌ VAPID keys not configured');
      return false;
    }
  } catch (error) {
    console.log('❌ VAPID configuration check failed:', error.message);
    return false;
  }
}

async function testServiceWorker() {
  console.log('\n🔍 Testing service worker...');
  
  try {
    const response = await fetch(`${SERVER_URL}/sw.js`);
    
    if (response.ok) {
      console.log('✅ Service worker file accessible');
      return true;
    } else {
      console.log('❌ Service worker file not found');
      return false;
    }
  } catch (error) {
    console.log('❌ Service worker check failed:', error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🧪 VibeTunnel Notification System Test\n');
  
  const tests = [
    { name: 'Server Health', fn: testServerHealth },
    { name: 'VAPID Configuration', fn: testVapidConfiguration },
    { name: 'Service Worker', fn: testServiceWorker },
    { name: 'Push Notification Endpoint', fn: testPushNotificationEndpoint },
  ];
  
  const results = [];
  
  for (const test of tests) {
    const passed = await test.fn();
    results.push({ name: test.name, passed });
  }
  
  console.log('\n📊 Test Results:');
  console.log('================');
  
  const passed = results.filter(r => r.passed).length;
  const total = results.length;
  
  results.forEach(result => {
    const status = result.passed ? '✅' : '❌';
    console.log(`${status} ${result.name}`);
  });
  
  console.log(`\n${passed}/${total} tests passed`);
  
  if (passed === total) {
    console.log('\n🎉 All notification system components are working!');
    console.log('\nNext steps:');
    console.log('1. Open http://localhost:4020 in your browser');
    console.log('2. Go to Settings > Notifications');
    console.log('3. Enable notifications and test the "Test Notification" button');
  } else {
    console.log('\n⚠️  Some components need attention');
    console.log('\nTroubleshooting:');
    console.log('1. Check server logs for errors');
    console.log('2. Verify VAPID keys are generated');
    console.log('3. Ensure service worker is accessible');
  }
}

// Run the tests
runAllTests().catch(console.error); 