import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Components/common_appbar.dart';
import '../Components/design_system.dart';

class AttendanceTracking extends StatefulWidget {
  const AttendanceTracking({super.key});

  @override
  State<AttendanceTracking> createState() => _AttendanceTrackingState();
}

class _AttendanceTrackingState extends State<AttendanceTracking> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1/employees');
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  final today = DateTime.now().toString().split(' ')[0];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final snapshot = await _database.get();
      if (!snapshot.exists) {
        setState(() {
          _employees = [];
          _isLoading = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _employees = data.entries.map((entry) {
          final employee = Map<String, dynamic>.from(entry.value);
          employee['id'] = entry.key;
          return employee;
        }).toList()
          ..sort((a, b) => a['name'].compareTo(b['name']));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _markAttendance(String employeeId, String type) async {
    try {
      final selectedDate = _selectedDate.toString().split(' ')[0];
      final now = DateTime.now();
      final time = DateFormat('HH:mm').format(now);

      await _database
          .child(employeeId)
          .child('attendance')
          .child(selectedDate)
          .update({type: time});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type marked at $time'),
          backgroundColor: DesignSystem.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking $type: $e'),
          backgroundColor: DesignSystem.errorColor,
        ),
      );
    }
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 4,
      shadowColor: DesignSystem.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: DesignSystem.primaryCardDecoration,
        child: InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.primaryColor),
        ),
      );
    }

    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 80,
              color: DesignSystem.textSecondaryColor.withOpacity(0.3),
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
              'Add employees to track attendance',
              style: DesignSystem.bodyMedium,
            ),
          ],
        ),
      );
    }

    final selectedDate = _selectedDate.toString().split(' ')[0];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final attendance =
            Map<String, dynamic>.from(employee['attendance'] ?? {});
        final todayAttendance = attendance[selectedDate] ?? {};
        final checkIn = todayAttendance['check_in'];
        final checkOut = todayAttendance['check_out'];

        return Card(
          elevation: 4,
          shadowColor: DesignSystem.primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: DesignSystem.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: DesignSystem.avatarDecoration,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: DesignSystem.primaryColor,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee['name'],
                            style: DesignSystem.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: DesignSystem.getStatusDecoration(
                              DesignSystem.primaryColor,
                            ),
                            child: Text(
                              employee['role'],
                              style: TextStyle(
                                color: DesignSystem.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAttendanceStatus(
                        'Check In',
                        checkIn ?? '--:--',
                        Icons.login,
                        checkIn != null
                            ? DesignSystem.successColor
                            : DesignSystem.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAttendanceStatus(
                        'Check Out',
                        checkOut ?? '--:--',
                        Icons.logout,
                        checkOut != null
                            ? DesignSystem.successColor
                            : DesignSystem.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: checkIn != null
                            ? null
                            : () => _markAttendance(employee['id'], 'check_in'),
                        icon: const Icon(Icons.login),
                        label: const Text('Check In'),
                        style: DesignSystem.primaryButtonStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: checkIn == null || checkOut != null
                            ? null
                            : () =>
                                _markAttendance(employee['id'], 'check_out'),
                        icon: const Icon(Icons.logout),
                        label: const Text('Check Out'),
                        style: DesignSystem.primaryButtonStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStatus(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Attendance Tracking'),
      body: Container(
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildDateSelector(),
            ),
            Expanded(
              child: _buildEmployeeList(),
            ),
          ],
        ),
      ),
    );
  }
}
