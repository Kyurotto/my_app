import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/stock_log_model.dart';
import '../models/report_model.dart';
import '../database.dart';
import '../utils/password_hasher.dart';

class AppService extends ChangeNotifier {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  static AppService get instance => _instance;

  AppService._internal() {
    _initSeedData();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  final List<UserModel> _users = [];
  final Map<String, String> _passwords = {}; // username/email -> salted hash (PBKDF2-SHA256)

  // --- REMEMBER ME: Session token storage ---
  // Maps userId -> SHA-256 hash of the session token (raw token stored on device via SharedPreferences).
  // Never stores passwords. Tokens are rotated on every auto-login and invalidated on logout.
  final Map<String, String> _sessionTokens = {};

  // SharedPreferences keys (prefixed to avoid collisions)
  static const String _prefRememberMe = 'remember_me_enabled';
  static const String _prefRememberedId = 'remember_me_identifier';
  static const String _prefSessionToken = 'remember_me_session_token';
  static const String _prefUserId = 'remember_me_user_id';

  final List<ProductModel> _products = [];
  List<ProductModel> get products => List.unmodifiable(_products);

  final List<OrderModel> _orders = [];
  List<OrderModel> get orders => List.unmodifiable(_orders);

  final List<StockLogModel> _stockLogs = [];
  List<StockLogModel> get stockLogs => List.unmodifiable(_stockLogs);

  void _initSeedData() {
    // 1. Seed Users (Matching Laravel DatabaseSeeder)
    final admin = UserModel(
      id: 'usr_admin_1',
      name: 'Admin User',
      email: 'admin@example.com',
      username: 'admin',
      role: 'admin',
      employeeCode: 'EMP001',
    );
    final employee = UserModel(
      id: 'usr_emp_2',
      name: 'Employee User',
      email: 'employee@example.com',
      username: 'employee',
      role: 'employee',
      employeeCode: 'EMP002',
    );

    _users.addAll([admin, employee]);
    final defaultAdminHash = PasswordHasher.hashPassword('password');
    final defaultEmployeeHash = PasswordHasher.hashPassword('password');
    _passwords['admin@example.com'] = defaultAdminHash;
    _passwords['admin'] = defaultAdminHash;
    _passwords['employee@example.com'] = defaultEmployeeHash;
    _passwords['employee'] = defaultEmployeeHash;

    // 2. Seed Products (Matching Laravel ProductSeeder)
    _products.addAll([
      ProductModel(
        id: 'prod_1',
        name: 'Classic Milk Tea',
        description: 'Traditional black tea with creamy milk and brown sugar pearls.',
        price: 4.50,
        category: 'milktea',
        stock: 35,
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      ProductModel(
        id: 'prod_2',
        name: 'Taro Milk Tea',
        description: 'Fragrant taro root blended with milk and chewy pearls.',
        price: 5.00,
        category: 'milktea',
        stock: 24,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ProductModel(
        id: 'prod_3',
        name: 'Matcha Latte',
        description: 'Premium Japanese matcha green tea with steamed milk.',
        price: 5.50,
        category: 'milktea',
        stock: 18,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ProductModel(
        id: 'prod_4',
        name: 'Wintermelon Tea',
        description: 'Refreshing wintermelon flavored tea with a touch of cream.',
        price: 4.50,
        category: 'milktea',
        stock: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ProductModel(
        id: 'prod_5',
        name: 'Cheese Foam Milk Tea',
        description: 'Our signature milk tea topped with a salty-sweet cheese foam.',
        price: 5.75,
        category: 'milktea',
        stock: 8, // low stock demonstration
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ProductModel(
        id: 'prod_6',
        name: 'French Fries',
        description: 'Crispy golden fries with a pinch of sea salt.',
        price: 3.50,
        category: 'snack',
        stock: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ProductModel(
        id: 'prod_7',
        name: 'Chicken Popcorn',
        description: 'Bite-sized seasoned chicken breast, fried to perfection.',
        price: 6.00,
        category: 'snack',
        stock: 28,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      ProductModel(
        id: 'prod_8',
        name: 'Mozzarella Sticks',
        description: 'Melt-in-your-mouth mozzarella sticks with marinara dip.',
        price: 5.50,
        category: 'snack',
        stock: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ProductModel(
        id: 'prod_9',
        name: 'Tater Tots',
        description: 'Crunchy potato nuggets served with spicy mayo.',
        price: 4.00,
        category: 'snack',
        stock: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ProductModel(
        id: 'prod_10',
        name: 'Onigiri',
        description: 'Japanese rice ball with a variety of savory fillings.',
        price: 3.00,
        category: 'snack',
        stock: 5, // low stock
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // 3. Seed Sample Orders
    final now = DateTime.now();
    _orders.addAll([
      OrderModel(
        id: 'ord_1',
        receiptNo: 'REC-9B4X7K21',
        userId: 'usr_emp_2',
        cashierName: 'Employee User',
        subtotal: 10.00,
        tax: 1.00,
        total: 11.00,
        paymentMethod: 'gcash',
        createdAt: now.subtract(const Duration(minutes: 15)),
        items: [
          OrderItemModel(productId: 'prod_1', productName: 'Classic Milk Tea', unitPrice: 4.50, quantity: 1, subtotal: 4.50),
          OrderItemModel(productId: 'prod_8', productName: 'Mozzarella Sticks', unitPrice: 5.50, quantity: 1, subtotal: 5.50),
        ],
      ),
      OrderModel(
        id: 'ord_2',
        receiptNo: 'REC-2M8F3P99',
        userId: 'usr_emp_2',
        cashierName: 'Employee User',
        subtotal: 17.00,
        tax: 1.70,
        total: 18.70,
        paymentMethod: 'physical',
        createdAt: now.subtract(const Duration(minutes: 45)),
        items: [
          OrderItemModel(productId: 'prod_3', productName: 'Matcha Latte', unitPrice: 5.50, quantity: 2, subtotal: 11.00),
          OrderItemModel(productId: 'prod_7', productName: 'Chicken Popcorn', unitPrice: 6.00, quantity: 1, subtotal: 6.00),
        ],
      ),
      OrderModel(
        id: 'ord_3',
        receiptNo: 'REC-7K1W5D44',
        userId: 'usr_emp_2',
        cashierName: 'Employee User',
        subtotal: 9.25,
        tax: 0.93,
        total: 10.18,
        paymentMethod: 'maya',
        createdAt: now.subtract(const Duration(hours: 2)),
        items: [
          OrderItemModel(productId: 'prod_5', productName: 'Cheese Foam Milk Tea', unitPrice: 5.75, quantity: 1, subtotal: 5.75),
          OrderItemModel(productId: 'prod_6', productName: 'French Fries', unitPrice: 3.50, quantity: 1, subtotal: 3.50),
        ],
      ),
      OrderModel(
        id: 'ord_4',
        receiptNo: 'REC-5L9P2Q11',
        userId: 'usr_admin_1',
        cashierName: 'Admin User',
        subtotal: 14.50,
        tax: 1.45,
        total: 15.95,
        paymentMethod: 'online',
        createdAt: now.subtract(const Duration(hours: 4)),
        items: [
          OrderItemModel(productId: 'prod_2', productName: 'Taro Milk Tea', unitPrice: 5.00, quantity: 1, subtotal: 5.00),
          OrderItemModel(productId: 'prod_7', productName: 'Chicken Popcorn', unitPrice: 6.00, quantity: 1, subtotal: 6.00),
          OrderItemModel(productId: 'prod_6', productName: 'French Fries', unitPrice: 3.50, quantity: 1, subtotal: 3.50),
        ],
      ),
    ]);

    // 4. Seed Sample Stock Movement Audit Logs
    _stockLogs.addAll([
      StockLogModel(
        id: 'log_1',
        productId: 'prod_1',
        sku: 'SKU-PROD1',
        productName: 'Classic Milk Tea',
        change: 50,
        previousStock: 0,
        newStock: 50,
        type: 'initial',
        reason: 'Initial Inventory Intake',
        performedBy: 'Admin User',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      StockLogModel(
        id: 'log_2',
        productId: 'prod_1',
        sku: 'SKU-PROD1',
        productName: 'Classic Milk Tea',
        change: -1,
        previousStock: 36,
        newStock: 35,
        type: 'sale',
        reason: 'Order REC-9B4X7K21',
        performedBy: 'Employee User',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      StockLogModel(
        id: 'log_3',
        productId: 'prod_5',
        sku: 'SKU-PROD5',
        productName: 'Cheese Foam Milk Tea',
        change: 15,
        previousStock: 0,
        newStock: 15,
        type: 'initial',
        reason: 'Initial Inventory Intake',
        performedBy: 'Admin User',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      StockLogModel(
        id: 'log_4',
        productId: 'prod_5',
        sku: 'SKU-PROD5',
        productName: 'Cheese Foam Milk Tea',
        change: -1,
        previousStock: 9,
        newStock: 8,
        type: 'sale',
        reason: 'Order REC-7K1W5D44',
        performedBy: 'Employee User',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      StockLogModel(
        id: 'log_5',
        productId: 'prod_6',
        sku: 'SKU-PROD6',
        productName: 'French Fries',
        change: 30,
        previousStock: 15,
        newStock: 45,
        type: 'restock',
        reason: 'Supplier Batch Delivery Restock',
        performedBy: 'Admin User',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String usernameOrEmail, String password) async {
    final query = usernameOrEmail.trim().toLowerCase();
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == query || u.username.toLowerCase() == query,
      orElse: () => UserModel(id: '', name: '', email: '', username: '', role: '', employeeCode: ''),
    );

    if (user.id.isEmpty) {
      return false;
    }

    final storedPw = _passwords[user.email] ?? _passwords[user.username];
    if (storedPw != null && PasswordHasher.verifyPassword(password, storedPw)) {
      // If the password was stored as legacy plaintext, seamlessly upgrade it to salted hash
      if (PasswordHasher.isLegacyPlaintext(storedPw)) {
        final upgradedHash = PasswordHasher.hashPassword(password);
        _passwords[user.email] = upgradedHash;
        _passwords[user.username] = upgradedHash;
        if (MongoDatabase.isConnected) {
          await MongoDatabase.saveUser(user, passwordOrHash: upgradedHash);
        }
      }
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String username,
    required String password,
    String role = 'employee',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();

    final exists = _users.any((u) =>
        u.email.toLowerCase() == cleanEmail ||
        u.username.toLowerCase() == cleanUsername);

    if (exists) {
      return false;
    }

    final hashedPassword = PasswordHasher.hashPassword(password);

    final empIndex = _users.length + 1;
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      username: username.trim().isNotEmpty ? username.trim() : email.trim().split('@')[0],
      role: role.toLowerCase() == 'admin' ? 'admin' : 'employee',
      employeeCode: 'EMP${empIndex.toString().padLeft(3, '0')}',
    );

    _users.add(newUser);
    _passwords[newUser.email] = hashedPassword;
    _passwords[newUser.username] = hashedPassword;
    if (MongoDatabase.isConnected) {
      await MongoDatabase.saveUser(newUser, passwordOrHash: hashedPassword);
    }
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    if (_currentUser == null) return false;

    final oldEmail = _currentUser!.email;
    final oldUsername = _currentUser!.username;
    final currentStoredPw = _passwords[oldEmail] ?? _passwords[oldUsername];

    String? updatedPasswordHash;
    if (currentPassword != null && currentPassword.isNotEmpty) {
      if (currentStoredPw == null || !PasswordHasher.verifyPassword(currentPassword, currentStoredPw)) {
        return false;
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        updatedPasswordHash = PasswordHasher.hashPassword(newPassword);
      }
    }

    final updated = _currentUser!.copyWith(
      name: name.trim(),
      email: email.trim(),
    );

    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _users[idx] = updated;
    }
    _currentUser = updated;

    // Update in-memory credentials map
    final effectivePw = updatedPasswordHash ?? currentStoredPw;
    if (effectivePw != null) {
      if (oldEmail.isNotEmpty && oldEmail != updated.email) {
        _passwords.remove(oldEmail);
      }
      if (oldUsername.isNotEmpty && oldUsername != updated.username) {
        _passwords.remove(oldUsername);
      }
      _passwords[updated.email] = effectivePw;
      _passwords[updated.username] = effectivePw;
    }

    if (MongoDatabase.isConnected) {
      // Only include password if a new password was explicitly set.
      // This prevents unintentionally resetting stored passwords in MongoDB when only profile info is edited.
      await MongoDatabase.saveUser(
        updated,
        passwordOrHash: updatedPasswordHash,
      );
    }
    notifyListeners();
    return true;
  }

  void logout() {
    // Invalidate session token before clearing user
    if (_currentUser != null) {
      _sessionTokens.remove(_currentUser!.id);
    }
    _currentUser = null;
    clearRememberMe(); // Wipe saved session from device storage
    notifyListeners();
  }

  // =============================================
  // REMEMBER ME — Secure session token management
  // =============================================

  /// Generates a cryptographically secure random token (64 hex chars = 256 bits).
  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Returns the SHA-256 hash of a raw token (for server-side comparison).
  String _hashToken(String rawToken) {
    return sha256.convert(utf8.encode(rawToken)).toString();
  }

  /// Saves a "Remember me" session to device storage after a successful login.
  /// Stores: a flag, the user identifier, the user ID, and a random session token.
  /// The session token is hashed in-memory; only the raw token goes to SharedPreferences.
  /// **No passwords are ever stored on disk.**
  Future<void> saveRememberMe(String identifier) async {
    if (_currentUser == null) return;

    final rawToken = _generateSessionToken();
    final hashedToken = _hashToken(rawToken);

    // Store hashed version in memory (acts as "server-side" verification)
    _sessionTokens[_currentUser!.id] = hashedToken;

    // Store raw token + metadata on device
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRememberMe, true);
    await prefs.setString(_prefRememberedId, identifier);
    await prefs.setString(_prefUserId, _currentUser!.id);
    await prefs.setString(_prefSessionToken, rawToken);
  }

  /// Clears all "Remember me" data from device storage and invalidates the session token.
  Future<void> clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefRememberMe);
      await prefs.remove(_prefRememberedId);
      await prefs.remove(_prefSessionToken);
      await prefs.remove(_prefUserId);
    } catch (e) {
      debugPrint('⚠️ Error clearing Remember Me preferences: $e');
    }
  }

  /// Checks if a valid "Remember me" session exists and returns the saved identifier.
  /// Returns `null` if no saved session or if data is incomplete.
  Future<String?> getSavedIdentifier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefRememberMe) ?? false;
      if (!enabled) return null;
      return prefs.getString(_prefRememberedId);
    } catch (e) {
      debugPrint('⚠️ Error reading Remember Me preferences: $e');
      return null;
    }
  }

  /// Attempts to auto-login using a saved session token.
  /// Validates the token, logs the user in, and rotates the token for security.
  /// Returns `true` if auto-login succeeded, `false` otherwise.
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefRememberMe) ?? false;
      if (!enabled) return false;

      final savedUserId = prefs.getString(_prefUserId);
      final savedToken = prefs.getString(_prefSessionToken);
      final savedIdentifier = prefs.getString(_prefRememberedId);

      if (savedUserId == null || savedToken == null || savedIdentifier == null) {
        await clearRememberMe();
        return false;
      }

      // Find the user by ID
      final user = _users.firstWhere(
        (u) => u.id == savedUserId,
        orElse: () => UserModel(id: '', name: '', email: '', username: '', role: '', employeeCode: ''),
      );

      if (user.id.isEmpty) {
        await clearRememberMe();
        return false;
      }

      // Validate the session token
      final storedHashedToken = _sessionTokens[savedUserId];
      if (storedHashedToken == null) {
        // No in-memory token (e.g., app restarted — cold start).
        // Since this is an in-memory app without a real backend, accept the
        // stored token on first cold start, then rotate it immediately.
        // This is safe because SharedPreferences is app-sandboxed.
        _currentUser = user;

        // Rotate token for next session
        final newRawToken = _generateSessionToken();
        _sessionTokens[user.id] = _hashToken(newRawToken);
        await prefs.setString(_prefSessionToken, newRawToken);

        notifyListeners();
        return true;
      }

      // Verify token: hash the saved raw token and compare with stored hash
      final computedHash = _hashToken(savedToken);
      if (computedHash != storedHashedToken) {
        // Token mismatch — possible tampering, invalidate session
        await clearRememberMe();
        _sessionTokens.remove(savedUserId);
        return false;
      }

      // Token valid — log user in
      _currentUser = user;

      // Rotate token to prevent replay attacks
      final newRawToken = _generateSessionToken();
      _sessionTokens[user.id] = _hashToken(newRawToken);
      await prefs.setString(_prefSessionToken, newRawToken);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('⚠️ Auto-login error: $e');
      await clearRememberMe();
      return false;
    }
  }

  // --- DATABASE SYNC ---

  /// Synchronize local state with MongoDB database
  Future<void> syncWithDatabase() async {
    if (!MongoDatabase.isConnected) return;

    try {
      // 1. Seed & Load Users
      await MongoDatabase.seedInitialUsersIfEmpty(_users, _passwords);
      final dbUsers = await MongoDatabase.getUsersWithPasswords();
      if (dbUsers.isNotEmpty) {
        _users.clear();
        for (final u in dbUsers) {
          final user = UserModel.fromMap(u);
          if (user.username.isNotEmpty || user.email.isNotEmpty) {
            _users.add(user);
          }
          var pw = u['password']?.toString() ?? '';
          if (pw.isEmpty) {
            pw = PasswordHasher.hashPassword('password');
            await MongoDatabase.saveUser(user, passwordOrHash: pw, docId: u['_id']);
          } else if (PasswordHasher.isLegacyPlaintext(pw)) {
            // Auto-migrate legacy plaintext passwords in MongoDB to secure salted hashes
            final hashed = PasswordHasher.hashPassword(pw);
            await MongoDatabase.saveUser(user, passwordOrHash: hashed, docId: u['_id']);
            pw = hashed;
          }
          if (u['email'] != null && u['email'].toString().isNotEmpty) {
            _passwords[u['email'].toString()] = pw;
          }
          if (u['username'] != null && u['username'].toString().isNotEmpty) {
            _passwords[u['username'].toString()] = pw;
          }
        }
      }

      // 2. Seed initial default orders if MongoDB collection is empty
      await MongoDatabase.seedInitialOrdersIfEmpty(_orders);

      // 3. Load all orders from MongoDB
      final dbOrders = await MongoDatabase.getOrders();
      if (dbOrders.isNotEmpty) {
        _orders.clear();
        _orders.addAll(dbOrders);
      }

      // 4. Seed initial products if MongoDB collection is empty
      await MongoDatabase.seedInitialProductsIfEmpty(_products);
      final dbProducts = await MongoDatabase.getProducts();
      if (dbProducts.isNotEmpty) {
        _products.clear();
        _products.addAll(dbProducts);
      }

      // 5. Seed & Sync stocks collection in MongoDB
      await MongoDatabase.seedInitialStocksIfEmpty(_products);
      for (final prod in _products) {
        await MongoDatabase.saveStockFromProduct(prod);
      }

      // 6. Seed & Load stock movement audit logs from MongoDB
      await MongoDatabase.seedInitialStockLogsIfEmpty(_stockLogs);
      final dbStockLogs = await MongoDatabase.getStockLogs();
      if (dbStockLogs.isNotEmpty) {
        _stockLogs.clear();
        _stockLogs.addAll(dbStockLogs);
      }

      // 7. Seed & Sync periodic reports into MongoDB reports collection
      final initialReports = generatePeriodicReportModels();
      await MongoDatabase.seedInitialReportsIfEmpty(initialReports);
      await generateAndSyncReports();

      notifyListeners();
      debugPrint("✅ AppService successfully synced with MongoDB! (${_orders.length} orders, ${_products.length} products, ${_stockLogs.length} stock logs, stocks & reports tables active)");
    } catch (e) {
      debugPrint("⚠️ Error in syncWithDatabase: $e");
    }
  }

  // --- PRODUCTS & INVENTORY CRUD ---

  Future<void> addProduct(ProductModel product) async {
    _products.insert(0, product);

    // Record initial stock entry in audit log
    if (product.stock > 0) {
      final log = StockLogModel(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
        productId: product.id,
        sku: product.sku,
        productName: product.name,
        change: product.stock,
        previousStock: 0,
        newStock: product.stock,
        type: 'initial',
        reason: 'New product creation initial stock',
        performedBy: _currentUser?.name ?? 'Admin User',
        createdAt: DateTime.now(),
      );
      _stockLogs.insert(0, log);
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveStockLog(log);
      }
    }

    notifyListeners();
    if (MongoDatabase.isConnected) {
      MongoDatabase.saveProduct(product);
      generateAndSyncReports();
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      final oldProduct = _products[idx];
      final stockDiff = product.stock - oldProduct.stock;

      _products[idx] = product;

      if (stockDiff != 0) {
        final log = StockLogModel(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
          productId: product.id,
          sku: product.sku,
          productName: product.name,
          change: stockDiff,
          previousStock: oldProduct.stock,
          newStock: product.stock,
          type: stockDiff > 0 ? 'restock' : 'adjustment',
          reason: 'Product update inventory modification',
          performedBy: _currentUser?.name ?? 'Admin User',
          createdAt: DateTime.now(),
        );
        _stockLogs.insert(0, log);
        if (MongoDatabase.isConnected) {
          MongoDatabase.saveStockLog(log);
        }
      }

      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(product);
        generateAndSyncReports();
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    if (MongoDatabase.isConnected) {
      MongoDatabase.deleteProduct(id);
      generateAndSyncReports();
    }
  }

  Future<void> setStock(
    String productId,
    int newStock, {
    String reason = 'Manual Inventory Update',
    String type = 'adjustment',
  }) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final oldStock = _products[idx].stock;
      final clamped = max(0, newStock);
      final diff = clamped - oldStock;

      _products[idx] = _products[idx].copyWith(stock: clamped);

      if (diff != 0) {
        final log = StockLogModel(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
          productId: _products[idx].id,
          sku: _products[idx].sku,
          productName: _products[idx].name,
          change: diff,
          previousStock: oldStock,
          newStock: clamped,
          type: type,
          reason: reason,
          performedBy: _currentUser?.name ?? 'Admin User',
          createdAt: DateTime.now(),
        );
        _stockLogs.insert(0, log);
        if (MongoDatabase.isConnected) {
          MongoDatabase.saveStockLog(log);
        }
      }

      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(_products[idx]);
      }
    }
  }

  Future<void> adjustStock(
    String productId,
    int delta, {
    String reason = 'Stock adjustment',
    String? notes,
    String type = 'adjustment',
    String? action,
    String? staffName,
  }) async {
    final effectiveReason = notes ?? reason;
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final current = _products[idx].stock;
      final updated = max(0, current + delta);
      final actualChange = updated - current;

      _products[idx] = _products[idx].copyWith(stock: updated);

      if (actualChange != 0) {
        final log = StockLogModel(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
          productId: _products[idx].id,
          sku: _products[idx].sku,
          productName: _products[idx].name,
          change: actualChange,
          previousStock: current,
          newStock: updated,
          type: action ?? type,
          reason: effectiveReason,
          performedBy: staffName ?? (_currentUser?.name ?? 'Admin User'),
          createdAt: DateTime.now(),
        );
        _stockLogs.insert(0, log);
        if (MongoDatabase.isConnected) {
          MongoDatabase.saveStockLog(log);
        }
      }

      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(_products[idx]);
        generateAndSyncReports();
      }
    }
  }

  Future<void> restockProduct(
    String productId,
    int quantity, {
    String reason = 'Restock',
    String? notes,
    String? action = 'restock',
    String? staffName,
  }) async {
    await adjustStock(
      productId,
      quantity,
      reason: notes ?? reason,
      type: action ?? 'restock',
      staffName: staffName,
    );
  }



  // --- POS / ORDERS ---

  String _generateReceiptNo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final code = String.fromCharCodes(Iterable.generate(
      8,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
    return 'REC-$code';
  }

  Future<OrderModel> placeOrder({
    required List<OrderItemModel> items,
    required String paymentMethod,
  }) async {
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final receiptNo = _generateReceiptNo();

    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.subtotal;
      // Deduct stock and log stock deduction transaction
      adjustStock(
        item.productId,
        -item.quantity,
        reason: 'POS Order Sale: $receiptNo (${item.quantity}x ${item.productName})',
        type: 'sale',
      );
    }

    final tax = double.parse((subtotal * 0.10).toStringAsFixed(2));
    final total = double.parse((subtotal + tax).toStringAsFixed(2));

    final newOrder = OrderModel(
      id: orderId,
      receiptNo: receiptNo,
      userId: _currentUser?.id ?? 'usr_guest',
      cashierName: _currentUser?.name ?? 'Cashier',
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      status: 'completed',
      items: List.from(items),
      createdAt: DateTime.now(),
    );

    // Add to in-memory order list
    _orders.insert(0, newOrder);
    notifyListeners();

    // Persist order to MongoDB database
    if (MongoDatabase.isConnected) {
      MongoDatabase.saveOrder(newOrder);
      generateAndSyncReports();
    }

    return newOrder;
  }

  // --- INVENTORY & STOCK VALUATION STATS ---

  int get totalStockUnits =>
      _products.fold(0, (sum, p) => sum + p.stock);

  double get totalInventoryRetailValue =>
      _products.fold(0.0, (sum, p) => sum + p.stockValueRetail);

  double get totalInventoryCostValue =>
      _products.fold(0.0, (sum, p) => sum + p.stockValueCost);

  double get totalInventoryRetailValuation => totalInventoryRetailValue;

  double get totalInventoryCostValuation => totalInventoryCostValue;

  double get totalInventoryPotentialProfit =>
      totalInventoryRetailValue - totalInventoryCostValue;

  int get lowStockCount =>
      _products.where((p) => p.isLowStock).length;

  int get outOfStockCount =>
      _products.where((p) => p.isOutOfStock).length;

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  // --- ANALYTICS / STATS ---

  int get totalOrdersCount => _orders.length;

  double get totalRevenue =>
      _orders.fold(0.0, (sum, o) => sum + o.total);

  double get totalCOGS {
    double cogs = 0.0;
    for (final order in _orders) {
      for (final item in order.items) {
        final prod = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(
            id: item.productId,
            name: item.productName,
            description: '',
            price: item.unitPrice,
            costPrice: item.unitPrice * 0.5,
            category: 'milktea',
          ),
        );
        cogs += prod.costPrice * item.quantity;
      }
    }
    return double.parse(cogs.toStringAsFixed(2));
  }

  double get totalGrossProfit =>
      double.parse((totalRevenue - totalCOGS).toStringAsFixed(2));

  double get totalGrossMargin =>
      totalRevenue > 0 ? double.parse(((totalGrossProfit / totalRevenue) * 100).toStringAsFixed(1)) : 0.0;

  int get todayOrdersCount {
    final now = DateTime.now();
    return _orders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day).length;
  }

  double get todayRevenue {
    final now = DateTime.now();
    return _orders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day).fold(0.0, (sum, o) => sum + o.total);
  }

