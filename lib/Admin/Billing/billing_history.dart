import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'generate_invoice.dart';

class BillingHistory extends StatefulWidget {
  const BillingHistory({super.key});

  @override
  State<BillingHistory> createState() => _BillingHistoryState();
}

class _BillingHistoryState extends State<BillingHistory> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shops/shop_1');
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _filterBy = 'all'; // all, today, week, month
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final ordersSnapshot = await _database.child('billing/orders').once();
    if (ordersSnapshot.snapshot.value != null) {
      final ordersData =
          Map<String, dynamic>.from(ordersSnapshot.snapshot.value as Map);
      setState(() {
        _orders = ordersData.entries.map((entry) {
          final order = Map<String, dynamic>.from(entry.value);
          order['id'] = entry.key;
          return order;
        }).toList()
          ..sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        _isLoading = false;
      });
    } else {
      setState(() {
        _orders = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _orders.where((order) {
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        final orderItems = (order['items'] as Map<String, dynamic>).values;
        final hasMatchingItem = orderItems.any((item) =>
            (item['name'] as String).toLowerCase().contains(searchTerm));
        if (!hasMatchingItem) return false;
      }

      // Apply date filter
      final orderDate = DateTime.fromMillisecondsSinceEpoch(order['timestamp']);
      switch (_filterBy) {
        case 'today':
          return orderDate.isAfter(startOfDay);
        case 'week':
          return orderDate.isAfter(startOfWeek);
        case 'month':
          return orderDate.isAfter(startOfMonth);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Orders',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: 'today',
                      label: Text('Today'),
                    ),
                    ButtonSegment(
                      value: 'week',
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: 'month',
                      label: Text('Month'),
                    ),
                  ],
                  selected: {_filterBy},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _filterBy = newSelection.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final orderDate = DateTime.fromMillisecondsSinceEpoch(
                          order['timestamp']);
                      final itemCount =
                          (order['items'] as Map<String, dynamic>).length;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            'Order #${order['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('MMM dd, yyyy hh:mm a')
                                  .format(orderDate)),
                              Text('$itemCount items • Cash Payment'),
                            ],
                          ),
                          trailing: Text(
                            '₹${order['final_total']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GenerateInvoice(
                                  orderId: order['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
