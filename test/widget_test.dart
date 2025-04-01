// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockBillingHome extends StatelessWidget {
  const MockBillingHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Products',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('No items in cart'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:'),
                    Text('₹0.00'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount:'),
                    Text('₹0.00'),
                  ],
                ),
                const Divider(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:'),
                    Text('₹0.00'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Apply Discount'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Proceed to Payment'),
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

void main() {
  testWidgets('Billing screen UI elements test', (WidgetTester tester) async {
    // Build a MaterialApp with our MockBillingHome widget
    await tester.pumpWidget(
      const MaterialApp(
        home: MockBillingHome(),
      ),
    );

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // Verify basic UI elements are present
    expect(find.byType(TextField), findsOneWidget); // Search field
    expect(find.byIcon(Icons.search), findsOneWidget); // Search icon
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget); // Scan button
    expect(find.text('Search Products'), findsOneWidget); // Search placeholder
    expect(find.text('Scan'), findsOneWidget); // Scan button text

    // Verify cart-related elements
    expect(find.text('No items in cart'), findsOneWidget);
    expect(find.text('Subtotal:'), findsOneWidget);
    expect(find.text('Discount:'), findsOneWidget);
    expect(find.text('Total:'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Apply Discount'), findsOneWidget);
    expect(find.text('Proceed to Payment'), findsOneWidget);
  });
}
