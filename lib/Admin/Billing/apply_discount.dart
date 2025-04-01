import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ApplyDiscount extends StatefulWidget {
  const ApplyDiscount({super.key});

  @override
  State<ApplyDiscount> createState() => _ApplyDiscountState();
}

class _ApplyDiscountState extends State<ApplyDiscount> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  final TextEditingController _discountController = TextEditingController();
  String _discountType = 'percentage'; // or 'fixed'
  double _subtotal = 0;
  double _discount = 0;
  double _finalTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadCartTotal();
    _discountController.clear();
    _discount = 0;
    _calculateFinalTotal();
  }

  void _loadCartTotal() {
    _database.child('Billing/current_cart').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        double total = 0;
        data.forEach((key, value) {
          final item = Map<String, dynamic>.from(value);
          total += (item['total_price'] ?? 0).toDouble();
        });
        setState(() {
          _subtotal = total;
          _calculateFinalTotal();
        });
      }
    });
  }

  void _calculateFinalTotal() {
    if (_discountType == 'percentage') {
      final percentage = double.tryParse(_discountController.text) ?? 0;
      if (percentage > 100) {
        showCustomSnackBar(
          context,
          message: 'Discount percentage cannot exceed 100%',
          isError: true,
        );
        _discountController.text = '100';
        _discount = _subtotal;
      } else {
        _discount = (_subtotal * percentage) / 100;
      }
    } else {
      _discount = double.tryParse(_discountController.text) ?? 0;
      if (_discount > _subtotal) {
        showCustomSnackBar(
          context,
          message: 'Discount cannot exceed total amount',
          isError: true,
        );
        _discountController.text = _subtotal.toString();
        _discount = _subtotal;
      }
    }
    _finalTotal = _subtotal - _discount;
    setState(() {});
  }

  Future<void> _applyDiscount() async {
    if (_discount <= 0) {
      showCustomSnackBar(
        context,
        message: 'Please enter a valid discount',
        isError: true,
      );
      return;
    }

    try {
      // Update the discount in the current cart
      await _database.child('Billing/current_bill').update({
        'subtotal': _subtotal,
        'discount': _discount,
        'discount_type': _discountType,
        'final_total': _finalTotal,
      });

      // Also update the parent BillingHome widget's state through Firebase
      await _database.child('Billing').update({
        'current_discount': _discount,
      });

      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Discount applied successfully',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Error applying discount: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apply Discount',
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Subtotal: ₹${_subtotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Discount: ₹${_discount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Divider(height: 24),
                              Text(
                                'Final Total: ₹${_finalTotal.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'percentage',
                            label: Text('Percentage (%)'),
                            icon: Icon(Icons.percent),
                          ),
                          ButtonSegment(
                            value: 'fixed',
                            label: Text('Fixed Amount'),
                            icon: Icon(Icons.currency_rupee),
                          ),
                        ],
                        selected: {_discountType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _discountType = newSelection.first;
                            _discountController.clear();
                            _discount = 0;
                            _calculateFinalTotal();
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).primaryColor;
                              }
                              return Colors.white;
                            },
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Theme.of(context).primaryColor;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _discountType == 'percentage'
                              ? 'Discount %'
                              : 'Discount Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(
                            _discountType == 'percentage'
                                ? Icons.percent
                                : Icons.currency_rupee,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          _calculateFinalTotal();
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _applyDiscount,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Apply Discount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }
}

// Add the custom snackbar function
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
