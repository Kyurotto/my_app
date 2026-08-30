import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/app_service.dart';
import 'package:my_app/widgets/stock_adjust_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockAdjustModal Input Validation Tests', () {
    late ProductModel testProduct;

    setUp(() {
      testProduct = ProductModel(
        id: 'test_prod_adj',
        name: 'Adjustment Test Tea',
        description: 'Test Description',
        price: 5.0,
        costPrice: 2.5,
        stock: 20,
        minStock: 10,
        category: 'milktea',
      );
      // Ensure product is in AppService
      final service = AppService.instance;
      if (!service.products.any((p) => p.id == testProduct.id)) {
        service.addProduct(testProduct);
      }
    });

    testWidgets('Rejects negative stock level when action type is adjustment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockAdjustModal(product: testProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch dropdown to 'adjustment'
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚖️ Count Reconciliation (=)').last);
      await tester.pumpAndSettle();

      // Enter a negative stock level
      final textFormField = find.widgetWithText(TextFormField, 'New Exact Stock Level');
      expect(textFormField, findsOneWidget);
      await tester.enterText(textFormField, '-5');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save & Update DB'));
      await tester.pumpAndSettle();

      // Validation error must be visible
      expect(find.text('Stock level cannot be negative'), findsOneWidget);
      // Modal should NOT have dismissed
      expect(find.byType(StockAdjustModal), findsOneWidget);
    });

    testWidgets('Allows 0 and positive stock level when action type is adjustment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockAdjustModal(product: testProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch dropdown to 'adjustment'
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚖️ Count Reconciliation (=)').last);
      await tester.pumpAndSettle();

      // Enter 0 as exact stock level
      final textFormField = find.widgetWithText(TextFormField, 'New Exact Stock Level');
      await tester.enterText(textFormField, '0');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save & Update DB'));
      await tester.pumpAndSettle();

      // No validation error
      expect(find.text('Stock level cannot be negative'), findsNothing);
    });

    testWidgets('Rejects <= 0 quantities when action type is restock or damage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockAdjustModal(product: testProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is restock. Enter 0.
      final textFormField = find.byType(TextFormField).first;
      await tester.enterText(textFormField, '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Update DB'));
      await tester.pumpAndSettle();

      expect(find.text('Quantity must be greater than 0'), findsOneWidget);
    });
  });
}
