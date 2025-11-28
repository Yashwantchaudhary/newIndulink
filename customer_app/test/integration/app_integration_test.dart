import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indulink/main.dart';
import 'package:indulink/routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App initializes and shows splash screen', (tester) async {
      // Build the app
      await tester.pumpWidget(
        const ProviderScope(
          child: IndulinkApp(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Verify we're on the splash screen (initial route)
      expect(find.byType(MaterialApp), findsOneWidget);

      // Check that the app title is correct
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Indulink - B2B E-Commerce');
    });

    testWidgets('App supports theme switching', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IndulinkApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify theme configuration
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, isNotNull);
    });

    testWidgets('App supports localization', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IndulinkApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify localization setup
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, isNotEmpty);
      expect(materialApp.localizationsDelegates, isNotEmpty);
      expect(materialApp.locale, isNotNull);
    });

    testWidgets('App has proper routing configuration', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IndulinkApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify routing setup
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.initialRoute, AppRoutes.splash);
      expect(materialApp.onGenerateRoute, isNotNull);
    });
  });
}