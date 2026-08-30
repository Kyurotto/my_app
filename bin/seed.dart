import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  const String mongoUri = 'mongodb://127.0.0.1:27017/CoffeeShopDB';
  print('Connecting to MongoDB at: $mongoUri ...');

  final db = await Db.create(mongoUri);
  await db.open();
  print('Connected to MongoDB database: CoffeeShopDB');

  final usersCol = db.collection('users');
  final productsCol = db.collection('products');
  final ordersCol = db.collection('orders');

  // Seed Users
  final userCount = await usersCol.count();
  if (userCount == 0) {
    print('Seeding default users...');
    await usersCol.insertMany([
      {
        'id': 'usr_admin_1',
        'name': 'Admin User',
        'email': 'admin@example.com',
        'username': 'admin',
        'role': 'admin',
        'employeeCode': 'EMP001',
        'password': 'password',
      },
      {
        'id': 'usr_emp_2',
        'name': 'Employee User',
        'email': 'employee@example.com',
        'username': 'employee',
        'role': 'employee',
        'employeeCode': 'EMP002',
        'password': 'password',
      },
    ]);
  }

  // Seed Products
  final productCount = await productsCol.count();
  if (productCount == 0) {
    print('Seeding default products...');
    final now = DateTime.now().toIso8601String();
    await productsCol.insertMany([
      {
        'id': 'prod_1',
        'name': 'Classic Milk Tea',
        'description': 'Traditional black tea with creamy milk and brown sugar pearls.',
        'price': 4.50,
        'category': 'milktea',
        'stock': 35,
        'createdAt': now,
      },
      {
        'id': 'prod_2',
        'name': 'Taro Milk Tea',
        'description': 'Fragrant taro root blended with milk and chewy pearls.',
        'price': 5.00,
        'category': 'milktea',
        'stock': 24,
        'createdAt': now,
      },
      {
        'id': 'prod_3',
        'name': 'Matcha Latte',
        'description': 'Premium Japanese matcha green tea with steamed milk.',
        'price': 5.50,
        'category': 'milktea',
        'stock': 18,
        'createdAt': now,
      },
      {
        'id': 'prod_4',
        'name': 'Wintermelon Tea',
        'description': 'Refreshing wintermelon flavored tea with a touch of cream.',
        'price': 4.50,
        'category': 'milktea',
        'stock': 20,
        'createdAt': now,
      },
      {
        'id': 'prod_5',
        'name': 'Cheese Foam Milk Tea',
        'description': 'Our signature milk tea topped with a salty-sweet cheese foam.',
        'price': 5.75,
        'category': 'milktea',
        'stock': 8,
        'createdAt': now,
      },
      {
        'id': 'prod_6',
        'name': 'French Fries',
        'description': 'Crispy golden fries seasoned with sea salt.',
        'price': 3.50,
        'category': 'snack',
        'stock': 40,
        'createdAt': now,
      },
      {
        'id': 'prod_7',
        'name': 'Chicken Popcorn',
        'description': 'Bite-sized crispy tender chicken pieces.',
        'price': 6.00,
        'category': 'snack',
        'stock': 25,
        'createdAt': now,
      },
      {
        'id': 'prod_8',
        'name': 'Mozzarella Sticks',
        'description': 'Deep-fried battered mozzarella cheese.',
        'price': 5.50,
        'category': 'snack',
        'stock': 15,
        'createdAt': now,
      },
    ]);
  }

  // Seed Orders
  final orderCount = await ordersCol.count();
  if (orderCount == 0) {
    print('Seeding default orders...');
    final now = DateTime.now().toIso8601String();
    await ordersCol.insertMany([
      {
        'id': 'ord_1',
        'receiptNo': 'REC-9B4X7K21',
        'userId': 'usr_emp_2',
        'cashierName': 'Employee User',
        'subtotal': 10.00,
        'tax': 1.00,
        'total': 11.00,
        'paymentMethod': 'gcash',
        'status': 'completed',
        'createdAt': now,
        'items': [
          {'productId': 'prod_1', 'productName': 'Classic Milk Tea', 'unitPrice': 4.50, 'quantity': 1, 'subtotal': 4.50},
          {'productId': 'prod_8', 'productName': 'Mozzarella Sticks', 'unitPrice': 5.50, 'quantity': 1, 'subtotal': 5.50},
        ],
      },
      {
        'id': 'ord_2',
        'receiptNo': 'REC-2M8F3P99',
        'userId': 'usr_emp_2',
        'cashierName': 'Employee User',
        'subtotal': 17.00,
        'tax': 1.70,
        'total': 18.70,
        'paymentMethod': 'physical',
        'status': 'completed',
        'createdAt': now,
        'items': [
          {'productId': 'prod_3', 'productName': 'Matcha Latte', 'unitPrice': 5.50, 'quantity': 2, 'subtotal': 11.00},
          {'productId': 'prod_7', 'productName': 'Chicken Popcorn', 'unitPrice': 6.00, 'quantity': 1, 'subtotal': 6.00},
        ],
      },
    ]);
  }

  final finalUsers = await usersCol.count();
  final finalProducts = await productsCol.count();
  final finalOrders = await ordersCol.count();

  print('\n=== MONGODB INITIALIZATION COMPLETE ===');
  print('Database: CoffeeShopDB');
  print('Collections:');
  print(' - users: $finalUsers documents');
  print(' - products: $finalProducts documents');
  print(' - orders: $finalOrders documents');
  print('========================================\n');

  await db.close();
}
