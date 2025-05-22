import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  final List<Map<String, dynamic>> results = [
    {'date': '2025-05-15', 'crashPoint': 3.72, 'winnerCount': 15},
    {'date': '2025-05-14', 'crashPoint': 1.43, 'winnerCount': 8},
    {'date': '2025-05-13', 'crashPoint': 2.95, 'winnerCount': 12},
    {'date': '2025-05-12', 'crashPoint': 1.20, 'winnerCount': 5},
  ];

  ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Results')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final item = results[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
              title: Text('Crash Point: x${item['crashPoint']}'),
              subtitle: Text('Date: ${item['date']}'),
              trailing: Text('${item['winnerCount']} winners'),
            ),
          );
        },
      ),
    );
  }
}

