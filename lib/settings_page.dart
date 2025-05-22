import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final Function()? onThemeToggle;
  final bool initialDarkMode;

  const SettingsPage({
    super.key,
    this.onThemeToggle,
    this.initialDarkMode = false,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.initialDarkMode;
  }

  void _onToggle(bool value) {
    setState(() => _darkMode = value);
    if (widget.onThemeToggle != null) {
      widget.onThemeToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Toggle between light and dark themes'),
            value: _darkMode,
            onChanged: _onToggle,
            secondary: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About SafePull'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SafePull',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 SafePull Inc.',
                children: [
                  Text('SafePull is a game that simulates a volatile market. Play responsibly.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


