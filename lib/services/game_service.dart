import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/game_model.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Provably fair crash point generation
  double generateCrashPoint(String seed) {
    final hash = sha256.convert(utf8.encode(seed)).toString();
    final hex = hash.substring(0, 8);
    final intValue = int.parse(hex, radix: 16);
    
    // Use house edge of 2%
    final result = (intValue / 0xFFFFFFFF) * 0.98;
    
    if (result < 0.01) return 1.0;
    
    return (99 / (1 - result)).clamp(1.0, 100.0);
  }

  String generateGameSeed() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString() + DateTime.now().microsecond.toString();
    return sha256.convert(utf8.encode(random)).toString();
  }

  String generateGameHash(String seed) {
    return sha256.convert(utf8.encode(seed)).toString();
  }

  Future<GameModel> startGame(String userId, double betAmount) async {
    return await _firestore.runTransaction((txn) async {
      // Check user balance
      final userDoc = await txn.get(_firestore.collection('users').doc(userId));
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final currentBalance = (userData['balance'] ?? 0.0).toDouble();

      if (currentBalance < betAmount) {
        throw Exception('Insufficient balance');
      }

      // Check self-exclusion
      final isSelfExcluded = userData['isSelfExcluded'] ?? false;
      if (isSelfExcluded) {
        final exclusionUntil = userData['selfExclusionUntil'] as Timestamp?;
        if (exclusionUntil != null && exclusionUntil.toDate().isAfter(DateTime.now())) {
          throw Exception('Account is self-excluded until ${exclusionUntil.toDate()}');
        }
      }

      // Deduct bet amount
      final newBalance = currentBalance - betAmount;
      txn.update(_firestore.collection('users').doc(userId), {
        'balance': newBalance,
        'totalWagered': FieldValue.increment(betAmount),
        'gamesPlayed': FieldValue.increment(1),
      });

      // Create bet transaction
      final betTransactionRef = _firestore.collection('transactions').doc();
      txn.set(betTransactionRef, {
        'userId': userId,
        'type': 'bet',
        'status': 'completed',
        'amount': betAmount,
        'balanceBefore': currentBalance,
        'balanceAfter': newBalance,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'description': 'Game bet',
      });

      // Generate provably fair game
      final gameSeed = generateGameSeed();
      final gameHash = generateGameHash(gameSeed);
      final crashPoint = generateCrashPoint(gameSeed);

      final game = GameModel(
        id: '',
        userId: userId,
        betAmount: betAmount,
        crashPoint: crashPoint,
        gameHash: gameHash,
        gameSeed: gameSeed,
        status: GameStatus.active,
        startedAt: DateTime.now(),
      );

      final gameRef = _firestore.collection('games').doc();
      txn.set(gameRef, game.toFirestore());

      // Update bet transaction with gameId
      txn.update(betTransactionRef, {'gameId': gameRef.id});

      return game.copyWith(id: gameRef.id);
    });
  }

  Future<GameModel> cashout(String gameId, double multiplier) async {
    return await _firestore.runTransaction((txn) async {
      final gameDoc = await txn.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) throw Exception('Game not found');

      final gameData = gameDoc.data()!;
      final userId = gameData['userId'] as String;
      final betAmount = (gameData['betAmount'] as num).toDouble();
      final crashPoint = (gameData['crashPoint'] as num).toDouble();
      final startedAt = (gameData['startedAt'] as Timestamp).toDate();

      // Verify multiplier is valid
      if (multiplier > crashPoint) {
        throw Exception('Cannot cashout after crash point');
      }

      final winAmount = betAmount * multiplier;
      final duration = DateTime.now().difference(startedAt).inSeconds;

      // Update game
      txn.update(_firestore.collection('games').doc(gameId), {
        'cashoutMultiplier': multiplier,
        'winAmount': winAmount,
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
        'duration': duration,
      });

      // Update user balance
      final userDoc = await txn.get(_firestore.collection('users').doc(userId));
      final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + winAmount;

      txn.update(_firestore.collection('users').doc(userId), {
        'balance': newBalance,
        'totalWon': FieldValue.increment(winAmount),
      });

      // Create win transaction
      txn.set(_firestore.collection('transactions').doc(), {
        'userId': userId,
        'type': 'win',
        'status': 'completed',
        'amount': winAmount,
        'balanceBefore': currentBalance,
        'balanceAfter': newBalance,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'gameId': gameId,
        'description': 'Game win (${multiplier.toStringAsFixed(2)}x)',
        'metadata': {
          'multiplier': multiplier,
          'betAmount': betAmount,
        },
      });

      return GameModel.fromFirestore(gameDoc).copyWith(
        cashoutMultiplier: multiplier,
        winAmount: winAmount,
        status: GameStatus.completed,
        endedAt: DateTime.now(),
        duration: duration,
      );
    });
  }

  Future<void> crashGame(String gameId) async {
    await _firestore.runTransaction((txn) async {
      final gameDoc = await txn.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) return;

      final gameData = gameDoc.data()!;
      final startedAt = (gameData['startedAt'] as Timestamp).toDate();
      final duration = DateTime.now().difference(startedAt).inSeconds;

      txn.update(_firestore.collection('games').doc(gameId), {
        'status': 'crashed',
        'endedAt': FieldValue.serverTimestamp(),
        'duration': duration,
      });
    });
  }

  Future<void> refundGame(String gameId, String reason) async {
    await _firestore.runTransaction((txn) async {
      final gameDoc = await txn.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) throw Exception('Game not found');

      final gameData = gameDoc.data()!;
      final userId = gameData['userId'] as String;
      final betAmount = (gameData['betAmount'] as num).toDouble();

      // Update game status
      txn.update(_firestore.collection('games').doc(gameId), {
        'status': 'refunded',
        'endedAt': FieldValue.serverTimestamp(),
      });

      // Refund user
      final userDoc = await txn.get(_firestore.collection('users').doc(userId));
      final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + betAmount;

      txn.update(_firestore.collection('users').doc(userId), {
        'balance': newBalance,
        'totalWagered': FieldValue.increment(-betAmount),
        'gamesPlayed': FieldValue.increment(-1),
      });

      // Create refund transaction
      txn.set(_firestore.collection('transactions').doc(), {
        'userId': userId,
        'type': 'refund',
        'status': 'completed',
        'amount': betAmount,
        'balanceBefore': currentBalance,
        'balanceAfter': newBalance,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'gameId': gameId,
        'description': 'Game refund: $reason',
      });
    });
  }

  Stream<List<GameModel>> watchUserGames(String userId, {int limit = 20}) {
    return _firestore
        .collection('games')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList());
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final user = await _firestore.collection('users').doc(userId).get();
    if (!user.exists) throw Exception('User not found');

    final userData = user.data()!;

    final games = await _firestore
        .collection('games')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['completed', 'crashed'])
        .get();

    final wins = games.docs.where((doc) {
      final winAmount = doc.data()['winAmount'];
      final betAmount = doc.data()['betAmount'];
      return winAmount != null && winAmount > betAmount;
    }).length;

    final losses = games.docs.length - wins;
    final winRate = games.docs.isEmpty ? 0.0 : (wins / games.docs.length) * 100;

    final biggestWin = games.docs.fold<double>(0.0, (max, doc) {
      final winAmount = (doc.data()['winAmount'] ?? 0.0).toDouble();
      final betAmount = (doc.data()['betAmount'] ?? 0.0).toDouble();
      final profit = winAmount - betAmount;
      return profit > max ? profit : max;
    });

    final bestMultiplier = games.docs.fold<double>(0.0, (max, doc) {
      final multiplier = (doc.data()['cashoutMultiplier'] ?? 0.0).toDouble();
      return multiplier > max ? multiplier : max;
    });

    return {
      'totalGames': userData['gamesPlayed'] ?? 0,
      'wins': wins,
      'losses': losses,
      'winRate': winRate,
      'totalWagered': userData['totalWagered'] ?? 0.0,
      'totalWon': userData['totalWon'] ?? 0.0,
      'netProfit': (userData['totalWon'] ?? 0.0) - (userData['totalWagered'] ?? 0.0),
      'biggestWin': biggestWin,
      'bestMultiplier': bestMultiplier,
    };
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final users = await _firestore
        .collection('users')
        .orderBy('totalWon', descending: true)
        .limit(limit)
        .get();

    return users.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': doc.id,
        'phoneNumber': data['phoneNumber'] ?? 'Anonymous',
        'totalWon': data['totalWon'] ?? 0.0,
        'gamesPlayed': data['gamesPlayed'] ?? 0,
      };
    }).toList();
  }
}

extension on GameModel {
  GameModel copyWith({
    String? id,
    String? userId,
    double? betAmount,
    double? cashoutMultiplier,
    double? winAmount,
    double? crashPoint,
    String? gameHash,
    String? gameSeed,
    GameStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
  }) {
    return GameModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      betAmount: betAmount ?? this.betAmount,
      cashoutMultiplier: cashoutMultiplier ?? this.cashoutMultiplier,
      winAmount: winAmount ?? this.winAmount,
      crashPoint: crashPoint ?? this.crashPoint,
      gameHash: gameHash ?? this.gameHash,
      gameSeed: gameSeed ?? this.gameSeed,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }
}
