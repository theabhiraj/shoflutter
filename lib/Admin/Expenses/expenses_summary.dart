import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Add custom snackbar function at the top level
void showCustomSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onActionPressed,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isError ? Colors.red[400] : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onActionPressed ?? () {},
            )
          : null,
    ),
  );
}

class ExpensesSummary extends StatefulWidget {
  const ExpensesSummary({super.key});

  @override
  State<ExpensesSummary> createState() => _ExpensesSummaryState();
}

class _ExpensesSummaryState extends State<ExpensesSummary>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('shop_management/shop_1/expenses');

  Map<String, double> monthlyExpenses = {};
  Map<String, Map<String, double>> categoryExpenses = {};
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  double totalYearlyExpenses = 0.0;
  bool _isLoading = false;
  late AnimationController _animationController;
  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchExpensesSummary();
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('$selectedMonth-01'),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateFormat('yyyy-MM').format(picked);
        selectedYear = picked.year.toString();
      });
      _fetchExpensesSummary();
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(
      currentYear - 2019,
      (index) => currentYear - index,
    );

    final int? selectedYearInt = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: years.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(years[index].toString()),
                  onTap: () => Navigator.of(context).pop(years[index]),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedYearInt != null) {
      setState(() {
        selectedYear = selectedYearInt.toString();
        selectedMonth = '$selectedYear-${selectedMonth.split('-')[1]}';
      });
      _fetchExpensesSummary();
    }
  }

  void _fetchExpensesSummary() {
    setState(() => _isLoading = true);
    _subscription?.cancel();

    // Fetch monthly summary for the selected month
    _subscription = _database.child('summary/$selectedMonth').onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            categoryExpenses[selectedMonth] = {};
            data.forEach((key, value) {
              if (key != 'total_expenses' && key != 'top_category') {
                categoryExpenses[selectedMonth]![key] =
                    (value as num).toDouble();
              }
            });
          });
        }
      },
      onError: (error) {
        showCustomSnackBar(
          context,
          message: 'Error fetching expenses: $error',
          isError: true,
        );
      },
    );

    // Fetch yearly summary
    _database.child('summary').onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            monthlyExpenses.clear();
            totalYearlyExpenses = 0;

            data.forEach((key, value) {
              if (key.startsWith(selectedYear)) {
                final monthData = Map<String, dynamic>.from(value as Map);
                final total = (monthData['total_expenses'] ?? 0.0) as num;
                monthlyExpenses[key] = total.toDouble();
                totalYearlyExpenses += total.toDouble();
              }
            });

            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() => _isLoading = false);
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        showCustomSnackBar(
          context,
          message: 'Error fetching yearly summary: $error',
          isError: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expenses Summary',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Yearly Expenses',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalYearlyExpenses.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectMonth(context),
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          DateFormat('MMMM yyyy')
                              .format(DateTime.parse('$selectedMonth-01')),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectYear(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(selectedYear),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : monthlyExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Expenses Data',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add some expenses to see analytics',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Expenses',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        maxY: monthlyExpenses.values.reduce(
                                                (a, b) => a > b ? a : b) *
                                            1.2,
                                        barTouchData: BarTouchData(
                                          enabled: true,
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipItem: (group, groupIndex,
                                                    rod, rodIndex) =>
                                                BarTooltipItem(
                                              '₹${rod.toY.toStringAsFixed(2)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                if (value.toInt() >=
                                                    monthlyExpenses.length) {
                                                  return const SizedBox();
                                                }
                                                final month = monthlyExpenses
                                                    .keys
                                                    .elementAt(value.toInt());
                                                return Transform.rotate(
                                                  angle: -0.5,
                                                  child: Text(
                                                    DateFormat('MMM').format(
                                                        DateTime.parse(
                                                            '$month-01')),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '₹${value.toInt()}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: 1000,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: Colors.grey[300],
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        borderData: FlBorderData(
                                          show: false,
                                        ),
                                        barGroups: monthlyExpenses.entries
                                            .map(
                                              (entry) => BarChartGroupData(
                                                x: monthlyExpenses.keys
                                                    .toList()
                                                    .indexOf(entry.key),
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: entry.value,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    width: 16,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(6),
                                                      topRight:
                                                          Radius.circular(6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (categoryExpenses[selectedMonth]?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Category Breakdown',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 40,
                                          sections: categoryExpenses[
                                                  selectedMonth]!
                                              .entries
                                              .map(
                                                (entry) => PieChartSectionData(
                                                  color: Colors.primaries[entry
                                                          .key.hashCode %
                                                      Colors.primaries.length],
                                                  value: entry.value,
                                                  title:
                                                      '${entry.key}\n${(entry.value / monthlyExpenses[selectedMonth]! * 100).toStringAsFixed(1)}%',
                                                  radius: 100,
                                                  titleStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}

// ignore: unused_element
class _Badge extends StatelessWidget {
  final String category;
  final double amount;
  final Color color;

  const _Badge(this.category, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
