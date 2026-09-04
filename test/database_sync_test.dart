import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/database.dart';
import 'package:my_app/services/app_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Connect to MySQL, seed tables, and verify stocks and reports exist', () async {
    final connected = await MySqlDatabase.connect();
    expect(connected, isTrue, reason: 'MySQL should be reachable on localhost:3306');

    // Run the full database synchronization
    await AppService.instance.syncWithDatabase();

    // Verify all table handles in MySqlDatabase
    expect(MySqlDatabase.stocksCollection, isNotNull);
    expect(MySqlDatabase.reportCollection, isNotNull);
    expect(MySqlDatabase.productCollection, isNotNull);
    expect(MySqlDatabase.orderCollection, isNotNull);
    expect(MySqlDatabase.userCollection, isNotNull);
    expect(MySqlDatabase.stockLogCollection, isNotNull);

    // Verify stocks count
    final stocks = await MySqlDatabase.getStocks();
    expect(stocks.isNotEmpty, isTrue, reason: 'stocks table should have seeded records');
    // ignore: avoid_print
    print('✅ Verified stocks table count: ${stocks.length}');

    // Verify reports count
    final reports = await MySqlDatabase.getReports();
    expect(reports.isNotEmpty, isTrue, reason: 'reports table should have seeded records');
    // ignore: avoid_print
    print('✅ Verified reports table count: ${reports.length}');

    for (final r in reports) {
      // ignore: avoid_print
      print('   - Report ID: ${r.id}, Type: ${r.reportType}, Title: ${r.title}');
    }

    // Verify tables directly from MySQL
    final tableResults = await MySqlDatabase.db!.query('SHOW TABLES');
    final tables = tableResults.map((row) => row.values?.first?.toString() ?? '').toList();
    // ignore: avoid_print
    print('✅ Tables present in MySQL: $tables');
    expect(tables.contains('stocks'), isTrue, reason: 'Database must contain "stocks" table');
    expect(tables.contains('reports'), isTrue, reason: 'Database must contain "reports" table');
  });
}
