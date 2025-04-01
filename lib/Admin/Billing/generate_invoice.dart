import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class GenerateInvoice extends StatefulWidget {
  final String orderId;

  const GenerateInvoice({
    super.key,
    required this.orderId,
  });

  @override
  State<GenerateInvoice> createState() => _GenerateInvoiceState();
}

class _GenerateInvoiceState extends State<GenerateInvoice> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shops/shop_1');
  bool _isLoading = true;
  Map<String, dynamic> _orderData = {};

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    final orderSnapshot =
        await _database.child('billing/orders/${widget.orderId}').once();
    if (orderSnapshot.snapshot.value != null) {
      setState(() {
        _orderData =
            Map<String, dynamic>.from(orderSnapshot.snapshot.value as Map);
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Add shop logo and details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24)),
                    pw.Text('Order #${widget.orderId}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Date: ${DateTime.fromMillisecondsSinceEpoch(_orderData['timestamp']).toString()}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Item', 'Quantity', 'Price', 'Total'],
                data: (_orderData['items'] as Map<String, dynamic>)
                    .entries
                    .map((item) {
                  final itemData = Map<String, dynamic>.from(item.value);
                  return [
                    itemData['name'],
                    itemData['quantity'].toString(),
                    '₹${itemData['price']}',
                    '₹${itemData['total_price']}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ₹${_orderData['subtotal']}'),
                    pw.Text('Discount: ₹${_orderData['discount']}'),
                    pw.Divider(),
                    pw.Text(
                      'Total: ₹${_orderData['final_total']}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Payment Method: Cash Payment'),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your business!'),
            ],
          );
        },
      ),
    );

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Invoice'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(
                  onLayout: (format) => pdf.save(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Invoice'),
              onTap: () async {
                Navigator.pop(context);
                final output = await getTemporaryDirectory();
                final file =
                    File('${output.path}/invoice_${widget.orderId}.pdf');
                await file.writeAsBytes(await pdf.save());
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Invoice #${widget.orderId}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Text(
                        'Date: ${DateTime.fromMillisecondsSinceEpoch(_orderData['timestamp']).toString()}'),
                    Text('Payment Method: ${_orderData['payment_method']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          (_orderData['items'] as Map<String, dynamic>).length,
                      itemBuilder: (context, index) {
                        final item =
                            (_orderData['items'] as Map<String, dynamic>)
                                .values
                                .elementAt(index);
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text(
                              'Qty: ${item['quantity']} x ₹${item['price']}'),
                          trailing: Text('₹${item['total_price']}'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('₹${_orderData['subtotal']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('₹${_orderData['discount']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_orderData['final_total']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
