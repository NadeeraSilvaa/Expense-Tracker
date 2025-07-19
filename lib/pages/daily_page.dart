import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:icon_badge/icon_badge.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  Future<Map<String, dynamic>> getUserData() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return {};
  }

  Stream<Map<String, double>> getFinancialSummaryStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({'Income': 0.0, 'Expenses': 0.0, 'Loan': 0.0, 'Loan Payment': 0.0});

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      double income = 0.0;
      double expenses = 0.0;
      double loans = 0.0;
      double loanPayments = 0.0;

      for (var doc in snapshot.docs) {
        double amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        String category = doc['category']?.toString() ?? '';
        switch (category) {
          case 'Income':
            income += amount;
            break;
          case 'Expense':
            expenses += amount;
            break;
          case 'Loan':
            loans += amount;
            break;
          case 'Loan Payment':
            loanPayments += amount;
            break;
          default:
          // Treat custom categories as expenses
            expenses += amount;
            break;
        }
      }

      return {
        'Income': income,
        'Expenses': expenses,
        'Loan': loans,
        'Loan Payment': loanPayments,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getRecentTransactionsStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'category': doc['category']?.toString() ?? 'Unknown',
          'description': doc['description']?.toString() ?? '',
          'amount': doc['amount']?.toDouble() ?? 0.0,
          'icon': _getIconForCategory(doc['category']?.toString() ?? ''),
        };
      }).toList();
    });
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Income':
        return Icons.arrow_downward_rounded;
      case 'Expense':
        return Icons.arrow_upward_rounded;
      case 'Loan':
        return CupertinoIcons.money_dollar;
      case 'Loan Payment':
        return Icons.payment_rounded;
      default:
        return Icons.category; // Default icon for custom categories
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (FirebaseAuth.instance.currentUser == null) {
      return Center(
        child: Text(
          "Please log in to view your data",
          style: TextStyle(
              fontSize: 16, color: AppColors.black(themeProvider.isDarkMode)),
        ),
      );
    }
    var size = MediaQuery.of(context).size;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 10),
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.bar_chart, color: AppColors.black(themeProvider.isDarkMode)),
                          Icon(Icons.more_vert, color: AppColors.black(themeProvider.isDarkMode)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                    "https://images.unsplash.com/photo-1531256456869-ce942a665e80"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: (size.width - 40) * 0.6,
                            child: Column(
                              children: [
                                FutureBuilder<Map<String, dynamic>>(
                                  future: getUserData(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return Text("Error: ${snapshot.error}");
                                    }
                                    String name =
                                        snapshot.data?['name'] ?? 'User';
                                    return Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainFontColor(themeProvider.isDarkMode),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Software Developer",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black(themeProvider.isDarkMode),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      StreamBuilder<Map<String, double>>(
                        stream: getFinancialSummaryStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text("Error: ${snapshot.error}"));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: Text("No financial data available"));
                          }
                          final summary = snapshot.data ?? {'Income': 0.0, 'Expenses': 0.0, 'Loan': 0.0, 'Loan Payment': 0.0};
                          final balance = summary['Income']! - summary['Expenses']!;
                          return Column(
                            children: [
                              Text(
                                "LKR ${balance.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: balance < 0
                                      ? AppColors.red(themeProvider.isDarkMode)
                                      : AppColors.mainFontColor(themeProvider.isDarkMode),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Total Balance",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.black(themeProvider.isDarkMode),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Overview",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.mainFontColor(themeProvider.isDarkMode),
                          ),
                        ),
                        IconBadge(
                          icon: Icon(Icons.notifications_none,
                              color: AppColors.black(themeProvider.isDarkMode)),
                          itemCount: 1,
                          badgeColor: AppColors.red(themeProvider.isDarkMode),
                          itemColor: AppColors.mainFontColor(themeProvider.isDarkMode),
                          hideZero: true,
                          top: -1,
                          onTap: () {},
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.mainFontColor(themeProvider.isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getRecentTransactionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No transactions available"));
                  }
                  final transactions = snapshot.data ?? [];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: transactions
                          .asMap()
                          .entries
                          .map((entry) => _buildTransactionRow(
                        size,
                        entry.value['category'],
                        entry.value['description'],
                        "LKR ${entry.value['amount'].toStringAsFixed(2)}",
                        entry.value['icon'],
                        themeProvider.isDarkMode,
                      ))
                          .toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
      Size size, String category, String subtitle, String amount, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white(isDarkMode),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey(isDarkMode).withOpacity(0.03),
                  spreadRadius: 10,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.arrowBgColor(isDarkMode),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                        child: Icon(icon, color: AppColors.mainFontColor(isDarkMode))),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.black(isDarkMode),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black(isDarkMode).withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}