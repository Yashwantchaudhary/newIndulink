import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core
import 'core/theme/app_theme.dart';

// Services
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/cached_api_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'providers/language_provider.dart';
import 'providers/address_provider.dart';
import 'providers/rfq_provider.dart';
import 'providers/review_provider.dart';
import 'providers/websocket_provider.dart';
import 'providers/export_provider.dart';
import 'providers/analytics_provider.dart';

// Routes
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'routes/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service first
  await StorageService().init();

  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  // Initialize Cached API Service
  try {
    await CachedApiService().initialize();
    debugPrint('Cached API service initialized successfully');
  } catch (e) {
    debugPrint('Cached API service initialization error: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const IndulinkApp());
}

class IndulinkApp extends StatefulWidget {
  const IndulinkApp({super.key});

  @override
  State<IndulinkApp> createState() => _IndulinkAppState();
}

class _IndulinkAppState extends State<IndulinkApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth and theme providers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a safe context that has access to providers
      final buildContext = NavigationService().currentContext;
      if (buildContext != null) {
        final authProvider =
            Provider.of<AuthProvider>(buildContext, listen: false);
        authProvider.init();

        final themeProvider =
            Provider.of<ThemeProvider>(buildContext, listen: false);
        themeProvider.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        // Product & Search Providers
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),

        // Shopping Providers
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // Communication Providers
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),

        // User Data Providers
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => RFQProvider()),

        // Real-time Updates
        ChangeNotifierProxyProvider<AuthProvider, WebSocketProvider>(
          create: (context) => WebSocketProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) =>
              previous ?? WebSocketProvider(authProvider),
        ),

        // Data Export/Import
        ChangeNotifierProvider(create: (_) => ExportProvider()),

        // Analytics and Reporting
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            key: ValueKey(
                themeProvider.themeMode), // Prevents GlobalKey conflicts
            title: 'INDULINK',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Navigation
            navigatorKey: NavigationService().navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRoutes.splash,

            // Localization (for future implementation)
            // localizationsDelegates: AppLocalizations.localizationsDelegates,
            // supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
