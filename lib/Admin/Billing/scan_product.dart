import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanProduct extends StatefulWidget {
  const ScanProduct({super.key});

  @override
  State<ScanProduct> createState() => _ScanProductState();
}

class _ScanProductState extends State<ScanProduct> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid barcode detected')),
          );
        }
        continue;
      }

      setState(() => _isScanning = false);

      try {
        // Search for product in inventory
        final productSnapshot = await _database
            .child('Inventory')
            .orderByChild('barcode')
            .equalTo(barcode.rawValue)
            .once();

        if (productSnapshot.snapshot.value != null) {
          final productData = Map<String, dynamic>.from(
              (productSnapshot.snapshot.value as Map).values.first as Map);
          final productKey = (productSnapshot.snapshot.value as Map).keys.first;

          // Check stock before adding
          final stock = productData['stock'] as int? ?? 0;
          if (stock <= 0) {
            throw Exception('Product out of stock');
          }

          // Add to cart
          await _addToCart(productKey, productData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${productData['name']} to cart')),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Product not found');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
          setState(() => _isScanning = true);
        }
      }
    }
  }

  Future<void> _addToCart(
      String productKey, Map<String, dynamic> productData) async {
    final cartRef = _database.child('Billing/current_cart/$productKey');
    final cartSnapshot = await cartRef.once();

    if (cartSnapshot.snapshot.value != null) {
      // Update existing cart item
      final currentData =
          Map<String, dynamic>.from(cartSnapshot.snapshot.value as Map);
      final newQuantity = (currentData['quantity'] ?? 0) + 1;
      await cartRef.update({
        'quantity': newQuantity,
        'total_price': newQuantity * (productData['price'] ?? 0),
      });
    } else {
      // Add new cart item
      await cartRef.set({
        'name': productData['name'],
        'price': productData['price'],
        'quantity': 1,
        'total_price': productData['price'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Align barcode within the frame',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
