import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_service.dart';

class StockLogsView extends StatefulWidget {
  const StockLogsView({super.key});

  @override
  State<StockLogsView> createState() => _StockLogsViewState();
}

class _StockLogsViewState extends State<StockLogsView> {
  String _filterType = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final logs = service.stockLogs.where((l) {
      if (_filterType != 'all' && l.action != _filterType) return false;
      if (_search.isNotEmpty) {
        final query = _search.toLowerCase();
        return l.productName.toLowerCase().contains(query) ||
            l.productId.toLowerCase().contains(query) ||
            l.productSku.toLowerCase().contains(query) ||
            l.referenceNo.toLowerCase().contains(query) ||
            l.notes.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Search audit logs (Product, SKU, Note)...',
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
                value: _filterType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Events')),
                  DropdownMenuItem(value: 'restock', child: Text('📦 Restock')),
                  DropdownMenuItem(value: 'sale', child: Text('🛒 POS Sale')),
                  DropdownMenuItem(value: 'adjustment', child: Text('⚖️ Adjustment')),
                  DropdownMenuItem(value: 'damage', child: Text('⚠️ Damaged')),
                  DropdownMenuItem(value: 'wastage', child: Text('☕ Wastage')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _filterType = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: const Text('No stock movement logs found.', style: TextStyle(fontWeight: FontWeight.bold)),
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
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3EDE2)),
              itemBuilder: (context, idx) {
                final log = logs[idx];
                final isPositive = log.quantityChanged > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(log.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                const SizedBox(width: 6),
                                Text('(${log.productSku})', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${log.actionLabel} • ${log.notes} • Staff: ${log.staffName}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPositive ? '+' : ''}${log.quantityChanged}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                          Text('${log.previousStock} ➔ ${log.newStock}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          Text(DateFormat('MMM dd, hh:mm a').format(log.createdAt), style: TextStyle(fontSize: 9.5, color: Colors.grey[500])),
                        ],
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
}
