import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Components/common_appbar.dart';
import '../Components/design_system.dart';

class SalaryManagement extends StatefulWidget {
  const SalaryManagement({super.key});

  @override
  State<SalaryManagement> createState() => _SalaryManagementState();
}

class _SalaryManagementState extends State<SalaryManagement> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1');

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _setupEmployeesListener();
  }

  void _setupEmployeesListener() {
    _database.child('employees').onValue.listen((event) {
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

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      _loadSalaryRecords();
    }
  }

  Future<void> _loadSalaryRecords() async {
    setState(() => _isLoading = true);

    try {
      final salarySnapshot =
          await _database.child('salary_records').child(_selectedMonth).get();

      setState(() {
        for (var employee in _employees) {
          if (salarySnapshot.exists) {
            final salaryData =
                Map<String, dynamic>.from(salarySnapshot.value as Map);
            if (salaryData.containsKey(employee['id'])) {
              final employeeData =
                  Map<String, dynamic>.from(salaryData[employee['id']]);
              employee['salary_paid'] = employeeData['payment_type'] == 'full';
              employee['payment_date'] = employeeData['payment_date'];
              employee['amount_paid'] = employeeData['amount'];
              employee['working_days'] = employeeData['working_days'];
              employee['payment_type'] = employeeData['payment_type'];
            } else {
              employee['salary_paid'] = false;
              employee['payment_date'] = null;
              employee['amount_paid'] = null;
              employee['working_days'] = null;
              employee['payment_type'] = null;
            }
          } else {
            employee['salary_paid'] = false;
            employee['payment_date'] = null;
            employee['amount_paid'] = null;
            employee['working_days'] = null;
            employee['payment_type'] = null;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading salary records: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showPaymentDialog(String employeeId, String employeeName,
      double expectedSalary, int workingDays) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController daysController = TextEditingController();
    String paymentType = 'advance';

    // Get attendance data for the selected month
    final attendanceData = await _getMonthlyAttendance(employeeId);
    final int presentDays = attendanceData['presentDays'] ?? 0;
    final int totalDays = attendanceData['totalDays'] ?? workingDays;

    // Check payment status
    final paymentStatus = await _getPaymentStatus(employeeId);
    final bool isFullPaid = paymentStatus['isFullPaid'];
    final bool hasPartialPayment = paymentStatus['hasPartialPayment'];
    final double paidAmount = paymentStatus['paidAmount'];
    final int paidDays = paymentStatus['paidDays'];

    // Get advance payment info
    final advanceInfo = await _getAdvancePaymentInfo(employeeId);
    final hasAdvance = advanceInfo['hasAdvance'] ?? false;
    final advanceAmount = advanceInfo['amount'] ?? 0.0;

    // Set initial amount based on attendance
    final perDaySalary = expectedSalary / totalDays;

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pay Salary - $employeeName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (presentDays == 0 && paymentType != 'advance') ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No attendance records found for this month. Only advance payment is allowed.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isFullPaid || hasPartialPayment) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFullPaid) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Full payment already made',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Payment'),
                                        content: const Text(
                                          'Are you sure you want to delete this payment record? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldDelete == true) {
                                      await _deleteSalaryRecord(employeeId);
                                      Navigator.pop(context, false);
                                    }
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (hasPartialPayment) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Partial payment made: ₹$paidAmount for $paidDays days',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Payment'),
                                        content: const Text(
                                          'Are you sure you want to delete this payment record? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldDelete == true) {
                                      await _deleteSalaryRecord(employeeId);
                                      Navigator.pop(context, false);
                                    }
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hasAdvance) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Advance payment of ₹$advanceAmount will be deducted',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Payment Type:'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'full',
                        label: const Text('Full'),
                        enabled: !isFullPaid && !hasPartialPayment,
                      ),
                      ButtonSegment(
                        value: 'partial',
                        label: const Text('Partial'),
                        enabled: !isFullPaid && !hasPartialPayment,
                      ),
                      const ButtonSegment(
                        value: 'advance',
                        label: Text('Advance'),
                      ),
                    ],
                    selected: {paymentType},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        paymentType = selection.first;
                        if (paymentType == 'full') {
                          amountController.text =
                              (perDaySalary * presentDays).toStringAsFixed(0);
                          daysController.text = presentDays.toString();
                        } else if (paymentType == 'partial') {
                          daysController.clear();
                          amountController.clear();
                        } else if (paymentType == 'advance') {
                          daysController.clear();
                          amountController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (paymentType == 'partial') ...[
                    TextField(
                      controller: daysController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Days',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final days = int.tryParse(value) ?? 0;
                        if (days > 0) {
                          if (days > presentDays) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Only $presentDays days of attendance recorded'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            daysController.text = presentDays.toString();
                            amountController.text =
                                (perDaySalary * presentDays).toStringAsFixed(0);
                          } else {
                            amountController.text =
                                (perDaySalary * days).toStringAsFixed(0);
                          }
                        } else {
                          amountController.clear();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: paymentType == 'advance'
                          ? 'Advance Amount (₹)'
                          : 'Amount (₹)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: paymentType != 'advance',
                  ),
                  const SizedBox(height: 8),
                  if (paymentType == 'full' || paymentType == 'partial') ...[
                    Text(
                      'Present Days: $presentDays out of $totalDays',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Per Day Salary: ₹${perDaySalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ] else if (paymentType == 'advance') ...[
                    Text(
                      'Monthly Salary: ₹${expectedSalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Advance will be deducted from next month\'s salary',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Check attendance for full/partial payments
                    if (paymentType != 'advance' && presentDays == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'No attendance records found for this month. Only advance payment is allowed.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (paymentType == 'partial') {
                      final days = int.tryParse(daysController.text);
                      if (days == null || days <= 0 || days > presentDays) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Please enter a valid number of days (max: $presentDays)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    if (paymentType == 'advance') {
                      if (amount > expectedSalary) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Advance cannot exceed monthly salary'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    } else {
                      // For full/partial payments, validate against attendance
                      final maxAmount = perDaySalary * presentDays;
                      if (amount > maxAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Amount cannot exceed ₹${maxAmount.toStringAsFixed(0)} (based on $presentDays days of attendance)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Pay'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final amount = double.parse(amountController.text);
      final days = paymentType == 'partial'
          ? int.parse(daysController.text)
          : paymentType == 'full'
              ? presentDays
              : 0;
      await _markSalaryPaid(employeeId, amount, paymentType, days);
    }
  }

  // ignore: unused_element
  Future<bool> _isFullPaymentMade(String employeeId) async {
    try {
      final salarySnapshot = await _database
          .child('salary_records')
          .child(_selectedMonth)
          .child(employeeId)
          .get();

      if (salarySnapshot.exists) {
        final data = Map<String, dynamic>.from(salarySnapshot.value as Map);
        return data['payment_type'] == 'full';
      }
      return false;
    } catch (e) {
      debugPrint('Error checking full payment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getAdvancePaymentInfo(String employeeId) async {
    try {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);
      // ignore: unused_local_variable
      final nextMonthStr = DateFormat('yyyy-MM').format(nextMonth);

      final advanceSnapshot = await _database
          .child('salary_records')
          .child(_selectedMonth)
          .child(employeeId)
          .get();

      if (advanceSnapshot.exists) {
        final data = Map<String, dynamic>.from(advanceSnapshot.value as Map);
        if (data['payment_type'] == 'advance') {
          return {
            'hasAdvance': true,
            'amount': data['amount'],
            'date': data['payment_date'],
          };
        }
      }
      return {'hasAdvance': false};
    } catch (e) {
      debugPrint('Error checking advance payment: $e');
      return {'hasAdvance': false};
    }
  }

  Future<void> _markSalaryPaid(
      String employeeId, double amount, String paymentType, int days) async {
    try {
      final now = DateTime.now();
      final joiningDate = DateTime.parse(_employees
          .firstWhere((emp) => emp['id'] == employeeId)['joining_date']);

      final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);
      final isFullMonth = joiningDate.year == selectedDate.year &&
              joiningDate.month == selectedDate.month
          ? false
          : true;

      final daysInMonth =
          DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      final workingDays =
          isFullMonth ? daysInMonth : (daysInMonth - (joiningDate.day - 1));

      // For advance payment, create a record for next month's deduction
      if (paymentType == 'advance') {
        final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
        final nextMonthStr = DateFormat('yyyy-MM').format(nextMonth);

        await _database
            .child('advance_payments')
            .child(nextMonthStr)
            .child(employeeId)
            .set({
          'amount': amount,
          'payment_date': DateFormat('yyyy-MM-dd').format(now),
          'deduction_month': nextMonthStr,
        });
      }

      // Save the salary record
      await _database
          .child('salary_records')
          .child(_selectedMonth)
          .child(employeeId)
          .set({
        'amount': amount,
        'payment_method': 'Cash',
        'payment_date': DateFormat('yyyy-MM-dd').format(now),
        'is_full_month': isFullMonth,
        'working_days': days,
        'payment_type': paymentType,
        'total_days': workingDays,
        'expected_amount':
            _employees.firstWhere((emp) => emp['id'] == employeeId)['salary'],
      });

      // Update local state
      setState(() {
        final employeeIndex =
            _employees.indexWhere((emp) => emp['id'] == employeeId);
        if (employeeIndex != -1) {
          _employees[employeeIndex]['salary_paid'] = paymentType == 'full';
          _employees[employeeIndex]['payment_date'] =
              DateFormat('yyyy-MM-dd').format(now);
          _employees[employeeIndex]['amount_paid'] = amount;
          _employees[employeeIndex]['working_days'] = days;
          _employees[employeeIndex]['payment_type'] = paymentType;
        }
      });

      // Reload salary records to refresh the UI
      await _loadSalaryRecords();

      String message = '';
      switch (paymentType) {
        case 'full':
          message = 'Full salary paid for $days days: ₹$amount';
          break;
        case 'partial':
          message = 'Partial salary paid for $days days: ₹$amount';
          break;
        case 'advance':
          message =
              'Advance payment of ₹$amount recorded (will be deducted from next month)';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error recording salary payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording salary payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, int>> _getMonthlyAttendance(String employeeId) async {
    try {
      final employee = _employees.firstWhere((emp) => emp['id'] == employeeId);
      final joiningDate = DateTime.parse(employee['joining_date']);
      final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);
      final daysInMonth =
          DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

      // If employee joined this month
      if (joiningDate.year == selectedDate.year &&
          joiningDate.month == selectedDate.month) {
        // Calculate remaining days from joining date
        final remainingDays = daysInMonth - joiningDate.day + 1;
        return {
          'presentDays': remainingDays,
          'totalDays': remainingDays,
        };
      } else {
        // For employees who joined before this month
        return {
          'presentDays': daysInMonth,
          'totalDays': daysInMonth,
        };
      }
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return {
        'presentDays': 0,
        'totalDays': 30,
      };
    }
  }

  Future<void> _deleteSalaryRecord(String employeeId) async {
    try {
      // Delete the salary record
      await _database
          .child('salary_records')
          .child(_selectedMonth)
          .child(employeeId)
          .remove();

      // Update local state
      setState(() {
        final employeeIndex =
            _employees.indexWhere((emp) => emp['id'] == employeeId);
        if (employeeIndex != -1) {
          _employees[employeeIndex]['salary_paid'] = false;
          _employees[employeeIndex]['payment_date'] = null;
          _employees[employeeIndex]['amount_paid'] = null;
          _employees[employeeIndex]['working_days'] = null;
          _employees[employeeIndex]['payment_type'] = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting salary record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting salary record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getPaymentStatus(String employeeId) async {
    try {
      final salarySnapshot = await _database
          .child('salary_records')
          .child(_selectedMonth)
          .child(employeeId)
          .get();

      if (salarySnapshot.exists) {
        final data = Map<String, dynamic>.from(salarySnapshot.value as Map);
        return {
          'isFullPaid': data['payment_type'] == 'full',
          'hasPartialPayment': data['payment_type'] == 'partial',
          'paidAmount': data['amount'] ?? 0.0,
          'paidDays': data['working_days'] ?? 0,
        };
      }
      return {
        'isFullPaid': false,
        'hasPartialPayment': false,
        'paidAmount': 0.0,
        'paidDays': 0,
      };
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return {
        'isFullPaid': false,
        'hasPartialPayment': false,
        'paidAmount': 0.0,
        'paidDays': 0,
      };
    }
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 4,
      shadowColor: DesignSystem.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: DesignSystem.primaryCardDecoration,
        child: InkWell(
          onTap: () => _selectMonth(context),
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
                      DateFormat('MMMM yyyy')
                          .format(DateFormat('yyyy-MM').parse(_selectedMonth)),
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
              Icons.people_outline,
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
              'Add employees to manage their salaries',
              style: DesignSystem.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final paymentType = employee['payment_type'];
        final joiningDate = DateTime.parse(employee['joining_date']);
        final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);
        final isJoiningMonth = joiningDate.year == selectedDate.year &&
            joiningDate.month == selectedDate.month;
        final daysInMonth =
            DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
        final workingDays =
            isJoiningMonth ? daysInMonth - (joiningDate.day - 1) : daysInMonth;
        final expectedSalary = isJoiningMonth
            ? (employee['salary'] / daysInMonth) * workingDays
            : employee['salary'].toDouble();
        final bool showPayButton =
            paymentType == null || paymentType == 'partial';

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
                          if (isJoiningMonth) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Joined: ${DateFormat('dd MMM yyyy').format(joiningDate)}',
                              style: DesignSystem.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: DesignSystem.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹${NumberFormat('#,##,###').format(expectedSalary)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildEmployeeStatus(employee),
                        if (isJoiningMonth) ...[
                          const SizedBox(height: 4),
                          Text(
                            '($workingDays days)',
                            style: DesignSystem.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (paymentType != null) ...[
                  const Divider(height: 32, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            'Paid on: ${employee['payment_date']}',
                            style: DesignSystem.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DesignSystem.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 16,
                                  color: DesignSystem.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cash',
                                  style: TextStyle(
                                    color: DesignSystem.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (paymentType != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Payment'),
                                    content: const Text(
                                      'Are you sure you want to delete this payment record? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldDelete == true) {
                                  await _deleteSalaryRecord(employee['id']);
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
                if (showPayButton) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(
                        employee['id'],
                        employee['name'],
                        expectedSalary,
                        workingDays,
                      ),
                      style: DesignSystem.primaryButtonStyle,
                      child: const Text(
                        'Pay Salary (Cash)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeStatus(Map<String, dynamic> employee) {
    final paymentType = employee['payment_type'];
    final paidAmount = employee['amount_paid'];
    final paidDays = employee['working_days'];

    Color getStatusColor() {
      if (paymentType == 'full') {
        return DesignSystem.successColor;
      } else if (paymentType == 'partial') {
        return DesignSystem.warningColor;
      } else if (paymentType == 'advance') {
        return DesignSystem.infoColor;
      } else {
        return DesignSystem.errorColor;
      }
    }

    String getStatusText() {
      if (paymentType == 'full') {
        return 'Paid (Full)';
      } else if (paymentType == 'partial') {
        return 'Partial (₹$paidAmount, $paidDays days)';
      } else if (paymentType == 'advance') {
        return 'Advance (₹$paidAmount)';
      } else {
        final joiningDate = DateTime.parse(employee['joining_date']);
        final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);
        final daysInMonth =
            DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
        final days = joiningDate.year == selectedDate.year &&
                joiningDate.month == selectedDate.month
            ? daysInMonth - (joiningDate.day - 1)
            : daysInMonth;
        return 'Pending ($days days)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: DesignSystem.getStatusDecoration(getStatusColor()),
      child: Text(
        getStatusText(),
        style: TextStyle(
          color: getStatusColor(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Salary Management'),
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
              child: _buildMonthSelector(),
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
