import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        verificationFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserModel> getOrCreateUser(String? referredByCode) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      return UserModel.fromFirestore(userDoc);
    }

    // Create new user
    final referralCode = _generateReferralCode();
    final newUser = UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      referralCode: referralCode,
      referredBy: referredByCode,
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());

    // Give referral bonus if applicable
    if (referredByCode != null) {
      await _giveReferralBonus(referredByCode, user.uid);
    }

    return newUser;
  }

  Future<void> _giveReferralBonus(String referralCode, String newUserId) async {
    try {
      final referrerQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (referrerQuery.docs.isNotEmpty) {
        final referrerId = referrerQuery.docs.first.id;
        const bonusAmount = 50.0; // KES 50 bonus

        await _firestore.runTransaction((transaction) async {
          final referrerDoc = await transaction.get(
            _firestore.collection('users').doc(referrerId),
          );

          if (referrerDoc.exists) {
            final currentBalance = (referrerDoc.data()?['balance'] ?? 0.0).toDouble();
            transaction.update(
              _firestore.collection('users').doc(referrerId),
              {'balance': currentBalance + bonusAmount},
            );

            // Create transaction record
            transaction.set(
              _firestore.collection('transactions').doc(),
              {
                'userId': referrerId,
                'type': 'referralBonus',
                'status': 'completed',
                'amount': bonusAmount,
                'balanceBefore': currentBalance,
                'balanceAfter': currentBalance + bonusAmount,
                'createdAt': FieldValue.serverTimestamp(),
                'completedAt': FieldValue.serverTimestamp(),
                'description': 'Referral bonus for inviting new user',
                'metadata': {'referredUserId': newUserId},
              },
            );
          }
        });
      }
    } catch (e) {
      print('Error giving referral bonus: $e');
    }
  }

  Future<void> updateLastActive() async {
    final user = currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
