import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  Map<String, TextEditingController> quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadCartItems() {
    _database.child('Billing/current_cart').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          cartItems = data.entries.map((entry) {
            final item = Map<String, dynamic>.from(entry.value);
            item['id'] = entry.key;

            // Create or update controller for this item
            if (!quantityControllers.containsKey(entry.key)) {
              quantityControllers[entry.key] = TextEditingController(
                text: (item['quantity'] ?? 1).toString(),
              );
            } else {
              quantityControllers[entry.key]!.text =
                  (item['quantity'] ?? 1).toString();
            }

            return item;
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          cartItems = [];
          isLoading = false;
          // Clear unused controllers
          for (var controller in quantityControllers.values) {
            controller.dispose();
          }
          quantityControllers.clear();
        });
      }
    });
  }

  Future<void> _updateQuantity(
      String productId, int newQuantity, double price) async {
    try {
      // Validate quantity
      if (newQuantity <= 0) {
        // Show confirmation dialog for removal
        final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content:
                const Text('Do you want to remove this item from the cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );

        if (shouldRemove == true) {
          await _database.child('Billing/current_cart/$productId').remove();
        } else {
          // Reset quantity to 1 if user cancels
          quantityControllers[productId]?.text = '1';
          await _database.child('Billing/current_cart/$productId').update({
            'quantity': 1,
            'total_price': price,
          });
        }
      } else {
        // Check stock availability
        final stockSnapshot =
            await _database.child('Inventory/$productId/stock').once();
        final currentStock = (stockSnapshot.snapshot.value as int?) ?? 0;

        if (newQuantity > currentStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Only $currentStock items available in stock')),
            );
          }
          // Reset to previous valid quantity
          final currentItem =
              cartItems.firstWhere((item) => item['id'] == productId);
          quantityControllers[productId]?.text =
              (currentItem['quantity'] ?? 1).toString();
          return;
        }

        await _database.child('Billing/current_cart/$productId').update({
          'quantity': newQuantity,
          'total_price': newQuantity * price,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content:
                        const Text('Are you sure you want to clear the cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _database.child('Billing/current_cart').remove();
                }
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final controller = quantityControllers[item['id']];

                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _database
                        .child('Billing/current_cart/${item['id']}')
                        .remove();
                  },
                  child: ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text('Price: ₹${item['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            final currentQty =
                                int.tryParse(controller?.text ?? '1') ?? 1;
                            _updateQuantity(
                              item['id'],
                              currentQty - 1,
                              item['price'] ?? 0,
                            );
                          },
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: controller,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (value) {
                              final newQty = int.tryParse(value) ?? 1;
                              _updateQuantity(
                                item['id'],
                                newQty,
                                item['price'] ?? 0,
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final currentQty =
                                int.tryParse(controller?.text ?? '1') ?? 1;
                            _updateQuantity(
                              item['id'],
                              currentQty + 1,
                              item['price'] ?? 0,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
