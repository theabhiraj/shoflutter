import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Admin/Billing/billing_home.dart';
import 'Admin/Categories/category_page.dart';
import 'Admin/Inventory/add_product.dart';
import 'Admin/Inventory/barcode_scanner.dart';
import 'Admin/Inventory/inventory_home.dart';
import 'Admin/Inventory/stock_tracking.dart';
import 'Admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set error handler for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.exception}');
  };
  
  await Firebase.initializeApp();
  runApp(const ShopManagementApp());
}

class ShopManagementApp extends StatelessWidget {
  const ShopManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'xShop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AdminHome(),
      routes: {
        '/inventory': (context) => const InventoryHome(),
        '/inventory/add': (context) => const AddProduct(),
        '/inventory/scanner': (context) => const BarcodeScanner(),
        '/inventory/stock': (context) => const StockTracking(),
        '/categories': (context) => const CategoryPage(),
        '/billing': (context) => const BillingHome(),
      },
    );
  }
}
