#!/usr/bin/env node

/**
 * VibeTunnel Notification Debug Script
 * 
 * This script helps debug notification issues by checking:
 * 1. Server-side VAPID configuration
 * 2. Client-side subscription state
 * 3. Service worker registration
 * 4. Browser permissions
 */

import chalk from 'chalk';
import fetch from 'node-fetch';

const SERVER_URL = process.env.VIBETUNNEL_URL || 'http://localhost:4020';

async function checkServerStatus() {
  console.log(chalk.blue('\n🔍 Checking Server Status...'));
  
  try {
    // Check health endpoint
    const healthResponse = await fetch(`${SERVER_URL}/api/health`);
    if (!healthResponse.ok) {
      console.log(chalk.red('❌ Server is not responding'));
      return false;
    }
    
    const health = await healthResponse.json();
    console.log(chalk.green('✅ Server is running'), health);
    
    // Check VAPID configuration
    const vapidResponse = await fetch(`${SERVER_URL}/api/push/vapid-public-key`);
    if (!vapidResponse.ok) {
      console.log(chalk.red('❌ VAPID keys not configured'));
      return false;
    }
    
    const vapidData = await vapidResponse.json();
    if (vapidData.enabled && vapidData.publicKey) {
      console.log(chalk.green('✅ VAPID keys configured'));
      console.log(chalk.gray(`   Public Key: ${vapidData.publicKey.substring(0, 20)}...`));
    } else {
      console.log(chalk.red('❌ VAPID keys disabled or missing'));
      return false;
    }
    
    // Check push notification status
    const pushStatusResponse = await fetch(`${SERVER_URL}/api/push/status`);
    if (pushStatusResponse.ok) {
      const pushStatus = await pushStatusResponse.json();
      console.log(chalk.green('✅ Push notification service status:'));
      console.log(chalk.gray(`   Enabled: ${pushStatus.enabled}`));
      console.log(chalk.gray(`   Configured: ${pushStatus.configured}`));
      console.log(chalk.gray(`   Active subscriptions: ${pushStatus.subscriptions || 0}`));
    }
    
    return true;
  } catch (error) {
    console.log(chalk.red('❌ Error checking server:'), error.message);
    return false;
  }
}

async function checkClientInstructions() {
  console.log(chalk.blue('\n📱 Client-Side Debug Instructions:'));
  
  console.log(chalk.yellow('\n1. Open VibeTunnel in your browser'));
  console.log(chalk.gray(`   ${SERVER_URL}`));
  
  console.log(chalk.yellow('\n2. Open browser DevTools (F12) and go to Console'));
  
  console.log(chalk.yellow('\n3. Run these commands in the console:'));
  
  const debugCommands = `
// Check service worker status
navigator.serviceWorker.getRegistrations().then(regs => {
  console.log('Service Workers:', regs.length);
  regs.forEach(reg => console.log('  -', reg.scope, reg.active?.state));
});

// Check notification permission
console.log('Notification Permission:', Notification.permission);

// Check push subscription
navigator.serviceWorker.ready.then(reg => {
  reg.pushManager.getSubscription().then(sub => {
    console.log('Push Subscription:', sub ? 'Active' : 'None');
    if (sub) console.log('  Endpoint:', sub.endpoint);
  });
});

// Check saved preferences
const prefs = localStorage.getItem('vibetunnel_notification_preferences');
console.log('Saved Preferences:', prefs ? JSON.parse(prefs) : 'None');

// Force re-initialization
console.log('\\nTo force re-initialization, run:');
console.log('pushNotificationService.initialize()');
`;

  console.log(chalk.cyan(debugCommands));
  
  console.log(chalk.yellow('\n4. Check for errors in the console'));
  console.log(chalk.gray('   Look for messages starting with [push-notification-service]'));
}

async function suggestFixes() {
  console.log(chalk.blue('\n🔧 Common Fixes:'));
  
  console.log(chalk.yellow('\n1. If notifications were enabled but not working:'));
  console.log(chalk.gray('   - Go to Settings and toggle notifications OFF then ON'));
  console.log(chalk.gray('   - This will re-sync the subscription with the server'));
  
  console.log(chalk.yellow('\n2. If permission is blocked:'));
  console.log(chalk.gray('   - Click the lock icon in the address bar'));
  console.log(chalk.gray('   - Set Notifications to "Allow"'));
  console.log(chalk.gray('   - Refresh the page'));
  
  console.log(chalk.yellow('\n3. If service worker issues:'));
  console.log(chalk.gray('   - Clear browser cache and cookies'));
  console.log(chalk.gray('   - In DevTools > Application > Service Workers'));
  console.log(chalk.gray('   - Unregister all workers and refresh'));
  
  console.log(chalk.yellow('\n4. Test notification delivery:'));
  console.log(chalk.gray('   - Enable notifications in Settings'));
  console.log(chalk.gray('   - Click "Test Notification" button'));
  console.log(chalk.gray('   - Should see a test notification immediately'));
}

async function main() {
  console.log(chalk.bold.blue('🔔 VibeTunnel Notification Debugger'));
  
  const serverOk = await checkServerStatus();
  
  if (!serverOk) {
    console.log(chalk.red('\n⚠️  Server issues detected. Please check the server configuration.'));
  }
  
  await checkClientInstructions();
  await suggestFixes();
  
  console.log(chalk.green('\n✨ Debug complete!'));
}

main().catch(console.error);