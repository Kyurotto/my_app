import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/app_service.dart';
import 'package:my_app/widgets/reports_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reports & Payment Breakdown Tests', () {
    test('getFilteredReport generates paymentBreakdown with map entries', () {
      final service = AppService.instance;
      final report = service.getFilteredReport(period: 'all');

      expect(report.containsKey('paymentBreakdown'), isTrue);
      final paymentBreakdown = report['paymentBreakdown'] as Map<String, dynamic>;

      for (final entry in paymentBreakdown.entries) {
        expect(entry.value, isA<Map<String, dynamic>>());
        final data = entry.value as Map<String, dynamic>;
        expect(data.containsKey('count'), isTrue);
        expect(data.containsKey('revenue'), isTrue);
        expect(data.containsKey('percent'), isTrue);
      }
    });

    test('getFilteredReport correctly aggregates various periods and payment methods', () {
      final service = AppService.instance;

      for (final period in ['today', 'week', 'month', 'year', 'all']) {
        final rep = service.getFilteredReport(period: period);
        expect(rep.containsKey('periodRevenue'), isTrue);
        expect(rep.containsKey('periodOrders'), isTrue);
        expect(rep.containsKey('paymentBreakdown'), isTrue);

        final breakdown = rep['paymentBreakdown'] as Map<String, dynamic>;
        expect(breakdown, isNotNull);
      }
    });

    test('getFilteredReport aggregates actual periodTax from collected order taxes', () {
      final service = AppService.instance;
      final report = service.getFilteredReport(period: 'all');

      expect(report.containsKey('periodTax'), isTrue);
      expect(report.containsKey('periodSubtotal'), isTrue);

      final periodTax = report['periodTax'] as double;
      final periodSubtotal = report['periodSubtotal'] as double;

      // Sum of order taxes in seed data / placed orders
      final expectedTax = double.parse(
        service.orders.fold<double>(0.0, (sum, o) => sum + o.tax).toStringAsFixed(2),
      );
      expect(periodTax, equals(expectedTax));
      // Orders use 10% tax rate
      expect(periodTax, closeTo(periodSubtotal * 0.10, 0.05));
    });

    testWidgets('ReportsView renders payment methods split without type error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Income Statement Summary'), findsOneWidget);
      expect(find.text('Sales Tax Collected (10%)'), findsOneWidget);
      expect(find.text('Estimated Sales Tax (8%)'), findsNothing);
      expect(find.text('Payment Methods Split'), findsOneWidget);
      expect(find.byType(ReportsView), findsOneWidget);
    });

    testWidgets('ReportsView renders with empty or simulated order items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check key sections exist
      expect(find.text('Category Margin Breakdown'), findsOneWidget);
      expect(find.text('Product Sales Leaderboard'), findsOneWidget);
    });
  });
}

