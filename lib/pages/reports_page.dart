import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Monthly';
  List<String> _categories = ['Income', 'Expense', 'Loan', 'Loan Payment'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();
      setState(() {
        _categories = [
          'Income',
          'Expense',
          'Loan',
          'Loan Payment',
          ...snapshot.docs.map((doc) => doc['name'] as String)
        ];
      });
    }
  }

  Stream<Map<String, double>> getFinancialSummaryStream(String period) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid);

    DateTime now = DateTime.now();
    DateTime startDate;
    if (period == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (period == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    query = query.where('date', isGreaterThanOrEqualTo: startDate);

    return query.snapshots().map((snapshot) {
      Map<String, double> summary = {};
      for (var category in _categories) {
        summary[category] = 0.0;
      }

      for (var doc in snapshot.docs) {
        String category = doc['category']?.toString() ?? 'Expense';
        double amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        if (summary.containsKey(category)) {
          summary[category] = (summary[category] ?? 0.0) + amount;
        } else {
          summary['Expense'] = (summary['Expense'] ?? 0.0) + amount;
        }
      }
      return summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary(themeProvider.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.primary(themeProvider.isDarkMode),
        elevation: 0,
        title: Text(
          "Reports",
          style: TextStyle(
            color: AppColors.mainFontColor(themeProvider.isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white(themeProvider.isDarkMode),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey(themeProvider.isDarkMode).withOpacity(0.03),
                        spreadRadius: 10,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    underline: Container(),
                    items: ['Weekly', 'Monthly', 'Yearly']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPeriod = value!),
                    style: TextStyle(
                      color: AppColors.black(themeProvider.isDarkMode),
                      fontSize: 16,
                    ),
                    dropdownColor: AppColors.white(themeProvider.isDarkMode),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white(themeProvider.isDarkMode),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey(themeProvider.isDarkMode).withOpacity(0.03),
                        spreadRadius: 10,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: StreamBuilder<Map<String, double>>(
                    stream: getFinancialSummaryStream(_selectedPeriod),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No data available"));
                      }

                      final summary = snapshot.data!;
                      List<PieChartSectionData> sections = _categories
                          .asMap()
                          .entries
                          .map((entry) {
                        int index = entry.key;
                        String category = entry.value;
                        double value = summary[category] ?? 0.0;
                        return PieChartSectionData(
                          color: _getColorForCategory(category, themeProvider.isDarkMode),
                          value: value,
                          title: value > 0 ? category : '',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white(themeProvider.isDarkMode),
                          ),
                        );
                      })
                          .where((section) => section.value > 0)
                          .toList();

                      return PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<Map<String, double>>(
                  stream: getFinancialSummaryStream(_selectedPeriod),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No data available"));
                    }

                    final summary = snapshot.data!;
                    return Column(
                      children: _categories.map((category) {
                        double amount = summary[category] ?? 0.0;
                        if (amount == 0) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white(themeProvider.isDarkMode),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grey(themeProvider.isDarkMode).withOpacity(0.03),
                                spreadRadius: 10,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.arrowBgColor(themeProvider.isDarkMode),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getIconForCategory(category),
                                        color: AppColors.mainFontColor(themeProvider.isDarkMode),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black(themeProvider.isDarkMode),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "LKR ${amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black(themeProvider.isDarkMode),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Income':
        return Icons.arrow_downward_rounded;
      case 'Expense':
        return Icons.arrow_upward_rounded;
      case 'Loan':
        return Icons.account_balance_wallet;
      case 'Loan Payment':
        return Icons.payment;
      default:
        return Icons.category;
    }
  }

  Color _getColorForCategory(String category, bool isDarkMode) {
    switch (category) {
      case 'Income':
        return AppColors.green(isDarkMode);
      case 'Expense':
        return AppColors.red(isDarkMode);
      case 'Loan':
        return AppColors.blue(isDarkMode);
      case 'Loan Payment':
        return AppColors.purple(isDarkMode);
      default:
        return AppColors.grey(isDarkMode);
    }
  }
}