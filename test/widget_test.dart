import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resume_builder_ai/screens/login_screen.dart';
import 'package:resume_builder_ai/services/auth_service.dart';

void main() {
  testWidgets('LoginScreen shows email/password fields and a login button', (
    WidgetTester tester,
  ) async {
    // AuthService is provided lazily: nothing here touches FirebaseAuth
    // unless a button is pressed, so no Firebase.initializeApp() is needed.
    await tester.pumpWidget(
      Provider<AuthService>(
        create: (_) => AuthService(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Log In'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });
}
