import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'models/order_model.dart';
import 'models/product_model.dart';
import 'models/user_model.dart';
import 'models/stock_log_model.dart';
import 'models/stock_model.dart';
import 'models/report_model.dart';

class MongoDatabase {
  static Db? db;
  static DbCollection? orderCollection;
  static DbCollection? userCollection;
  static DbCollection? productCollection;
  static DbCollection? stockLogCollection;
  static DbCollection? stocksCollection;
  static DbCollection? reportCollection;

  static bool isConnected = false;

  static Future<bool> connect({String? connectionString}) async {
    const String defaultMongoUrl = "mongodb://127.0.0.1:27017/CoffeeShopDB";
    final url = connectionString ?? defaultMongoUrl;

    try {
      final database = await Db.create(url);
      await database.open();
      
      db = database;
      orderCollection = database.collection('orders');
      userCollection = database.collection('users');
      productCollection = database.collection('products');
      stockLogCollection = database.collection('stock_logs');
      stocksCollection = database.collection('stocks');
      reportCollection = database.collection('reports');
      isConnected = true;

      debugPrint("✅ Connected to MongoDB successfully!");
      return true;
    } catch (e) {
      isConnected = false;
      debugPrint("⚠️ MongoDB offline or unreachable: $e. Running with embedded reactive store.");
      return false;
    }
  }

  // --- ORDER DATABASE METHODS ---

  /// Save or update an order into MongoDB database
  static Future<bool> saveOrder(OrderModel order) async {
    if (!isConnected || orderCollection == null) return false;
    try {
      final map = order.toMap();
      await orderCollection!.updateOne(
        where.eq('id', order.id),
        {r'$set': map},
        upsert: true,
      );
      debugPrint("✅ Order ${order.receiptNo} saved to MongoDB!");
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving order to database: $e");
      return false;
    }
  }

  /// Get all orders from MongoDB database
  static Future<List<OrderModel>> getOrders() async {
    if (!isConnected || orderCollection == null) return [];
    try {
      final data = await orderCollection!.find().toList();
      final orders = data.map((json) => OrderModel.fromMap(json)).toList();
      // Sort newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint("✅ Fetched ${orders.length} orders from MongoDB!");
      return orders;
    } catch (e) {
      debugPrint("⚠️ Error fetching orders from database: $e");
      return [];
    }
  }

