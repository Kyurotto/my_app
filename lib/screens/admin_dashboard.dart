import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/pie_chart_painter.dart';
import '../widgets/product_modal.dart';
import '../widgets/receipt_modal.dart';
import '../widgets/profile_modal.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab = 0; // 0: Overview, 1: Orders, 2: Products, 3: Stocks, 4: Reports

  // Filters
  String _productSearch = '';
  String _productCategory = 'all';
  String _orderSearch = '';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppService.instance,
      builder: (context, _) {
        final service = AppService.instance;
        final currentUser = service.currentUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F5EE),
          appBar: AppBar(
            backgroundColor: AppTheme.primaryCoffee,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.amberGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
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
                        'Coffee Shop Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Management Console',
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
              // Switch to POS
              IconButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/employee_dashboard'),
                icon: const Icon(Icons.point_of_sale_rounded, size: 20, color: AppTheme.amberGold),
                tooltip: 'Open POS Terminal',
              ),

              // Profile & Logout Menu
              if (currentUser != null)
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
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
                        children: const [
                          Icon(Icons.person_outline, size: 18, color: Color(0xFF78472A)),
                          SizedBox(width: 8),
                          Text('Admin Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, size: 18, color: AppTheme.dangerRed),
                          SizedBox(width: 8),
                          Text('Sign Out', style: TextStyle(color: AppTheme.dangerRed)),
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

              if (isWide) {
                // Desktop / Tablet Sidebar Layout
                return Row(
                  children: [
                    // Sidebar Nav
                    Container(
                      width: 240,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Color(0xFFEBE5DA), width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Text(
                              'MAIN MENU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Color(0xFF78716C),
                              ),
                            ),
                          ),
                          _buildSidebarItem(0, 'Dashboard', Icons.dashboard_rounded),
                          _buildSidebarItem(1, 'Orders', Icons.receipt_long_rounded, badge: service.todayOrdersCount.toString()),
                          _buildSidebarItem(2, 'Products', Icons.inventory_2_rounded),
                          _buildSidebarItem(3, 'Stocks', Icons.layers_rounded),
                          _buildSidebarItem(4, 'Reports', Icons.analytics_rounded),
                          const Spacer(),
                          // Quick Info Card
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEBE3D6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF16A34A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Store Active',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('EEEE, MMM dd').format(DateTime.now()),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF78472A), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Tab View Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildActiveTabContent(service),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile Layout with Top Tabs or Bottom Nav
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildActiveTabContent(service),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width < 900
              ? NavigationBar(
                  selectedIndex: _activeTab,
                  onDestinationSelected: (idx) => setState(() => _activeTab = idx),
                  backgroundColor: Colors.white,
                  indicatorColor: AppTheme.amberGold.withValues(alpha: 0.25),
                  destinations: [
                    const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
                    NavigationDestination(
                      icon: Badge(
                        label: Text('${service.todayOrdersCount}'),
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      selectedIcon: Badge(
                        label: Text('${service.todayOrdersCount}'),
                        child: const Icon(Icons.receipt_long_rounded),
                      ),
                      label: 'Orders',
                    ),
                    const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Products'),
                    const NavigationDestination(icon: Icon(Icons.layers_outlined), selectedIcon: Icon(Icons.layers_rounded), label: 'Stocks'),
                    const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Reports'),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon, {String? badge}) {
    final isSelected = _activeTab == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.amberGold : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.amberGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.primaryCoffee : const Color(0xFF78716C),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? AppTheme.primaryCoffee : const Color(0xFF44403C),
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryCoffee : const Color(0xFFEBE5DA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF78472A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(AppService service) {
    switch (_activeTab) {
      case 0:
        return _buildOverviewTab(service);
      case 1:
        return _buildOrdersTab(service);
      case 2:
        return _buildProductsTab(service);
      case 3:
        return _buildStocksTab(service);
      case 4:
        return _buildReportsTab(service);
      default:
        return _buildOverviewTab(service);
    }
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(AppService service) {
    final recentOrders = service.orders.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
        ),
        const SizedBox(height: 4),
        Text('Real-time store performance and order feed', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 20),

        // 4 KPI Stat Cards Grid
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            StatCard(
              title: "Today's Orders",
              value: service.todayOrdersCount.toString(),
              icon: Icons.coffee_rounded,
              iconColor: const Color(0xFFD97706),
              subtitle: 'Updated live',
            ),
            StatCard(
              title: "Today's Revenue",
              value: '\$${service.todayRevenue.toStringAsFixed(2)}',
              icon: Icons.attach_money_rounded,
              iconColor: const Color(0xFF16A34A),
              subtitle: 'Today cash & online',
            ),
            StatCard(
              title: "Total Orders",
              value: service.totalOrdersCount.toString(),
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF2563EB),
              subtitle: 'All-time transactions',
            ),
            StatCard(
              title: "All-Time Revenue",
              value: '\$${service.totalRevenue.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF7C3AED),
              subtitle: 'Completed sales',
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Recent Orders Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
            ),
            TextButton(
              onPressed: () => setState(() => _activeTab = 1),
              child: const Text('View All Orders →', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: Text('No orders recorded yet. Place orders via POS!', style: TextStyle(color: Colors.grey[500])),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentOrders.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3EDE2)),
              itemBuilder: (context, idx) {
                final order = recentOrders[idx];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ReceiptModal(order: order, onNewOrder: () {}),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(order.receiptNo, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: order.paymentMethod == 'physical' ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.paymentLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: order.paymentMethod == 'physical' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.cashierName} • ${DateFormat('hh:mm a').format(order.createdAt)} • ${order.items.map((i) => '${i.productName} ×${i.quantity}').join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB45309), fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- TAB 2: ORDERS ---
  Widget _buildOrdersTab(AppService service) {
    final filteredOrders = service.orders.where((o) {
      return o.receiptNo.toLowerCase().contains(_orderSearch.toLowerCase()) ||
          o.cashierName.toLowerCase().contains(_orderSearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
        ),
        const SizedBox(height: 4),
        Text('All customer transactions and receipts', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 20),

        // Search bar
        TextField(
          onChanged: (v) => setState(() => _orderSearch = v),
          decoration: InputDecoration(
            hintText: 'Search by receipt number (e.g. REC-...) or cashier name...',
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF78472A)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text('No orders found matching your search', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredOrders.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3EDE2)),
              itemBuilder: (context, idx) {
                final order = filteredOrders[idx];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ReceiptModal(order: order, onNewOrder: () {}),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(order.receiptNo, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13.5)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: order.paymentMethod == 'physical' ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.paymentLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: order.paymentMethod == 'physical' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EDE2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF78472A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cashier: ${order.cashierName} • ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Items: ${order.items.map((i) => '${i.productName} ×${i.quantity}').join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB45309), fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- TAB 3: PRODUCTS (CRUD) ---
  Widget _buildProductsTab(AppService service) {
    final filtered = service.products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_productSearch.toLowerCase()) ||
          p.description.toLowerCase().contains(_productSearch.toLowerCase());
      final matchCat = _productCategory == 'all' || p.category == _productCategory;
      return matchSearch && matchCat;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
        ),
        const SizedBox(height: 4),
        Text('Create, update, or remove items from the store menu', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ProductModal(
                  onSave: (newProduct) => service.addProduct(newProduct),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amberGold,
              foregroundColor: AppTheme.primaryCoffee,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Filter Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEBE5DA)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _productSearch = v),
                  decoration: const InputDecoration(
                    hintText: 'Search products by name...',
                    prefixIcon: Icon(Icons.search_rounded),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _productCategory,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  DropdownMenuItem(value: 'milktea', child: Text('Milk Tea')),
                  DropdownMenuItem(value: 'snack', child: Text('Snacks')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _productCategory = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Product Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, idx) {
            final product = filtered[idx];
            final isMilktea = product.category == 'milktea';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBE5DA)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isMilktea ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                    ),
                    child: Icon(
                      isMilktea ? Icons.local_cafe_rounded : Icons.lunch_dining_rounded,
                      color: isMilktea ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.categoryLabel} • Stock: ${product.stock}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB45309), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                        tooltip: 'Edit',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ProductModal(
                              product: product,
                              onSave: (updated) => service.updateProduct(updated),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                        tooltip: 'Delete',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Delete Product'),
                              content: Text('Are you sure you want to remove "${product.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dCtx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(dCtx).pop();
                                    service.deleteProduct(product.id);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- TAB 4: STOCKS ---
  Widget _buildStocksTab(AppService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
        ),
        const SizedBox(height: 4),
        Text('Monitor inventory levels and update product stocks instantly', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE5DA)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.products.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3EDE2)),
            itemBuilder: (context, idx) {
              final product = service.products[idx];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text('${product.categoryLabel} • \$${product.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? const Color(0xFFFEE2E2)
                            : (product.isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isOutOfStock
                            ? 'Out of Stock'
                            : (product.isLowStock ? 'Low Stock' : 'In Stock'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: product.isOutOfStock
                              ? const Color(0xFFDC2626)
                              : (product.isLowStock ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Quick Stock Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F6F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2DAD0)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => service.adjustStock(product.id, -1),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 34),
                            alignment: Alignment.center,
                            child: Text(
                              '${product.stock}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => service.adjustStock(product.id, 1),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 5: REPORTS ---
  Widget _buildReportsTab(AppService service) {
    final report = service.getFilteredReport(month: _selectedMonth, year: _selectedYear);
    final periodOrders = report['periodOrders'] as int;
    final periodRevenue = report['periodRevenue'] as double;
    final catData = Map<String, double>.from(report['categoryRevenue']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales & Revenue Reports',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
        ),
        const SizedBox(height: 4),
        Text('Monthly summaries and revenue breakdowns', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Financial report for $_selectedMonth/$_selectedYear printed / exported!'),
                  backgroundColor: AppTheme.primaryCoffee,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Export Report'),
          ),
        ),
        const SizedBox(height: 20),

        // Filter Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEBE5DA)),
          ),
          child: Row(
            children: [
              const Text('Filter Period: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedMonth,
                underline: const SizedBox(),
                items: List.generate(12, (i) {
                  final m = i + 1;
                  return DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
                  );
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedMonth = v);
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox(),
                items: [2026, 2025, 2024, 2023].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedYear = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3 Cards Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: _buildReportCards(service, periodOrders, periodRevenue, catData),
              );
            } else {
              return Column(
                children: _buildReportCards(service, periodOrders, periodRevenue, catData)
                    .map((card) => Padding(padding: const EdgeInsets.only(bottom: 16), child: card))
                    .toList(),
              );
            }
          },
        ),

      ],
    );
  }

  List<Widget> _buildReportCards(AppService service, int periodOrders, double periodRevenue, Map<String, double> catData) {
    return [
      // Card 1: Revenue Progress
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBE5DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Revenue Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Revenue", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('\$${service.todayRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: service.totalRevenue > 0 ? (service.todayRevenue / service.totalRevenue).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: const Color(0xFFF3EDE2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                  borderRadius: BorderRadius.circular(6),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Period Revenue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('\$${periodRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: const Color(0xFFF3EDE2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  borderRadius: BorderRadius.circular(6),
                  minHeight: 8,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Calculated from completed receipts', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),

      // Card 2: Order Totals
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBE5DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Order Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildReportRow('Period Orders', '$periodOrders orders'),
                const Divider(height: 12, color: Color(0xFFF5EFEB)),
                _buildReportRow("Today's Orders", '${service.todayOrdersCount} orders', valueColor: const Color(0xFFD97706)),
                const Divider(height: 12, color: Color(0xFFF5EFEB)),
                _buildReportRow('Period Revenue', '\$${periodRevenue.toStringAsFixed(2)}', valueColor: const Color(0xFF7C3AED)),
                const Divider(height: 12, color: Color(0xFFF5EFEB)),
                _buildReportRow("Today's Revenue", '\$${service.todayRevenue.toStringAsFixed(2)}', valueColor: const Color(0xFF16A34A)),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),

      // Card 3: Revenue by Category Pie Chart
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBE5DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: CategoryPieChart(data: catData),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildReportRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1E1B18),
          ),
        ),
      ],
    );
  }
}
