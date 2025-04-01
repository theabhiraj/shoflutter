import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'edit_product.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final DatabaseReference _database = FirebaseDatabase.instance
      .ref()
      .child('shop_management/shops/shop_1/Inventory');
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _searchQuery = '';
  String _sortBy = 'name'; // Can be 'name', 'price', or 'stock'

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
          _filterAndSortProducts();
        });
      }
    });
  }

  void _filterAndSortProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = product['name'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        return name.contains(searchLower) || category.contains(searchLower);
      }).toList();

      _filteredProducts.sort((a, b) {
        switch (_sortBy) {
          case 'price':
            return (a['price'] as num).compareTo(b['price'] as num);
          case 'stock':
            return (a['stock'] as num).compareTo(b['stock'] as num);
          default:
            return a['name'].toString().compareTo(b['name'].toString());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or category',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterAndSortProducts();
                    });
                  },
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (String value) {
                  setState(() {
                    _sortBy = value;
                    _filterAndSortProducts();
                  });
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Text('Sort by Name'),
                  ),
                  const PopupMenuItem(
                    value: 'price',
                    child: Text('Sort by Price'),
                  ),
                  const PopupMenuItem(
                    value: 'stock',
                    child: Text('Sort by Stock'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(product['name'].toString()),
                  subtitle: Text('Category: ${product['category']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${product['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Stock: ${product['stock']}',
                            style: TextStyle(
                              color: (product['stock'] as num) < 5
                                  ? Colors.red
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
