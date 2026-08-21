import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('App smoke test builds login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CoffeeApp());
    await tester.pumpAndSettle();

    expect(find.text('Coffee Shop POS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
