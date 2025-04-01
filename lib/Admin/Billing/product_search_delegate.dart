import 'package:flutter/material.dart';

class ProductSearchDelegate extends SearchDelegate<void> {
  final Map<String, dynamic> products;
  final Function(String, Map<String, dynamic>) onProductSelected;

  ProductSearchDelegate({
    required this.products,
    required this.onProductSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredProducts = products.entries.where((entry) {
      final product = Map<String, dynamic>.from(entry.value);
      final productName = (product['name'] as String).toLowerCase();
      return productName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final entry = filteredProducts[index];
        final product = Map<String, dynamic>.from(entry.value);

        return ListTile(
          title: Text(product['name'] ?? ''),
          subtitle:
              Text('Price: ₹${product['price']} | Stock: ${product['stock']}'),
          onTap: () {
            onProductSelected(entry.key, product);
            close(context, null);
          },
        );
      },
    );
  }
}
