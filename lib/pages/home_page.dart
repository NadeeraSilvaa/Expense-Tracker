import 'package:finance_app/pages/daily_page.dart';
import 'package:finance_app/pages/reports_page.dart';
import 'package:finance_app/pages/settings_page.dart';
import 'package:finance_app/pages/transaction_page.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/theme_provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DailyPage(),
    const TransactionPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary(themeProvider.isDarkMode),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_expense');
        },
        backgroundColor: AppColors.buttonColor(themeProvider.isDarkMode),
        child: Icon(Icons.add, color: AppColors.white(themeProvider.isDarkMode)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        selectedItemColor: AppColors.buttonColor(themeProvider.isDarkMode),
        unselectedItemColor: AppColors.grey(themeProvider.isDarkMode),
        backgroundColor: AppColors.white(themeProvider.isDarkMode),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.square_list,
              color: _currentIndex == 0
                  ? AppColors.buttonColor(themeProvider.isDarkMode)
                  : AppColors.grey(themeProvider.isDarkMode),
            ),
            label: 'Daily',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.compare_arrows_rounded,
              color: _currentIndex == 1
                  ? AppColors.buttonColor(themeProvider.isDarkMode)
                  : AppColors.grey(themeProvider.isDarkMode),
            ),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bar_chart,
              color: _currentIndex == 2
                  ? AppColors.buttonColor(themeProvider.isDarkMode)
                  : AppColors.grey(themeProvider.isDarkMode),
            ),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
              color: _currentIndex == 3
                  ? AppColors.buttonColor(themeProvider.isDarkMode)
                  : AppColors.grey(themeProvider.isDarkMode),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}