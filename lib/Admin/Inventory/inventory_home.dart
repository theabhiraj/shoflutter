import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Components/common_appbar.dart';
import '../Components/common_drawer.dart';
import 'add_product.dart';
import 'edit_product.dart';

class InventoryHome extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const InventoryHome({
    super.key,
    this.initialData,
  });

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  final TextEditingController searchController = TextEditingController();

  int totalProducts = 0;
  List<Map<String, dynamic>> lowStockProducts = [];
  List<Map<String, dynamic>> products = [];
  String sortBy = 'name'; // Default sort
  bool groupByCategory = false;

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  void _fetchInventoryData() {
    _database.child('Inventory').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          products = data.entries.map((entry) {
            final product = Map<String, dynamic>.from(entry.value);
            product['id'] = entry.key;
            return product;
          }).toList();

          // Apply sorting
          _sortProducts();

          totalProducts = products.length;
          lowStockProducts =
              products.where((product) => (product['stock'] ?? 0) < 5).toList();
        });
      } else {
        setState(() {
          products = [];
          totalProducts = 0;
          lowStockProducts = [];
        });
      }
    });
  }

  void _sortProducts() {
    switch (sortBy) {
      case 'name':
        products.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'quantity':
        products.sort((a, b) => (b['stock'] ?? 0).compareTo(a['stock'] ?? 0));
        break;
      case 'price':
        products.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'category':
        products.sort(
            (a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
        break;
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _database.child('Inventory/$productId').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  Widget _buildProductList() {
    if (products.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    if (groupByCategory) {
      // Group products by category
      final groupedProducts = <String, List<Map<String, dynamic>>>{};
      for (var product in products) {
        final category = product['category'] ?? 'Uncategorized';
        groupedProducts.putIfAbsent(category, () => []).add(product);
      }

      return ListView.builder(
        itemCount: groupedProducts.length,
        itemBuilder: (context, index) {
          final category = groupedProducts.keys.elementAt(index);
          final categoryProducts = groupedProducts[category]!;

          return ExpansionTile(
            title: Text(category),
            children: categoryProducts
                .map((product) => _buildProductCard(product))
                .toList(),
          );
        },
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(product['name'] ?? 'Unnamed Product'),
        subtitle: Text(
          'Category: ${product['category'] ?? 'Uncategorized'}\n'
          'Stock: ${product['stock'] ?? 0}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${product['price']?.toString() ?? '0'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProduct(product: product),
                        ),
                      );
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _deleteProduct(product['id']);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Inventory Dashboard'),
      drawer: const CommonDrawer(),
      body: Column(
        children: [
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Categories Button (25% width)
                Expanded(
                  flex: 25,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/categories'),
                    icon: const Icon(Icons.category),
                    label: const Text('Categ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Add Product Button (75% width)
                Expanded(
                  flex: 75,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddProduct()),
                      );
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Statistics Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Total Products',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            totalProducts.toString(),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.warning,
                              size: 40, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            'Low Stock Alert',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            lowStockProducts.length.toString(),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search and Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Products',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Button
                PopupMenuButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort by',
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by Name'),
                    ),
                    const PopupMenuItem(
                      value: 'quantity',
                      child: Text('Sort by Quantity'),
                    ),
                    const PopupMenuItem(
                      value: 'price',
                      child: Text('Sort by Price'),
                    ),
                    const PopupMenuItem(
                      value: 'category',
                      child: Text('Sort by Category'),
                    ),
                  ],
                  onSelected: (value) {
                    setState(() {
                      sortBy = value;
                      _sortProducts();
                    });
                  },
                ),
                // Group by Category Toggle
                IconButton(
                  icon: Icon(
                    groupByCategory ? Icons.category : Icons.category_outlined,
                  ),
                  tooltip: 'Group by Category',
                  onPressed: () {
                    setState(() {
                      groupByCategory = !groupByCategory;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Product List
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }
}
