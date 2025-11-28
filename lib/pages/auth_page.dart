import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    // Format phone number for Kenya
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+254${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+254$phone';
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await userProvider.signInWithPhone(formattedPhone);
    
    // In a real implementation, you'd get the verificationId from the provider
    // For now, we'll simulate it
    setState(() {
      _codeSent = true;
      _verificationId = 'simulated-verification-id';
    });
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty || otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showError('Please request OTP first');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final referralCode = _referralController.text.trim().isEmpty
        ? null
        : _referralController.text.trim();

    await userProvider.verifyOTP(_verificationId!, otp, referralCode);

    if (userProvider.error != null) {
      _showError(userProvider.error!);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1321),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to SafePull',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '0712345678',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.phone, color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: '123456',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.lock, color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _referralController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    hintText: 'Enter referral code',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.card_giftcard, color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: userProvider.isLoading
                          ? null
                          : (_codeSent ? _verifyOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              _codeSent ? 'VERIFY & SIGN IN' : 'SEND OTP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _verificationId = null;
                      _otpController.clear();
                    });
                  },
                  child: const Text(
                    'Change phone number',
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _referralController.dispose();
    super.dispose();
  }
}
