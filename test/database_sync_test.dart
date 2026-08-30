import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/database.dart';
import 'package:my_app/services/app_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Connect to MongoDB, seed collections, and verify stocks and reports exist', () async {
    final connected = await MongoDatabase.connect();
    expect(connected, isTrue, reason: 'MongoDB should be reachable on localhost:27017');

    // Run the full database synchronization
    await AppService.instance.syncWithDatabase();

    // Verify all collections in MongoDatabase
    expect(MongoDatabase.stocksCollection, isNotNull);
    expect(MongoDatabase.reportCollection, isNotNull);
    expect(MongoDatabase.productCollection, isNotNull);
    expect(MongoDatabase.orderCollection, isNotNull);
    expect(MongoDatabase.userCollection, isNotNull);
    expect(MongoDatabase.stockLogCollection, isNotNull);

    // Verify stocks count
    final stocks = await MongoDatabase.getStocks();
    expect(stocks.isNotEmpty, isTrue, reason: 'stocks collection should have seeded documents');
    print('✅ Verified stocks collection count: ${stocks.length}');

    // Verify reports count
    final reports = await MongoDatabase.getReports();
    expect(reports.isNotEmpty, isTrue, reason: 'reports collection should have seeded documents');
    print('✅ Verified reports collection count: ${reports.length}');

    for (final r in reports) {
      print('   - Report ID: ${r.id}, Type: ${r.reportType}, Title: ${r.title}');
    }

    // Verify DB collection list directly from mongo_dart
    final collections = await MongoDatabase.db!.getCollectionNames();
    print('✅ Collections present in CoffeeShopDB: $collections');
    expect(collections.contains('stocks'), isTrue, reason: 'Database must contain "stocks" collection');
    expect(collections.contains('reports'), isTrue, reason: 'Database must contain "reports" collection');
  });
}
