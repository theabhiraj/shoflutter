import 'package:firebase_database/firebase_database.dart';

class DataValidator {
  static final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');

  // Validate stock availability
  static Future<bool> validateStock(
      String productId, int requestedQuantity) async {
    try {
      final snapshot =
          await _database.child('Inventory/$productId/stock').get();
      if (!snapshot.exists) return false;
      final currentStock = (snapshot.value as num).toInt();
      return currentStock >= requestedQuantity;
    } catch (e) {
      print('Error validating stock: $e');
      return false;
    }
  }

  // Validate product data
  static Future<bool> validateProduct(Map<String, dynamic> product) async {
    return product.containsKey('name') &&
        product.containsKey('price') &&
        product.containsKey('stock') &&
        (product['price'] as num) > 0 &&
        (product['stock'] as num) >= 0;
  }

  // Validate transaction data
  static Future<bool> validateTransaction(
      Map<String, dynamic> transaction) async {
    try {
      // Basic validation
      if (!transaction.containsKey('items') || 
          !transaction.containsKey('final_total') ||
          transaction['items'] == null ||
          (transaction['items'] as List).isEmpty ||
          (transaction['final_total'] as num) <= 0) {
        print('Transaction validation failed: missing required fields');
        return false;
      }
      
      // Verify the items have the necessary fields
      final items = transaction['items'] as List;
      for (var item in items) {
        if (item is! Map<String, dynamic>) {
          print('Transaction validation failed: item is not a map');
          return false;
        }
        
        if (!item.containsKey('id') || !item.containsKey('quantity')) {
          print('Transaction validation failed: item missing id or quantity');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Error validating transaction: $e');
      return false;
    }
  }

  // Validate report data
  static Future<bool> validateReportData(
      Map<String, dynamic> reportData) async {
    return reportData.containsKey('timestamp') &&
        reportData.containsKey('data') &&
        (reportData['data'] as Map).isNotEmpty;
  }

  // Check data consistency between modules
  static Future<bool> checkDataConsistency() async {
    try {
      final inventorySnapshot = await _database.child('Inventory').get();
      final reportsSnapshot = await _database.child('reports').get();
      final billingSnapshot = await _database.child('Billing').get();

      if (!inventorySnapshot.exists ||
          !reportsSnapshot.exists ||
          !billingSnapshot.exists) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking data consistency: $e');
      return false;
    }
  }
}
