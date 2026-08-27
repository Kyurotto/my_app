class OrderItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName'] ?? '',
      unitPrice: (map['unitPrice'] is num)
          ? (map['unitPrice'] as num).toDouble()
          : 0.0,
      quantity: (map['quantity'] is num)
          ? (map['quantity'] as num).toInt()
          : 1,
      subtotal: (map['subtotal'] is num)
          ? (map['subtotal'] as num).toDouble()
          : 0.0,
    );
  }
}

class OrderModel {
  final String id;
  final String receiptNo;
  final String userId;
  final String cashierName;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod; // 'physical' / 'cash', 'universal', 'online'
  final String status; // 'completed'
  final List<OrderItemModel> items;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.receiptNo,
    required this.userId,
    required this.cashierName,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.status = 'completed',
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get paymentLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'physical':
      case 'cash':
        return 'Cash';
      case 'online':
        return 'Online Payment';
      case 'universal':
        return 'Universal QR Payment';
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'maribank':
        return 'MariBank';
      default:
        return paymentMethod;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptNo': receiptNo,
      'userId': userId,
      'cashierName': cashierName,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      receiptNo: map['receiptNo'] ?? 'REC-00000000',
      userId: map['userId']?.toString() ?? '',
      cashierName: map['cashierName'] ?? 'Cashier',
      subtotal: (map['subtotal'] is num)
          ? (map['subtotal'] as num).toDouble()
          : 0.0,
      tax: (map['tax'] is num) ? (map['tax'] as num).toDouble() : 0.0,
      total: (map['total'] is num) ? (map['total'] as num).toDouble() : 0.0,
      paymentMethod: map['paymentMethod'] ?? 'physical',
      status: map['status'] ?? 'completed',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) =>
                  OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
