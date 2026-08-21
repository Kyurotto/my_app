import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static Db? db;
  static DbCollection? orderCollection;
  static DbCollection? userCollection;
  static DbCollection? productCollection;

  static bool isConnected = false;

  static Future<bool> connect({String? connectionString}) async {
    const String defaultMongoUrl = "mongodb://127.0.0.1:27017/CoffeeShopDB";
    final url = connectionString ?? defaultMongoUrl;

    try {
      final database = await Db.create(url);
      await database.open();
      
      db = database;
      orderCollection = database.collection('orders');
      userCollection = database.collection('users');
      productCollection = database.collection('products');
      isConnected = true;

      debugPrint("✅ Connected to MongoDB successfully!");
      return true;
    } catch (e) {
      isConnected = false;
      debugPrint("⚠️ MongoDB offline or unreachable: $e. Running with embedded reactive store.");
      return false;
    }
  }

  static void logout() {
    debugPrint("✅ User session logged out.");
  }
}
