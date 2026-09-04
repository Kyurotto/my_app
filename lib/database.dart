import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:mysql1/mysql1.dart';
import 'models/order_model.dart';
import 'models/product_model.dart';
import 'models/user_model.dart';
import 'models/stock_log_model.dart';
import 'models/stock_model.dart';
import 'models/report_model.dart';
import 'utils/password_hasher.dart';

class MySqlDatabase {
  static MySqlConnection? db;

  // Compatibility handles for existing services and tests
  static Object? orderCollection;
  static Object? userCollection;
  static Object? productCollection;
  static Object? stockLogCollection;
  static Object? stocksCollection;
  static Object? reportCollection;

  static bool isConnected = false;
  static ConnectionSettings? _cachedSettings;

  /// Format DateTime to standard MySQL DATETIME string: YYYY-MM-DD HH:MM:SS
  static String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  /// Parse DateTime safely from MySQL timestamp or string
  static DateTime _parseDateTime(dynamic val) {
    if (val is DateTime) return val;
    if (val == null) return DateTime.now();
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  /// Helper to get an active MySQL connection or reconnect if needed
  static Future<MySqlConnection?> _getConnection() async {
    if (db != null) return db;
    if (_cachedSettings != null) {
      try {
        db = await MySqlConnection.connect(_cachedSettings!);
        isConnected = true;
        return db;
      } catch (e) {
        debugPrint("⚠️ MySQL reconnection failed: $e");
        isConnected = false;
        return null;
      }
    }
    return null;
  }

  /// Connect to MySQL / MariaDB database
  static Future<bool> connect({
    String? connectionString,
    String? host,
    int? port,
    String? user,
    String? password,
    String? databaseName,
    bool secure = false,
  }) async {
    // Default connection parameters (matching local XAMPP / MariaDB / MySQL)
    String defaultHost = '127.0.0.1';
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          defaultHost = '10.0.2.2'; // Standard loopback to host PC XAMPP from Android emulator
        }
      } catch (_) {}
    }

    String effectiveHost = host ?? defaultHost;
    int effectivePort = port ?? 3306;
    String effectiveUser = user ?? 'root';
    String? effectivePassword = (password != null && password.isNotEmpty) ? password : null;
    String effectiveDb = databaseName ?? 'coffee';

    // Parse URI if connectionString was provided (e.g. mysql://root:pass@127.0.0.1:3306/coffee)
    if (connectionString != null && connectionString.isNotEmpty) {
      try {
        final uri = Uri.parse(connectionString);
        if (uri.host.isNotEmpty) effectiveHost = uri.host;
        if (uri.hasPort) effectivePort = uri.port;
        if (uri.userInfo.isNotEmpty) {
          final parts = uri.userInfo.split(':');
          effectiveUser = parts[0];
          if (parts.length > 1 && parts[1].isNotEmpty) {
            effectivePassword = parts[1];
          }
        }
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty) {
          effectiveDb = uri.pathSegments.first;
        }
      } catch (e) {
        debugPrint("⚠️ Could not parse MySQL connection string: $e. Using default parameters.");
      }
    }

    try {
      final settings = ConnectionSettings(
        host: effectiveHost,
        port: effectivePort,
        user: effectiveUser,
        password: effectivePassword,
        db: effectiveDb,
      );
      _cachedSettings = settings;

      final connection = await MySqlConnection.connect(settings);
      db = connection;

      // Initialize all required tables and schema migrations
      await _initializeSchema(connection);

      isConnected = true;
      orderCollection = 'orders';
      userCollection = 'users';
      productCollection = 'products';
      stockLogCollection = 'stock_logs';
      stocksCollection = 'stocks';
      reportCollection = 'reports';

      debugPrint("✅ Connected to MySQL database ($effectiveDb) successfully!");
      return true;
    } catch (e) {
      isConnected = false;
      db = null;
      orderCollection = null;
      userCollection = null;
      productCollection = null;
      stockLogCollection = null;
      stocksCollection = null;
      reportCollection = null;
      debugPrint("⚠️ MySQL offline or unreachable: $e. Running with embedded reactive store.");
      return false;
    }
  }

  /// Initialize all required tables and schema migrations
  static Future<void> _initializeSchema(MySqlConnection conn) async {
    try {
      // 1. Users table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS users (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) NOT NULL UNIQUE,
          email_verified_at TIMESTAMP NULL,
          password VARCHAR(255) NOT NULL,
          remember_token VARCHAR(100) NULL,
          created_at TIMESTAMP NULL,
          updated_at TIMESTAMP NULL
        )
      ''');

      // 2. Employees table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS employees (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          user_id BIGINT UNSIGNED NOT NULL UNIQUE,
          role VARCHAR(255) NOT NULL,
          employee_code VARCHAR(255) NOT NULL UNIQUE,
          created_at TIMESTAMP NULL,
          updated_at TIMESTAMP NULL
        )
      ''');

      // 3. Products table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS products (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT NULL,
          price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          category VARCHAR(100) NOT NULL DEFAULT 'milktea',
          image_path VARCHAR(255) NULL,
          stock INT NOT NULL DEFAULT 25,
          min_stock INT NOT NULL DEFAULT 10,
          sku VARCHAR(100) NULL,
          unit VARCHAR(50) NOT NULL DEFAULT 'units',
          created_at TIMESTAMP NULL,
          updated_at TIMESTAMP NULL
        )
      ''');

      try {
        await conn.query('''
          ALTER TABLE products
            ADD COLUMN IF NOT EXISTS cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
            ADD COLUMN IF NOT EXISTS stock INT NOT NULL DEFAULT 25,
            ADD COLUMN IF NOT EXISTS min_stock INT NOT NULL DEFAULT 10,
            ADD COLUMN IF NOT EXISTS sku VARCHAR(100) NULL,
            ADD COLUMN IF NOT EXISTS unit VARCHAR(50) NOT NULL DEFAULT 'units'
        ''');
      } catch (_) {}

      // 4. Orders table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS orders (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          user_id BIGINT UNSIGNED NOT NULL,
          receipt_no VARCHAR(255) NOT NULL UNIQUE,
          subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          tax DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          status VARCHAR(255) NOT NULL DEFAULT 'completed',
          payment_method VARCHAR(255) NOT NULL DEFAULT 'physical',
          created_at TIMESTAMP NULL,
          updated_at TIMESTAMP NULL
        )
      ''');

      // 5. Order items table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS order_items (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          order_id BIGINT UNSIGNED NOT NULL,
          product_id BIGINT UNSIGNED NOT NULL,
          product_name VARCHAR(255) NOT NULL,
          unit_price DECIMAL(10, 2) NOT NULL,
          quantity INT UNSIGNED NOT NULL,
          subtotal DECIMAL(10, 2) NOT NULL,
          created_at TIMESTAMP NULL,
          updated_at TIMESTAMP NULL
        )
      ''');

      // 6. Stocks table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS stocks (
          id VARCHAR(100) PRIMARY KEY,
          product_id VARCHAR(100) NOT NULL,
          product_name VARCHAR(255) NOT NULL,
          sku VARCHAR(100) NULL,
          category VARCHAR(100) NOT NULL DEFAULT 'milktea',
          current_stock INT NOT NULL DEFAULT 0,
          min_stock INT NOT NULL DEFAULT 10,
          unit VARCHAR(50) NOT NULL DEFAULT 'pcs',
          cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          selling_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          stock_value_cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          stock_value_selling DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
          status VARCHAR(50) NOT NULL DEFAULT 'in_stock',
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
      ''');

      // 7. Stock audit logs table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS stock_logs (
          id VARCHAR(100) PRIMARY KEY,
          product_id VARCHAR(100) NOT NULL,
          sku VARCHAR(100) NULL,
          product_name VARCHAR(255) NOT NULL,
          stock_change INT NOT NULL DEFAULT 0,
          previous_stock INT NOT NULL DEFAULT 0,
          new_stock INT NOT NULL DEFAULT 0,
          type VARCHAR(50) NOT NULL DEFAULT 'adjustment',
          reason TEXT NULL,
          performed_by VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // 8. Reports table
      await conn.query('''
        CREATE TABLE IF NOT EXISTS reports (
          id VARCHAR(100) PRIMARY KEY,
          report_type VARCHAR(100) NOT NULL,
          title VARCHAR(255) NOT NULL,
          period VARCHAR(50) NOT NULL,
          generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          generated_by VARCHAR(255) NOT NULL,
          metrics LONGTEXT NULL,
          inventory_summary LONGTEXT NULL,
          notes TEXT NULL
        )
      ''');
    } catch (e) {
      debugPrint("Note during MySQL schema initialization: $e");
    }
  }

  // --- ORDER DATABASE METHODS ---

  /// Save or update an order into MySQL database
  static Future<bool> saveOrder(OrderModel order) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      // Find matching user id or fallback to first user
      int userId = int.tryParse(order.userId) ?? 1;
      if (userId == 0) {
        final uRes = await conn.query('SELECT id FROM users LIMIT 1');
        if (uRes.isNotEmpty) {
          userId = (uRes.first['id'] as num).toInt();
        }
      }

      final dateStr = _formatDateTime(order.createdAt);

      // Check if order already exists by receipt_no
      final existing = await conn.query(
        'SELECT id FROM orders WHERE receipt_no = ?',
        [order.receiptNo],
      );

      int orderId;
      if (existing.isNotEmpty) {
        orderId = (existing.first['id'] as num).toInt();
        await conn.query('''
          UPDATE orders
          SET user_id = ?, subtotal = ?, tax = ?, total = ?, status = ?, payment_method = ?, updated_at = ?
          WHERE id = ?
        ''', [
          userId,
          order.subtotal,
          order.tax,
          order.total,
          order.status,
          order.paymentMethod,
          dateStr,
          orderId,
        ]);

        // Remove old order items to replace with updated list
        await conn.query('DELETE FROM order_items WHERE order_id = ?', [orderId]);
      } else {
        final result = await conn.query('''
          INSERT INTO orders (user_id, receipt_no, subtotal, tax, total, status, payment_method, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          userId,
          order.receiptNo,
          order.subtotal,
          order.tax,
          order.total,
          order.status,
          order.paymentMethod,
          dateStr,
          dateStr,
        ]);
        orderId = result.insertId ?? 1;
      }

      // Insert order items
      for (final item in order.items) {
        final prodId = int.tryParse(item.productId) ?? 1;
        await conn.query('''
          INSERT INTO order_items (order_id, product_id, product_name, unit_price, quantity, subtotal, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          orderId,
          prodId,
          item.productName,
          item.unitPrice,
          item.quantity,
          item.subtotal,
          dateStr,
          dateStr,
        ]);
      }

      debugPrint("✅ Order ${order.receiptNo} saved to MySQL!");
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving order to MySQL: $e");
      return false;
    }
  }

  /// Get all orders from MySQL database
  static Future<List<OrderModel>> getOrders() async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      final orderRows = await conn.query('''
        SELECT o.id, o.receipt_no, o.user_id, COALESCE(u.name, 'Cashier') AS cashier_name,
               o.subtotal, o.tax, o.total, o.payment_method, o.status, o.created_at
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        ORDER BY o.created_at DESC
      ''');

      final itemRows = await conn.query('SELECT * FROM order_items');
      final itemsByOrderId = <String, List<OrderItemModel>>{};
      for (final item in itemRows) {
        final orderId = item['order_id'].toString();
        itemsByOrderId.putIfAbsent(orderId, () => []).add(
          OrderItemModel(
            productId: item['product_id'].toString(),
            productName: item['product_name']?.toString() ?? '',
            unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      final orders = <OrderModel>[];
      for (final row in orderRows) {
        final ordId = row['id'].toString();
        orders.add(
          OrderModel(
            id: ordId,
            receiptNo: row['receipt_no']?.toString() ?? 'REC-00000000',
            userId: row['user_id']?.toString() ?? '',
            cashierName: row['cashier_name']?.toString() ?? 'Cashier',
            subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0.0,
            tax: (row['tax'] as num?)?.toDouble() ?? 0.0,
            total: (row['total'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: row['payment_method']?.toString() ?? 'physical',
            status: row['status']?.toString() ?? 'completed',
            items: itemsByOrderId[ordId] ?? [],
            createdAt: _parseDateTime(row['created_at']),
          ),
        );
      }

      debugPrint("✅ Fetched ${orders.length} orders from MySQL!");
      return orders;
    } catch (e) {
      debugPrint("⚠️ Error fetching orders from MySQL: $e");
      return [];
    }
  }

  /// Seed initial orders if database table is empty
  static Future<void> seedInitialOrdersIfEmpty(List<OrderModel> initialOrders) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM orders');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && initialOrders.isNotEmpty) {
        for (final order in initialOrders) {
          await saveOrder(order);
        }
        debugPrint("✅ Initial sample orders seeded into MySQL (${initialOrders.length} orders).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding orders into MySQL: $e");
    }
  }

  // --- PRODUCT DATABASE METHODS ---

  static Future<bool> saveProduct(ProductModel product) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      final nowStr = _formatDateTime(DateTime.now());
      final prodIntId = int.tryParse(product.id);

      bool exists = false;
      if (prodIntId != null) {
        final check = await conn.query('SELECT id FROM products WHERE id = ?', [prodIntId]);
        exists = check.isNotEmpty;
      }

      if (exists && prodIntId != null) {
        await conn.query('''
          UPDATE products
          SET name = ?, description = ?, price = ?, cost_price = ?, category = ?,
              image_path = ?, stock = ?, min_stock = ?, sku = ?, unit = ?, updated_at = ?
          WHERE id = ?
        ''', [
          product.name,
          product.description,
          product.price,
          product.costPrice,
          product.category,
          product.imagePath,
          product.stock,
          product.minStock,
          product.sku,
          product.unit,
          nowStr,
          prodIntId,
        ]);
      } else {
        await conn.query('''
          INSERT INTO products (name, description, price, cost_price, category, image_path, stock, min_stock, sku, unit, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          product.name,
          product.description,
          product.price,
          product.costPrice,
          product.category,
          product.imagePath,
          product.stock,
          product.minStock,
          product.sku,
          product.unit,
          _formatDateTime(product.createdAt),
          nowStr,
        ]);
      }

      // Synchronize stocks table
      await saveStockFromProduct(product);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving product to MySQL: $e");
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      final intId = int.tryParse(id);
      if (intId != null) {
        await conn.query('DELETE FROM products WHERE id = ?', [intId]);
      }
      await deleteStock(id);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting product from MySQL: $e");
      return false;
    }
  }

  static Future<List<ProductModel>> getProducts() async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      final rows = await conn.query('SELECT * FROM products ORDER BY id ASC');
      return rows.map((p) {
        final priceVal = (p['price'] as num?)?.toDouble() ?? 0.0;
        final costVal = (p['cost_price'] as num?)?.toDouble() ?? (priceVal * 0.5);

        return ProductModel(
          id: p['id'].toString(),
          name: p['name']?.toString() ?? '',
          description: p['description']?.toString() ?? '',
          price: priceVal,
          costPrice: costVal,
          category: p['category']?.toString() ?? 'milktea',
          imagePath: p['image_path']?.toString(),
          stock: (p['stock'] as num?)?.toInt() ?? 25,
          minStock: (p['min_stock'] as num?)?.toInt() ?? 10,
          sku: p['sku']?.toString(),
          unit: p['unit']?.toString() ?? 'units',
          createdAt: _parseDateTime(p['created_at']),
          updatedAt: _parseDateTime(p['updated_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching products from MySQL: $e");
      return [];
    }
  }

  static Future<void> seedInitialProductsIfEmpty(List<ProductModel> initialProducts) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM products');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && initialProducts.isNotEmpty) {
        for (final prod in initialProducts) {
          await saveProduct(prod);
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding products into MySQL: $e");
    }
  }

  // --- STOCKS (INVENTORY TABLE) DATABASE METHODS ---

  static Future<bool> saveStock(StockModel stock) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      await conn.query('''
        INSERT INTO stocks (
          id, product_id, product_name, sku, category, current_stock, min_stock, unit,
          cost_price, selling_price, stock_value_cost, stock_value_selling, status, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          product_name = VALUES(product_name),
          sku = VALUES(sku),
          category = VALUES(category),
          current_stock = VALUES(current_stock),
          min_stock = VALUES(min_stock),
          unit = VALUES(unit),
          cost_price = VALUES(cost_price),
          selling_price = VALUES(selling_price),
          stock_value_cost = VALUES(stock_value_cost),
          stock_value_selling = VALUES(stock_value_selling),
          status = VALUES(status),
          updated_at = VALUES(updated_at)
      ''', [
        stock.id,
        stock.productId,
        stock.productName,
        stock.sku,
        stock.category,
        stock.currentStock,
        stock.minStock,
        stock.unit,
        stock.costPrice,
        stock.sellingPrice,
        stock.stockValueCost,
        stock.stockValueSelling,
        stock.status,
        _formatDateTime(stock.updatedAt),
      ]);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving stock item to MySQL: $e");
      return false;
    }
  }

  static Future<bool> saveStockFromProduct(ProductModel product) async {
    final stockModel = StockModel.fromProduct(product);
    return await saveStock(stockModel);
  }

  static Future<bool> deleteStock(String productId) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      await conn.query(
        'DELETE FROM stocks WHERE product_id = ? OR id = ? OR id = ?',
        [productId, productId, 'stock_$productId'],
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting stock from MySQL: $e");
      return false;
    }
  }

  static Future<List<StockModel>> getStocks() async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      final rows = await conn.query('SELECT * FROM stocks ORDER BY product_name ASC');
      return rows.map((s) {
        return StockModel(
          id: s['id']?.toString() ?? '',
          productId: s['product_id']?.toString() ?? '',
          productName: s['product_name']?.toString() ?? '',
          sku: s['sku']?.toString() ?? '',
          category: s['category']?.toString() ?? '',
          currentStock: (s['current_stock'] as num?)?.toInt() ?? 0,
          minStock: (s['min_stock'] as num?)?.toInt() ?? 10,
          unit: s['unit']?.toString() ?? 'pcs',
          costPrice: (s['cost_price'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (s['selling_price'] as num?)?.toDouble() ?? 0.0,
          stockValueCost: (s['stock_value_cost'] as num?)?.toDouble() ?? 0.0,
          stockValueSelling: (s['stock_value_selling'] as num?)?.toDouble() ?? 0.0,
          status: s['status']?.toString() ?? 'in_stock',
          updatedAt: _parseDateTime(s['updated_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching stocks from MySQL: $e");
      return [];
    }
  }

  static Future<void> seedInitialStocksIfEmpty(List<ProductModel> products) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM stocks');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && products.isNotEmpty) {
        for (final prod in products) {
          final stock = StockModel.fromProduct(prod);
          await saveStock(stock);
        }
        debugPrint("✅ Initial stocks table seeded into MySQL (${products.length} stock items).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding stocks into MySQL: $e");
    }
  }

  // --- REPORTS DATABASE METHODS ---

  static Future<bool> saveReport(ReportModel report) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      final metricsStr = jsonEncode(report.metrics);
      final inventoryStr = jsonEncode(report.inventorySummary);

      await conn.query('''
        INSERT INTO reports (
          id, report_type, title, period, generated_at, generated_by, metrics, inventory_summary, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          report_type = VALUES(report_type),
          title = VALUES(title),
          period = VALUES(period),
          generated_at = VALUES(generated_at),
          generated_by = VALUES(generated_by),
          metrics = VALUES(metrics),
          inventory_summary = VALUES(inventory_summary),
          notes = VALUES(notes)
      ''', [
        report.id,
        report.reportType,
        report.title,
        report.period,
        _formatDateTime(report.generatedAt),
        report.generatedBy,
        metricsStr,
        inventoryStr,
        report.notes,
      ]);

      debugPrint("✅ Report ${report.title} (${report.id}) saved to MySQL!");
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving report to MySQL: $e");
      return false;
    }
  }

  static Future<bool> saveReportData(Map<String, dynamic> reportData) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      final report = ReportModel.fromMap(reportData);
      return await saveReport(report);
    } catch (e) {
      debugPrint("⚠️ Error saving report data to MySQL: $e");
      return false;
    }
  }

  static Future<List<ReportModel>> getReports({String? reportType, int? limit}) async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      String sql = 'SELECT * FROM reports';
      final params = <dynamic>[];

      if (reportType != null) {
        sql += ' WHERE report_type = ?';
        params.add(reportType);
      }

      sql += ' ORDER BY generated_at DESC';

      if (limit != null) {
        sql += ' LIMIT $limit';
      }

      final rows = await conn.query(sql, params);
      return rows.map((r) {
        Map<String, dynamic> metrics = {};
        if (r['metrics'] != null) {
          try {
            metrics = Map<String, dynamic>.from(jsonDecode(r['metrics'].toString()) as Map);
          } catch (_) {}
        }

        Map<String, dynamic> inventorySummary = {};
        if (r['inventory_summary'] != null) {
          try {
            inventorySummary = Map<String, dynamic>.from(jsonDecode(r['inventory_summary'].toString()) as Map);
          } catch (_) {}
        }

        return ReportModel(
          id: r['id']?.toString() ?? '',
          reportType: r['report_type']?.toString() ?? 'daily_summary',
          title: r['title']?.toString() ?? 'Report',
          period: r['period']?.toString() ?? 'today',
          generatedAt: _parseDateTime(r['generated_at']),
          generatedBy: r['generated_by']?.toString() ?? 'System',
          metrics: metrics,
          inventorySummary: inventorySummary,
          notes: r['notes']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching reports from MySQL: $e");
      return [];
    }
  }

  static Future<void> seedInitialReportsIfEmpty(List<ReportModel> initialReports) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM reports');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && initialReports.isNotEmpty) {
        for (final report in initialReports) {
          await saveReport(report);
        }
        debugPrint("✅ Initial reports table seeded into MySQL (${initialReports.length} reports).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding reports into MySQL: $e");
    }
  }

  // --- STOCK LOGS DATABASE METHODS ---

  static Future<bool> saveStockLog(StockLogModel log) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      await conn.query('''
        INSERT INTO stock_logs (
          id, product_id, sku, product_name, stock_change, previous_stock, new_stock,
          type, reason, performed_by, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          stock_change = VALUES(stock_change),
          previous_stock = VALUES(previous_stock),
          new_stock = VALUES(new_stock),
          type = VALUES(type),
          reason = VALUES(reason),
          performed_by = VALUES(performed_by)
      ''', [
        log.id,
        log.productId,
        log.sku,
        log.productName,
        log.change,
        log.previousStock,
        log.newStock,
        log.type,
        log.reason,
        log.performedBy,
        _formatDateTime(log.createdAt),
      ]);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving stock log to MySQL: $e");
      return false;
    }
  }

  static Future<List<StockLogModel>> getStockLogs({String? productId, int? limit}) async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      String sql = 'SELECT * FROM stock_logs';
      final params = <dynamic>[];

      if (productId != null) {
        sql += ' WHERE product_id = ?';
        params.add(productId);
      }

      sql += ' ORDER BY created_at DESC';

      if (limit != null) {
        sql += ' LIMIT $limit';
      }

      final rows = await conn.query(sql, params);
      return rows.map((l) {
        return StockLogModel(
          id: l['id']?.toString() ?? '',
          productId: l['product_id']?.toString() ?? '',
          sku: l['sku']?.toString(),
          productName: l['product_name']?.toString() ?? '',
          change: (l['stock_change'] as num?)?.toInt() ?? 0,
          previousStock: (l['previous_stock'] as num?)?.toInt() ?? 0,
          newStock: (l['new_stock'] as num?)?.toInt() ?? 0,
          type: l['type']?.toString() ?? 'adjustment',
          reason: l['reason']?.toString() ?? '',
          performedBy: l['performed_by']?.toString() ?? 'Admin',
          createdAt: _parseDateTime(l['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching stock logs from MySQL: $e");
      return [];
    }
  }

  static Future<void> seedInitialStockLogsIfEmpty(List<StockLogModel> initialLogs) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM stock_logs');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && initialLogs.isNotEmpty) {
        for (final log in initialLogs) {
          await saveStockLog(log);
        }
        debugPrint("✅ Initial stock logs seeded into MySQL (${initialLogs.length} logs).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding stock logs into MySQL: $e");
    }
  }

  // --- USER DATABASE METHODS ---

  static Future<void> seedInitialUsersIfEmpty(
    List<UserModel> initialUsers,
    Map<String, String> passwords,
  ) async {
    final conn = await _getConnection();
    if (conn == null) return;

    try {
      final res = await conn.query('SELECT COUNT(*) AS cnt FROM users');
      final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
      if (count == 0 && initialUsers.isNotEmpty) {
        for (final user in initialUsers) {
          final pw = passwords[user.email] ?? passwords[user.username] ?? 'password';
          final hashedPw = PasswordHasher.isHashed(pw) ? pw : PasswordHasher.hashPassword(pw);
          await saveUser(user, passwordOrHash: hashedPw);
        }
        debugPrint("✅ Initial users seeded into MySQL (${initialUsers.length} users with secure passwords).");
      }
    } catch (e) {
      debugPrint("⚠️ Error seeding users into MySQL: $e");
    }
  }

  static Future<bool> saveUser(
    UserModel user, {
    String? passwordOrHash,
    dynamic docId,
  }) async {
    final conn = await _getConnection();
    if (conn == null) return false;

    try {
      final nowStr = _formatDateTime(DateTime.now());
      int? existingUserId = int.tryParse(user.id);

      if (existingUserId == null && docId != null) {
        existingUserId = int.tryParse(docId.toString());
      }

      // Check if user exists by id or email
      if (existingUserId == null) {
        final check = await conn.query(
          'SELECT id FROM users WHERE email = ? LIMIT 1',
          [user.email],
        );
        if (check.isNotEmpty) {
          existingUserId = (check.first['id'] as num).toInt();
        }
      }

      String? hashedPw;
      if (passwordOrHash != null && passwordOrHash.isNotEmpty) {
        hashedPw = PasswordHasher.isHashed(passwordOrHash)
            ? passwordOrHash
            : PasswordHasher.hashPassword(passwordOrHash);
      }

      if (existingUserId != null) {
        if (hashedPw != null) {
          await conn.query('''
            UPDATE users SET name = ?, email = ?, password = ?, updated_at = ?
            WHERE id = ?
          ''', [user.name, user.email, hashedPw, nowStr, existingUserId]);
        } else {
          await conn.query('''
            UPDATE users SET name = ?, email = ?, updated_at = ?
            WHERE id = ?
          ''', [user.name, user.email, nowStr, existingUserId]);
        }

        // Upsert employee metadata
        await conn.query('''
          INSERT INTO employees (user_id, role, employee_code, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            role = VALUES(role),
            employee_code = VALUES(employee_code),
            updated_at = VALUES(updated_at)
        ''', [
          existingUserId,
          user.role,
          user.employeeCode,
          nowStr,
          nowStr,
        ]);
      } else {
        final pwToSave = hashedPw ?? PasswordHasher.hashPassword('password');
        final insertRes = await conn.query('''
          INSERT INTO users (name, email, password, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?)
        ''', [user.name, user.email, pwToSave, nowStr, nowStr]);

        final newId = insertRes.insertId ?? 1;
        await conn.query('''
          INSERT INTO employees (user_id, role, employee_code, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            role = VALUES(role),
            employee_code = VALUES(employee_code),
            updated_at = VALUES(updated_at)
        ''', [
          newId,
          user.role,
          user.employeeCode,
          nowStr,
          nowStr,
        ]);
      }

      return true;
    } catch (e) {
      debugPrint("⚠️ Error saving user to MySQL: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersWithPasswords() async {
    final conn = await _getConnection();
    if (conn == null) return [];

    try {
      final rows = await conn.query('''
        SELECT u.id, u.name, u.email, u.password,
               COALESCE(e.role, 'employee') AS role,
               COALESCE(e.employee_code, 'EMP001') AS employeeCode
        FROM users u
        LEFT JOIN employees e ON u.id = e.user_id
      ''');

      return rows.map((u) {
        final emailStr = u['email']?.toString() ?? '';
        final usernameStr = emailStr.contains('@') ? emailStr.split('@').first : 'user';

        return <String, dynamic>{
          '_id': u['id'].toString(),
          'id': u['id'].toString(),
          'name': u['name']?.toString() ?? '',
          'email': emailStr,
          'username': usernameStr,
          'role': u['role']?.toString() ?? 'employee',
          'employeeCode': u['employeeCode']?.toString() ?? 'EMP001',
          'password': u['password']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching users from MySQL: $e");
      return [];
    }
  }

  static void logout() {
    debugPrint("✅ User session logged out.");
  }
}

/// Backward compatibility alias for any existing references to MongoDatabase
typedef MongoDatabase = MySqlDatabase;
