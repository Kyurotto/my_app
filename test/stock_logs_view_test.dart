import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/stock_log_model.dart';
import 'package:my_app/widgets/stock_logs_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockLogModel & StockLogsView Tests', () {
    test('StockLogModel initializes SKU properly and provides productSku getter', () {
      final logExplicitSku = StockLogModel(
        id: 'log_100',
        productId: 'prod_1',
        sku: 'SKU-PROD1',
        productName: 'Classic Milk Tea',
        change: 10,
        previousStock: 20,
        newStock: 30,
        type: 'restock',
        reason: 'Restock shipment',
        performedBy: 'Admin User',
      );

      expect(logExplicitSku.sku, equals('SKU-PROD1'));
      expect(logExplicitSku.productSku, equals('SKU-PROD1'));
      expect(logExplicitSku.productId, equals('prod_1'));

      final logFallbackSku = StockLogModel(
        id: 'log_101',
        productId: 'prod_99',
        productName: 'Taro Milk Tea',
        change: 5,
        previousStock: 10,
        newStock: 15,
        type: 'restock',
        reason: 'Restock',
        performedBy: 'Admin User',
      );

      expect(logFallbackSku.sku, equals('SKU-PROD99'));
      expect(logFallbackSku.productSku, equals('SKU-PROD99'));
      expect(logFallbackSku.productId, equals('prod_99'));
    });

    test('StockLogModel toMap and fromMap preserve sku and productId', () {
      final log = StockLogModel(
        id: 'log_102',
        productId: 'prod_cheese',
        sku: 'SKU-CHEESE-01',
        productName: 'Cheese Foam',
        change: -2,
        previousStock: 10,
        newStock: 8,
        type: 'sale',
        reason: 'POS Sale',
        performedBy: 'Employee User',
      );

      final map = log.toMap();
      expect(map['sku'], equals('SKU-CHEESE-01'));
      expect(map['productId'], equals('prod_cheese'));

      final restored = StockLogModel.fromMap(map);
      expect(restored.sku, equals('SKU-CHEESE-01'));
      expect(restored.productSku, equals('SKU-CHEESE-01'));
      expect(restored.productId, equals('prod_cheese'));
    });

    testWidgets('StockLogsView displays SKU and filters by SKU and Product ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockLogsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure SKU is rendered in parentheses (e.g. (SKU-PROD1))
      expect(find.text('(SKU-PROD1)'), findsWidgets);

      // Search by SKU
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'SKU-PROD5');
      await tester.pumpAndSettle();

      expect(find.text('Cheese Foam Milk Tea'), findsWidgets);
      expect(find.text('Classic Milk Tea'), findsNothing);

      // Search by Product ID
      await tester.enterText(searchField, 'prod_1');
      await tester.pumpAndSettle();

      expect(find.text('Classic Milk Tea'), findsWidgets);
      expect(find.text('Cheese Foam Milk Tea'), findsNothing);
    });
  });
}
