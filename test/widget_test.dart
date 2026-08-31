import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('App smoke test builds login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CoffeeApp());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Coffee Shop POS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
