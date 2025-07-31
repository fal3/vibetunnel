# VibeTunnel Push Notification HTTPS Fix

## Issue Summary

Push notifications were not working when accessing VibeTunnel via HTTP (non-secure context). The notification toggle appeared disabled with a warning message, preventing users from enabling notifications even on localhost.

## Root Cause

The push notification service requires a secure context (`window.isSecureContext`) to function properly because:
1. Service Workers only work in secure contexts (HTTPS or localhost)
2. Push API requires HTTPS for security reasons
3. The initialization was returning early when not in a secure context

## Changes Made

### 1. Enhanced Security Check Logging
Added explicit security context check with helpful logging in `push-notification-service.ts`:
```typescript
// Check if we're in a secure context (HTTPS or localhost)
// Service workers require HTTPS except for localhost/127.0.0.1
if (!window.isSecureContext) {
  logger.warn(
    'Push notifications require HTTPS or localhost. Current context is not secure.'
  );
  return;
}
```

### 2. Improved Initialization Logging
Added detailed logging in `app.ts` to help debug initialization issues:
```typescript
logger.log('Push notification initialization complete:', {
  isSupported,
  isSecureContext: isSecure,
  location: window.location.hostname,
  protocol: window.location.protocol,
});
```

### 3. Enhanced User Guidance
Updated the warning message in `settings.ts` to be more helpful:
- Shows the current URL being used
- Provides specific alternatives that will work:
  - HTTPS version of current URL
  - localhost:4020
  - 127.0.0.1:4020

## How to Enable Notifications

To use push notifications, access VibeTunnel via:

1. **HTTPS**: `https://your-hostname:port`
2. **Localhost**: `http://localhost:4020`
3. **Local IP**: `http://127.0.0.1:4020`

## Technical Details

### Service Worker Requirements
- Service Workers require HTTPS except for localhost/127.0.0.1
- This is a browser security restriction, not a VibeTunnel limitation
- The check uses `window.isSecureContext` which is true for:
  - HTTPS origins
  - localhost (any port)
  - 127.0.0.1 (any port)
  - file:// URLs (but not relevant for web apps)

### Push API Requirements
- Push subscriptions require VAPID keys
- VAPID keys are fetched from the server during initialization
- The subscription process requires user permission

## Testing

To verify the fix works:

1. Access VibeTunnel via localhost:4020
2. Open browser console and check for initialization logs
3. Go to Settings → Notifications
4. The toggle should be enabled (not grayed out)
5. Toggle notifications on
6. Test with the "Test Notification" button

## Debug Commands

If notifications still don't work, run these in the browser console:

```javascript
// Check if in secure context
console.log('Secure context:', window.isSecureContext);

// Check service worker registration
navigator.serviceWorker.getRegistrations().then(regs => console.log('Service Workers:', regs));

// Check notification permission
console.log('Permission:', Notification.permission);

// Force re-initialization
window.pushNotificationService?.initialize();
```