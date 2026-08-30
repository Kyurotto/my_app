import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../database.dart';

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
  final Map<String, String> _passwords = {}; // username/email -> password

  final List<ProductModel> _products = [];
  List<ProductModel> get products => List.unmodifiable(_products);

  final List<OrderModel> _orders = [];
  List<OrderModel> get orders => List.unmodifiable(_orders);

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
    _passwords['admin@example.com'] = 'password';
    _passwords['admin'] = 'password';
    _passwords['employee@example.com'] = 'password';
    _passwords['employee'] = 'password';

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
    if (storedPw == password) {
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
    _passwords[newUser.email] = password;
    _passwords[newUser.username] = password;
    if (MongoDatabase.isConnected) {
      MongoDatabase.saveUser(newUser, password);
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

    if (currentPassword != null && currentPassword.isNotEmpty) {
      final storedPw = _passwords[_currentUser!.email] ?? _passwords[_currentUser!.username];
      if (storedPw != currentPassword) {
        return false;
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        _passwords[email.trim()] = newPassword;
        _passwords[_currentUser!.username] = newPassword;
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
    if (MongoDatabase.isConnected) {
      final pw = _passwords[updated.email] ?? _passwords[updated.username] ?? 'password';
      MongoDatabase.saveUser(updated, pw);
    }
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
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
          _users.add(UserModel.fromMap(u));
          final pw = u['password']?.toString() ?? 'password';
          if (u['email'] != null) _passwords[u['email'].toString()] = pw;
          if (u['username'] != null) _passwords[u['username'].toString()] = pw;
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

      notifyListeners();
      debugPrint("✅ AppService successfully synced with MongoDB! (${_orders.length} orders loaded)");
    } catch (e) {
      debugPrint("⚠️ Error in syncWithDatabase: $e");
    }
  }

  // --- PRODUCTS CRUD ---

  Future<void> addProduct(ProductModel product) async {
    _products.insert(0, product);
    notifyListeners();
    if (MongoDatabase.isConnected) {
      MongoDatabase.saveProduct(product);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(product);
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    if (MongoDatabase.isConnected) {
      MongoDatabase.deleteProduct(id);
    }
  }

  Future<void> setStock(String productId, int newStock) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final clamped = max(0, newStock);
      _products[idx] = _products[idx].copyWith(stock: clamped);
      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(_products[idx]);
      }
    }
  }

  Future<void> adjustStock(String productId, int delta) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final current = _products[idx].stock;
      final updated = max(0, current + delta);
      _products[idx] = _products[idx].copyWith(stock: updated);
      notifyListeners();
      if (MongoDatabase.isConnected) {
        MongoDatabase.saveProduct(_products[idx]);
      }
    }
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
    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.subtotal;
      // Deduct stock
      adjustStock(item.productId, -item.quantity);
    }

    final tax = double.parse((subtotal * 0.10).toStringAsFixed(2));
    final total = double.parse((subtotal + tax).toStringAsFixed(2));

    final newOrder = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      receiptNo: _generateReceiptNo(),
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
    }

    return newOrder;
  }

  // --- ANALYTICS / STATS ---

  int get totalOrdersCount => _orders.length;

  double get totalRevenue =>
      _orders.fold(0.0, (sum, o) => sum + o.total);

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

  Map<String, dynamic> getFilteredReport({required int month, required int year}) {
    final filtered = _orders.where((o) =>
        o.createdAt.month == month && o.createdAt.year == year).toList();

    final periodOrders = filtered.length;
    final periodRevenue = filtered.fold(0.0, (sum, o) => sum + o.total);

    double milkTea = 0.0;
    double snack = 0.0;
    for (final order in filtered) {
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
      'periodOrders': periodOrders,
      'periodRevenue': double.parse(periodRevenue.toStringAsFixed(2)),
      'categoryRevenue': {
        'Milk Tea': double.parse(milkTea.toStringAsFixed(2)),
        'Snack': double.parse(snack.toStringAsFixed(2)),
      },
    };
  }
}
