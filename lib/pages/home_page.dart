import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/pages/daily_page.dart';
import 'package:finance_app/pages/transaction_page.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:finance_app/pages/reports_page.dart';
import 'package:finance_app/pages/add_expense_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  final List<Widget> pages = [
    const DailyPage(),
    const TransactionPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: getBody(),
      bottomNavigationBar: getFooter(),
      floatingActionButton: SafeArea(
        child: SizedBox(
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddExpensePage()),
              );
            },
            child: const Icon(Icons.add, size: 20),
            backgroundColor: buttoncolor,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  Widget getFooter() {
    List<IconData> iconItems = [
      CupertinoIcons.home,
      CupertinoIcons.creditcard,
      CupertinoIcons.money_dollar,
      CupertinoIcons.person,
    ];
    return AnimatedBottomNavigationBar(
      backgroundColor: primary,
      icons: iconItems,
      splashColor: secondary,
      inactiveColor: black.withOpacity(0.5),
      gapLocation: GapLocation.center,
      activeIndex: pageIndex,
      notchSmoothness: NotchSmoothness.softEdge,
      leftCornerRadius: 10,
      iconSize: 25,
      rightCornerRadius: 10,
      elevation: 2,
      onTap: (index) {
        setTabs(index);
      },
    );
  }

  void setTabs(int index) {
    setState(() {
      pageIndex = index;
    });
  }
}