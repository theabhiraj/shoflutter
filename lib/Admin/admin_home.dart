import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shop_management/Admin/Billing/billing_home.dart';
import 'package:shop_management/Admin/Components/common_appbar.dart';
import 'package:shop_management/Admin/Components/common_drawer.dart';
import 'package:shop_management/Admin/Employees/employees_home.dart';
import 'package:shop_management/Admin/Expenses/expenses_home.dart';
import 'package:shop_management/Admin/Inventory/inventory_home.dart';
import 'package:shop_management/Admin/Reports/reports_home.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final Map<String, dynamic> _moduleData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModuleData();
  }

  Future<void> _loadModuleData() async {
    try {
      final ref = FirebaseDatabase.instance.ref('shop_management/shop_1');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        setState(() {
          final data = snapshot.value;
          if (data is Map) {
            _moduleData.clear();
            data.forEach((key, value) {
              if (key is String) {
                _moduleData[key] = value;
              }
            });
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading module data: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Dashboard'),
      drawer: const CommonDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadModuleData,
        child: GridView.count(
          padding: const EdgeInsets.all(16.0),
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildMenuCard(
              context,
              'Inventory',
              Icons.inventory,
              Colors.blue,
              () {
                // Safely handle inventory data
                dynamic inventoryData = _moduleData['inventory'];
                Map<String, dynamic>? safeInventoryData;
                
                // Check if data exists and convert it safely
                if (inventoryData != null) {
                  try {
                    if (inventoryData is Map) {
                      safeInventoryData = {};
                      inventoryData.forEach((key, value) {
                        if (key is String) {
                          safeInventoryData![key] = value;
                        }
                      });
                    }
                  } catch (e) {
                    debugPrint('Error converting inventory data: $e');
                    safeInventoryData = null;
                  }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryHome(
                      initialData: safeInventoryData,
                    ),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Billing',
              Icons.point_of_sale,
              Colors.green,
              () {
                // Safely handle inventory data for billing
                dynamic inventoryData = _moduleData['inventory'];
                Map<String, dynamic>? safeInventoryData;
                
                // Check if data exists and convert it safely
                if (inventoryData != null) {
                  try {
                    if (inventoryData is Map) {
                      safeInventoryData = {};
                      inventoryData.forEach((key, value) {
                        if (key is String) {
                          safeInventoryData![key] = value;
                        }
                      });
                    }
                  } catch (e) {
                    debugPrint('Error converting inventory data for billing: $e');
                    safeInventoryData = null;
                  }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BillingHome(
                      inventoryData: safeInventoryData,
                    ),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Reports',
              Icons.assessment,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsHome(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              'Employees',
              Icons.badge,
              Colors.teal,
              () {
                // Safely handle employees data
                dynamic employeesData = _moduleData['employees'];
                Map<String, dynamic>? safeEmployeesData;
                
                // Check if data exists and convert it safely
                if (employeesData != null) {
                  try {
                    // Handle different data types
                    if (employeesData is Map) {
                      safeEmployeesData = {};
                      employeesData.forEach((key, value) {
                        if (key is String) {
                          safeEmployeesData![key] = value;
                        }
                      });
                    }
                  } catch (e) {
                    debugPrint('Error converting employees data: $e');
                    safeEmployeesData = null;
                  }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeesHome(
                      initialData: safeEmployeesData,
                    ),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Expenses',
              Icons.account_balance_wallet,
              Colors.red,
              () {
                // Safely handle expenses data
                dynamic expensesData = _moduleData['expenses'];
                Map<String, dynamic>? safeExpensesData;
                
                // Check if data exists and convert it safely
                if (expensesData != null) {
                  try {
                    if (expensesData is Map) {
                      safeExpensesData = {};
                      expensesData.forEach((key, value) {
                        if (key is String) {
                          safeExpensesData![key] = value;
                        }
                      });
                    }
                  } catch (e) {
                    debugPrint('Error converting expenses data: $e');
                    safeExpensesData = null;
                  }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpensesHome(
                      initialData: safeExpensesData,
                    ),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Settings',
              Icons.settings,
              Colors.grey,
              () {
                // TODO: Navigate to Settings
              },
            ),
          ],
        ),
      ),
    );
  }
}
