import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class ReportSync {
  static final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');

  // Listen to inventory changes and update reports
  static StreamSubscription<DatabaseEvent> listenToInventoryChanges(
      Function(Map<String, dynamic>) onUpdate) {
    return _database.child('Inventory').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final inventoryData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        // Calculate inventory statistics
        final stats = _calculateInventoryStats(inventoryData);

        // Callback with the updated data
        onUpdate(stats);
      } else {
        // If no data, return empty stats
        onUpdate({
          'total_products': 0,
          'low_stock_items': 0,
          'total_inventory_value': 0,
        });
      }
    });
  }

  // Listen to sales changes and update reports
  static StreamSubscription<DatabaseEvent> listenToSalesChanges(
      Function(Map<String, dynamic>) onUpdate) {
    return _database.child('Billing/orders').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final salesData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        // Calculate sales statistics
        final stats = _calculateSalesStats(salesData);

        // Callback with the updated data
        onUpdate(stats);
      } else {
        // If no data, return empty stats
        onUpdate({
          'total_revenue': 0,
          'total_orders': 0,
          'product_sales': {},
          'average_order_value': 0,
        });
      }
    });
  }

  // Calculate inventory statistics
  static Map<String, dynamic> _calculateInventoryStats(
      Map<String, dynamic> inventoryData) {
    int totalProducts = 0;
    int lowStockItems = 0;
    double totalValue = 0;

    inventoryData.forEach((key, value) {
      if (value is Map) {
        final product = Map<String, dynamic>.from(value);
        totalProducts++;
        final stockLevel = (product['stock'] as num?) ?? 0;
        if (stockLevel < 5) {
          lowStockItems++;
        }
        final price = (product['price'] as num?) ?? 0;
        final stock = (product['stock'] as num?) ?? 0;
        totalValue += price * stock;
      }
    });

    return {
      'total_products': totalProducts,
      'low_stock_items': lowStockItems,
      'total_inventory_value': totalValue,
    };
  }

  // Calculate sales statistics
  static Map<String, dynamic> _calculateSalesStats(
      Map<String, dynamic> salesData) {
    double totalRevenue = 0;
    int totalOrders = 0;
    Map<String, int> productSales = {};

    salesData.forEach((key, value) {
      if (value is Map) {
        final order = Map<String, dynamic>.from(value);
        totalRevenue += (order['final_total'] as num?) ?? 0;
        totalOrders++;

        // Track individual product sales
        if (order['items'] is List) {
          for (var item in order['items'] as List) {
            if (item is Map) {
              final productId = item['id'] as String;
              final quantity = (item['quantity'] as num?) ?? 0;
              productSales[productId] =
                  (productSales[productId] ?? 0) + quantity.toInt();
            }
          }
        }
      }
    });

    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'product_sales': productSales,
      'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }
}
