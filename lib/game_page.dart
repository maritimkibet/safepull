import 'dart:async';
import 'dart:math';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GamePage extends StatefulWidget {
  final FirebaseAnalytics analytics;
  const GamePage({super.key, required this.analytics});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<FlSpot> _spots = [];
  final List<String> _timestamps = [];
  final TextEditingController _betController = TextEditingController();
  final Random _random = Random();

  Timer? _timer;
  Timer? _countdownTimer;

  double _wallet = 1000.0;
  double _betAmount = 0.0;
  double _marketValue = 1.0;
  double _currentX = 0;

  bool _isGameRunning = false;
  bool _isBetPlaced = false;

  int _countdownSeconds = 30;

  // Format current time
  String _formattedTime() => DateFormat.Hms().format(DateTime.now());

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await widget.analytics.logEvent(name: name, parameters: parameters);
  }

  void _startGame() async {
    final input = _betController.text.trim();
    final bet = double.tryParse(input);

    if (_isGameRunning || bet == null || bet <= 0 || bet > _wallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bet == null || bet <= 0
            ? 'Enter a valid bet amount'
            : 'Insufficient wallet balance')),
      );
      return;
    }

    setState(() {
      _betAmount = bet;
      _wallet -= bet;
      _marketValue = 1.0;
      _currentX = 0;
      _spots.clear();
      _timestamps.clear();
      _spots.add(FlSpot(0, _marketValue));
      _timestamps.add(_formattedTime());
      _isGameRunning = true;
      _isBetPlaced = true;
      _countdownSeconds = 30;
    });

    await _logEvent('game_start', parameters: {
      'bet_amount': _betAmount,
      'wallet_balance': _wallet,
    });

    _startTimers();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final change = (_random.nextDouble() * 0.3) - 0.15;
        _marketValue = max(0.5, _marketValue + change);
        _currentX += 1;

        _spots.add(FlSpot(_currentX, _marketValue));
        _timestamps.add(_formattedTime());

        if (_spots.length > 20) {
          _spots.removeAt(0);
          _timestamps.removeAt(0);
          _spots.setAll(0, _spots.map((e) => FlSpot(e.x - 1, e.y)));
          _currentX -= 1;
        }

        if (_random.nextDouble() < 0.05) {
          _endGame(crashed: true);
        }
      });
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds <= 0) {
          _endGame(crashed: true);
        }
      });
    });
  }

  void _endGame({required bool crashed}) async {
    _timer?.cancel();
    _countdownTimer?.cancel();

    if (crashed) {
      await _logEvent('game_crash', parameters: {
        'lost_bet': _betAmount,
        'wallet_balance': _wallet,
      });

      _showResult(
        success: false,
        message: 'Game crashed!\nYou lost your bet of KES ${_betAmount.toStringAsFixed(2)}.',
      );
    } else {
      setState(() {
        _isGameRunning = false;
        _isBetPlaced = false;
        _marketValue = 1.0;
        _spots.clear();
        _timestamps.clear();
      });
    }
  }

  void _pullOut() async {
    if (!_isBetPlaced || !_isGameRunning) return;

    _timer?.cancel();
    _countdownTimer?.cancel();

    final winnings = _betAmount * _marketValue;

    setState(() {
      _wallet += winnings;
      _isGameRunning = false;
      _isBetPlaced = false;
      _marketValue = 1.0;
      _spots.clear();
      _timestamps.clear();
    });

    await _logEvent('game_pull_out', parameters: {
      'bet_amount': _betAmount,
      'multiplier': _marketValue,
      'winnings': winnings,
      'wallet_balance': _wallet,
    });

    _showResult(
      success: true,
      message: 'You pulled out in time!\nWinnings: KES ${winnings.toStringAsFixed(2)}',
    );
  }

  void _showResult({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A40),
        title: Text(success ? 'Success' : 'Crashed',
            style: TextStyle(color: success ? Colors.greenAccent : Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildMarketGraph() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: 0.4,
          maxY: 2.0,
          gridData: FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index >= 0 && index < _timestamps.length) {
                    return Text(
                      _timestamps[index],
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.2,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot == _spots.last,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyanAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _betController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1321),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2942),
        title: const Text('SafePull Game'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                'Wallet: KES ${_wallet.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMarketGraph(),
            const SizedBox(height: 20),
            if (_isGameRunning)
              Text('Time Left: $_countdownSeconds s',
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            if (!_isGameRunning)
              TextField(
                controller: _betController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Enter Bet Amount (KES)',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.money, color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isGameRunning)
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Start Game'),
                  ),
                if (_isGameRunning)
                  ElevatedButton(
                    onPressed: _pullOut,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Pull Out'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
