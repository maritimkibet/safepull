import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  UserProvider() {
    _authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadUser();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUser() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _user = await _walletService.getUserWallet(firebaseUser.uid);
        _watchUserUpdates();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _watchUserUpdates() {
    if (_user != null) {
      _walletService.watchUserWallet(_user!.uid).listen((updatedUser) {
        _user = updatedUser;
        notifyListeners();
      });
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (verificationId) {
          _isLoading = false;
          notifyListeners();
        },
        verificationFailed: (error) {
          _error = error;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP(String verificationId, String smsCode, String? referralCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _user = await _authService.getOrCreateUser(referralCode);
      _watchUserUpdates();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateSelfExclusion(bool exclude, DateTime? until) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'isSelfExcluded': exclude,
        'selfExclusionUntil': until != null ? Timestamp.fromDate(until) : null,
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDepositLimit(double limit) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'dailyDepositLimit': limit,
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