  /// Seed initial orders if database collection is empty
  static Future<void> seedInitialOrdersIfEmpty(List<OrderModel> initialOrders) async {
    if (!isConnected || orderCollection == null) return;
    try {
      final count = await orderCollection!.count();
      if (count == 0 && initialOrders.isNotEmpty) {
        for (final order in initialOrders) {
          await orderCollection!.insertOne(order.toMap());
        }
        debugPrint("✅ Initial sample orders seeded into database (${initialOrders.length} orders).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding orders into database: $e");
    }
  }

  // --- PRODUCT DATABASE METHODS ---

  static Future<bool> saveProduct(ProductModel product) async {
    if (!isConnected || productCollection == null) return false;
    try {
      final map = product.toMap();
      await productCollection!.updateOne(
        where.eq('id', product.id),
        {r'$set': map},
        upsert: true,
      );
      // Synchronize stocks table
      await saveStockFromProduct(product);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving product to database: $e");
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    if (!isConnected || productCollection == null) return false;
    try {
      await productCollection!.deleteOne(where.eq('id', id));
      await deleteStock(id);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting product: $e");
      return false;
    }
  }

  static Future<List<ProductModel>> getProducts() async {
    if (!isConnected || productCollection == null) return [];
    try {
      final data = await productCollection!.find().toList();
      return data.map((json) => ProductModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching products: $e");
      return [];
    }
  }

  static Future<void> seedInitialProductsIfEmpty(List<ProductModel> initialProducts) async {
    if (!isConnected || productCollection == null) return;
    try {
      final count = await productCollection!.count();
      if (count == 0 && initialProducts.isNotEmpty) {
        for (final prod in initialProducts) {
          await productCollection!.insertOne(prod.toMap());
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding products: $e");
    }
  }

  // --- STOCKS (INVENTORY TABLE) DATABASE METHODS ---

  static Future<bool> saveStock(StockModel stock) async {
    if (!isConnected || stocksCollection == null) return false;
    try {
      final map = stock.toMap();
      await stocksCollection!.updateOne(
        where.eq('id', stock.id),
        {r'$set': map},
        upsert: true,
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving stock item: $e");
      return false;
    }
  }

  static Future<bool> saveStockFromProduct(ProductModel product) async {
    final stockModel = StockModel.fromProduct(product);
    return await saveStock(stockModel);
  }

  static Future<bool> deleteStock(String productId) async {
    if (!isConnected || stocksCollection == null) return false;
    try {
      await stocksCollection!.deleteOne(
        where.eq('productId', productId).or(where.eq('id', 'stock_$productId')),
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting stock: $e");
      return false;
    }
  }

  static Future<List<StockModel>> getStocks() async {
    if (!isConnected || stocksCollection == null) return [];
    try {
      final data = await stocksCollection!.find().toList();
      return data.map((json) => StockModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching stocks: $e");
      return [];
    }
  }

  static Future<void> seedInitialStocksIfEmpty(List<ProductModel> products) async {
    if (!isConnected || stocksCollection == null) return;
    try {
      final count = await stocksCollection!.count();
      if (count == 0 && products.isNotEmpty) {
        for (final prod in products) {
          final stock = StockModel.fromProduct(prod);
          await stocksCollection!.insertOne(stock.toMap());
        }
        debugPrint("✅ Initial stocks table seeded into database (${products.length} stock items).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding stocks into database: $e");
    }
  }

  // --- REPORTS DATABASE METHODS ---

  static Future<bool> saveReport(ReportModel report) async {
    if (!isConnected || reportCollection == null) return false;
    try {
      final map = report.toMap();
      await reportCollection!.updateOne(
        where.eq('id', report.id),
        {r'$set': map},
        upsert: true,
      );
      debugPrint("✅ Report ${report.title} (${report.id}) saved to MongoDB!");
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving report to database: $e");
      return false;
    }
  }

  static Future<bool> saveReportData(Map<String, dynamic> reportData) async {
    if (!isConnected || reportCollection == null) return false;
    try {
      final id = reportData['id']?.toString() ?? 'rep_${DateTime.now().millisecondsSinceEpoch}';
      final map = Map<String, dynamic>.from(reportData)..['id'] = id;
      await reportCollection!.updateOne(
        where.eq('id', id),
        {r'$set': map},
        upsert: true,
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving report data to database: $e");
      return false;
    }
  }

  static Future<List<ReportModel>> getReports({String? reportType, int? limit}) async {
    if (!isConnected || reportCollection == null) return [];
    try {
      final selector = reportType != null ? where.eq('reportType', reportType) : where;
      final data = await reportCollection!.find(selector).toList();
      final reports = data.map((json) => ReportModel.fromMap(json)).toList();
      reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      if (limit != null && reports.length > limit) {
        return reports.sublist(0, limit);
      }
      return reports;
    } catch (e) {
      debugPrint("⚠️ Error fetching reports: $e");
      return [];
    }
  }

  static Future<void> seedInitialReportsIfEmpty(List<ReportModel> initialReports) async {
    if (!isConnected || reportCollection == null) return;
    try {
      final count = await reportCollection!.count();
      if (count == 0 && initialReports.isNotEmpty) {
        for (final report in initialReports) {
          await reportCollection!.insertOne(report.toMap());
        }
        debugPrint("✅ Initial reports table seeded into database (${initialReports.length} reports).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding reports into database: $e");
    }
  }

  // --- STOCK LOGS DATABASE METHODS ---

  static Future<bool> saveStockLog(StockLogModel log) async {
    if (!isConnected || stockLogCollection == null) return false;
    try {
      final map = log.toMap();
      await stockLogCollection!.updateOne(
        where.eq('id', log.id),
        {r'$set': map},
        upsert: true,
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving stock log to database: $e");
      return false;
    }
  }

  static Future<List<StockLogModel>> getStockLogs({String? productId, int? limit}) async {
    if (!isConnected || stockLogCollection == null) return [];
    try {
      final selector = productId != null ? where.eq('productId', productId) : where;
      final data = await stockLogCollection!.find(selector).toList();
      final logs = data.map((json) => StockLogModel.fromMap(json)).toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (limit != null && logs.length > limit) {
        return logs.sublist(0, limit);
      }
      return logs;
    } catch (e) {
      debugPrint("⚠️ Error fetching stock logs: $e");
      return [];
    }
  }

  static Future<void> seedInitialStockLogsIfEmpty(List<StockLogModel> initialLogs) async {
    if (!isConnected || stockLogCollection == null) return;
    try {
      final count = await stockLogCollection!.count();
      if (count == 0 && initialLogs.isNotEmpty) {
        for (final log in initialLogs) {
          await stockLogCollection!.insertOne(log.toMap());
        }
        debugPrint("✅ Initial stock logs seeded into database (${initialLogs.length} logs).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding stock logs: $e");
    }
  }

  // --- USER DATABASE METHODS ---

  static Future<void> seedInitialUsersIfEmpty(List<UserModel> initialUsers, Map<String, String> passwords) async {
    if (!isConnected || userCollection == null) return;
    try {
      final count = await userCollection!.count();
      if (count == 0 && initialUsers.isNotEmpty) {
        for (final user in initialUsers) {
          final pw = passwords[user.email] ?? passwords[user.username] ?? 'password';
          final map = user.toMap()..addAll({'password': pw});
          await userCollection!.insertOne(map);
        }
        debugPrint("✅ Initial users seeded into database (${initialUsers.length} users).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding users into database: $e");
    }
  }

  static Future<bool> saveUser(UserModel user, String password) async {
    if (!isConnected || userCollection == null) return false;
    try {
      final map = user.toMap()..addAll({'password': password});
      await userCollection!.updateOne(
        where.eq('id', user.id),
        {r'$set': map},
        upsert: true,
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving user: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersWithPasswords() async {
    if (!isConnected || userCollection == null) return [];
    try {
      return await userCollection!.find().toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching users: $e");
      return [];
    }
  }

  static void logout() {
    debugPrint("✅ User session logged out.");
  }
}
