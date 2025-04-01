import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Components/common_appbar.dart';
import '../Components/common_drawer.dart';
import '../Components/design_system.dart';
import 'add_employee.dart';
import 'attendance_tracking.dart';
import 'employee_list.dart';
import 'salary_management.dart';

class EmployeesHome extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const EmployeesHome({
    super.key,
    this.initialData,
  });

  @override
  State<EmployeesHome> createState() => _EmployeesHomeState();
}

class _EmployeesHomeState extends State<EmployeesHome> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1/employees');
  int _totalEmployees = 0;
  int _presentToday = 0;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadEmployeeStats();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final snapshot = await _database.get();
      if (!snapshot.exists) {
        setState(() => _employees = []);
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _employees = data.entries.map((entry) {
          final employee = Map<String, dynamic>.from(entry.value);
          employee['id'] = entry.key;
          return employee;
        }).toList();
        _sortEmployees();
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  void _sortEmployees() {
    switch (_sortBy) {
      case 'name':
        _employees.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'role':
        _employees.sort((a, b) => (a['role'] ?? '').compareTo(b['role'] ?? ''));
        break;
      case 'salary':
        _employees
            .sort((a, b) => (b['salary'] ?? 0).compareTo(a['salary'] ?? 0));
        break;
      case 'joining_date':
        _employees.sort((a, b) =>
            (b['joining_date'] ?? '').compareTo(a['joining_date'] ?? ''));
        break;
    }
  }

  Future<void> _loadEmployeeStats() async {
    try {
      final employeesSnapshot = await _database.get();
      if (!employeesSnapshot.exists) {
        setState(() {
          _totalEmployees = 0;
          _presentToday = 0;
          _isLoading = false;
        });
        return;
      }

      final employeesData =
          Map<String, dynamic>.from(employeesSnapshot.value as Map);
      final today = DateTime.now().toString().split(' ')[0];
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      int presentCount = 0;
      // ignore: unused_local_variable
      int pendingCount = 0;

      // Get salary records for current month
      final salarySnapshot = await _database.parent!
          .child('salary_records')
          .child(currentMonth)
          .get();

      Map<String, dynamic> salaryData = {};
      if (salarySnapshot.exists) {
        salaryData = Map<String, dynamic>.from(salarySnapshot.value as Map);
      }

      employeesData.forEach((employeeId, employeeData) {
        // Count present employees
        final attendance =
            Map<String, dynamic>.from(employeeData['attendance'] ?? {});
        if (attendance[today] != null &&
            attendance[today]['check_in'] != null) {
          presentCount++;
        }

        // Check if employee joined this month
        final joiningDate = DateTime.parse(employeeData['joining_date']);
        final now = DateTime.now();

        // Only count as pending if:
        // 1. Employee joined in a previous month, or
        // 2. Employee joined this month but before today
        if ((joiningDate.year < now.year ||
                (joiningDate.year == now.year &&
                    joiningDate.month < now.month)) ||
            (joiningDate.year == now.year &&
                joiningDate.month == now.month &&
                joiningDate.day < now.day)) {
          // Check if salary is pending
          if (!salaryData.containsKey(employeeId) ||
              (salaryData[employeeId]['payment_type'] != 'full' &&
                  salaryData[employeeId]['payment_type'] != 'advance')) {
            pendingCount++;
          }
        }
      });

      setState(() {
        _totalEmployees = employeesData.length;
        _presentToday = presentCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading employee stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Employees Dashboard'),
      drawer: const CommonDrawer(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(DesignSystem.primaryColor),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.surfaceColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadEmployeeStats();
                  await _loadEmployees();
                },
                color: DesignSystem.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'Total Employees',
                              value: _totalEmployees.toString(),
                              icon: Icons.groups,
                              color: DesignSystem.primaryColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmployeeList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'Present Today',
                              value: '$_presentToday/$_totalEmployees',
                              icon: Icons.how_to_reg,
                              color: DesignSystem.secondaryColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AttendanceTracking(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Actions',
                            style: DesignSystem.headingLarge,
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEmployee(),
                              ),
                            ),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Employee'),
                            style: DesignSystem.primaryButtonStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildQuickActionButton(
                            title: 'Attendance\nTracking',
                            icon: Icons.fact_check,
                            color: DesignSystem.infoColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AttendanceTracking(),
                              ),
                            ),
                          ),
                          _buildQuickActionButton(
                            title: 'Salary\nManagement',
                            icon: Icons.account_balance_wallet,
                            color: DesignSystem.accentColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalaryManagement(),
                              ),
                            ),
                          ),
                          _buildQuickActionButton(
                            title: 'Employee\nDetails',
                            icon: Icons.badge,
                            color: DesignSystem.primaryColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmployeeList(),
                              ),
                            ),
                          ),
                          _buildQuickActionButton(
                            title: 'Salary\nHistory',
                            icon: Icons.history,
                            color: DesignSystem.successColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmployeeList(
                                  showSalaryHistory: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
