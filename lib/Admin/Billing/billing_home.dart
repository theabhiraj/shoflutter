import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Components/common_drawer.dart';
import 'apply_discount.dart';
import 'billing_history.dart';
import 'payment_options.dart';
import 'scan_product.dart';

// Add custom snackbar function at the top level
void showCustomSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onActionPressed,
  bool isError = false,
}) {
  // Cancel any existing snackbars
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  // Create a simple snackbar
  final snackBar = SnackBar(
    content: Text(
      message,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: isError ? Colors.red[400] : Colors.black87,
    behavior: SnackBarBehavior.floating,
    action: actionLabel != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: onActionPressed ?? () {},
          )
        : null,
    duration: const Duration(seconds: 3),
  );
  
  // Show the snackbar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class BillingHome extends StatefulWidget {
  final Map<String, dynamic>? inventoryData;

  const BillingHome({
    super.key,
    this.inventoryData,
  });

  @override
  State<BillingHome> createState() => _BillingHomeState();
}

class _BillingHomeState extends State<BillingHome> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  List<Map<String, dynamic>> cartItems = [];
  double subtotal = 0.0;
  double discount = 0.0;
  double finalTotal = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Clear any existing cart on start (this ensures a clean state)
    _resetCart();
    
    _initializeCart();
    _listenToDiscount();
  }

  void _listenToDiscount() {
    _database.child('Billing/current_discount').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          discount = (event.snapshot.value as num).toDouble();
          _calculateTotals();
        });
      } else {
        // Reset discount when there is no discount value
        setState(() {
          discount = 0;
          _calculateTotals();
        });
      }
    });
  }

  void _initializeCart() {
    _database.child('Billing/current_cart').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          cartItems = data.entries.map((entry) {
            final item = Map<String, dynamic>.from(entry.value);
            item['id'] = entry.key;
            return item;
          }).toList();
          _calculateTotals();
        });
      } else {
        setState(() {
          cartItems = [];
          _calculateTotals();
        });
      }
    });
  }

  void _calculateTotals() {
    subtotal =
        cartItems.fold(0, (sum, item) => sum + (item['total_price'] ?? 0));
    finalTotal = subtotal - discount;
  }

  void _searchProduct(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _database.child('Inventory').once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final allProducts =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        // Filter products locally
        final filteredProducts = allProducts.entries.map((entry) {
          final product = Map<String, dynamic>.from(entry.value);
          product['id'] = entry.key;
          return product;
        }).where((product) {
          final name = (product['name'] as String).toLowerCase();
          final queryLower = query.toLowerCase();
          // Also search by category and barcode if available
          final category =
              (product['category'] as String?)?.toLowerCase() ?? '';
          final barcode = (product['barcode'] as String?)?.toLowerCase() ?? '';
          return name.contains(queryLower) ||
              category.contains(queryLower) ||
              barcode.contains(queryLower);
        }).toList();

        setState(() {
          _searchResults = filteredProducts;
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }).catchError((error) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      showCustomSnackBar(
        context,
        message: 'Error searching products: $error',
        isError: true,
      );
    });
  }

  Future<void> _addToCart(String productKey, Map<String, dynamic> product,
      [int change = 1]) async {
    try {
      // First get the latest stock value
      final stockSnapshot =
          await _database.child('Inventory/$productKey/stock').once();

      final currentStock = (stockSnapshot.snapshot.value as int?) ?? 0;
      if (currentStock <= 0) {
        throw Exception('Product out of stock');
      }

      final cartRef = _database.child('Billing/current_cart/$productKey');
      final cartSnapshot = await cartRef.once();

      if (cartSnapshot.snapshot.value != null) {
        // Update existing cart item
        final currentData =
            Map<String, dynamic>.from(cartSnapshot.snapshot.value as Map);
        final currentQuantity = currentData['quantity'] as int? ?? 0;
        final newQuantity = currentQuantity + change;

        if (newQuantity <= 0) {
          // Remove item if quantity becomes 0 or negative
          await cartRef.remove();
          showCustomSnackBar(
            context,
            message: 'Removed ${product['name']} from cart',
          );
          return;
        }

        // Check if adding one more exceeds stock
        if (newQuantity > currentStock) {
          throw Exception('Not enough stock available');
        }

        await cartRef.update({
          'quantity': newQuantity,
          'total_price': newQuantity * (product['price'] ?? 0),
        });
      } else if (change > 0) {
        // Add new cart item only if change is positive
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'quantity': 1,
          'total_price': product['price'],
        });
      }

      showCustomSnackBar(
        context,
        message: change > 0
            ? 'Added ${product['name']} to cart'
            : 'Updated ${product['name']} quantity',
        actionLabel: 'CANCEL',
        onActionPressed: () async {
          try {
            // Remove the item from cart
            await _database.child('Billing/current_cart/$productKey').remove();
            // Show confirmation of removal
            if (mounted) {
              showCustomSnackBar(
                context,
                message: 'Removed ${product['name']} from cart',
              );
            }
          } catch (e) {
            print('Error removing item: $e');
          }
        },
      );
    } catch (e) {
      showCustomSnackBar(
        context,
        message: e.toString(),
        isError: true,
      );
    }
  }

  // Add method to reset cart
  Future<void> _resetCart() async {
    try {
      // Check if we're returning from a completed payment
      final completedPaymentSnapshot = await _database.child('Billing/completed_payment').once();
      if (completedPaymentSnapshot.snapshot.exists && completedPaymentSnapshot.snapshot.value == true) {
        // If we just completed a payment, ensure cart is cleared
        await _database.child('Billing/current_cart').remove();
        await _database.child('Billing/current_discount').remove();
        // Reset the flag
        await _database.child('Billing/completed_payment').remove();
      }
    } catch (e) {
      print('Error resetting cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billing',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: cartItems.isEmpty 
                ? null 
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text('Are you sure you want to clear all items?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _database.child('Billing/current_cart').remove();
                      await _database.child('Billing/current_discount').remove();
                      showCustomSnackBar(
                        context,
                        message: 'Cart has been cleared',
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillingHistory()),
              );
            },
          ),
        ],
      ),
      drawer: const CommonDrawer(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Products',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey),
                                    onPressed: () {
                                      searchController.clear();
                                      _searchProduct('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: _searchProduct,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ScanProduct()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          title: Text(
                            product['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Price: ₹${product['price']} | Stock: ${product['stock']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  color: Theme.of(context).primaryColor,
                                  onPressed: () {
                                    _addToCart(product['id'], product, -1);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  color: Theme.of(context).primaryColor,
                                  onPressed: () {
                                    _addToCart(product['id'], product, 1);
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
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items to get started',
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: Key(item['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await _database
                              .child('Billing/current_cart/${item['id']}')
                              .remove();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: ₹${item['price']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        color: Theme.of(context).primaryColor,
                                        onPressed: () {
                                          _addToCart(item['id'], item, -1);
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '${item['quantity'] ?? 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        color: Theme.of(context).primaryColor,
                                        onPressed: () {
                                          _addToCart(item['id'], item, 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '₹${item['total_price']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${discount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${finalTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplyDiscount(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.discount_outlined),
                        label: const Text('Apply Discount'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PaymentOptions(),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.payment),
                        label: const Text('Proceed to Pay'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
