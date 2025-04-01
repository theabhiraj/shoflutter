import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Components/common_appbar.dart';
import '../Components/common_drawer.dart';
import '../Components/report_sync.dart';
import 'employee_performance.dart';
import 'expenses_reports.dart';
import 'export_reports.dart';
import 'financial_summary.dart';
import 'inventory_reports.dart';
import 'sales_reports.dart';

class ReportsHome extends StatefulWidget {
  const ReportsHome({super.key});

  @override
  State<ReportsHome> createState() => _ReportsHomeState();
}

class _ReportsHomeState extends State<ReportsHome> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String? _error;
  StreamSubscription? _inventorySubscription;
  StreamSubscription? _salesSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSync();
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _salesSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSync() {
    setState(() {
      _isLoading = true;
      _error = null;
      _reportData = {}; // Reset data
    });

    try {
      // Cancel existing subscriptions
      _inventorySubscription?.cancel();
      _salesSubscription?.cancel();

      // Listen to inventory changes
      _inventorySubscription =
          ReportSync.listenToInventoryChanges((inventoryStats) {
        if (mounted) {
          setState(() {
            _reportData['inventory'] = inventoryStats;
            _isLoading = false;
          });
        }
      });

      // Listen to sales changes
      _salesSubscription = ReportSync.listenToSalesChanges((salesStats) {
        if (mounted) {
          setState(() {
            _reportData['sales'] = salesStats;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmptyState({String? message, String? subMessage}) {
    return Center(
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
            message ?? 'No Reports Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subMessage ?? 'Start making transactions to generate reports',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _setupRealtimeSync,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEmptyState(String section) {
    final messages = {
      'sales': {
        'title': 'No Sales Data',
        'message': 'Complete some sales to see revenue data'
      },
      'expenses': {
        'title': 'No Expense Data',
        'message': 'Record expenses to see expense reports'
      },
      'inventory': {
        'title': 'No Inventory Data',
        'message': 'Add products to inventory to see stock reports'
      },
      'employees': {
        'title': 'No Employee Data',
        'message': 'Add employees to see performance reports'
      },
    };

    final data = messages[section] ??
        {
          'title': 'No Data Available',
          'message': 'Add some data to see reports'
        };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 24,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            data['title']!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['message']!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue & Expenses Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                          if (value.toInt() < labels.length) {
                            return Text(labels[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2),
                        FlSpot(1, 3),
                        FlSpot(2, 2),
                        FlSpot(3, 3.5),
                        FlSpot(4, 3),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('Revenue', Colors.blue),
                const SizedBox(width: 16),
                _buildChartLegend('Expenses', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Reports...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'Reports Dashboard'),
        drawer: const CommonDrawer(),
        body: _buildEmptyState(
          message: 'Error Loading Reports',
          subMessage: _error,
        ),
      );
    }

    if (_reportData.isEmpty) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'Reports Dashboard'),
        drawer: const CommonDrawer(),
        body: _buildEmptyState(),
      );
    }

    // Safely extract data with null checks and type casting
    final inventoryData =
        _reportData['inventory'] as Map<String, dynamic>? ?? {};
    final salesData = _reportData['sales'] as Map<String, dynamic>? ?? {};

    final bool hasSalesData =
        salesData.isNotEmpty && (salesData['total_revenue'] ?? 0) > 0;
    final bool hasExpenseData =
        salesData.isNotEmpty && (salesData['total_expenses'] ?? 0) > 0;
    final bool hasInventoryData = inventoryData.isNotEmpty;
    final bool hasEmployeeData =
        (_reportData['employees'] as Map<String, dynamic>?)?.isNotEmpty ??
            false;

    final totalRevenue = (salesData['total_revenue'] ?? 0).toString();
    final totalExpenses = (salesData['total_expenses'] ?? 0).toString();
    final netProfit =
        ((salesData['total_revenue'] ?? 0) - (salesData['total_expenses'] ?? 0))
            .toString();
    final lowStockCount = inventoryData['low_stock_items'] ?? 0;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Reports Dashboard'),
      drawer: const CommonDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _setupRealtimeSync();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  hasSalesData
                      ? _buildOverviewCard(
                          title: 'Total Revenue',
                          value: '₹$totalRevenue',
                          icon: Icons.trending_up,
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalesReports(
                                initialData: salesData,
                                selectedDate: DateTime.now(),
                              ),
                            ),
                          ),
                        )
                      : _buildSectionEmptyState('sales'),
                  hasExpenseData
                      ? _buildOverviewCard(
                          title: 'Total Expenses',
                          value: '₹$totalExpenses',
                          icon: Icons.trending_down,
                          color: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpensesReports(
                                initialData: _reportData['expenses'],
                                selectedDate: DateTime.now(),
                              ),
                            ),
                          ),
                        )
                      : _buildSectionEmptyState('expenses'),
                  hasSalesData || hasExpenseData
                      ? _buildOverviewCard(
                          title: 'Net Profit',
                          value: '₹$netProfit',
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FinancialSummary(
                                initialData: {
                                  'total_revenue':
                                      salesData['total_revenue'] ?? 0,
                                  'total_expenses':
                                      salesData['total_expenses'] ?? 0,
                                  'net_profit':
                                      (salesData['total_revenue'] ?? 0) -
                                          (salesData['total_expenses'] ?? 0),
                                },
                                selectedDate: DateTime.now(),
                              ),
                            ),
                          ),
                        )
                      : _buildSectionEmptyState('sales'),
                  hasInventoryData
                      ? _buildOverviewCard(
                          title: 'Low Stock Items',
                          value: lowStockCount == 0
                              ? 'All Good'
                              : '$lowStockCount Items',
                          icon: Icons.inventory,
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryReports(
                                initialData: {
                                  'low_stock_items': lowStockCount,
                                  'inventory_data': inventoryData,
                                },
                              ),
                            ),
                          ),
                        )
                      : _buildSectionEmptyState('inventory'),
                ],
              ),
              const SizedBox(height: 24),
              hasSalesData || hasExpenseData
                  ? _buildRevenueChart()
                  : _buildSectionEmptyState('sales'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: hasEmployeeData
                        ? ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeePerformance(
                                  initialData: _reportData['employees'],
                                  selectedDate: DateTime.now(),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.people),
                            label: const Text('Employee Reports'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : _buildSectionEmptyState('employees'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExportReports(
                            reportData: _reportData,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Reports'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
