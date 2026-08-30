import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductModal extends StatefulWidget {
  final ProductModel? product;
  final Function(ProductModel) onSave;

  const ProductModal({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  String _category = 'milktea';
  String _unit = 'cups';

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(
      text: widget.product?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(2) : '',
    );
    _costPriceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.costPrice.toStringAsFixed(2)
          : '',
    );
    _stockController = TextEditingController(
      text: widget.product != null ? widget.product!.stock.toString() : '25',
    );
    _minStockController = TextEditingController(
      text: widget.product != null ? widget.product!.minStock.toString() : '10',
    );
    _category = widget.product?.category ?? 'milktea';
    _unit = widget.product?.unit ?? 'cups';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final costPrice = double.tryParse(_costPriceController.text.trim()) ?? (price * 0.5);
      final stock = int.tryParse(_stockController.text.trim()) ?? 20;
      final minStock = int.tryParse(_minStockController.text.trim()) ?? 10;

      final updatedProduct = ProductModel(
        id: widget.product?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        costPrice: costPrice,
        category: _category,
        stock: stock,
        minStock: minStock,
        unit: _unit,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(updatedProduct);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name & SKU
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          hintText: 'e.g. Classic Milk Tea',
                          prefixIcon: Icon(Icons.drive_file_rename_outline),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU / Code',
                          hintText: 'MT-001',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category & Unit
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'milktea', child: Text('Milk Tea')),
                          DropdownMenuItem(value: 'snack', child: Text('Snack')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _category = val;
                              _unit = val == 'milktea' ? 'cups' : 'servings';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.straighten_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cups', child: Text('Cups')),
                          DropdownMenuItem(value: 'servings', child: Text('Servings')),
                          DropdownMenuItem(value: 'pcs', child: Text('Pieces')),
                          DropdownMenuItem(value: 'boxes', child: Text('Boxes')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Selling Price & Cost Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (\$)',
                          hintText: '4.50',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter price';
                          final d = double.tryParse(val.trim());
                          if (d == null || d <= 0) return 'Valid price > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cost Price (\$)',
                          hintText: '2.25',
                          prefixIcon: Icon(Icons.money_off_rounded),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final d = double.tryParse(val.trim());
                            if (d == null || d < 0) return 'Cost >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Initial Stock & Min Stock (Alert Threshold)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current Stock',
                          hintText: '25',
                          prefixIcon: Icon(Icons.inventory_2_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter stock';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Stock >= 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Alert',
                          hintText: '10',
                          prefixIcon: Icon(Icons.notification_important_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter min';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Min >= 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                    hintText: 'Product ingredients, flavor profile, or supplier info...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isEdit ? 'Save Changes' : 'Add Product'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
