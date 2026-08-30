class StockLogModel {
  final String id;
  final String productId;
  final String productName;
  final int change; // e.g. +10, -3
  final int previousStock;
  final int newStock;
  final String type; // 'restock', 'sale', 'adjustment', 'initial', 'waste'
  final String reason; // e.g. 'Order REC-12345678', 'Weekly Restock', 'Spoilage'
  final String performedBy; // cashier/admin name or code
  final DateTime createdAt;

  StockLogModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.change,
    required this.previousStock,
    required this.newStock,
    required this.type,
    required this.reason,
    required this.performedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAddition => change > 0;
  bool get isDeduction => change < 0;

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'restock':
        return 'Restock';
      case 'sale':
        return 'POS Sale';
      case 'adjustment':
        return 'Adjustment';
      case 'waste':
      case 'spoilage':
        return 'Waste / Spoilage';
      case 'initial':
        return 'Initial Stock';
      default:
        return type;
    }
  }
  String get action => type;
  String get actionLabel => typeLabel;
  String get productSku => productId;
  String get referenceNo => id;
  String get notes => reason;
  String get staffName => performedBy;
  int get quantityChanged => change;


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'change': change,
      'previousStock': previousStock,
      'newStock': newStock,
      'type': type,
      'reason': reason,
      'performedBy': performedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockLogModel.fromMap(Map<String, dynamic> map) {
    return StockLogModel(
      id: map['id']?.toString() ?? (map['_id']?.toString() ?? ''),
      productId: map['productId']?.toString() ?? '',
      productName: map['productName'] ?? '',
      change: (map['change'] is num) ? (map['change'] as num).toInt() : 0,
      previousStock: (map['previousStock'] is num) ? (map['previousStock'] as num).toInt() : 0,
      newStock: (map['newStock'] is num) ? (map['newStock'] as num).toInt() : 0,
      type: map['type'] ?? 'adjustment',
      reason: map['reason'] ?? '',
      performedBy: map['performedBy'] ?? 'Admin',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
