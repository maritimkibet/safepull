import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> getUserWallet(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found');
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel> watchUserWallet(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  Future<bool> canDeposit(String userId, double amount) async {
    final user = await getUserWallet(userId);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayDeposits = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'deposit')
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    final totalDepositedToday = todayDeposits.docs.fold<double>(
      0.0,
      (sum, doc) => sum + ((doc.data()['amount'] ?? 0.0) as num).toDouble(),
    );

    return (totalDepositedToday + amount) <= user.dailyDepositLimit;
  }

  Future<bool> canWithdraw(String userId, double amount) async {
    final user = await getUserWallet(userId);

    if (user.balance < amount) return false;
    if (amount < 100) return false; // Minimum withdrawal 100 KES

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayWithdrawals = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'withdrawal')
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    final totalWithdrawnToday = todayWithdrawals.docs.fold<double>(
      0.0,
      (sum, doc) => sum + ((doc.data()['amount'] ?? 0.0) as num).toDouble(),
    );

    return (totalWithdrawnToday + amount) <= user.dailyWithdrawalLimit;
  }

  Future<TransactionModel> createDepositTransaction(
    String userId,
    double amount,
    String mpesaTransactionId,
  ) async {
    final user = await getUserWallet(userId);

    final transaction = TransactionModel(
      id: '',
      userId: userId,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      amount: amount,
      balanceBefore: user.balance,
      balanceAfter: user.balance,
      createdAt: DateTime.now(),
      mpesaTransactionId: mpesaTransactionId,
      description: 'M-Pesa deposit',
    );

    final docRef = await _firestore
        .collection('transactions')
        .add(transaction.toFirestore());

    return transaction.copyWith(id: docRef.id);
  }

  Future<void> completeDeposit(
    String transactionId,
    String mpesaReceiptNumber,
  ) async {
    await _firestore.runTransaction((txn) async {
      final transactionDoc = await txn.get(
        _firestore.collection('transactions').doc(transactionId),
      );

      if (!transactionDoc.exists) throw Exception('Transaction not found');

      final data = transactionDoc.data()!;
      final userId = data['userId'] as String;
      final amount = (data['amount'] as num).toDouble();

      final userDoc = await txn.get(_firestore.collection('users').doc(userId));
      if (!userDoc.exists) throw Exception('User not found');

      final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + amount;

      txn.update(_firestore.collection('users').doc(userId), {
        'balance': newBalance,
        'totalDeposited': FieldValue.increment(amount),
      });

      txn.update(_firestore.collection('transactions').doc(transactionId), {
        'status': 'completed',
        'balanceAfter': newBalance,
        'completedAt': FieldValue.serverTimestamp(),
        'mpesaReceiptNumber': mpesaReceiptNumber,
      });
    });
  }

  Future<TransactionModel> createWithdrawalTransaction(
    String userId,
    double amount,
  ) async {
    final user = await getUserWallet(userId);

    if (user.balance < amount) {
      throw Exception('Insufficient balance');
    }

    return await _firestore.runTransaction((txn) async {
      final userDoc = await txn.get(_firestore.collection('users').doc(userId));
      final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final newBalance = currentBalance - amount;

      txn.update(_firestore.collection('users').doc(userId), {
        'balance': newBalance,
      });

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        type: TransactionType.withdrawal,
        status: TransactionStatus.pending,
        amount: amount,
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
        createdAt: DateTime.now(),
        description: 'M-Pesa withdrawal',
      );

      final docRef = _firestore.collection('transactions').doc();
      txn.set(docRef, transaction.toFirestore());

      return transaction.copyWith(id: docRef.id);
    });
  }

  Future<void> completeWithdrawal(
    String transactionId,
    String mpesaReceiptNumber,
  ) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'mpesaReceiptNumber': mpesaReceiptNumber,
    });

    final transactionDoc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();
    final amount = (transactionDoc.data()?['amount'] ?? 0.0).toDouble();
    final userId = transactionDoc.data()?['userId'] as String;

    await _firestore.collection('users').doc(userId).update({
      'totalWithdrawn': FieldValue.increment(amount),
    });
  }

  Future<void> failTransaction(String transactionId, String reason) async {
    final transactionDoc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!transactionDoc.exists) return;

    final data = transactionDoc.data()!;
    final type = data['type'] as String;
    final userId = data['userId'] as String;
    final amount = (data['amount'] as num).toDouble();

    await _firestore.runTransaction((txn) async {
      // If withdrawal failed, refund the amount
      if (type == 'withdrawal') {
        final userDoc = await txn.get(_firestore.collection('users').doc(userId));
        final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();

        txn.update(_firestore.collection('users').doc(userId), {
          'balance': currentBalance + amount,
        });
      }

      txn.update(_firestore.collection('transactions').doc(transactionId), {
        'status': 'failed',
        'completedAt': FieldValue.serverTimestamp(),
        'metadata': {'failureReason': reason},
      });
    });
  }

  Stream<List<TransactionModel>> watchTransactions(String userId, {int limit = 50}) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }
}

extension on TransactionModel {
  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    DateTime? createdAt,
    DateTime? completedAt,
    String? mpesaReceiptNumber,
    String? mpesaTransactionId,
    String? gameId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      mpesaTransactionId: mpesaTransactionId ?? this.mpesaTransactionId,
      gameId: gameId ?? this.gameId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }
}
