import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Core
import 'core/theme/app_theme.dart';

// Services
import 'services/storage_service.dart';

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

// Routes
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'routes/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service first
  await StorageService().init();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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

class IndulinkApp extends StatelessWidget {
  const IndulinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..init()),

        // Product & Search Providers
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()..init()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()..init()),

        // Shopping Providers
        ChangeNotifierProvider(create: (_) => CartProvider()..init()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // Communication Providers
        ChangeNotifierProvider(create: (_) => NotificationProvider()..init()),
        ChangeNotifierProvider(create: (_) => MessageProvider()..init()),

        // User Data Providers
        ChangeNotifierProvider(create: (_) => AddressProvider()..init()),
        ChangeNotifierProvider(create: (_) => RFQProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
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
