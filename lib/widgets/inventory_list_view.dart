import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import 'stock_adjust_modal.dart';

class InventoryListView extends StatefulWidget {
  const InventoryListView({super.key});

  @override
  State<InventoryListView> createState() => _InventoryListViewState();
}

class _InventoryListViewState extends State<InventoryListView> {
  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Search product or SKU...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBE5DA)),
          ),
          child: DropdownButton<String>(
            value: _filter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Stock')),
              DropdownMenuItem(value: 'low', child: Text('⚠️ Low Alert')),
              DropdownMenuItem(value: 'out', child: Text('🛑 Out of Stock')),
              DropdownMenuItem(value: 'in', child: Text('✅ Normal')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _filter = v);
            },
          ),
        ),
      ],
    );
  }

  String _filter = 'all';
  String _search = '';

  Widget _buildItem(AppService service, ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryCoffee, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('(${product.sku})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    Text('Sell: \$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    Text('Cost: \$${product.costPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Margin: ${product.profitMargin.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: product.isOutOfStock ? const Color(0xFFFEE2E2) : (product.isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.isOutOfStock ? 'Out' : (product.isLowStock ? 'Low (≤${product.minStock})' : 'In Stock'),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: product.isOutOfStock ? const Color(0xFFDC2626) : (product.isLowStock ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text('Min: ${product.minStock} ${product.unit}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2DAD0)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 15),
                  onPressed: () => service.adjustStock(product.id, -1, reason: 'Manual adjustment', staffName: service.currentUser?.name ?? 'Admin'),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  alignment: Alignment.center,
                  child: Text('${product.stock}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 15),
                  onPressed: () => service.adjustStock(product.id, 1, reason: 'Manual adjustment', staffName: service.currentUser?.name ?? 'Admin'),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryCoffee),
            tooltip: 'Adjust / Restock',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => StockAdjustModal(product: product),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final productList = service.products.where((p) {
      if (_filter == 'low' && (!p.isLowStock || p.isOutOfStock)) return false;
      if (_filter == 'out' && !p.isOutOfStock) return false;
      if (_filter == 'in' && (p.isLowStock || p.isOutOfStock)) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(),
        const SizedBox(height: 16),
        if (productList.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: const Text('No products match current filter.', style: TextStyle(fontWeight: FontWeight.bold)),
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
              itemCount: productList.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3EDE2)),
              itemBuilder: (context, idx) => _buildItem(service, productList[idx]),
            ),
          ),
      ],
    );
  }
}
