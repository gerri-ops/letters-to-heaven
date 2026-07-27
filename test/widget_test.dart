import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/theme/app_theme.dart';
import 'package:letters_to_heaven/features/onboarding/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WelcomeScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Letters to Heaven'), findsOneWidget);
    expect(find.text('Save the little things before time carries them away.'), findsOneWidget);
    expect(find.text('Begin Gently'), findsOneWidget);
  });
}
