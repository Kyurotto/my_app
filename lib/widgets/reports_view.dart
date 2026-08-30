import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import 'stat_card.dart';
import 'pie_chart_painter.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedPeriod = 'month'; // 'today', 'week', 'month', 'year', 'all', 'custom'
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _customDateRange;

  String _productSortBy = 'revenue'; // 'revenue', 'units', 'profit', 'margin'
  String _productSearch = '';

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final report = service.getFilteredReport(
      period: _selectedPeriod,
      month: _selectedMonth,
      year: _selectedYear,
      startDate: _customDateRange?.start,
      endDate: _customDateRange?.end,
    );

    final periodOrders = report['periodOrders'] as int;
    final periodRevenue = report['periodRevenue'] as double;
    final periodSubtotal = report['periodSubtotal'] as double;
    final periodTax = report['periodTax'] as double;
    final periodCOGS = report['periodCOGS'] as double;
    final grossProfit = report['grossProfit'] as double;
    final grossMargin = report['grossMargin'] as double;
    final avgOrderValue = report['avgOrderValue'] as double;
    final totalUnitsSold = report['totalUnitsSold'] as int;
    final catData = Map<String, double>.from(report['categoryRevenue']);
    final catBreakdown = Map<String, dynamic>.from(report['categoryBreakdown']);
    final paymentBreakdown = Map<String, dynamic>.from(report['paymentBreakdown']);
    final rawTopProducts = List<Map<String, dynamic>>.from(report['topProducts']);

    final filteredTopProducts = rawTopProducts.where((item) {
      final prod = item['product'] as ProductModel;
      return prod.name.toLowerCase().contains(_productSearch.toLowerCase()) ||
          prod.sku.toLowerCase().contains(_productSearch.toLowerCase());
    }).toList();

    filteredTopProducts.sort((a, b) {
      switch (_productSortBy) {
        case 'units':
          return (b['units'] as int).compareTo(a['units'] as int);
        case 'profit':
          return (b['profit'] as double).compareTo(a['profit'] as double);
        case 'margin':
          return (b['margin'] as double).compareTo(a['margin'] as double);
        case 'revenue':
        default:
          return (b['revenue'] as double).compareTo(a['revenue'] as double);
      }
    });

    final isCompact = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, service, report),
        const SizedBox(height: 16),
        _buildPeriodFilterBar(context),
        const SizedBox(height: 20),
        _buildFinancialKpiCards(
          periodRevenue: periodRevenue,
          periodOrders: periodOrders,
          avgOrderValue: avgOrderValue,
          periodCOGS: periodCOGS,
          grossProfit: grossProfit,
          grossMargin: grossMargin,
          totalUnitsSold: totalUnitsSold,
          catBreakdown: catBreakdown,
          isCompact: isCompact,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildCategoryProfitabilityCard(catData, catBreakdown, periodRevenue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildFinancialHealthCard(
                      periodRevenue: periodRevenue,
                      periodSubtotal: periodSubtotal,
                      periodTax: periodTax,
                      periodCOGS: periodCOGS,
                      grossProfit: grossProfit,
                      grossMargin: grossMargin,
                      periodOrders: periodOrders,
                      paymentBreakdown: paymentBreakdown,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildCategoryProfitabilityCard(catData, catBreakdown, periodRevenue),
                  const SizedBox(height: 16),
                  _buildFinancialHealthCard(
                    periodRevenue: periodRevenue,
                    periodSubtotal: periodSubtotal,
                    periodTax: periodTax,
                    periodCOGS: periodCOGS,
                    grossProfit: grossProfit,
                    grossMargin: grossMargin,
                    periodOrders: periodOrders,
                    paymentBreakdown: paymentBreakdown,
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        _buildTopProductsCard(filteredTopProducts, periodRevenue),
        const SizedBox(height: 32),
      ],
    );
  }
  Widget _buildHeader(BuildContext context, AppService service, Map<String, dynamic> report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final titleContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales & Profit Analytics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B18),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Revenue, COGS, gross margins, and product performance reports',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        );

        final exportButton = ElevatedButton.icon(
          onPressed: () => _showExportReportDialog(context, service, report),
          icon: const Icon(Icons.print_rounded, size: 17),
          label: const Text('Export / Print Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCoffee,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleContent,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: exportButton),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleContent),
            const SizedBox(width: 16),
            exportButton,
          ],
        );
      },
    );
  }
  Widget _buildPeriodFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE5DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPeriodChip('today', 'Today', Icons.today_rounded),
              _buildPeriodChip('week', 'This Week', Icons.date_range_rounded),
              _buildPeriodChip('month', 'This Month', Icons.calendar_month_rounded),
              _buildPeriodChip('year', 'This Year', Icons.calendar_today_rounded),
              _buildPeriodChip('all', 'All Time', Icons.all_inclusive_rounded),
              _buildPeriodChip('custom', 'Custom Range', Icons.tune_rounded),
            ],
          ),
          if (_selectedPeriod == 'month') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3EDE2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_note_rounded, size: 16, color: AppTheme.coffeeLight),
                    SizedBox(width: 6),
                    Text('Select Month: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF44403C))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2DAD0)),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2DAD0)),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                    items: [2026, 2025, 2024, 2023].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedYear = v);
                    },
                  ),
                ),
              ],
            ),
          ] else if (_selectedPeriod == 'custom') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3EDE2)),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                      initialDateRange: _customDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 30)),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      setState(() => _customDateRange = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _customDateRange != null
                        ? '${DateFormat('MMM dd, yyyy').format(_customDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_customDateRange!.end)}'
                        : 'Select Date Range',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCoffee : const Color(0xFFF9F6F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCoffee : const Color(0xFFE5DDD0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.amberGold : const Color(0xFF78716C),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF44403C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialKpiCards({
    required double periodRevenue,
    required int periodOrders,
    required double avgOrderValue,
    required double periodCOGS,
    required double grossProfit,
    required double grossMargin,
    required int totalUnitsSold,
    required Map<String, dynamic> catBreakdown,
    required bool isCompact,
  }) {
    final cards = [
      StatCard(
        title: 'Gross Revenue',
        value: '\$${periodRevenue.toStringAsFixed(2)}',
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF16A34A),
        subtitle: '$periodOrders orders • Avg \$${avgOrderValue.toStringAsFixed(2)}',
      ),
      StatCard(
        title: 'Cost of Goods (COGS)',
        value: '\$${periodCOGS.toStringAsFixed(2)}',
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFFDC2626),
        subtitle: '${periodRevenue > 0 ? (periodCOGS / periodRevenue * 100).toStringAsFixed(1) : 0}% of Gross Sales',
      ),
      StatCard(
        title: 'Gross Profit',
        value: '\$${grossProfit.toStringAsFixed(2)}',
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF2563EB),
        subtitle: '${grossMargin.toStringAsFixed(1)}% Gross Margin',
      ),
      StatCard(
        title: 'Units Sold',
        value: '$totalUnitsSold items',
        icon: Icons.local_cafe_rounded,
        iconColor: const Color(0xFFD97706),
        subtitle: '${catBreakdown['Milk Tea']?['units'] ?? 0} drinks • ${catBreakdown['Snack']?['units'] ?? 0} snacks',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 950
            ? 4
            : constraints.maxWidth > 550
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: crossAxisCount == 4 ? 1.5 : (crossAxisCount == 2 ? 2.0 : 2.6),
          ),
          itemCount: cards.length,
          itemBuilder: (_, idx) => cards[idx],
        );
      },
    );
  }

  Widget _buildCategoryProfitabilityCard(
    Map<String, double> catData,
    Map<String, dynamic> catBreakdown,
    double periodRevenue,
  ) {
    const palette = [
      AppTheme.coffeeMedium,
      AppTheme.amberGold,
      AppTheme.softMatcha,
      AppTheme.roseBerry,
      AppTheme.coffeeDark,
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
    ];

    final sortedEntries = catBreakdown.entries.toList()
      ..sort((a, b) => ((b.value['revenue'] as double)).compareTo(a.value['revenue'] as double));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE5DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.amberGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, size: 20, color: AppTheme.primaryCoffee),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Margin Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                    ),
                    Text(
                      'Revenue, COGS, and profit margin by department',
                      style: TextStyle(fontSize: 12, color: Color(0xFF78716C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (catData.isEmpty || periodRevenue == 0)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text('No sales data in this period', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            )
          else ...[
            Center(
              child: SizedBox(
                height: 140,
                width: 140,
                child: CustomPaint(painter: PieChartPainter(data: catData)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3EDE2)),
            const SizedBox(height: 12),
            ...sortedEntries.asMap().entries.map((item) {
              final idx = item.key;
              final entry = item.value;
              final catName = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final rev = data['revenue'] as double;
              final cogs = data['cogs'] as double;
              final profit = data['profit'] as double;
              final margin = data['margin'] as double;
              final units = data['units'] as int;
              final share = periodRevenue > 0 ? (rev / periodRevenue * 100) : 0.0;
              final color = palette[idx % palette.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Text('\$${rev.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$units sold • ${share.toStringAsFixed(1)}% of sales', style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
                        Text('COGS \$${cogs.toStringAsFixed(0)} | Profit \$${profit.toStringAsFixed(0)} (${margin.toStringAsFixed(0)}%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: margin >= 50 ? const Color(0xFF15803D) : const Color(0xFFB45309))),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard({
    required double periodRevenue,
    required double periodSubtotal,
    required double periodTax,
    required double periodCOGS,
    required double grossProfit,
    required double grossMargin,
    required int periodOrders,
    required Map<String, dynamic> paymentBreakdown,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE5DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.softMatcha.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 20, color: Color(0xFF15803D)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income Statement Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                    ),
                    Text(
                      'Period accounting and financial breakdown',
                      style: TextStyle(fontSize: 12, color: Color(0xFF78716C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildHealthRow('Product Subtotal (Net of Tax)', '\$${periodSubtotal.toStringAsFixed(2)}', isBold: false),
          const SizedBox(height: 8),
          _buildHealthRow('Estimated Sales Tax (8%)', '+\$${periodTax.toStringAsFixed(2)}', isBold: false, textColor: const Color(0xFF78716C)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF3EDE2)),
          const SizedBox(height: 8),
          _buildHealthRow('Gross Revenue Collected', '\$${periodRevenue.toStringAsFixed(2)}', isBold: true, textColor: const Color(0xFF1E1B18)),
          const SizedBox(height: 8),
          _buildHealthRow('Cost of Goods Sold (COGS)', '-\$${periodCOGS.toStringAsFixed(2)}', isBold: false, textColor: const Color(0xFFDC2626)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF3EDE2)),
          const SizedBox(height: 8),
          _buildHealthRow(
            'Gross Operating Profit',
            '\$${grossProfit.toStringAsFixed(2)}',
            isBold: true,
            textColor: grossProfit >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            badge: '${grossMargin.toStringAsFixed(1)}% margin',
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Methods Split',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF44403C)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paymentBreakdown.entries.map((e) {
              final count = e.value as int;
              final pct = periodOrders > 0 ? (count / periodOrders * 100).toStringAsFixed(0) : '0';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE7E0D3)),
                ),
                child: Text(
                  '${e.key}: $count ($pct%)',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF44403C)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, {bool isBold = false, Color? textColor, String? badge}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF44403C),
            ),
          ),
        ),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
          ),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: textColor ?? const Color(0xFF1E1B18),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(List<Map<String, dynamic>> products, double periodRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE5DA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderboardHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3EDE2)),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text('No products match your filter criteria.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            )
          else
            _buildLeaderboardTable(products),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final title = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryCoffee.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.leaderboard_rounded, size: 20, color: AppTheme.primaryCoffee),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Sales Leaderboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                ),
                Text(
                  'Sales volume, COGS, and profit margin performance',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78716C)),
                ),
              ],
            ),
          ],
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isNarrow ? 130 : 170,
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _productSearch = v),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search item...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF78716C)),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: const Color(0xFFF9F6F0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DAD0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DAD0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2DAD0)),
              ),
              child: DropdownButton<String>(
                value: _productSortBy,
                underline: const SizedBox(),
                icon: const Icon(Icons.sort_rounded, size: 16),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                items: const [
                  DropdownMenuItem(value: 'revenue', child: Text('Sort: Revenue')),
                  DropdownMenuItem(value: 'units', child: Text('Sort: Units')),
                  DropdownMenuItem(value: 'profit', child: Text('Sort: Profit')),
                  DropdownMenuItem(value: 'margin', child: Text('Sort: Margin %')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _productSortBy = v);
                },
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), controls],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [title, controls],
        );
      },
    );
  }

  Widget _buildLeaderboardTable(List<Map<String, dynamic>> products) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        horizontalMargin: 8,
        columnSpacing: 18,
        headingTextStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF78716C),
          letterSpacing: 0.2,
        ),
        columns: const [
          DataColumn(label: Text('RANK / ITEM')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('PRICE / COST'), numeric: true),
          DataColumn(label: Text('UNITS'), numeric: true),
          DataColumn(label: Text('REVENUE'), numeric: true),
          DataColumn(label: Text('COGS'), numeric: true),
          DataColumn(label: Text('PROFIT'), numeric: true),
          DataColumn(label: Text('MARGIN'), numeric: true),
        ],
        rows: products.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;
          final product = item['product'] as ProductModel;
          final units = item['units'] as int;
          final revenue = item['revenue'] as double;
          final cogs = item['cogs'] as double;
          final profit = item['profit'] as double;
          final margin = item['margin'] as double;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? const Color(0xFFFEF3C7)
                            : (rank == 2 ? const Color(0xFFE2E8F0) : (rank == 3 ? const Color(0xFFFFEDD5) : const Color(0xFFF5F5F4))),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: rank == 1
                              ? const Color(0xFFB45309)
                              : (rank == 2 ? const Color(0xFF475569) : (rank == 3 ? const Color(0xFFC2410C) : const Color(0xFF78716C))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B18))),
                        Text('SKU: ${product.sku}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF78716C))),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(6)),
                  child: Text(product.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF57534E))),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Cost \$${product.costPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Color(0xFF78716C))),
                  ],
                ),
              ),
              DataCell(Text('$units', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF1E1B18)))),
              DataCell(Text('\$${revenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF16A34A)))),
              DataCell(Text('\$${cogs.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
              DataCell(Text('\$${profit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF2563EB)))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: margin >= 60 ? const Color(0xFFDCFCE7) : (margin >= 40 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: margin >= 60 ? const Color(0xFF15803D) : (margin >= 40 ? const Color(0xFFB45309) : const Color(0xFFB91C1C)),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showExportReportDialog(BuildContext context, AppService service, Map<String, dynamic> report) {
    final periodOrders = report['periodOrders'] as int;
    final periodRevenue = report['periodRevenue'] as double;
    final periodSubtotal = report['periodSubtotal'] as double;
    final periodTax = report['periodTax'] as double;
    final periodCOGS = report['periodCOGS'] as double;
    final grossProfit = report['grossProfit'] as double;
    final grossMargin = report['grossMargin'] as double;
    final topProducts = List<Map<String, dynamic>>.from(report['topProducts']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCoffee.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryCoffee, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Boba Time Cafe - Statement', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E1B18))),
                          Text('Period: ${_selectedPeriod.toUpperCase()} • Generated ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEBE5DA)),
                const SizedBox(height: 12),
                const Text('FINANCIAL SUMMARY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF78716C), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _buildHealthRow('Total Completed Orders', '$periodOrders'),
                const SizedBox(height: 6),
                _buildHealthRow('Product Subtotal', '\$${periodSubtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _buildHealthRow('Sales Tax Collected', '\$${periodTax.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _buildHealthRow('Gross Revenue', '\$${periodRevenue.toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 6),
                _buildHealthRow('Cost of Goods (COGS)', '-\$${periodCOGS.toStringAsFixed(2)}', textColor: const Color(0xFFDC2626)),
                const SizedBox(height: 6),
                _buildHealthRow('Gross Profit', '\$${grossProfit.toStringAsFixed(2)}', isBold: true, textColor: const Color(0xFF15803D), badge: '${grossMargin.toStringAsFixed(1)}% margin'),
                const SizedBox(height: 18),
                const Text('TOP SELLING ITEMS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF78716C), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...topProducts.take(5).map((item) {
                  final p = item['product'] as ProductModel;
                  final u = item['units'] as int;
                  final r = item['revenue'] as double;
                  final m = item['margin'] as double;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text('$u sold • \$${r.toStringAsFixed(2)} (${m.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11.5, color: Color(0xFF57534E))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF78716C))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report export prepared & ready for print/download.'),
                  backgroundColor: Color(0xFF15803D),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Print / Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCoffee,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }


}
