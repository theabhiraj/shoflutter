import 'package:firebase_database/firebase_database.dart';

import 'data_validator.dart';

class TransactionHandler {
  static final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');

  // Update inventory stock with transaction lock
  static Future<bool> updateInventoryStock(
      String productId, int quantity) async {
    try {
      // First check if stock is available without locking
      final stockSnapshot = await _database.child('Inventory/$productId/stock').get();
      if (!stockSnapshot.exists) {
        print('Product $productId does not exist');
        return false;
      }
      
      final currentStock = (stockSnapshot.value as num).toInt();
      if (currentStock < quantity) {
        print('Not enough stock for product $productId: $currentStock < $quantity');
        return false;
      }

      // Now use transaction to safely update the stock
      final TransactionResult result = await _database
          .child('Inventory/$productId/stock')
          .runTransaction((Object? stock) {
        if (stock == null) return Transaction.abort();
        
        final int currentStock = (stock as num).toInt();
        if (currentStock < quantity) return Transaction.abort();
        
        return Transaction.success(currentStock - quantity);
      });
      
      if (result.committed) {
        return true;
      } else {
        print('Transaction failed to commit for product $productId');
        return false;
      }
    } catch (e) {
      print('Error updating inventory stock for $productId: $e');
      return false;
    }
  }

  // Process sale with backup
  static Future<bool> processSale(Map<String, dynamic> saleData) async {
    try {
      // First validate the sale data
      final isValid = await DataValidator.validateTransaction(saleData);
      if (!isValid) {
        print('Invalid transaction data');
        return false;
      }

      // Generate order ID
      final String orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      
      // Process inventory updates
      final List<dynamic> items = saleData['items'] as List<dynamic>;
      for (var item in items) {
        final Map<String, dynamic> itemData = item as Map<String, dynamic>;
        final String itemId = itemData['id'] as String;
        final int quantity = itemData['quantity'] as int;
        
        // Check inventory
        final snapshot = await _database.child('Inventory/$itemId/stock').get();
        if (!snapshot.exists) {
          print('Item $itemId not found in inventory');
          continue;
        }
        
        final int currentStock = (snapshot.value as int);
        if (currentStock < quantity) {
          print('Not enough stock for item $itemId: $currentStock < $quantity');
          return false;
        }
        
        // Update stock
        await _database.child('Inventory/$itemId/stock').set(currentStock - quantity);
      }
      
      // Record the order
      await _database.child('Billing/orders/$orderId').set(saleData);
      
      return true;
    } catch (e) {
      print('Error processing sale: $e');
      return false;
    }
  }

  // Revert a failed sale
  static Future<void> _revertSale(String orderId) async {
    try {
      await _database.child('Billing/orders/$orderId').remove();
    } catch (e) {
      print('Error reverting sale: $e');
    }
  }

  // Update reports data
  static Future<bool> updateReports(Map<String, dynamic> reportData) async {
    try {
      final isValid = await DataValidator.validateReportData(reportData);
      if (!isValid) return false;

      final String reportId = DateTime.now().toIso8601String();
      await _database.child('reports/$reportId').set(reportData);
      return true;
    } catch (e) {
      print('Error updating reports: $e');
      return false;
    }
  }
}