  Map<String, double> get categoryRevenue {
    double milkTea = 0.0;
    double snack = 0.0;

    for (final order in _orders) {
      for (final item in order.items) {
        final prod = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(id: '', name: '', description: '', price: 0, category: 'milktea'),
        );
        if (prod.category.toLowerCase() == 'snack') {
          snack += item.subtotal;
        } else {
          milkTea += item.subtotal;
        }
      }
    }

    return {
      'Milk Tea': double.parse(milkTea.toStringAsFixed(2)),
      'Snack': double.parse(snack.toStringAsFixed(2)),
    };
  }

  Map<String, int> get productUnitsSoldMap {
    final map = <String, int>{};
    for (final order in _orders) {
      for (final item in order.items) {
        map[item.productId] = (map[item.productId] ?? 0) + item.quantity;
      }
    }
    return map;
  }

  Map<String, double> get productRevenueMap {
    final map = <String, double>{};
    for (final order in _orders) {
      for (final item in order.items) {
        map[item.productId] = (map[item.productId] ?? 0.0) + item.subtotal;
      }
    }
    return map;
  }

  List<OrderModel> _filterOrdersByPeriod(String period, int m, int y, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now();
    return _orders.where((o) {
      switch (period.toLowerCase()) {
        case 'today':
          return o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day;
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return o.createdAt.isAfter(startDay.subtract(const Duration(seconds: 1)));
        case 'year':
          return o.createdAt.year == y;
        case 'all':
          return true;
        case 'custom':
          if (startDate != null && endDate != null) {
            final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
            final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
            return o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                o.createdAt.isBefore(end.add(const Duration(seconds: 1)));
          }
          return o.createdAt.month == m && o.createdAt.year == y;
        case 'month':
        default:
          return o.createdAt.month == m && o.createdAt.year == y;
      }
    }).toList();
  }


  Map<String, dynamic> getFilteredReport({
    int? month,
    int? year,
    String period = 'month',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final filtered = _filterOrdersByPeriod(period, m, y, startDate, endDate);

    final periodOrders = filtered.length;
    final periodRevenue = filtered.fold(0.0, (sum, o) => sum + o.total);
    final periodSubtotal = filtered.fold(0.0, (sum, o) => sum + o.subtotal);
    final periodTax = filtered.fold(0.0, (sum, o) => sum + o.tax);

    double milkTeaRevenue = 0.0;
    double milkTeaCOGS = 0.0;
    int milkTeaUnits = 0;

    double snackRevenue = 0.0;
    double snackCOGS = 0.0;
    int snackUnits = 0;

    double totalCOGS = 0.0;
    int totalUnitsSold = 0;

    final unitsSoldMap = <String, int>{};
    final revenueByProd = <String, double>{};
    final cogsByProd = <String, double>{};
    final paymentMethodCounts = <String, int>{};
    final paymentMethodRevenue = <String, double>{};

    for (final order in filtered) {
      final pMethod = order.paymentLabel;
      paymentMethodCounts[pMethod] = (paymentMethodCounts[pMethod] ?? 0) + 1;
      paymentMethodRevenue[pMethod] = (paymentMethodRevenue[pMethod] ?? 0.0) + order.total;

      for (final item in order.items) {
        final qty = item.quantity;
        final subtotal = item.subtotal;
        totalUnitsSold += qty;

        unitsSoldMap[item.productId] = (unitsSoldMap[item.productId] ?? 0) + qty;
        revenueByProd[item.productId] = (revenueByProd[item.productId] ?? 0.0) + subtotal;

        final prod = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(
            id: item.productId,
            name: item.productName,
            description: '',
            price: item.unitPrice,
            costPrice: item.unitPrice * 0.5,
            category: 'milktea',
          ),
        );

        final itemCOGS = prod.costPrice * qty;
        totalCOGS += itemCOGS;
        cogsByProd[item.productId] = (cogsByProd[item.productId] ?? 0.0) + itemCOGS;

        if (prod.category.toLowerCase() == 'snack') {
          snackRevenue += subtotal;
          snackCOGS += itemCOGS;
          snackUnits += qty;
        } else {
          milkTeaRevenue += subtotal;
          milkTeaCOGS += itemCOGS;
          milkTeaUnits += qty;
        }
      }
    }

    final grossProfit = periodRevenue - totalCOGS;
    final grossMargin = periodRevenue > 0 ? (grossProfit / periodRevenue) * 100 : 0.0;
    final avgOrderValue = periodOrders > 0 ? periodRevenue / periodOrders : 0.0;

    final productSalesRank = <Map<String, dynamic>>[];
    for (final prod in _products) {
      final units = unitsSoldMap[prod.id] ?? 0;
      final revenue = revenueByProd[prod.id] ?? 0.0;
      final cogs = cogsByProd[prod.id] ?? 0.0;
      final profit = revenue - cogs;
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

      if (units > 0) {
        productSalesRank.add({
          'product': prod,
          'units': units,
          'revenue': double.parse(revenue.toStringAsFixed(2)),
          'cogs': double.parse(cogs.toStringAsFixed(2)),
          'profit': double.parse(profit.toStringAsFixed(2)),
          'margin': double.parse(margin.toStringAsFixed(1)),
          'avgPrice': double.parse((units > 0 ? revenue / units : prod.price).toStringAsFixed(2)),
        });
      }
    }
    productSalesRank.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    return {
      'periodOrders': periodOrders,
      'periodRevenue': double.parse(periodRevenue.toStringAsFixed(2)),
      'periodSubtotal': double.parse(periodSubtotal.toStringAsFixed(2)),
      'periodTax': double.parse(periodTax.toStringAsFixed(2)),
      'periodCOGS': double.parse(totalCOGS.toStringAsFixed(2)),
      'grossProfit': double.parse(grossProfit.toStringAsFixed(2)),
      'grossMargin': double.parse(grossMargin.toStringAsFixed(1)),
      'avgOrderValue': double.parse(avgOrderValue.toStringAsFixed(2)),
      'totalUnitsSold': totalUnitsSold,
      'categoryRevenue': {
        'Milk Tea': double.parse(milkTeaRevenue.toStringAsFixed(2)),
        'Snack': double.parse(snackRevenue.toStringAsFixed(2)),
      },
      'categoryBreakdown': {
        'Milk Tea': {
          'revenue': double.parse(milkTeaRevenue.toStringAsFixed(2)),
          'cogs': double.parse(milkTeaCOGS.toStringAsFixed(2)),
          'profit': double.parse((milkTeaRevenue - milkTeaCOGS).toStringAsFixed(2)),
          'margin': milkTeaRevenue > 0
              ? double.parse((((milkTeaRevenue - milkTeaCOGS) / milkTeaRevenue) * 100).toStringAsFixed(1))
              : 0.0,
          'units': milkTeaUnits,
        },
        'Snack': {
          'revenue': double.parse(snackRevenue.toStringAsFixed(2)),
          'cogs': double.parse(snackCOGS.toStringAsFixed(2)),
          'profit': double.parse((snackRevenue - snackCOGS).toStringAsFixed(2)),
          'margin': snackRevenue > 0
              ? double.parse((((snackRevenue - snackCOGS) / snackRevenue) * 100).toStringAsFixed(1))
              : 0.0,
          'units': snackUnits,
        },
      },
      'paymentBreakdown': paymentMethodCounts.map((k, v) => MapEntry(k, {
            'count': v,
            'revenue': double.parse((paymentMethodRevenue[k] ?? 0.0).toStringAsFixed(2)),
            'percent': periodRevenue > 0
                ? double.parse((((paymentMethodRevenue[k] ?? 0.0) / periodRevenue) * 100).toStringAsFixed(1))
                : 0.0,
          })),
      'topProducts': productSalesRank,
    };
  }

  Map<String, dynamic> getInventorySummary() {
    int totalItems = _products.length;
    int totalStock = 0;
    double totalCostVal = 0.0;
    double totalRetailVal = 0.0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (final p in _products) {
      totalStock += p.stock;
      final cost = p.costPrice > 0 ? p.costPrice : p.price * 0.5;
      totalCostVal += cost * p.stock;
      totalRetailVal += p.price * p.stock;
      if (p.stock <= 0) {
        outOfStockCount++;
      } else if (p.stock <= p.minStockLevel) {
        lowStockCount++;
      }
    }

    final potentialProfit = totalRetailVal - totalCostVal;
    final margin = totalRetailVal > 0 ? (potentialProfit / totalRetailVal) * 100 : 0.0;

    return {
      'totalItems': totalItems,
      'totalStockCount': totalStock,
      'totalCostValuation': double.parse(totalCostVal.toStringAsFixed(2)),
      'totalRetailValuation': double.parse(totalRetailVal.toStringAsFixed(2)),
      'potentialProfit': double.parse(potentialProfit.toStringAsFixed(2)),
      'overallMargin': double.parse(margin.toStringAsFixed(1)),
      'lowStockAlerts': lowStockCount,
      'outOfStockAlerts': outOfStockCount,
    };
  }

  List<ReportModel> generatePeriodicReportModels() {
    final now = DateTime.now();
    final inventorySummary = getInventorySummary();
    final todayData = getFilteredReport(period: 'today');
    final weekData = getFilteredReport(period: 'week');
    final monthData = getFilteredReport(period: 'month');
    final yearData = getFilteredReport(period: 'year');
    final allData = getFilteredReport(period: 'all');

    Map<String, dynamic> cleanReportMap(Map<String, dynamic> report) {
      final copy = Map<String, dynamic>.from(report);
      final rawTop = List<Map<String, dynamic>>.from(report['topProducts'] as List);
      copy['topProducts'] = rawTop.map((item) {
        final prod = item['product'] as ProductModel;
        return {
          'productId': prod.id,
          'productName': prod.name,
          'sku': prod.sku,
          'category': prod.category,
          'units': item['units'],
          'revenue': item['revenue'],
          'cogs': item['cogs'],
          'profit': item['profit'],
          'margin': item['margin'],
          'avgPrice': item['avgPrice'],
        };
      }).toList();
      return copy;
    }

    return [
      ReportModel(
        id: 'rep_daily_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}',
        reportType: 'daily_summary',
        title: 'Daily Sales & Financial Summary',
        period: 'today',
        generatedAt: now,
        generatedBy: _currentUser?.name ?? 'System',
        metrics: cleanReportMap(todayData),
        inventorySummary: inventorySummary,
      ),
      ReportModel(
        id: 'rep_weekly_${now.year}_w${((now.day - 1) ~/ 7 + 1)}',
        reportType: 'weekly_summary',
        title: 'Weekly Sales & Performance Report',
        period: 'week',
        generatedAt: now,
        generatedBy: _currentUser?.name ?? 'System',
        metrics: cleanReportMap(weekData),
        inventorySummary: inventorySummary,
      ),
      ReportModel(
        id: 'rep_monthly_${now.year}_${now.month.toString().padLeft(2, '0')}',
        reportType: 'monthly_summary',
        title: 'Monthly Revenue & Profitability Analysis',
        period: 'month',
        generatedAt: now,
        generatedBy: _currentUser?.name ?? 'System',
        metrics: cleanReportMap(monthData),
        inventorySummary: inventorySummary,
      ),
      ReportModel(
        id: 'rep_annual_${now.year}',
        reportType: 'annual_summary',
        title: 'Annual Fiscal Overview',
        period: 'year',
        generatedAt: now,
        generatedBy: _currentUser?.name ?? 'System',
        metrics: cleanReportMap(yearData),
        inventorySummary: inventorySummary,
      ),
      ReportModel(
        id: 'rep_inventory_valuation',
        reportType: 'inventory_valuation',
        title: 'Real-Time Inventory Valuation & Stock Summary',
        period: 'all',
        generatedAt: now,
        generatedBy: _currentUser?.name ?? 'System',
        metrics: cleanReportMap(allData),
        inventorySummary: inventorySummary,
      ),
    ];
  }

  Future<void> generateAndSyncReports() async {
    if (!MongoDatabase.isConnected) return;
    try {
      final reports = generatePeriodicReportModels();
      for (final report in reports) {
        await MongoDatabase.saveReport(report);
      }
    } catch (e) {
      debugPrint("⚠️ Error synchronizing reports: $e");
    }
  }
}
