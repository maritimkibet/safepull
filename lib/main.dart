import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'tabs_page.dart';
import 'firebase_options.dart'; // Make sure this file is generated with `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePull',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      navigatorObservers: <NavigatorObserver>[observer],
      home: TabsPage(analytics: analytics), // 👈 This is your landing screen
    );
  }
}
