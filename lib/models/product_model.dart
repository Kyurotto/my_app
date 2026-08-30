class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // 'milktea' or 'snack'
  final String? imagePath;
  final int stock;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
    this.stock = 25,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isNew =>
      createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24)));

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock < 10;
  bool get isInStock => stock >= 10;

  String get categoryLabel =>
      category.toLowerCase() == 'milktea' ? 'Milk Tea' : 'Snack';

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imagePath,
    int? stock,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imagePath,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? (map['_id']?.toString() ?? ''),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      category: map['category'] ?? 'milktea',
      imagePath: map['imagePath'],
      stock: (map['stock'] is num) ? (map['stock'] as num).toInt() : 20,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
