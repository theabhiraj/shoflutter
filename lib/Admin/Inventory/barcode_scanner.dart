import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({super.key});

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shops/shop_1/Inventory');
  bool _isScanning = true;
  String? _lastScannedCode;
  final MobileScannerController controller = MobileScannerController();

  Future<Map<String, dynamic>?> _findProductByBarcode(String barcode) async {
    final event =
        await _database.orderByChild('barcode').equalTo(barcode).once();
    if (event.snapshot.value != null) {
      final Map<dynamic, dynamic> data = event.snapshot.value as Map;
      final product = Map<String, dynamic>.from(data.values.first as Map);
      product['id'] = data.keys.first;
      return product;
    }
    return null;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code != _lastScannedCode) {
        setState(() {
          _isScanning = false;
          _lastScannedCode = code;
        });

        final product = await _findProductByBarcode(code);
        if (mounted) {
          if (product != null) {
            _showProductFoundDialog(product);
          } else {
            _showBarcodeDialog(code);
          }
        }
        break;
      }
    }
  }

  void _showProductFoundDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Product Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${product['name']}'),
              Text('Price: \$${product['price']}'),
              Text('Stock: ${product['stock']}'),
              Text('Category: ${product['category']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(product['barcode']);
              },
              child: const Text('Use This Product'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                  _lastScannedCode = null;
                });
              },
              child: const Text('Scan Again'),
            ),
          ],
        );
      },
    );
  }

  void _showBarcodeDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Barcode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This barcode is not in the database:'),
              const SizedBox(height: 8),
              Text(
                barcode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(barcode);
              },
              child: const Text('Use This Barcode'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                  _lastScannedCode = null;
                });
              },
              child: const Text('Scan Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black87,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Align the barcode within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
