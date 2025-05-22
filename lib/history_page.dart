import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> history = [
    {
      'date': '2025-05-15 12:00',
      'result': 'Win',
      'crashPoint': 3.72,
      'earnings': 250.0,
    },
    {
      'date': '2025-05-14 18:45',
      'result': 'Loss',
      'crashPoint': 1.43,
      'earnings': -100.0,
    },
    {
      'date': '2025-05-13 20:30',
      'result': 'Win',
      'crashPoint': 2.95,
      'earnings': 180.0,
    },
  ];

  HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final entry = history[index];
          bool isWin = entry['result'] == 'Win';

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                isWin ? Icons.check_circle : Icons.cancel,
                color: isWin ? Colors.green : Colors.red,
                size: 32,
              ),
              title: Text('${entry['result']} - KES ${entry['earnings'].toStringAsFixed(2)}'),
              subtitle: Text('Crash at x${entry['crashPoint']} on ${entry['date']}'),
            ),
          );
        },
      ),
    );
  }
}
