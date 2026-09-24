import 'package:flutter_test/flutter_test.dart';

import 'package:medicare/features/auth/auth_screens.dart';
import 'package:medicare/main.dart';

void main() {
  testWidgets('starts with the Arabic Medicare onboarding flow', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicareApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('رعايتك الصحية تبدأ بسهولة'), findsOneWidget);
  });
}