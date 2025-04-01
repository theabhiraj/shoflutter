import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Components/common_appbar.dart';
import '../Components/design_system.dart';

class SalaryHistory extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final double currentSalary;

  const SalaryHistory({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    required this.currentSalary,
  });

  @override
  State<SalaryHistory> createState() => _SalaryHistoryState();
}

class _SalaryHistoryState extends State<SalaryHistory> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');
  bool _isLoading = true;
  List<Map<String, dynamic>> _salaryRecords = [];

  @override
  void initState() {
    super.initState();
    _loadSalaryHistory();
  }

  Future<void> _loadSalaryHistory() async {
    try {
      final salarySnapshot =
          await _database.child('salary_records').orderByKey().get();

      if (salarySnapshot.exists) {
        final monthlyRecords =
            Map<String, dynamic>.from(salarySnapshot.value as Map);
        final List<Map<String, dynamic>> records = [];

        monthlyRecords.forEach((month, data) {
          if (data is Map && data.containsKey(widget.employeeId)) {
            final record = Map<String, dynamic>.from(data[widget.employeeId]);
            record['month'] = month;
            records.add(record);
          }
        });

        records.sort((a, b) => b['month'].compareTo(a['month']));

        setState(() {
          _salaryRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _salaryRecords = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading salary history: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEmployeeHeader() {
    return Card(
      elevation: 4,
      shadowColor: DesignSystem.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: DesignSystem.primaryCardDecoration,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  widget.employeeName[0].toUpperCase(),
                  style: const TextStyle(
                    color: DesignSystem.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employeeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.employeeRole,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Salary: ₹${NumberFormat('#,##,###').format(widget.currentSalary)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryList() {
    if (_salaryRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: DesignSystem.textSecondaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No salary records found',
              style: DesignSystem.headingMedium.copyWith(
                color: DesignSystem.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Salary records will appear here',
              style: DesignSystem.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salaryRecords.length,
      itemBuilder: (context, index) {
        final record = _salaryRecords[index];
        final month = record['month'];
        final amount = record['amount'];
        final paymentDate = record['payment_date'];
        final paymentType = record['payment_type'];
        final workingDays = record['working_days'];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(
                        DateFormat('yyyy-MM').parse(month),
                      ),
                      style: DesignSystem.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: DesignSystem.getStatusDecoration(
                        paymentType == 'full'
                            ? DesignSystem.successColor
                            : paymentType == 'partial'
                                ? DesignSystem.warningColor
                                : DesignSystem.infoColor,
                      ),
                      child: Text(
                        paymentType.toUpperCase(),
                        style: TextStyle(
                          color: paymentType == 'full'
                              ? DesignSystem.successColor
                              : paymentType == 'partial'
                                  ? DesignSystem.warningColor
                                  : DesignSystem.infoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Paid',
                          style: DesignSystem.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###').format(amount)}',
                          style: DesignSystem.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Working Days',
                          style: DesignSystem.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workingDays.toString(),
                          style: DesignSystem.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: DesignSystem.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paid on: $paymentDate',
                      style: DesignSystem.bodyMedium.copyWith(
                        color: DesignSystem.textSecondaryColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Salary History',
      ),
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignSystem.primaryColor,
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildEmployeeHeader(),
                  ),
                  Expanded(
                    child: _buildSalaryList(),
                  ),
                ],
              ),
      ),
    );
  }
}
