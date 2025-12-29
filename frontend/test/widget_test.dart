import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/auth_screen.dart';

void main() {
  testWidgets('App starts at Auth Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We pass AuthScreen as the startScreen since we are testing the initial launch.
    await tester.pumpWidget(const MyApp(startScreen: AuthScreen()));

    // Verify that the "VibeSync" title is present (from the AuthScreen).
    expect(find.text('VibeSync'), findsOneWidget);

    // Verify that the "Login" button is present.
    expect(find.text('Login'), findsOneWidget);

    // Verify that we are NOT seeing a counter (just to be sure old code is gone).
    expect(find.text('0'), findsNothing);
  });
}