import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _category = 'Expense';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _categories = ['Expense', 'Income', 'Loan', 'Loan Payment'];

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
          'Expense',
          'Income',
          'Loan',
          'Loan Payment',
          ...snapshot.docs.map((doc) => doc['name'] as String)
        ];
        if (!_categories.contains(_category)) {
          _category = _categories[0];
        }
      });
    }
  }

  Future<void> _addExpense() async {
    if (_amount.text.isEmpty || _description.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }
    double? amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid positive amount")),
      );
      return;
    }
    setState(() => _isLoading = true);
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
          final userDoc = await transaction.get(userRef);
          double currentLoanBalance = userDoc.exists ? (userDoc.data()!['loanBalance']?.toDouble() ?? 0.0) : 0.0;
          double expenseLimit = userDoc.exists ? (userDoc.data()!['expenseLimit']?.toDouble() ?? double.infinity) : double.infinity;

          // Update loan balance for Loan or Loan Payment
          if (_category == 'Loan') {
            transaction.update(userRef, {'loanBalance': currentLoanBalance + amount});
          } else if (_category == 'Loan Payment') {
            if (currentLoanBalance < amount) {
              throw Exception("Payment exceeds current loan balance");
            }
            transaction.update(userRef, {'loanBalance': currentLoanBalance - amount});
          }

          // Check expense limit if category is Expense
          if (_category == 'Expense') {
            final now = DateTime.now();
            final firstDayOfMonth = DateTime(now.year, now.month, 1);
            final snapshot = await FirebaseFirestore.instance
                .collection('transactions')
                .where('userId', isEqualTo: uid)
                .where('category', isEqualTo: 'Expense')
                .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
                .get();
            double monthlyExpense = snapshot.docs.fold(
                0.0, (sum, doc) => sum + (doc['amount']?.toDouble() ?? 0.0));
            monthlyExpense += amount;
            if (monthlyExpense > expenseLimit) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Warning: Monthly expense limit of LKR $expenseLimit exceeded! Current: LKR ${monthlyExpense.toStringAsFixed(2)}")),
              );
            }
          }

          // Add transaction
          transaction.set(FirebaseFirestore.instance.collection('transactions').doc(), {
            'userId': uid,
            'amount': amount,
            'description': _description.text,
            'category': _category,
            'date': _selectedDate,
          });
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary(themeProvider.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.primary(themeProvider.isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: AppColors.black(themeProvider.isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Transaction",
          style: TextStyle(
              color: AppColors.mainFontColor(themeProvider.isDarkMode),
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildTextField("Amount", _amount, Icons.money, themeProvider.isDarkMode),
                const SizedBox(height: 20),
                _buildTextField("Description", _description, Icons.description, themeProvider.isDarkMode),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    value: _category,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _categories
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                    style: TextStyle(color: AppColors.black(themeProvider.isDarkMode)),
                    dropdownColor: AppColors.white(themeProvider.isDarkMode),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                        Text(
                          "Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}",
                          style: TextStyle(
                              fontSize: 16,
                              color: AppColors.black(themeProvider.isDarkMode)),
                        ),
                        Icon(Icons.calendar_today,
                            color: AppColors.black(themeProvider.isDarkMode)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                  onTap: _addExpense,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor(themeProvider.isDarkMode),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        "Add",
                        style: TextStyle(
                          color: AppColors.white(themeProvider.isDarkMode),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon, bool isDarkMode) {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.grey(isDarkMode).withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              cursorColor: AppColors.black(isDarkMode),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.black(isDarkMode),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.black(isDarkMode)),
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}