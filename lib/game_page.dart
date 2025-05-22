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
  List<FlSpot> _spots = [];
  List<String> _timestamps = [];
  double _currentX = 0;
  double _marketValue = 1.0;
  bool _isBetPlaced = false;
  bool _isGameRunning = false;
  Timer? _timer;
  Timer? _countdownTimer;
  int _countdownSeconds = 30;
  final Random _random = Random();

  final TextEditingController _betController = TextEditingController();
  double _betAmount = 0.0;
  double _wallet = 1000.0;

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await widget.analytics.logEvent(name: name, parameters: parameters);
  }

  void _startGame() async {
    if (_isGameRunning) return;

    final betInput = _betController.text.trim();
    final bet = double.tryParse(betInput);
    if (bet == null || bet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bet amount')),
      );
      return;
    }
    if (bet > _wallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance')),
      );
      return;
    }

    setState(() {
      _betAmount = bet;
      _wallet -= bet;
      _spots = [FlSpot(0, 1.0)];
      _timestamps = [_formattedTime()];
      _currentX = 0;
      _marketValue = 1.0;
      _isBetPlaced = true;
      _isGameRunning = true;
      _countdownSeconds = 30;
    });

    await _logEvent('game_start', parameters: {
      'bet_amount': _betAmount,
      'wallet_balance': _wallet,
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        double change = (_random.nextDouble() * 0.3) - 0.15;
        _marketValue += change;
        if (_marketValue < 0.5) _marketValue = 0.5;
        _currentX += 1;
        _spots.add(FlSpot(_currentX, _marketValue));
        _timestamps.add(_formattedTime());

        if (_spots.length > 20) {
          _spots.removeAt(0);
          _timestamps.removeAt(0);
          _spots = _spots.map((spot) => FlSpot(spot.x - 1, spot.y)).toList();
          _currentX -= 1;
        }

        if (_random.nextDouble() < 0.05) {
          _endGame(crashed: true);
        }
      });
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _endGame(crashed: true);
        }
      });
    });
  }

  void _endGame({bool crashed = false}) async {
    _timer?.cancel();
    _countdownTimer?.cancel();

    if (crashed) {
      await _logEvent('game_crash', parameters: {
        'lost_bet': _betAmount,
        'wallet_balance': _wallet,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsPage(
            wallet: _wallet,
            resultText: 'Game crashed! You lost your bet of KES ${_betAmount.toStringAsFixed(2)}.',
            isWin: false,
            analytics: widget.analytics,
          ),
        ),
      );
    } else {
      setState(() {
        _isGameRunning = false;
        _isBetPlaced = false;
        _spots = [];
        _timestamps = [];
        _marketValue = 1.0;
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
      _spots = [];
      _timestamps = [];
      _marketValue = 1.0;
    });

    await _logEvent('game_pull_out', parameters: {
      'bet_amount': _betAmount,
      'multiplier': _marketValue,
      'winnings': winnings,
      'wallet_balance': _wallet,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsPage(
          wallet: _wallet,
          resultText: 'You pulled out in time!\nWinnings: KES ${winnings.toStringAsFixed(2)}',
          isWin: true,
          analytics: widget.analytics,
        ),
      ),
    );
  }

  String _formattedTime() {
    return DateFormat.Hms().format(DateTime.now());
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: 0.2,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10),
            getDrawingVerticalLine: (_) => FlLine(color: Colors.white10),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white24),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot == _spots.last,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyanAccent.withAlpha((0.2 * 255).toInt()),
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
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMarketGraph(),
            const SizedBox(height: 20),
            if (_isGameRunning)
              Text(
                'Time Left: $_countdownSeconds seconds',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            const SizedBox(height: 10),
            if (!_isGameRunning)
              TextField(
                controller: _betController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Bet Amount (KES)',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.money, color: Colors.white70),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Start Game'),
                  ),
                if (_isGameRunning)
                  ElevatedButton(
                    onPressed: _pullOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Pull Out'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Stub for ResultsPage – replace this with your actual page if defined elsewhere.
class ResultsPage extends StatelessWidget {
  final double wallet;
  final String resultText;
  final bool isWin;
  final FirebaseAnalytics analytics;

  const ResultsPage({
    super.key,
    required this.wallet,
    required this.resultText,
    required this.isWin,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1321),
      appBar: AppBar(
        title: const Text('Game Result'),
        backgroundColor: const Color(0xFF1C2942),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isWin ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Wallet: KES ${wallet.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GamePage(analytics: analytics),
                    ),
                  );
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
