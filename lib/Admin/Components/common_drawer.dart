import 'package:flutter/material.dart';

import '../Billing/billing_home.dart';
import '../Employees/add_employee.dart';
import '../Employees/employees_home.dart';
import '../Employees/salary_management.dart';
import '../Expenses/expense_categories.dart';
import '../Expenses/expenses_home.dart';
import '../Expenses/expenses_list.dart';
import '../Expenses/expenses_summary.dart';
import '../Inventory/inventory_home.dart';
import '../Reports/reports_home.dart';
import '../admin_home.dart';

class CommonDrawer extends StatefulWidget {
  const CommonDrawer({super.key});

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer> {
  String? _expandedItem;

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    List<Widget>? subItems,
    String? itemKey,
  }) {
    final isExpanded = _expandedItem == itemKey;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                isExpanded ? (iconColor ?? Colors.blue).withOpacity(0.1) : null,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? Colors.blue, size: 22),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            trailing: subItems != null
                ? AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.chevron_right,
                      color: isExpanded ? iconColor : Colors.black54,
                    ),
                  )
                : null,
            onTap: subItems != null
                ? () {
                    setState(() {
                      _expandedItem = isExpanded ? null : itemKey;
                    });
                  }
                : onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (subItems != null)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(children: subItems),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
      ],
    );
  }

  Widget _buildSubItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 48, right: 8, bottom: 4),
      child: ListTile(
        leading: Icon(icon, size: 20, color: iconColor ?? Colors.black54),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: Colors.grey[50],
        hoverColor: Colors.grey[100],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/myLogo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'xShop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Management System',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminHome()),
                    );
                  },
                ),
                _buildDrawerItem(
                  title: 'Inventory',
                  icon: Icons.inventory_2_rounded,
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryHome(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  title: 'Billing',
                  icon: Icons.point_of_sale_rounded,
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BillingHome(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  title: 'Employees',
                  icon: Icons.people_rounded,
                  iconColor: Colors.indigo,
                  itemKey: 'employees',
                  onTap: () {},
                  subItems: [
                    _buildSubItem(
                      title: 'Overview',
                      icon: Icons.home_rounded,
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeesHome(),
                          ),
                        );
                      },
                    ),
                    _buildSubItem(
                      title: 'Add Employee',
                      icon: Icons.person_add_rounded,
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEmployee(),
                          ),
                        );
                      },
                    ),
                    _buildSubItem(
                      title: 'Salary Management',
                      icon: Icons.payments_rounded,
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalaryManagement(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _buildDrawerItem(
                  title: 'Expenses',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: Colors.purple,
                  itemKey: 'expenses',
                  onTap: () {},
                  subItems: [
                    _buildSubItem(
                      title: 'Overview',
                      icon: Icons.home_rounded,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpensesHome(),
                          ),
                        );
                      },
                    ),
                    _buildSubItem(
                      title: 'All Expenses',
                      icon: Icons.list_alt_rounded,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpensesList(),
                          ),
                        );
                      },
                    ),
                    _buildSubItem(
                      title: 'Categories',
                      icon: Icons.category_rounded,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseCategories(),
                          ),
                        );
                      },
                    ),
                    _buildSubItem(
                      title: 'Summary',
                      icon: Icons.analytics_rounded,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpensesSummary(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _buildDrawerItem(
                  title: 'Reports',
                  icon: Icons.assessment_rounded,
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsHome(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  iconColor: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Settings
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  title: 'Logout',
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  onTap: () {
                    // TODO: Implement logout
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
