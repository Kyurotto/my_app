import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/payment_modal.dart';
import '../widgets/receipt_modal.dart';
import '../widgets/profile_modal.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final Map<String, int> _cart = {}; // productId -> quantity
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'milktea', 'snack'

  void _addToCart(ProductModel product) {
    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is currently out of stock!'),
          backgroundColor: AppTheme.dangerRed,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add more than available stock (${product.stock})!'),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _cart[product.id] = currentQty + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _updateQuantity(String productId, int delta, int maxStock) {
    final currentQty = _cart[productId] ?? 0;
    final newQty = currentQty + delta;
    if (newQty <= 0) {
      _removeFromCart(productId);
    } else if (newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot exceed available stock ($maxStock)!'),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
    } else {
      setState(() {
        _cart[productId] = newQty;
      });
    }
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  int get _totalItemCount => _cart.values.fold(0, (sum, q) => sum + q);

  double _calculateSubtotal(List<ProductModel> products) {
    double sum = 0.0;
    for (final entry in _cart.entries) {
      final prod = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => ProductModel(id: '', name: '', description: '', price: 0, category: 'milktea'),
      );
      sum += prod.price * entry.value;
    }
    return sum;
  }

  void _openPaymentDialog(double grandTotal, List<ProductModel> products) {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentModal(
        total: grandTotal,
        onConfirm: (method) async {
          final items = <OrderItemModel>[];
          for (final entry in _cart.entries) {
            final prod = products.firstWhere((p) => p.id == entry.key);
            items.add(OrderItemModel(
              productId: prod.id,
              productName: prod.name,
              unitPrice: prod.price,
              quantity: entry.value,
              subtotal: prod.price * entry.value,
            ));
          }

          final order = await AppService.instance.placeOrder(
            items: items,
            paymentMethod: method,
          );

          if (!mounted) return;
          _clearCart();

          // Show Receipt Modal
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (rCtx) => ReceiptModal(
              order: order,
              onNewOrder: () {
                // POS reset
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppService.instance,
      builder: (context, _) {
        final service = AppService.instance;
        final currentUser = service.currentUser;
        final allProducts = service.products;

        final filteredProducts = allProducts.filter((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'all' ||
              p.category.toLowerCase() == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();

        final milkteaCount = allProducts.where((p) => p.category == 'milktea').length;
        final snackCount = allProducts.where((p) => p.category == 'snack').length;

        final subtotal = _calculateSubtotal(allProducts);
        final tax = double.parse((subtotal * 0.10).toStringAsFixed(2));
        final grandTotal = double.parse((subtotal + tax).toStringAsFixed(2));

        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F3),
          appBar: AppBar(
            backgroundColor: AppTheme.primaryCoffee,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: (currentUser?.isAdmin ?? false)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    tooltip: 'Back to Admin Dashboard',
                    onPressed: () => Navigator.pushReplacementNamed(context, '/admin_dashboard'),
                  )
                : null,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.amberGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    color: AppTheme.primaryCoffee,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coffee Shop POS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Cashier Terminal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD6C7B2),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Profile & Menu
              if (currentUser != null)
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.amberGold,
                          radius: 16,
                          child: Text(
                            currentUser.initial,
                            style: const TextStyle(
                              color: AppTheme.primaryCoffee,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'profile') {
                      showDialog(
                        context: context,
                        builder: (_) => ProfileModal(user: currentUser),
                      );
                    } else if (val == 'logout') {
                      service.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 18, color: Color(0xFF78472A)),
                          const SizedBox(width: 10),
                          Text(
                            currentUser.isAdmin ? 'Admin Profile' : 'Employee Profile',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C1810),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout_rounded, size: 18, color: AppTheme.dangerRed),
                          SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return Row(
                children: [
                  // Left Side: Product Catalog
                  Expanded(
                    flex: isWide ? 65 : 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search & Category Filters Bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: const Color(0xFFEBE5DA), width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search input
                              TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search products by name or ingredient...',
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF78472A)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () => setState(() => _searchQuery = ''),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: const Color(0xFFF9F7F3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Categories
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    CategoryChip(
                                      label: 'All Items',
                                      icon: Icons.restaurant_menu_rounded,
                                      isSelected: _selectedCategory == 'all',
                                      count: allProducts.length,
                                      onTap: () => setState(() => _selectedCategory = 'all'),
                                    ),
                                    const SizedBox(width: 8),
                                    CategoryChip(
                                      label: 'Milk Tea',
                                      icon: Icons.coffee_rounded,
                                      isSelected: _selectedCategory == 'milktea',
                                      count: milkteaCount,
                                      onTap: () => setState(() => _selectedCategory = 'milktea'),
                                    ),
                                    const SizedBox(width: 8),
                                    CategoryChip(
                                      label: 'Snacks',
                                      icon: Icons.lunch_dining_rounded,
                                      isSelected: _selectedCategory == 'snack',
                                      count: snackCount,
                                      onTap: () => setState(() => _selectedCategory = 'snack'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Products Grid
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No matching products found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try checking your search keyword or category filter',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide
                                        ? (constraints.maxWidth > 1200 ? 4 : 3)
                                        : (constraints.maxWidth > 500 ? 3 : 2),
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.76,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, idx) {
                                    final product = filteredProducts[idx];
                                    return ProductCard(
                                      product: product,
                                      onAddToCart: () => _addToCart(product),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Cart Panel (For Tablet & Desktop)
                  if (isWide)
                    Container(
                      width: 360,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: Color(0xFFEBE5DA), width: 1),
                        ),
                      ),
                      child: _buildCartContent(
                        allProducts: allProducts,
                        subtotal: subtotal,
                        tax: tax,
                        grandTotal: grandTotal,
                      ),
                    ),
                ],
              );
            },
          ),
          // Mobile Floating Cart Bottom Sheet
          bottomNavigationBar: MediaQuery.of(context).size.width < 900
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                  child: Row(
                    children: [
                      // Cart Summary Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (ctx) => FractionallySizedBox(
                                heightFactor: 0.75,
                                child: _buildCartContent(
                                  allProducts: allProducts,
                                  subtotal: subtotal,
                                  tax: tax,
                                  grandTotal: grandTotal,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.amberGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Color(0xFF92400E),
                                      size: 22,
                                    ),
                                  ),
                                  if (_totalItemCount > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.dangerRed,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_totalItemCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '\$${grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E1B18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _cart.isEmpty
                            ? null
                            : () => _openPaymentDialog(grandTotal, allProducts),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text('Checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.amberGold,
                          foregroundColor: AppTheme.primaryCoffee,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
        );
      },
    );
  }

  Widget _buildCartContent({
    required List<ProductModel> allProducts,
    required double subtotal,
    required double tax,
    required double grandTotal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Current Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.amberGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalItemCount items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCoffee,
                      ),
                    ),
                  ),
                ],
              ),
              if (_cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.grey),
                  tooltip: 'Clear Cart',
                  onPressed: _clearCart,
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEBE5DA)),

        // Cart Items List
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.amberGold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 36,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap items on the left to start an order',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final productId = _cart.keys.elementAt(idx);
                    final quantity = _cart.values.elementAt(idx);
                    final product = allProducts.firstWhere(
                      (p) => p.id == productId,
                      orElse: () => ProductModel(
                        id: productId,
                        name: 'Item',
                        description: '',
                        price: 0,
                        category: 'milktea',
                      ),
                    );

                    final lineTotal = product.price * quantity;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECE6DC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1B18),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)} each',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2DAD0)),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _updateQuantity(product.id, -1, product.stock),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.remove, size: 14, color: Color(0xFF78472A)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _updateQuantity(product.id, 1, product.stock),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.add, size: 14, color: Color(0xFF78472A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Line Total
                          Text(
                            '\$${lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Cart Summary & Checkout
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F3),
            border: const Border(top: BorderSide(color: Color(0xFFEBE5DA), width: 1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 12, color: Color(0xFF78716C))),
                  Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax (10% VAT)', style: TextStyle(fontSize: 12, color: Color(0xFF78716C))),
                  Text('\$${tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE5DFD4)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B18),
                    ),
                  ),
                  Text(
                    '\$${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _cart.isEmpty
                    ? null
                    : () => _openPaymentDialog(grandTotal, allProducts),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Place Order & Pay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amberGold,
                  foregroundColor: AppTheme.primaryCoffee,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}
