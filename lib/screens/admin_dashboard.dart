import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/product_modal.dart';
import '../widgets/receipt_modal.dart';
import '../widgets/profile_modal.dart';
import '../widgets/inventory_list_view.dart';
import '../widgets/stock_logs_view.dart';
import '../widgets/reports_view.dart';

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

  // Stocks tab state
  int _stockSubTab = 0; // 0: Inventory Levels, 1: Audit Log Trail

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
            automaticallyImplyLeading: false,
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
                          Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF78472A)),
                          SizedBox(width: 10),
                          Text(
                            'Admin Profile',
                            style: TextStyle(
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                  ),
                  const SizedBox(height: 4),
                  Text('Real-time store performance and order feed', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/employee_dashboard'),
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text('Open POS Terminal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.amberGold,
                        foregroundColor: AppTheme.primaryCoffee,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                      ),
                      const SizedBox(height: 4),
                      Text('Real-time store performance and order feed', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/employee_dashboard'),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  label: const Text('Open POS Terminal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amberGold,
                    foregroundColor: AppTheme.primaryCoffee,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ],
            );
          },
        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Order History',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.amberGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${service.orders.length} orders',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryCoffee,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('All customer transactions and receipts', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await service.syncWithDatabase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orders refreshed from database!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCoffee),
              tooltip: 'Refresh from Database',
            ),
          ],
        ),
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
        // Header Row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory & Stock Control',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time inventory valuations, thresholds & MongoDB audit logs',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await service.syncWithDatabase();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inventory & Stock Logs synced from Database!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync DB'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProductModal(
                        onSave: (p) => service.addProduct(p),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_box_rounded, size: 16),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4 Overview Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.9 : 1.15,
              children: [
                StatCard(
                  title: 'Total Stock Units',
                  value: '${service.totalStockUnits}',
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF0284C7),
                  subtitle: '${service.products.length} catalog items',
                ),
                StatCard(
                  title: 'Retail Asset Value',
                  value: '\$${service.totalInventoryRetailValuation.toStringAsFixed(2)}',
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF16A34A),
                  subtitle: 'Potential gross retail',
                ),
                StatCard(
                  title: 'Cost Asset Value',
                  value: '\$${service.totalInventoryCostValuation.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFFD97706),
                  subtitle: 'Invested inventory cost',
                ),
                StatCard(
                  title: 'Stock Alerts',
                  value: '${service.lowStockProducts.length + service.outOfStockProducts.length}',
                  icon: Icons.warning_amber_rounded,
                  iconColor: service.outOfStockProducts.isNotEmpty ? AppTheme.dangerRed : const Color(0xFFF59E0B),
                  subtitle: '${service.lowStockProducts.length} low, ${service.outOfStockProducts.length} out',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Sub-Tab Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBE5DA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStockSubTabButton(0, 'Current Inventory (${service.products.length})', Icons.table_chart_rounded),
              _buildStockSubTabButton(1, 'Movement Audit Logs (${service.stockLogs.length})', Icons.history_edu_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_stockSubTab == 0)
          const InventoryListView()
        else
          const StockLogsView(),
      ],
    );
  }

  Widget _buildStockSubTabButton(int tabIndex, String title, IconData icon) {
    final isSelected = _stockSubTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _stockSubTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryCoffee : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryCoffee : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 5: REPORTS ---
  Widget _buildReportsTab(AppService service) {
    return const ReportsView();
  }
}


