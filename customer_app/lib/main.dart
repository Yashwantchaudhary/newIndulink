import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_theme.dart';
import 'config/firebase_config.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'services/monitoring_service.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';
import 'routes.dart';
import 'widgets/common/error_boundary.dart';
import 'utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services with error handling
  try {
    // Initialize Firebase first
    await FirebaseConfig.initialize();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Initialize other services with error handling
  try {
    // Initialize notification service
    await NotificationService().initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Notification service failed: $e');
  }

  try {
    // Initialize connectivity service
    ConnectivityService();
    print('✅ Connectivity service initialized');
  } catch (e) {
    print('❌ Connectivity service failed: $e');
  }

  runApp(
    const ProviderScope(
      child: IndulinkApp(),
    ),
  );
}

class IndulinkApp extends ConsumerWidget {
  const IndulinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Indulink - B2B E-Commerce',
      debugShowCheckedModeBanner: false,

      // Localization support
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ne'),
        Locale('es'),
        Locale('bn'),
        Locale('ta'),
        Locale('te'),
        Locale('ml'),
        Locale('ur'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme configuration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),

      // Routing - start with splash screen
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
