import 'package:flutter/material.dart';
import '../services/game_service.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameService = GameService();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1321),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2942),
        title: const Text('Leaderboard'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: gameService.getLeaderboard(limit: 20),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final leaderboard = snapshot.data!;

          if (leaderboard.isEmpty) {
            return const Center(
              child: Text(
                'No players yet',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final player = leaderboard[index];
              final rank = index + 1;

              Color rankColor;
              IconData? rankIcon;

              if (rank == 1) {
                rankColor = Colors.amber;
                rankIcon = Icons.emoji_events;
              } else if (rank == 2) {
                rankColor = Colors.grey[400]!;
                rankIcon = Icons.emoji_events;
              } else if (rank == 3) {
                rankColor = Colors.brown[300]!;
                rankIcon = Icons.emoji_events;
              } else {
                rankColor = Colors.white70;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2942),
                  borderRadius: BorderRadius.circular(12),
                  border: rank <= 3
                      ? Border.all(color: rankColor, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 40,
                      child: rankIcon != null
                          ? Icon(rankIcon, color: rankColor, size: 32)
                          : Text(
                              '$rank',
                              style: TextStyle(
                                color: rankColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Player Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _maskPhoneNumber(player['phoneNumber']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${player['gamesPlayed']} games played',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total Won
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KES ${player['totalWon'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total Won',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}';
  }
}
