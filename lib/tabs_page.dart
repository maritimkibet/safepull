// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'game_page.dart';
import 'wallet_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class TabsPage extends StatefulWidget {
  final FirebaseAnalytics analytics;

  const TabsPage({super.key, required this.analytics});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;

  final List<String> _tabNames = [
    'Game',
    'Wallet',
    'History',
    'Profile',
    'Settings',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      GamePage(analytics: widget.analytics),
      const WalletPage(),
      HistoryPage(),
      const ProfilePage(),
      const SettingsPage(),
    ];
    _logTabSwitch(_currentIndex); // Log default tab
  }

  void _logTabSwitch(int index) {
    widget.analytics.logEvent(
      name: 'tab_switch',
      parameters: {
        'tab_name': _tabNames[index],
        'tab_index': index,
      },
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _logTabSwitch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).bottomAppBarColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Game'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

extension on ThemeData {
  get bottomAppBarColor => null;
}
