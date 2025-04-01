import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Components/transaction_handler.dart' as tx;
import 'billing_home.dart';

// Add custom snackbar function
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

class PaymentOptions extends StatefulWidget {
  const PaymentOptions({super.key});

  @override
  State<PaymentOptions> createState() => _PaymentOptionsState();
}

class _PaymentOptionsState extends State<PaymentOptions>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  double _finalTotal = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showSuccess = false;
  List<Map<String, dynamic>> _cartItems = [];
  bool _isConfirmed = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadBillDetails();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBillDetails() async {
    try {
      // Load cart items first
      final cartSnapshot = await _database.child('Billing/current_cart').once();
      if (cartSnapshot.snapshot.value != null) {
        final cartData =
            Map<String, dynamic>.from(cartSnapshot.snapshot.value as Map);
        setState(() {
          _cartItems = cartData.entries.map((entry) {
            final item = Map<String, dynamic>.from(entry.value);
            item['id'] = entry.key;
            return item;
          }).toList();
        });
      }

      // Load bill details
      final billSnapshot = await _database.child('Billing/current_bill').once();
      if (billSnapshot.snapshot.value != null) {
        final billData =
            Map<String, dynamic>.from(billSnapshot.snapshot.value as Map);
        setState(() {
          _finalTotal = (billData['final_total'] ?? 0).toDouble();
        });
      } else {
        // If no bill details found, calculate from cart items
        final subtotal = _cartItems.fold<double>(
          0,
          (sum, item) => sum + (item['total_price'] as num).toDouble(),
        );
        setState(() {
          _finalTotal = subtotal;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Error loading bill details: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (!mounted) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Validate we have items
      if (_cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }
      
      // Create sale data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderId = 'ORD_$timestamp';
      
      // Prepare simple data without nested objects
      final cleanItems = _cartItems.map((item) => {
        'id': item['id'] ?? '',
        'name': item['name'] ?? 'Unknown',
        'price': (item['price'] ?? 0).toDouble(),
        'quantity': (item['quantity'] ?? 1),
        'total_price': (item['total_price'] ?? 0).toDouble(),
      }).toList();
      
      final saleData = {
        'payment_method': 'cash',
        'items': cleanItems,
        'final_total': _finalTotal,
        'timestamp': timestamp,
        'status': 'completed'
      };
      
      // Process the sale
      final success = await tx.TransactionHandler.processSale(saleData);
      
      if (!success) {
        throw Exception('Failed to process payment');
      }
      
      // Clear the cart
      await _database.child('Billing/current_cart').remove();
      await _database.child('Billing/current_discount').remove();
      await _database.child('Billing/completed_payment').set(true);
      
      if (!mounted) return;
      
      // Show success state
      setState(() {
        _isProcessing = false;
        _showSuccess = true;
      });
      
      // Wait and return to billing
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Navigate back and show invoice
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BillingHome()),
        (route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isProcessing = false);
      
      // Show error message
      showCustomSnackBar(
        context,
        message: 'Payment failed: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showSuccess) {
      return Scaffold(
        body: Container(
          color: Colors.green[600],
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${_finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isProcessing) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).primaryColor,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Processing Payment...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._cartItems.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item['name'] ?? 'Unknown Item'}',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Qty: ${item['quantity'] ?? 1}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${item['total_price'] ?? 0}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ))
                              ,
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${_finalTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cash Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount to collect: ₹${_finalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CheckboxListTile(
                  value: _isConfirmed,
                  onChanged: (value) {
                    setState(() {
                      _isConfirmed = value ?? false;
                    });
                  },
                  title: const Text(
                    'I confirm that the order details are correct',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  activeColor: Theme.of(context).primaryColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isConfirmed ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: _isConfirmed
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  foregroundColor:
                      _isConfirmed ? Colors.white : Colors.grey[600],
                  elevation: _isConfirmed ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Complete Cash Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
