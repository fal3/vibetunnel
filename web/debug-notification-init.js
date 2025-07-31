#!/usr/bin/env node

/**
 * Debug Notification Initialization Issue
 * 
 * The problem: Notifications don't work until you go to settings and toggle them.
 * This script helps identify the initialization timing issue.
 */

console.log('🔍 Debugging Notification Initialization Issue\n');

console.log('📋 Manual Debug Steps:');
console.log('=====================');
console.log('');
console.log('1. Open browser console (F12)');
console.log('2. Go to http://localhost:4020');
console.log('3. Run these commands in console:');
console.log('');
console.log('   // Check if service worker is registered');
console.log('   navigator.serviceWorker.getRegistrations().then(regs => console.log("Service Workers:", regs));');
console.log('');
console.log('   // Check notification permission');
console.log('   console.log("Permission:", Notification.permission);');
console.log('');
console.log('   // Check if push manager is available');
console.log('   console.log("Push Manager:", !!navigator.serviceWorker.ready.then(reg => reg.pushManager));');
console.log('');
console.log('   // Check if VAPID key is fetched');
console.log('   fetch("/api/push/vapid-public-key").then(r => r.json()).then(console.log);');
console.log('');
console.log('   // Check current subscription');
console.log('   navigator.serviceWorker.ready.then(reg => reg.pushManager.getSubscription()).then(console.log);');
console.log('');

console.log('🔧 Likely Issues:');
console.log('================');
console.log('');
console.log('1. Service worker not registered on page load');
console.log('2. VAPID key not fetched automatically');
console.log('3. Auto-resubscribe not running');
console.log('4. Permission check failing silently');
console.log('5. Subscription not restored from storage');
console.log('');

console.log('💡 Quick Fixes to Try:');
console.log('=====================');
console.log('');
console.log('1. Add this to browser console to force initialization:');
console.log('   window.pushNotificationService?.initialize();');
console.log('');
console.log('2. Force auto-resubscribe:');
console.log('   window.pushNotificationService?.autoResubscribe();');
console.log('');
console.log('3. Check if preferences are loaded:');
console.log('   window.pushNotificationService?.loadPreferences().then(console.log);');
console.log('');

console.log('🎯 Root Cause Analysis:');
console.log('=====================');
console.log('');
console.log('The issue is likely in the autoResubscribe() function in push-notification-service.ts');
console.log('It probably has timing issues where:');
console.log('- Service worker registration is not ready');
console.log('- VAPID key is not fetched yet');
console.log('- Preferences are not loaded');
console.log('- Permission check happens too early');
console.log('');
console.log('The settings toggle works because it forces a fresh initialization');
console.log('with all dependencies properly loaded.'); 