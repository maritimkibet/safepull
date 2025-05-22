import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final VoidCallback toggleTheme;

  const HomePage({required this.toggleTheme, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SafePull Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: toggleTheme,
            tooltip: 'Toggle Theme',
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _HomeButton(icon: Icons.play_arrow, label: 'Play Game', route: '/game'),
          _HomeButton(icon: Icons.history, label: 'History', route: '/history'),
          _HomeButton(icon: Icons.account_balance_wallet, label: 'Wallet', route: '/wallet'),
          _HomeButton(icon: Icons.info, label: 'How it Works', route: '/how'),
          _HomeButton(icon: Icons.settings, label: 'Settings', route: '/settings'),
          _HomeButton(icon: Icons.person, label: 'Profile', route: '/profile'),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton.icon(
          icon: Icon(Icons.bar_chart),
          label: Text('View Results'),
          style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
          onPressed: () => Navigator.pushNamed(context, '/results'),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _HomeButton({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(12),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36),
          SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}


