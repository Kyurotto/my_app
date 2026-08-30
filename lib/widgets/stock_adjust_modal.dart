import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/app_service.dart';

class StockAdjustModal extends StatefulWidget {
  final ProductModel product;

  const StockAdjustModal({super.key, required this.product});

  @override
  State<StockAdjustModal> createState() => _StockAdjustModalState();
}

class _StockAdjustModalState extends State<StockAdjustModal> {
  final _qtyController = TextEditingController(text: '10');
  final _noteController = TextEditingController();
  String _actionType = 'restock';

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final product = widget.product;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Adjust: ${product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Current: ${product.stock} ${product.unit} (Min: ${product.minStock})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _actionType,
              decoration: const InputDecoration(labelText: 'Action Type'),
              items: const [
                DropdownMenuItem(value: 'restock', child: Text('📦 Restock Delivery (+)')),
                DropdownMenuItem(value: 'adjustment', child: Text('⚖️ Count Reconciliation (=)')),
                DropdownMenuItem(value: 'damage', child: Text('⚠️ Damaged / Expired (-)')),
                DropdownMenuItem(value: 'wastage', child: Text('☕ Sample / Wastage (-)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _actionType = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _actionType == 'adjustment' ? 'New Exact Stock Level' : 'Quantity to Apply',
                hintText: '10',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Audit Note / Ref #',
                hintText: 'e.g. PO-8921 / supplier delivery',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
            if (qty <= 0 && _actionType != 'adjustment') return;

            final staff = service.currentUser?.name ?? 'Admin';
            final note = _noteController.text.trim();

            if (_actionType == 'restock') {
              await service.restockProduct(product.id, qty, notes: note.isNotEmpty ? note : 'Restock shipment', staffName: staff);
            } else if (_actionType == 'damage' || _actionType == 'wastage') {
              await service.adjustStock(
                product.id,
                -qty,
                action: _actionType,
                reason: note.isNotEmpty ? note : (_actionType == 'damage' ? 'Damaged goods' : 'Wastage / samples'),
                staffName: staff,
              );
            } else {
              final delta = qty - product.stock;
              await service.adjustStock(product.id, delta, action: 'adjustment', reason: note.isNotEmpty ? note : 'Physical count audit', staffName: staff);
            }

            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save & Update DB'),
        ),
      ],
    );
  }
}
