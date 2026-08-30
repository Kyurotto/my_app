import 'product_model.dart';

class StockModel {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String category;
  final int currentStock;
  final int minStock;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double stockValueCost;
  final double stockValueSelling;
  final String status; // 'in_stock', 'low_stock', 'out_of_stock'
  final DateTime updatedAt;

  StockModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.category,
    required this.currentStock,
    this.minStock = 10,
    this.unit = 'pcs',
    required this.costPrice,
    required this.sellingPrice,
    required this.stockValueCost,
    required this.stockValueSelling,
    required this.status,
    required this.updatedAt,
  });

  factory StockModel.fromProduct(ProductModel product) {
    final cost = product.costPrice > 0 ? product.costPrice : product.price * 0.5;
    final status = product.stock <= 0
        ? 'out_of_stock'
        : (product.stock <= product.minStockLevel ? 'low_stock' : 'in_stock');
    return StockModel(
      id: 'stock_${product.id}',
      productId: product.id,
      productName: product.name,
      sku: product.sku,
      category: product.category,
      currentStock: product.stock,
      minStock: product.minStockLevel,
      unit: product.unit,
      costPrice: cost,
      sellingPrice: product.price,
      stockValueCost: double.parse((cost * product.stock).toStringAsFixed(2)),
      stockValueSelling: double.parse((product.price * product.stock).toStringAsFixed(2)),
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'category': category,
      'currentStock': currentStock,
      'minStock': minStock,
      'unit': unit,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockValueCost': stockValueCost,
      'stockValueSelling': stockValueSelling,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      currentStock: (map['currentStock'] as num?)?.toInt() ?? 0,
      minStock: (map['minStock'] as num?)?.toInt() ?? 10,
      unit: map['unit']?.toString() ?? 'pcs',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stockValueCost: (map['stockValueCost'] as num?)?.toDouble() ?? 0.0,
      stockValueSelling: (map['stockValueSelling'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'in_stock',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
