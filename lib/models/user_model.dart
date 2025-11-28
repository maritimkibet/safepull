import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final double balance;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isVerified;
  final double totalDeposited;
  final double totalWithdrawn;
  final double totalWagered;
  final double totalWon;
  final int gamesPlayed;
  final String? referralCode;
  final String? referredBy;
  final double dailyDepositLimit;
  final double dailyWithdrawalLimit;
  final bool isSelfExcluded;
  final DateTime? selfExclusionUntil;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.balance = 0.0,
    required this.createdAt,
    required this.lastActive,
    this.isVerified = false,
    this.totalDeposited = 0.0,
    this.totalWithdrawn = 0.0,
    this.totalWagered = 0.0,
    this.totalWon = 0.0,
    this.gamesPlayed = 0,
    this.referralCode,
    this.referredBy,
    this.dailyDepositLimit = 10000.0,
    this.dailyWithdrawalLimit = 50000.0,
    this.isSelfExcluded = false,
    this.selfExclusionUntil,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      totalDeposited: (data['totalDeposited'] ?? 0.0).toDouble(),
      totalWithdrawn: (data['totalWithdrawn'] ?? 0.0).toDouble(),
      totalWagered: (data['totalWagered'] ?? 0.0).toDouble(),
      totalWon: (data['totalWon'] ?? 0.0).toDouble(),
      gamesPlayed: data['gamesPlayed'] ?? 0,
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
      dailyDepositLimit: (data['dailyDepositLimit'] ?? 10000.0).toDouble(),
      dailyWithdrawalLimit: (data['dailyWithdrawalLimit'] ?? 50000.0).toDouble(),
      isSelfExcluded: data['isSelfExcluded'] ?? false,
      selfExclusionUntil: data['selfExclusionUntil'] != null
          ? (data['selfExclusionUntil'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isVerified': isVerified,
      'totalDeposited': totalDeposited,
      'totalWithdrawn': totalWithdrawn,
      'totalWagered': totalWagered,
      'totalWon': totalWon,
      'gamesPlayed': gamesPlayed,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'dailyDepositLimit': dailyDepositLimit,
      'dailyWithdrawalLimit': dailyWithdrawalLimit,
      'isSelfExcluded': isSelfExcluded,
      'selfExclusionUntil': selfExclusionUntil != null
          ? Timestamp.fromDate(selfExclusionUntil!)
          : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    double? balance,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isVerified,
    double? totalDeposited,
    double? totalWithdrawn,
    double? totalWagered,
    double? totalWon,
    int? gamesPlayed,
    String? referralCode,
    String? referredBy,
    double? dailyDepositLimit,
    double? dailyWithdrawalLimit,
    bool? isSelfExcluded,
    DateTime? selfExclusionUntil,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      totalWagered: totalWagered ?? this.totalWagered,
      totalWon: totalWon ?? this.totalWon,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      dailyDepositLimit: dailyDepositLimit ?? this.dailyDepositLimit,
      dailyWithdrawalLimit: dailyWithdrawalLimit ?? this.dailyWithdrawalLimit,
      isSelfExcluded: isSelfExcluded ?? this.isSelfExcluded,
      selfExclusionUntil: selfExclusionUntil ?? this.selfExclusionUntil,
    );
  }
}
