import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/user_provider.dart';
import '../services/game_service.dart';
import '../models/game_model.dart';

class NewGamePage extends StatefulWidget {
  final FirebaseAnalytics analytics;
  const NewGamePage({super.key, required this.analytics});

  @override
  State<NewGamePage> createState() => _NewGamePageState();
}

class _NewGamePageState extends State<NewGamePage> {
  final List<FlSpot> _spots = [];
  final List<String> _timestamps = [];
  final TextEditingController _betController = TextEditingController();
  final GameService _gameService = GameService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  GameModel? _currentGame;

  double _currentMultiplier = 1.0;
  double _currentX = 0;
  bool _isGameRunning = false;
  bool _isBetPlaced = false;
  bool _soundEnabled = true;

  String _formattedTime() => DateFormat.Hms().format(DateTime.now());

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await widget.analytics.logEvent(name: name, parameters: parameters);
  }

  void _playSound(String sound) {
    if (_soundEnabled) {
      // _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    }
  }

  void _startGame() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _showError('Please sign in to play');
      return;
    }

    final input = _betController.text.trim();
    final bet = double.tryParse(input);

    if (_isGameRunning || bet == null || bet <= 0) {
      _showError('Enter a valid bet amount');
      return;
    }

    if (bet > userProvider.user!.balance) {
      _showError('Insufficient balance');
      return;
    }

    if (userProvider.user!.isSelfExcluded) {
      _showError('Your account is self-excluded');
      return;
    }

    try {
      setState(() {
        _isGameRunning = true;
        _isBetPlaced = true;
      });

      _currentGame = await _gameService.startGame(userProvider.user!.uid, bet);

      setState(() {
        _currentMultiplier = 1.0;
        _currentX = 0;
        _spots.clear();
        _timestamps.clear();
        _spots.add(FlSpot(0, _currentMultiplier));
        _timestamps.add(_formattedTime());
      });

      await _logEvent('game_start', parameters: {
        'bet_amount': bet,
        'crash_point': _currentGame!.crashPoint,
        'game_hash': _currentGame!.gameHash,
      });

      _playSound('start');
      _startTimer();
    } catch (e) {
      setState(() {
        _isGameRunning = false;
        _isBetPlaced = false;
      });
      _showError(e.toString());
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _currentGame == null) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentX += 0.1;
        
        // Smooth multiplier growth
        final elapsed = _currentX;
        _currentMultiplier = 1.0 + (elapsed * 0.1);

        _spots.add(FlSpot(_currentX, _currentMultiplier));
        
        if (_currentX % 1 == 0) {
          _timestamps.add(_formattedTime());
        }

        if (_spots.length > 100) {
          _spots.removeAt(0);
          if (_timestamps.isNotEmpty) _timestamps.removeAt(0);
          _spots.setAll(0, _spots.map((e) => FlSpot(e.x - 0.1, e.y)));
          _currentX -= 0.1;
        }

        // Check if we've reached crash point
        if (_currentMultiplier >= _currentGame!.crashPoint) {
          _endGame(crashed: true);
        }
      });
    });
  }

  void _endGame({required bool crashed}) async {
    _timer?.cancel();

    if (crashed) {
      _playSound('crash');
      await _gameService.crashGame(_currentGame!.id);

      await _logEvent('game_crash', parameters: {
        'game_id': _currentGame!.id,
        'crash_point': _currentGame!.crashPoint,
        'lost_bet': _currentGame!.betAmount,
      });

      _showResult(
        success: false,
        message: 'Game crashed at ${_currentGame!.crashPoint.toStringAsFixed(2)}x!\n'
            'You lost KES ${_currentGame!.betAmount.toStringAsFixed(2)}',
      );
    }

    setState(() {
      _isGameRunning = false;
      _isBetPlaced = false;
      _currentGame = null;
      _spots.clear();
      _timestamps.clear();
    });
  }

  void _pullOut() async {
    if (!_isBetPlaced || !_isGameRunning || _currentGame == null) return;

    _timer?.cancel();

    try {
      final completedGame = await _gameService.cashout(
        _currentGame!.id,
        _currentMultiplier,
      );

      _playSound('cashout');

      await _logEvent('game_cashout', parameters: {
        'game_id': completedGame.id,
        'multiplier': _currentMultiplier,
        'bet_amount': completedGame.betAmount,
        'win_amount': completedGame.winAmount ?? 0.0,
      });

      setState(() {
        _isGameRunning = false;
        _isBetPlaced = false;
        _currentGame = null;
        _spots.clear();
        _timestamps.clear();
      });

      _showResult(
        success: true,
        message: 'Cashed out at ${_currentMultiplier.toStringAsFixed(2)}x!\n'
            'Winnings: KES ${completedGame.winAmount!.toStringAsFixed(2)}',
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showResult({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A40),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Success!' : 'Crashed!',
              style: TextStyle(
                color: success ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: Colors.white)),
            if (_currentGame != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                'Provably Fair',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hash: ${_currentGame!.gameHash.substring(0, 16)}...',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                'Crash: ${_currentGame!.crashPoint.toStringAsFixed(2)}x',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildMarketGraph() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGameRunning ? Colors.cyanAccent.withAlpha(100) : Colors.white24,
          width: 2,
        ),
      ),
      child: _spots.isEmpty
          ? Center(
              child: Text(
                'Place a bet to start',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : LineChart(
              LineChartData(
                minY: 0.8,
                maxY: _currentMultiplier + 1.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: _isGameRunning ? Colors.cyanAccent : Colors.grey,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot == _spots.last,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _isGameRunning
                          ? Colors.cyanAccent.withAlpha(50)
                          : Colors.grey.withAlpha(30),
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
    _betController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1321),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C2942),
            title: const Text('SafePull Game'),
            actions: [
              IconButton(
                icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
                onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'KES ${user?.balance.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_isGameRunning)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Current',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${_currentMultiplier.toStringAsFixed(2)}x',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Potential Win',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'KES ${(_currentGame!.betAmount * _currentMultiplier).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _buildMarketGraph(),
                const SizedBox(height: 20),
                if (!_isGameRunning) ...[
                  TextField(
                    controller: _betController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Bet Amount (KES)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.money, color: Colors.white70),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _betController.text = '50',
                            child: const Text('50'),
                          ),
                          TextButton(
                            onPressed: () => _betController.text = '100',
                            child: const Text('100'),
                          ),
                          TextButton(
                            onPressed: () => _betController.text = '500',
                            child: const Text('500'),
                          ),
                        ],
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: user != null ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        user != null ? 'START GAME' : 'SIGN IN TO PLAY',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isGameRunning) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _pullOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CASH OUT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
