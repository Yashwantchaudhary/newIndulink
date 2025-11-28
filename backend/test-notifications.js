#!/usr/bin/env node

/**
 * Simple test script for push notifications
 * Run with: node test-notifications.js
 */

const PushNotificationService = require('./services/pushNotificationService');

async function testNotifications() {
  console.log('🔔 Testing Push Notification System...\n');

  const pushService = new PushNotificationService();

  try {
    // Test 1: Check if FCM is initialized
    console.log('1. Checking FCM initialization...');
    if (pushService.messaging) {
      console.log('✅ FCM messaging service initialized');
    } else {
      console.log('❌ FCM messaging service not initialized');
      return;
    }

    // Test 2: Test notification endpoint (requires valid user with FCM token)
    console.log('\n2. Testing notification endpoints...');
    console.log('   Note: This requires a user with FCM token in database');
    console.log('   Use POST /api/notifications/test with authenticated user');

    // Test 3: Validate service methods exist
    console.log('\n3. Validating service methods...');
    const methods = [
      'sendMessageNotification',
      'sendConversationNotification',
      'sendBroadcastNotification',
      'updateUserFCMToken',
      'removeUserFCMToken',
      'isUserOnline'
    ];

    methods.forEach(method => {
      if (typeof pushService[method] === 'function') {
        console.log(`✅ ${method} method exists`);
      } else {
        console.log(`❌ ${method} method missing`);
      }
    });

    console.log('\n🎉 Push notification system validation complete!');
    console.log('\n📋 Next steps:');
    console.log('1. Start the backend server: npm start');
    console.log('2. Test FCM token registration from Flutter app');
    console.log('3. Send a test message to trigger push notification');
    console.log('4. Verify notification appears on device');

  } catch (error) {
    console.error('❌ Error testing notifications:', error.message);
  }
}

// Run the test
testNotifications().catch(console.error);