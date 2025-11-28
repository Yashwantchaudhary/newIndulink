# Flutter Integration Testing Suite

This directory contains comprehensive integration tests for the Indulink Flutter mobile application, ensuring end-to-end functionality across the entire user interface and user workflows.

## Overview

The Flutter integration testing suite covers:

- **App Initialization**: Proper app startup, theme configuration, localization
- **Authentication Flows**: Complete login/register/logout UI workflows
- **E-commerce User Journeys**: Product browsing, cart management, checkout flow
- **Navigation Testing**: Screen transitions and deep linking
- **UI Component Integration**: Widget interactions and state management
- **Cross-platform Consistency**: Web and mobile platform behavior
- **Real-time Features**: Push notifications, live updates in UI
- **Performance Testing**: UI rendering performance and memory usage

## Test Structure

```
test/
├── integration/               # Integration tests
│   ├── app_integration_test.dart
│   ├── auth_flow_integration_test.dart
│   ├── e2e_shopping_flow_test.dart
│   └── ...
├── unit/                      # Unit tests
├── widget/                    # Widget tests
└── golden/                    # Golden tests
```

## Running Tests

### All Integration Tests
```bash
flutter test integration_test/
```

### Specific Test Files
```bash
flutter test integration_test/app_integration_test.dart
flutter test integration_test/auth_flow_integration_test.dart
```

### With Device/Emulator
```bash
flutter test integration_test/ --device-id=<device_id>
```

### Web Platform Testing
```bash
flutter test integration_test/ --platform=chrome
```

## Test Environment Setup

### Dependencies
The following packages are required for integration testing:
- `integration_test` (already in pubspec.yaml)
- `mockito` for mocking
- `http` for HTTP client mocking

### Test Configuration
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test setup code here
}
```

## Writing Integration Tests

### Basic Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indulink/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integration Tests', () {
    testWidgets('Complete user workflow', (tester) async {
      // Build the app
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Perform UI interactions
      await tester.tap(find.byType(MyButton));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.text('Expected Result'), findsOneWidget);
    });
  });
}
```

### Testing User Interactions
```dart
// Text input
await tester.enterText(find.byType(TextField), 'test input');

// Button taps
await tester.tap(find.byKey(const Key('submit_button')));

// Scrolling
await tester.drag(find.byType(ListView), const Offset(0, -300));

// Waiting for async operations
await tester.pumpAndSettle();
```

### Testing Navigation
```dart
// Verify current screen
expect(find.byType(LoginScreen), findsOneWidget);

// Navigate to new screen
await tester.tap(find.text('Go to Profile'));
await tester.pumpAndSettle();

// Verify navigation
expect(find.byType(ProfileScreen), findsOneWidget);
```

### Testing State Management (Riverpod)
```dart
// Override providers for testing
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      authProvider.overrideWithValue(mockAuthState),
    ],
    child: const MyApp(),
  ),
);
```

## Test Categories

### App Initialization Tests
- App startup and configuration
- Theme and localization setup
- Initial route navigation
- Service initialization

### Authentication Flow Tests
- Login form validation
- Registration process
- Password visibility toggle
- Error handling and messaging
- Session persistence

### E-commerce Flow Tests
- Product browsing and search
- Cart operations (add/remove/update)
- Wishlist management
- Checkout process
- Order confirmation

### Navigation Tests
- Bottom navigation bar
- Drawer navigation
- Deep linking
- Back button behavior

### Real-time Feature Tests
- Push notification display
- Live data updates
- WebSocket connection status
- Offline/online state handling

## Mocking and Test Data

### HTTP Client Mocking
```dart
class MockHttpClient extends Mock implements http.Client {}

setUp(() {
  mockHttpClient = MockHttpClient();
  // Configure mock responses
  when(mockHttpClient.get(any))
      .thenAnswer((_) async => http.Response('{"data": "mock"}', 200));
});
```

### Provider Overrides
```dart
final mockAuthProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..state = mockAuthState;
});
```

## Best Practices

### Test Isolation
- Each test should be independent
- Use unique test data
- Clean up after tests

### Realistic Scenarios
- Test complete user journeys
- Include error states and edge cases
- Test on multiple screen sizes

### Performance Considerations
- Use `pumpAndSettle()` judiciously
- Avoid unnecessary waits
- Test on actual devices when possible

### Maintainable Tests
- Use descriptive test names
- Group related tests
- Keep tests focused and concise

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Flutter Integration Tests
  run: |
    cd customer_app
    flutter test integration_test/
  env:
    FLUTTER_TEST: true
```

### Test Reporting
- Integration with test dashboards
- Screenshot capture on failures
- Performance metrics collection

## Troubleshooting

### Common Issues

#### Widget Not Found
```dart
// Use keys for reliable widget location
final button = find.byKey(const Key('submit_button'));

// Or use more specific finders
final button = find.widgetWithText(ElevatedButton, 'Submit');
```

#### Timing Issues
```dart
// Wait for specific duration
await tester.pump(const Duration(seconds: 1));

// Wait for settling with timeout
await tester.pumpAndSettle(const Duration(seconds: 5));
```

#### Provider Dependencies
```dart
// Override providers that have dependencies
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(mockRepository),
    ],
    child: const MyApp(),
  ),
);
```

## Contributing

### Adding New Tests
1. Create test file in `test/integration/`
2. Follow naming convention: `feature_integration_test.dart`
3. Include proper setup and teardown
4. Add documentation for complex scenarios

### Test Coverage
- Focus on critical user paths
- Include accessibility testing
- Test error scenarios thoroughly

### Code Review
- Tests should be reviewed alongside features
- Ensure tests are reliable and fast
- Verify test maintainability