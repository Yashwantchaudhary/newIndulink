import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ConnectionTest {
  static Future<void> runFullTest(BuildContext context) async {
    print('\n🔧 Running Full Connection Test...\n');

    // Test 1: Check API URL configuration
    print('1️⃣ API Configuration Test:');
    AppConfig.printCurrentApiUrl();

    // Test 2: Test backend connection
    print('\n2️⃣ Backend Connection Test:');
    final isConnected = await AppConfig.testConnection();

    if (isConnected) {
      print('✅ All tests passed! Backend is accessible.');
      if (context.mounted) _showSuccessDialog(context);
    } else {
      print('❌ Connection test failed. Check the troubleshooting steps above.');
      if (context.mounted) _showErrorDialog(context);
    }
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Connection Successful'),
        content: const Text(
          'Backend connection is working properly!\n\n'
          'You can now use login/signup features.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Connection Failed'),
        content: const Text(
          'Cannot connect to backend server.\n\n'
          'Troubleshooting steps:\n'
          '1. Check if Render service is running\n'
          '2. Verify internet connection\n'
          '3. Check https://indulink-1.onrender.com/health\n'
          '4. Contact support if issue persists'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Test production backend
  static Future<void> testMultipleIPs() async {
    final ips = [
      'https://indulink-1.onrender.com',
    ];

    print('\n🔍 Testing multiple IP addresses...\n');

    for (final ip in ips) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);

        final uri = Uri.parse('$ip/health');
        print('Testing: $uri');

        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          print('✅ SUCCESS: $ip is accessible!');
          return;
        } else {
          print('❌ FAILED: $ip returned ${response.statusCode}');
        }
      } catch (e) {
        print('❌ FAILED: $ip - $e');
      }
    }

    print('\n💡 No working IP found. Make sure:');
    print('   - Backend server is running');
    print('   - Port 5000 is not blocked');
    print('   - Devices are on same network');
  }
}