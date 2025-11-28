import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { deposit, withdrawal, bet, win, refund, referralBonus }

enum TransactionStatus { pending, completed, failed, cancelled }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? mpesaReceiptNumber;
  final String? mpesaTransactionId;
  final String? gameId;
  final String? description;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    this.completedAt,
    this.mpesaReceiptNumber,
    this.mpesaTransactionId,
    this.gameId,
    this.description,
    this.metadata,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.bet,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      balanceBefore: (data['balanceBefore'] ?? 0.0).toDouble(),
      balanceAfter: (data['balanceAfter'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      mpesaReceiptNumber: data['mpesaReceiptNumber'],
      mpesaTransactionId: data['mpesaTransactionId'],
      gameId: data['gameId'],
      description: data['description'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'mpesaTransactionId': mpesaTransactionId,
      'gameId': gameId,
      'description': description,
      'metadata': metadata,
    };
  }
}
