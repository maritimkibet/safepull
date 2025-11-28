import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus { active, completed, crashed, refunded }

class GameModel {
  final String id;
  final String userId;
  final double betAmount;
  final double? cashoutMultiplier;
  final double? winAmount;
  final double crashPoint;
  final String gameHash;
  final String gameSeed;
  final GameStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int duration; // in seconds

  GameModel({
    required this.id,
    required this.userId,
    required this.betAmount,
    this.cashoutMultiplier,
    this.winAmount,
    required this.crashPoint,
    required this.gameHash,
    required this.gameSeed,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration = 0,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      betAmount: (data['betAmount'] ?? 0.0).toDouble(),
      cashoutMultiplier: data['cashoutMultiplier']?.toDouble(),
      winAmount: data['winAmount']?.toDouble(),
      crashPoint: (data['crashPoint'] ?? 1.0).toDouble(),
      gameHash: data['gameHash'] ?? '',
      gameSeed: data['gameSeed'] ?? '',
      status: GameStatus.values.firstWhere(
        (e) => e.toString() == 'GameStatus.${data['status']}',
        orElse: () => GameStatus.active,
      ),
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      duration: data['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'betAmount': betAmount,
      'cashoutMultiplier': cashoutMultiplier,
      'winAmount': winAmount,
      'crashPoint': crashPoint,
      'gameHash': gameHash,
      'gameSeed': gameSeed,
      'status': status.toString().split('.').last,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
    };
  }

  bool get isWin => winAmount != null && winAmount! > betAmount;
}
