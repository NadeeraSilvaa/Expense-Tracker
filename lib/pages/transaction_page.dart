import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedFilter = 'All';

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
          'id': doc.id, // Added for delete functionality
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
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: getBody(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: primary,
                boxShadow: [
                  BoxShadow(
                    color: grey.withOpacity(0.01),
                    spreadRadius: 10,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20, bottom: 25, right: 20, left: 20),
                child: Column(
                  children: [
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     IconButton(
                    //       icon: const Icon(CupertinoIcons.back, color: black),
                    //       onPressed: () => Navigator.pop(context),
                    //     ),
                    //     IconButton(
                    //       icon: const Icon(CupertinoIcons.search, color: black),
                    //       onPressed: () {},
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: mainFontColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Refresh",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: mainFontColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 20, left: 25, right: 25),
              child: Row(
                children: [
                  _buildFilterButton("All"),
                  const SizedBox(width: 10),
                  _buildFilterButton("Income"),
                  const SizedBox(width: 10),
                  _buildFilterButton("Expense"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: mainFontColor,
                    ),
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

                final today = DateTime.now();
                final transactions = snapshot.data!.where((transaction) {
                  final transactionDate = transaction['date'] as DateTime;
                  return transactionDate.year == today.year &&
                      transactionDate.month == today.month &&
                      transactionDate.day == today.day;
                }).toList();

                if (transactions.isEmpty) {
                  return const Center(child: Text("No transactions for today"));
                }

                return Column(
                  children: transactions.map((transaction) {
                    return Dismissible(
                      key: Key(transaction['id']),
                      background: Container(
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Implement delete functionality here
                        // FirebaseFirestore.instance.collection('transactions').doc(transaction['id']).delete();
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

  Widget _buildFilterButton(String filter) {
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
          color: _selectedFilter == filter ? buttoncolor : white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: grey.withOpacity(0.03),
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
                  ? Colors.white
                  : Colors.black.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
      Size size, String category, String subtitle, String amount, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 10, left: 25, right: 25),
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
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: arrowbgColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(child: Icon(icon, color: mainFontColor)),
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
                            style: const TextStyle(
                              fontSize: 15,
                              color: black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: black.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: black,
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