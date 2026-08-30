import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  const String mongoUri = 'mongodb://127.0.0.1:27017/CoffeeShopDB';
  final db = await Db.create(mongoUri);
  await db.open();

  final usersCol = db.collection('users');
  final users = await usersCol.find().toList();
  print('Users currently in DB (${users.length}):');
  for (final u in users) {
    print('  - ${u['username']} (${u['email']}), role: ${u['role']}');
  }

  // If missing admin or employee, insert them
  final hasAdmin = users.any((u) => u['username'] == 'admin' || u['email'] == 'admin@example.com');
  final hasEmp = users.any((u) => u['username'] == 'employee' || u['email'] == 'employee@example.com');

  if (!hasAdmin) {
    await usersCol.insertOne({
      'id': 'usr_admin_1',
      'name': 'Admin User',
      'email': 'admin@example.com',
      'username': 'admin',
      'role': 'admin',
      'employeeCode': 'EMP001',
      'password': 'password',
    });
    print('Added admin user.');
  }

  if (!hasEmp) {
    await usersCol.insertOne({
      'id': 'usr_emp_2',
      'name': 'Employee User',
      'email': 'employee@example.com',
      'username': 'employee',
      'role': 'employee',
      'employeeCode': 'EMP002',
      'password': 'password',
    });
    print('Added employee user.');
  }

  final updatedUsers = await usersCol.find().toList();
  print('\nUpdated Users list:');
  for (final u in updatedUsers) {
    print('  - ${u['username']} (${u['email']}), role: ${u['role']}');
  }

  final products = await db.collection('products').find().toList();
  print('\nProducts in DB (${products.length}):');
  for (final p in products) {
    print('  - ${p['name']} (\$${p['price']}), category: ${p['category']}');
  }

  final orders = await db.collection('orders').find().toList();
  print('\nOrders in DB (${orders.length}):');
  for (final o in orders) {
    print('  - Receipt: ${o['receiptNo']}, Total: \$${o['total']}, Payment: ${o['paymentMethod']}');
  }

  await db.close();
}
