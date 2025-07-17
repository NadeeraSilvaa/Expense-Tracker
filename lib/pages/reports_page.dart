import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  // Helper function to calculate monthly totals for the last 6 months
  Map<String, Map<String, double>> _calculateMonthlyTotals(
      List<QueryDocumentSnapshot> transactions) {
    final now = DateTime.now();
    final Map<String, Map<String, double>> monthlyData = {};

    // Initialize 6 months of data
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yyyy').format(date);
      monthlyData[key] = {'Income': 0.0, 'Expense': 0.0, 'Loan': 0.0, 'Loan Payment': 0.0};
    }

    for (var doc in transactions) {
      final date = (doc['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final key = DateFormat('MMM yyyy').format(date);
      final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
      final category = doc['category']?.toString() ?? 'Unknown';

      if (monthlyData.containsKey(key) && monthlyData[key]!.containsKey(category)) {
        monthlyData[key]![category] = monthlyData[key]![category]! + amount;
      }
    }

    return monthlyData;
  }

  // Fetch user's loan balance
  Future<double> _getLoanBalance() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? (doc.data()!['loanBalance']?.toDouble() ?? 0.0) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text(
          "Reports",
          style: TextStyle(color: mainFontColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No transactions available"));
            }

            var transactions = snapshot.data!.docs;
            double income = 0, expense = 0, loanPayment = 0;
            for (var doc in transactions) {
              double amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
              switch (doc['category']) {
                case 'Income':
                  income += amount;
                  break;
                case 'Expense':
                  expense += amount;
                  break;
                case 'Loan Payment':
                  loanPayment += amount;
                  break;
              }
            }

            // Calculate monthly totals for Bar Chart
            final monthlyData = _calculateMonthlyTotals(transactions);

            // Check if all pie chart data is zero
            bool isPieChartEmpty = income == 0 && expense == 0 && loanPayment == 0;

            // Calculate maxY for Bar Chart with fallback
            double maxY = monthlyData.values
                .map((data) => [
              data['Income']!,
              data['Expense']!,
              data['Loan']!,
              data['Loan Payment']!
            ].reduce((a, b) => a > b ? a : b))
                .reduce((a, b) => a > b ? a : b);
            maxY = maxY == 0 ? 100 : maxY * 1.2; // Fallback to 100 if no data, else add 20% padding

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard("Income", "LKR ${income.toStringAsFixed(2)}", green),
                    const SizedBox(height: 20),
                    _buildSummaryCard("Expenses", "LKR ${expense.toStringAsFixed(2)}", red),
                    const SizedBox(height: 20),
                    FutureBuilder<double>(
                      future: _getLoanBalance(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }
                        final loanBalance = snapshot.data ?? 0.0;
                        return _buildSummaryCard("Loan Balance", "LKR ${loanBalance.toStringAsFixed(2)}", blue);
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Transaction Distribution",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainFontColor,
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      height: 200,
                      child: isPieChartEmpty
                          ? const Center(child: Text("No data to display"))
                          : PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: income,
                              color: green,
                              title: "Income",
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: expense,
                              color: red,
                              title: "Expenses",
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: loanPayment,
                              color: purple, // Assuming purple is defined in colors.dart, else use #AB47BC
                              title: "Loan Payment",
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "Monthly Transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainFontColor,
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barGroups: monthlyData.entries.toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value.value;
                            return BarChartGroupData(
                              x: index,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: data['Income']!,
                                  color: green,
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: data['Expense']!,
                                  color: red,
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: data['Loan']!,
                                  color: blue,
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: data['Loan Payment']!,
                                  color: purple, // Assuming purple is defined in colors.dart
                                  width: 6,
                                ),
                              ],
                            );
                          }).toList(),
                          groupsSpace: 20,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: mainFontColor,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              axisNameWidget: const Text(
                                "Amount (LKR)",
                                style: TextStyle(
                                  color: mainFontColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final key = monthlyData.keys.toList()[value.toInt()];
                                  return Text(
                                    key.split(' ')[0], // Show only month (e.g., "Jul")
                                    style: const TextStyle(
                                      color: mainFontColor,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              axisNameWidget: const Text(
                                "Month",
                                style: TextStyle(
                                  color: mainFontColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                                final category = ['Income', 'Expense', 'Loan', 'Loan Payment'][rodIdx];
                                return BarTooltipItem(
                                  '$category: LKR ${rod.toY.toStringAsFixed(2)}',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: grey.withOpacity(0.03),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  title == "Income"
                      ? Icons.arrow_downward
                      : title == "Expenses"
                      ? Icons.arrow_upward
                      : Icons.money,
                  color: color,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainFontColor,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: black,
            ),
          ),
        ],
      ),
    );
  }
}