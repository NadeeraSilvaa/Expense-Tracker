import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/pages/login_page.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _expenseLimitController = TextEditingController();
  Stream<List<String>>? _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = _getCategoriesStream();
  }

  Stream<List<String>> _getCategoriesStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['name'] as String).toList());
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a category name")),
      );
      return;
    }
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .add({'name': _categoryController.text.trim()});
        _categoryController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category added successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add category: $e")),
      );
    }
  }

  Future<void> _deleteCategory(String category) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$category'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          var snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('categories')
              .where('name', isEqualTo: category)
              .get();
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Category deleted successfully")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete category: $e")),
        );
      }
    }
  }

  Future<void> _setExpenseLimit() async {
    if (_expenseLimitController.text.trim().isEmpty ||
        double.tryParse(_expenseLimitController.text) == null ||
        double.parse(_expenseLimitController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid positive amount")),
      );
      return;
    }
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'expenseLimit': double.parse(_expenseLimitController.text)},
          SetOptions(merge: true),
        );
        _expenseLimitController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense limit set successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to set expense limit: $e")),
      );
    }
  }

  Future<void> _editName() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: "Enter new name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirm && _nameController.text.trim().isNotEmpty) {
      try {
        String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set(
            {'name': _nameController.text.trim()},
            SetOptions(merge: true),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Name updated successfully")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update name: $e")),
        );
      }
    } else if (confirm && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid name")),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    if (confirm) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
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
        title: Text(
          "Settings",
          style: TextStyle(
              color: AppColors.mainFontColor(themeProvider.isDarkMode),
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _editName(),
                  child: Container(
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
                      children: [
                        Icon(Icons.edit, color: AppColors.blue(themeProvider.isDarkMode)),
                        const SizedBox(width: 15),
                        Text(
                          "Edit Name",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainFontColor(themeProvider.isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainFontColor(themeProvider.isDarkMode),
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: AppColors.buttonColor(themeProvider.isDarkMode),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Category",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainFontColor(themeProvider.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          hintText: "Enter new category",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: AppColors.white(themeProvider.isDarkMode),
                        ),
                        style: TextStyle(
                          color: AppColors.black(themeProvider.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _addCategory,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.buttonColor(themeProvider.isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Add Category",
                              style: TextStyle(
                                color: AppColors.white(themeProvider.isDarkMode),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Categories",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainFontColor(themeProvider.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<String>>(
                        stream: _categoriesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          }
                          final categories = snapshot.data ?? [];
                          if (categories.isEmpty) {
                            return const Text("No custom categories");
                          }
                          return Column(
                            children: categories.map((category) {
                              return ListTile(
                                title: Text(
                                  category,
                                  style: TextStyle(
                                    color: AppColors.black(themeProvider.isDarkMode),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete,
                                      color: AppColors.red(themeProvider.isDarkMode)),
                                  onPressed: () => _deleteCategory(category),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Set Monthly Expense Limit",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainFontColor(themeProvider.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _expenseLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter monthly expense limit (LKR)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: AppColors.white(themeProvider.isDarkMode),
                        ),
                        style: TextStyle(
                          color: AppColors.black(themeProvider.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _setExpenseLimit,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.buttonColor(themeProvider.isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Set Limit",
                              style: TextStyle(
                                color: AppColors.white(themeProvider.isDarkMode),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _logout(context),
                  child: Container(
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
                      children: [
                        Icon(Icons.logout, color: AppColors.red(themeProvider.isDarkMode)),
                        const SizedBox(width: 15),
                        Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainFontColor(themeProvider.isDarkMode),
                          ),
                        ),
                      ],
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
}