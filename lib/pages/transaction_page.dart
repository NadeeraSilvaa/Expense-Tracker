import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedFilter = 'All';
  String _selectedDateRange = 'Today';
  List<String> _categories = ['All', 'Income', 'Expense', 'Loan', 'Loan Payment'];

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
          'All',
          'Income',
          'Expense',
          'Loan',
          'Loan Payment',
          ...snapshot.docs.map((doc) => doc['name'] as String)
        ];
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getTransactionsStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);

    if (_selectedFilter != 'All') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'category': doc['category']?.toString() ?? 'Unknown',
          'description': doc['description']?.toString() ?? '',
          'amount': doc['amount']?.toDouble() ?? 0.0,
          'date': (doc['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
        return Icons.payment;
      default:
        return Icons.category;
    }
  }

  List<Map<String, dynamic>> filterTransactionsByDateRange(
      List<Map<String, dynamic>> transactions, String dateRange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last7Days = today.subtract(const Duration(days: 7));
    final last30Days = today.subtract(const Duration(days: 30));

    return transactions.where((transaction) {
      final transactionDate = (transaction['date'] as DateTime);
      final transactionDay =
      DateTime(transactionDate.year, transactionDate.month, transactionDate.day);

      switch (dateRange) {
        case 'Today':
          return transactionDay == today;
        case 'Yesterday':
          return transactionDay == yesterday;
        case 'Last 7 Days':
          return transactionDate.isAfter(last7Days) ||
              transactionDate.isAtSameMomentAs(last7Days);
        case 'Last 30 Days':
          return transactionDate.isAfter(last30Days) ||
              transactionDate.isAtSameMomentAs(last30Days);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary(themeProvider.isDarkMode),
      body: getBody(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary(themeProvider.isDarkMode),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey(themeProvider.isDarkMode).withOpacity(0.01),
                    spreadRadius: 10,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20, bottom: 25, right: 20, left: 20),
                child: Column(
                  children: [],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.mainFontColor(themeProvider.isDarkMode),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild to refresh data
                    },
                    child: Text(
                      "Refresh",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.mainFontColor(themeProvider.isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 20, left: 25, right: 25),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories
                      .map((filter) => [
                    _buildFilterButton(filter, themeProvider.isDarkMode),
                    const SizedBox(width: 10),
                  ])
                      .expand((element) => element)
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedDateRange,
                    items: <String>['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.mainFontColor(themeProvider.isDarkMode),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDateRange = newValue;
                        });
                      }
                    },
                    underline: Container(),
                    icon: Icon(Icons.arrow_drop_down,
                        color: AppColors.mainFontColor(themeProvider.isDarkMode)),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTransactionsStream(),
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

                final filteredTransactions =
                filterTransactionsByDateRange(snapshot.data!, _selectedDateRange);

                if (filteredTransactions.isEmpty) {
                  return Center(
                      child: Text(
                        "No transactions for $_selectedDateRange",
                        style: TextStyle(
                            color: AppColors.black(themeProvider.isDarkMode)),
                      ));
                }

                return Column(
                  children: filteredTransactions.map((transaction) {
                    return Dismissible(
                      key: Key(transaction['id']),
                      background: Container(
                        color: AppColors.red(themeProvider.isDarkMode),
                        child: Icon(Icons.delete,
                            color: AppColors.white(themeProvider.isDarkMode)),
                      ),
                      onDismissed: (direction) {
                        FirebaseFirestore.instance
                            .collection('transactions')
                            .doc(transaction['id'])
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction deleted")),
                        );
                      },
                      child: _buildTransactionRow(
                        size,
                        transaction['category'],
                        transaction['description'],
                        "LKR ${transaction['amount'].toStringAsFixed(2)}",
                        transaction['icon'],
                        themeProvider.isDarkMode,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: _selectedFilter == filter
              ? AppColors.buttonColor(isDarkMode)
              : AppColors.white(isDarkMode),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey(isDarkMode).withOpacity(0.03),
              spreadRadius: 10,
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            filter,
            style: TextStyle(
              color: _selectedFilter == filter
                  ? AppColors.white(isDarkMode)
                  : AppColors.black(isDarkMode).withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
            margin: const EdgeInsets.only(top: 10, left: 25, right: 25),
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
              padding: const EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
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
                      child: Icon(
                        icon,
                        color: AppColors.mainFontColor(isDarkMode),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      width: (size.width - 90) * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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