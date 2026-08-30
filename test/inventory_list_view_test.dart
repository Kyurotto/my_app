import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/widgets/inventory_list_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductModel & InventoryListView Margin Tests', () {
    test('ProductModel.profitMargin calculates percentage in 0-100 range', () {
      final product = ProductModel(
        id: 'test_prod',
        name: 'Test Product',
        description: 'Test description',
        price: 10.0,
        costPrice: 5.0,
        stock: 20,
        minStock: 5,
        category: 'milktea',
      );

      // (10 - 5) / 10 * 100 = 50.0%
      expect(product.profitMargin, equals(50.0));
      expect(product.profitMarginPercent, equals(50.0));
    });

    testWidgets('InventoryListView renders margin correctly without multiplying by 100 twice', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InventoryListView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure that we don't have unreasonable 4-digit percentage margins like 5000% or 6000%
      expect(find.textContaining('5000%'), findsNothing);
      expect(find.textContaining('6000%'), findsNothing);
      expect(find.textContaining('7000%'), findsNothing);
      expect(find.textContaining('Margin: '), findsWidgets);
    });
  });
}
