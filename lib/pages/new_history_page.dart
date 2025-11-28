import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../services/game_service.dart';
import '../models/game_model.dart';

class NewHistoryPage extends StatelessWidget {
  const NewHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('History')),
            body: const Center(child: Text('Please sign in')),
          );
        }

        final gameService = GameService();

        return Scaffold(
          backgroundColor: const Color(0xFF0B1321),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C2942),
            title: const Text('Game History'),
          ),
          body: Column(
            children: [
              // Stats Summary
              FutureBuilder<Map<String, dynamic>>(
                future: gameService.getUserStats(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final stats = snapshot.data!;

                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1C2942), Color(0xFF2A4365)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Games',
                              value: stats['totalGames'].toString(),
                              icon: Icons.casino,
                            ),
                            _StatItem(
                              label: 'Win Rate',
                              value: '${stats['winRate'].toStringAsFixed(1)}%',
                              icon: Icons.trending_up,
                            ),
                            _StatItem(
                              label: 'Best',
                              value: '${stats['bestMultiplier'].toStringAsFixed(2)}x',
                              icon: Icons.emoji_events,
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Wagered',
                              value: 'KES ${stats['totalWagered'].toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              small: true,
                            ),
                            _StatItem(
                              label: 'Won',
                              value: 'KES ${stats['totalWon'].toStringAsFixed(0)}',
                              icon: Icons.money,
                              small: true,
                            ),
                            _StatItem(
                              label: 'Net',
                              value: 'KES ${stats['netProfit'].toStringAsFixed(0)}',
                              icon: Icons.account_balance,
                              small: true,
                              color: stats['netProfit'] >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Game History List
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Games',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<GameModel>>(
                  stream: gameService.watchUserGames(user.uid, limit: 50),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final games = snapshot.data!;

                    if (games.isEmpty) {
                      return const Center(
                        child: Text(
                          'No games played yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _GameTile(game: game);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool small;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.small = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.cyanAccent, size: small ? 20 : 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: small ? 14 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: small ? 10 : 12,
          ),
        ),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameModel game;

  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final isWin = game.isWin;
    final isCrashed = game.status == GameStatus.crashed;
    final isRefunded = game.status == GameStatus.refunded;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isRefunded) {
      statusColor = Colors.blueAccent;
      statusIcon = Icons.refresh;
      statusText = 'Refunded';
    } else if (isWin) {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle;
      statusText = 'Won';
    } else if (isCrashed) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel;
      statusText = 'Lost';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = 'Active';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2942),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(game.startedAt),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bet Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'KES ${game.betAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              if (game.cashoutMultiplier != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Cashout',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${game.cashoutMultiplier!.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isWin ? 'Won' : 'Crash Point',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    isWin
                        ? 'KES ${game.winAmount!.toStringAsFixed(2)}'
                        : '${game.crashPoint.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: isWin ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text(
              'Provably Fair Details',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            children: [
              _DetailRow('Game Hash', game.gameHash.substring(0, 32) + '...'),
              _DetailRow('Crash Point', '${game.crashPoint.toStringAsFixed(4)}x'),
              _DetailRow('Duration', '${game.duration}s'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
