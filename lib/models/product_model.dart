class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double costPrice;
  final String category; // 'milktea' or 'snack'
  final String? imagePath;
  final int stock;
  final int minStock; // reorder threshold
  final String sku;
  final String unit; // 'cups', 'servings', 'pcs'
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    double? costPrice,
    required this.category,
    this.imagePath,
    this.stock = 25,
    this.minStock = 10,
    String? sku,
    this.unit = 'units',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : costPrice = costPrice ?? (price * 0.5),
        sku = sku ?? 'SKU-${id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()}',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  bool get isNew =>
      createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24)));

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= minStock;
  bool get isInStock => stock > minStock;

  double get stockValueRetail => stock * price;
  double get stockValueCost => stock * costPrice;
  double get potentialProfit => stockValueRetail - stockValueCost;
  double get profitMarginPercent =>
      price > 0 ? (((price - costPrice) / price) * 100) : 0.0;

  double get profitMargin => profitMarginPercent;

  String get categoryLabel =>
      category.toLowerCase() == 'milktea' ? 'Milk Tea' : 'Snack';

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    String? category,
    String? imagePath,
    int? stock,
    int? minStock,
    String? sku,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'category': category,
      'imagePath': imagePath,
      'stock': stock,
      'minStock': minStock,
      'sku': sku,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final priceVal = (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0;
    final costVal = (map['costPrice'] is num)
        ? (map['costPrice'] as num).toDouble()
        : (priceVal * 0.5);

    return ProductModel(
      id: map['id']?.toString() ?? (map['_id']?.toString() ?? ''),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: priceVal,
      costPrice: costVal,
      category: map['category'] ?? 'milktea',
      imagePath: map['imagePath'],
      stock: (map['stock'] is num) ? (map['stock'] as num).toInt() : 20,
      minStock: (map['minStock'] is num) ? (map['minStock'] as num).toInt() : 10,
      sku: map['sku']?.toString(),
      unit: map['unit']?.toString() ?? 'units',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
