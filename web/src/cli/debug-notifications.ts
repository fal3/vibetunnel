#!/usr/bin/env node

/**
 * VibeTunnel Notification Debug CLI
 *
 * This tool helps debug notification issues by inspecting:
 * - Server-side notification configuration
 * - Client-side subscription state
 * - VAPID key status
 * - Service worker registration
 * - Browser permission state
 *
 * Usage: npx vibetunnel debug-notifications [options]
 */

import chalk from 'chalk';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { createLogger } from '../server/utils/logger.js';
import { VapidManager } from '../server/utils/vapid-manager.js';

const _logger = createLogger('debug-notifications');

interface DebugOptions {
  serverUrl?: string;
  verbose?: boolean;
  checkServer?: boolean;
  checkClient?: boolean;
  checkVapid?: boolean;
  checkPermissions?: boolean;
  fixIssues?: boolean;
}

class NotificationDebugger {
  private serverUrl: string;
  private verbose: boolean;

  constructor(options: DebugOptions) {
    this.serverUrl = options.serverUrl || 'http://localhost:4020';
    this.verbose = options.verbose || false;
  }

  async runChecks(options: DebugOptions): Promise<void> {
    console.log(chalk.blue('🔍 VibeTunnel Notification Debug Tool\n'));

    const checks = [
      { name: 'Server Configuration', fn: () => this.checkServerConfig() },
      { name: 'VAPID Keys', fn: () => this.checkVapidKeys() },
      { name: 'Client Subscription', fn: () => this.checkClientSubscription() },
      { name: 'Browser Permissions', fn: () => this.checkBrowserPermissions() },
      { name: 'Service Worker', fn: () => this.checkServiceWorker() },
    ];

    const results: Array<{ name: string; status: string; details?: unknown; error?: string }> = [];
    for (const check of checks) {
      console.log(chalk.yellow(`\n📋 ${check.name}...`));
      try {
        const result = await check.fn();
        results.push({ name: check.name, ...result });
      } catch (error) {
        results.push({
          name: check.name,
          status: 'error',
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    this.printSummary(results);

    if (options.fixIssues) {
      await this.attemptFixes(results);
    }
  }

  private async checkServerConfig(): Promise<{ status: string; details: unknown }> {
    try {
      const response = await fetch(`${this.serverUrl}/api/health`);
      if (!response.ok) {
        return { status: 'error', details: `Server not responding: ${response.status}` };
      }

      const health = await response.json();

      // Check push notification status
      const pushResponse = await fetch(`${this.serverUrl}/api/push/status`);
      let pushStatus = null;
      if (pushResponse.ok) {
        pushStatus = await pushResponse.json();
      }

      return {
        status: 'ok',
        details: {
          server: health,
          pushNotifications: pushStatus,
          serverUrl: this.serverUrl,
        },
      };
    } catch (error) {
      return {
        status: 'error',
        details: `Cannot connect to server: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }

  private async checkVapidKeys(): Promise<{ status: string; details: unknown }> {
    try {
      const vapidManager = new VapidManager();
      await vapidManager.initialize({
        contactEmail: 'debug@vibetunnel.local',
        generateIfMissing: false,
      });

      const publicKey = vapidManager.getPublicKey();
      const hasKeys = !!publicKey;

      return {
        status: hasKeys ? 'ok' : 'warning',
        details: {
          hasKeys,
          publicKey: publicKey ? `${publicKey.substring(0, 20)}...` : null,
          keysDirectory: vapidManager.getKeysDirectory(),
        },
      };
    } catch (error) {
      return {
        status: 'error',
        details: `VAPID key check failed: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }

  private async checkClientSubscription(): Promise<{ status: string; details: unknown }> {
    try {
      // This would need to run in a browser context
      // For CLI, we'll check the stored preferences
      const configPath = path.join(os.homedir(), '.vibetunnel/notifications');
      const preferencesPath = path.join(configPath, 'preferences.json');

      let preferences: unknown = null;
      if (fs.existsSync(preferencesPath)) {
        preferences = JSON.parse(fs.readFileSync(preferencesPath, 'utf-8'));
      }

      const subscriptionsPath = path.join(configPath, 'subscriptions.json');
      let subscriptions: Array<{ isActive?: boolean }> = [];
      if (fs.existsSync(subscriptionsPath)) {
        subscriptions = JSON.parse(fs.readFileSync(subscriptionsPath, 'utf-8'));
      }

      return {
        status: preferences?.enabled ? 'ok' : 'warning',
        details: {
          preferences,
          subscriptionCount: subscriptions.length,
          activeSubscriptions: subscriptions.filter((s) => s.isActive).length,
        },
      };
    } catch (error) {
      return {
        status: 'error',
        details: `Client subscription check failed: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }

  private async checkBrowserPermissions(): Promise<{ status: string; details: unknown }> {
    // This would need to run in browser context
    // For CLI, we'll provide guidance
    return {
      status: 'info',
      details: {
        message: 'Browser permissions must be checked manually',
        instructions: [
          'Open browser developer tools',
          'Check Notification.permission status',
          'Verify service worker registration',
          'Check push subscription state',
        ],
      },
    };
  }

  private async checkServiceWorker(): Promise<{ status: string; details: unknown }> {
    // Check if service worker file exists
    const swPath = path.join(process.cwd(), 'public/sw.js');
    const exists = fs.existsSync(swPath);

    return {
      status: exists ? 'ok' : 'error',
      details: {
        serviceWorkerExists: exists,
        path: swPath,
        message: exists ? 'Service worker file found' : 'Service worker file missing',
      },
    };
  }

  private printSummary(
    results: Array<{ name: string; status: string; details?: unknown; error?: string }>
  ): void {
    console.log(chalk.blue('\n📊 Debug Summary\n'));

    const statusColors = {
      ok: chalk.green,
      warning: chalk.yellow,
      error: chalk.red,
      info: chalk.blue,
    };

    for (const result of results) {
      const color = statusColors[result.status as keyof typeof statusColors] || chalk.white;
      const icon =
        result.status === 'ok'
          ? '✅'
          : result.status === 'warning'
            ? '⚠️'
            : result.status === 'error'
              ? '❌'
              : 'ℹ️';

      console.log(`${icon} ${color(result.name)}: ${result.status.toUpperCase()}`);

      if (this.verbose && result.details) {
        console.log(chalk.gray('   Details:'), JSON.stringify(result.details, null, 2));
      }

      if (result.error) {
        console.log(chalk.red('   Error:'), result.error);
      }
    }
  }

  private async attemptFixes(
    results: Array<{ name: string; status: string; details?: unknown; error?: string }>
  ): Promise<void> {
    console.log(chalk.blue('\n🔧 Attempting Fixes\n'));

    for (const result of results) {
      if (result.status === 'error' || result.status === 'warning') {
        console.log(chalk.yellow(`\nFixing ${result.name}...`));

        try {
          if (result.name === 'VAPID Keys' && result.status === 'warning') {
            await this.fixVapidKeys();
          } else if (result.name === 'Server Configuration' && result.status === 'error') {
            await this.fixServerConnection();
          }
        } catch (error) {
          console.log(chalk.red(`Failed to fix ${result.name}: ${error}`));
        }
      }
    }
  }

  private async fixVapidKeys(): Promise<void> {
    try {
      const vapidManager = new VapidManager();
      await vapidManager.initialize({
        contactEmail: 'debug@vibetunnel.local',
        generateIfMissing: true,
      });
      console.log(chalk.green('✅ VAPID keys generated successfully'));
    } catch (error) {
      throw new Error(`Failed to generate VAPID keys: ${error}`);
    }
  }

  private async fixServerConnection(): Promise<void> {
    console.log(chalk.yellow('⚠️  Server connection issues require manual intervention:'));
    console.log(chalk.gray('   1. Check if VibeTunnel server is running'));
    console.log(chalk.gray('   2. Verify server URL is correct'));
    console.log(chalk.gray('   3. Check firewall/network settings'));
  }

  generateSwiftUIDebugCode(): string {
    return `
// SwiftUI Debug View for VibeTunnel Notifications
import SwiftUI

struct NotificationDebugView: View {
    @State private var debugInfo = NotificationDebugInfo()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Server Status") {
                    HStack {
                        Text("Server Connected")
                        Spacer()
                        Image(systemName: debugInfo.serverConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(debugInfo.serverConnected ? .green : .red)
                    }
                    
                    HStack {
                        Text("Push Enabled")
                        Spacer()
                        Image(systemName: debugInfo.pushEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(debugInfo.pushEnabled ? .green : .red)
                    }
                }
                
                Section("Client Status") {
                    HStack {
                        Text("Permission Granted")
                        Spacer()
                        Image(systemName: debugInfo.permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(debugInfo.permissionGranted ? .green : .red)
                    }
                    
                    HStack {
                        Text("Subscription Active")
                        Spacer()
                        Image(systemName: debugInfo.subscriptionActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(debugInfo.subscriptionActive ? .green : .red)
                    }
                }
                
                Section("Actions") {
                    Button("Refresh Debug Info") {
                        refreshDebugInfo()
                    }
                    
                    Button("Force Resubscribe") {
                        forceResubscribe()
                    }
                    
                    Button("Test Notification") {
                        testNotification()
                    }
                }
            }
            .navigationTitle("Notification Debug")
            .onAppear {
                refreshDebugInfo()
            }
        }
    }
    
    private func refreshDebugInfo() {
        isLoading = true
        // Implementation would call the debug CLI or API
        // and update debugInfo state
    }
    
    private func forceResubscribe() {
        // Implementation to force resubscribe
    }
    
    private func testNotification() {
        // Implementation to send test notification
    }
}

struct NotificationDebugInfo {
    var serverConnected = false
    var pushEnabled = false
    var permissionGranted = false
    var subscriptionActive = false
}
`;
  }
}

// CLI Entry Point
async function main() {
  const args = process.argv.slice(2);
  const options: DebugOptions = {
    verbose: args.includes('--verbose') || args.includes('-v'),
    checkServer: !args.includes('--no-server'),
    checkClient: !args.includes('--no-client'),
    checkVapid: !args.includes('--no-vapid'),
    checkPermissions: !args.includes('--no-permissions'),
    fixIssues: args.includes('--fix'),
  };

  // Parse server URL
  const serverUrlIndex = args.indexOf('--server-url');
  if (serverUrlIndex !== -1 && serverUrlIndex + 1 < args.length) {
    options.serverUrl = args[serverUrlIndex + 1];
  }

  const notificationDebugger = new NotificationDebugger(options);

  if (args.includes('--swiftui')) {
    console.log(notificationDebugger.generateSwiftUIDebugCode());
    return;
  }

  await notificationDebugger.runChecks(options);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(chalk.red('Debug tool failed:'), error);
    process.exit(1);
  });
}

export { NotificationDebugger };
