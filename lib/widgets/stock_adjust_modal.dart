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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  final _noteController = TextEditingController();
  String _actionType = 'restock';

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '10');
  }

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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Current: ${product.stock} ${product.unit} (Min: ${product.minStock})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
                  if (v != null) {
                    setState(() {
                      _actionType = v;
                      if (v == 'adjustment') {
                        _qtyController.text = product.stock.toString();
                      } else if (_qtyController.text == product.stock.toString() ||
                          (int.tryParse(_qtyController.text.trim()) ?? 0) <= 0) {
                        _qtyController.text = '10';
                      }
                    });
                    _formKey.currentState?.validate();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                decoration: InputDecoration(
                  labelText: _actionType == 'adjustment' ? 'New Exact Stock Level' : 'Quantity to Apply',
                  hintText: _actionType == 'adjustment' ? '0' : '10',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return _actionType == 'adjustment'
                        ? 'Please enter a stock level'
                        : 'Please enter a quantity';
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null) {
                    return 'Please enter a valid whole number';
                  }
                  if (_actionType == 'adjustment') {
                    if (parsed < 0) {
                      return 'Stock level cannot be negative';
                    }
                  } else {
                    if (parsed <= 0) {
                      return 'Quantity must be greater than 0';
                    }
                  }
                  return null;
                },
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final qty = int.tryParse(_qtyController.text.trim());
            if (qty == null) return;
            if (_actionType == 'adjustment' && qty < 0) return;
            if (_actionType != 'adjustment' && qty <= 0) return;

            final staff = service.currentUser?.name ?? 'Admin';
            final note = _noteController.text.trim();

            if (_actionType == 'restock') {
              await service.restockProduct(
                product.id,
                qty,
                notes: note.isNotEmpty ? note : 'Restock shipment',
                staffName: staff,
              );
            } else if (_actionType == 'damage' || _actionType == 'wastage') {
              await service.adjustStock(
                product.id,
                -qty,
                action: _actionType,
                reason: note.isNotEmpty
                    ? note
                    : (_actionType == 'damage' ? 'Damaged goods' : 'Wastage / samples'),
                staffName: staff,
              );
            } else {
              final delta = qty - product.stock;
              await service.adjustStock(
                product.id,
                delta,
                action: 'adjustment',
                reason: note.isNotEmpty ? note : 'Physical count audit',
                staffName: staff,
              );
            }

            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save & Update DB'),
        ),
      ],
    );
  }
}
