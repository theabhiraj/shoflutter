import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Components/common_appbar.dart';
import '../Components/design_system.dart';
import 'add_employee.dart';
import 'employee_details.dart';
import 'employee_edit.dart';
import 'salary_history.dart';

class EmployeeList extends StatefulWidget {
  final bool showSalaryHistory;

  const EmployeeList({
    super.key,
    this.showSalaryHistory = false,
  });

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1/employees');
  String _searchQuery = '';
  String _selectedRole = 'All';
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  final List<String> _roles = [
    'All',
    'Cashier',
    'Sales Associate',
    'Store Manager',
    'Inventory Manager',
    'Security Guard',
  ];

  @override
  void initState() {
    super.initState();
    _setupEmployeesListener();
  }

  void _setupEmployeesListener() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _employees = data.entries.map((entry) {
            final employee = Map<String, dynamic>.from(entry.value);
            employee['id'] = entry.key;
            return employee;
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _employees = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Error fetching employees: $error');
      setState(() => _isLoading = false);
    });
  }

  List<Map<String, dynamic>> get filteredEmployees {
    return _employees.where((employee) {
      final matchesSearch =
          employee['name'].toString().toLowerCase().contains(_searchQuery) ||
              employee['role'].toString().toLowerCase().contains(_searchQuery);
      final matchesRole =
          _selectedRole == 'All' || employee['role'] == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search employees...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: DesignSystem.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roles.map((role) {
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedRole = selected ? role : 'All');
                    },
                    backgroundColor: DesignSystem.backgroundColor,
                    selectedColor: DesignSystem.primaryColor.withOpacity(0.2),
                    checkmarkColor: DesignSystem.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? DesignSystem.primaryColor
                          : DesignSystem.textSecondaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? DesignSystem.primaryColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String employeeId) async {
    try {
      await _database.child(employeeId).remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String employeeId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: const Text(
            'Are you sure you want to delete this employee? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEmployee(employeeId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _employees.where((employee) {
      final matchesSearch = employee['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesRole =
          _selectedRole == 'All' || employee['role'] == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: widget.showSalaryHistory ? 'Select Employee' : 'Employee List',
      ),
      floatingActionButton: widget.showSalaryHistory
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEmployee(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Employee'),
              backgroundColor: DesignSystem.primaryColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      body: Container(
        color: DesignSystem.backgroundColor,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            DesignSystem.primaryColor),
                      ),
                    )
                  : filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_off,
                                size: 80,
                                color: DesignSystem.textSecondaryColor
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No employees found',
                                style: DesignSystem.headingMedium.copyWith(
                                  color: DesignSystem.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: DesignSystem.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shadowColor:
                                  DesignSystem.primaryColor.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: DesignSystem.cardDecoration,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    decoration: DesignSystem.avatarDecoration,
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor:
                                          DesignSystem.primaryColor,
                                      child: Text(
                                        employee['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    employee['name'],
                                    style: DesignSystem.bodyLarge,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: DesignSystem
                                                .getStatusDecoration(
                                                    DesignSystem.primaryColor),
                                            child: Text(
                                              employee['role'],
                                              style: TextStyle(
                                                color:
                                                    DesignSystem.primaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹${NumberFormat('#,##,###').format(employee['salary'])}',
                                            style: DesignSystem.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (widget.showSalaryHistory) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SalaryHistory(
                                            employeeId: employee['id'],
                                            employeeName: employee['name'],
                                            employeeRole: employee['role'],
                                            currentSalary: double.parse(
                                              employee['salary'].toString(),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EmployeeDetails(
                                            employeeId: employee['id'],
                                            employeeData: employee,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  trailing: widget.showSalaryHistory
                                      ? Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: DesignSystem.primaryColor,
                                        )
                                      : PopupMenuButton(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: DesignSystem.primaryColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit,
                                                  color:
                                                      DesignSystem.primaryColor,
                                                  size: 20,
                                                ),
                                                title: Text(
                                                  'Edit',
                                                  style: DesignSystem.bodyMedium
                                                      .copyWith(
                                                    color: DesignSystem
                                                        .textPrimaryColor,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onTap: () {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EmployeeEdit(
                                                          employeeId:
                                                              employee['id'],
                                                          employeeData:
                                                              employee,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete_outline,
                                                  color:
                                                      DesignSystem.errorColor,
                                                  size: 20,
                                                ),
                                                title: Text(
                                                  'Delete',
                                                  style: DesignSystem.bodyMedium
                                                      .copyWith(
                                                    color:
                                                        DesignSystem.errorColor,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onTap: () {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () => _showDeleteConfirmation(
                                                    employee['id'],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
