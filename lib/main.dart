import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'pages/auth_page.dart';
import 'pages/new_game_page.dart';
import 'pages/new_wallet_page.dart';
import 'pages/new_history_page.dart';
import 'pages/new_settings_page.dart';
import 'pages/leaderboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'SafePull',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0B1321),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C2942),
          ),
        ),
        navigatorObservers: <NavigatorObserver>[observer],
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const AuthPage(),
          '/home': (context) => HomePage(analytics: analytics),
          '/game': (context) => NewGamePage(analytics: analytics),
          '/wallet': (context) => const NewWalletPage(),
          '/history': (context) => const NewHistoryPage(),
          '/settings': (context) => const NewSettingsPage(),
          '/leaderboard': (context) => const LeaderboardPage(),
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final FirebaseAnalytics analytics;
  
  const HomePage({super.key, required this.analytics});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      NewGamePage(analytics: widget.analytics),
      const NewHistoryPage(),
      const NewWalletPage(),
      const LeaderboardPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C2942),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/settings'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.settings, color: Colors.black),
      ),
    );
  }
}
