import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'edit_product.dart';

class StockTracking extends StatefulWidget {
  const StockTracking({super.key});

  @override
  State<StockTracking> createState() => _StockTrackingState();
}

class _StockTrackingState extends State<StockTracking> {
  final DatabaseReference _database = FirebaseDatabase.instance
      .ref()
      .child('shop_management/shops/shop_1/Inventory');
  List<Map<String, dynamic>> _products = [];
  bool _showOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _products = data.entries.map((entry) {
            final product = Map<String, dynamic>.from(entry.value);
            product['id'] = entry.key;
            return product;
          }).toList();

          // Sort by stock level (ascending)
          _products
              .sort((a, b) => (a['stock'] as num).compareTo(b['stock'] as num));
        });
      }
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_showOnlyLowStock) {
      return _products
          .where((product) => (product['stock'] as num) < 5)
          .toList();
    }
    return _products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Tracking'),
        actions: [
          Switch(
            value: _showOnlyLowStock,
            onChanged: (value) {
              setState(() {
                _showOnlyLowStock = value;
              });
            },
            activeColor: Colors.red,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Low Stock Only',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alert: ${_products.where((p) => (p['stock'] as num) < 5).length} products',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                final int stock = product['stock'] as int;
                final bool isLowStock = stock < 5;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      product['name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Category: ${product['category']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stock: $stock',
                              style: TextStyle(
                                color: isLowStock ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isLowStock)
                              const Text(
                                'Low Stock!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProduct(
                                  product: product,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Restock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLowStock ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
