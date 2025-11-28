import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';

class NewSettingsPage extends StatefulWidget {
  const NewSettingsPage({super.key});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage> {
  final TextEditingController _depositLimitController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateDepositLimit() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final limit = double.tryParse(_depositLimitController.text.trim());
    if (limit == null || limit < 100) {
      _showError('Minimum limit is KES 100');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await userProvider.updateDepositLimit(limit);
      _showSuccess('Deposit limit updated');
      _depositLimitController.clear();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setSelfExclusion(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A40),
        title: const Text(
          'Self-Exclusion',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How long would you like to exclude yourself from playing?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _ExclusionButton(label: '24 Hours', days: 1),
            _ExclusionButton(label: '7 Days', days: 7),
            _ExclusionButton(label: '30 Days', days: 30),
            _ExclusionButton(label: '90 Days', days: 90),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    if (result != null) {
      final until = DateTime.now().add(Duration(days: result));
      await userProvider.updateSelfExclusion(true, until);
      _showSuccess('Self-exclusion activated until ${until.toString().substring(0, 16)}');
    }
  }

  Future<void> _removeSelfExclusion() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A40),
        title: const Text(
          'Remove Self-Exclusion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove self-exclusion? This will allow you to play immediately.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await userProvider.updateSelfExclusion(false, null);
      _showSuccess('Self-exclusion removed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(child: Text('Please sign in')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B1321),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C2942),
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Account Info
              const Text(
                'Account Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.phone,
                label: 'Phone Number',
                value: user.phoneNumber,
              ),
              _InfoCard(
                icon: Icons.verified_user,
                label: 'Verification Status',
                value: user.isVerified ? 'Verified' : 'Not Verified',
                valueColor: user.isVerified ? Colors.greenAccent : Colors.orange,
              ),
              _InfoCard(
                icon: Icons.card_giftcard,
                label: 'Referral Code',
                value: user.referralCode ?? 'N/A',
              ),
              const SizedBox(height: 24),

              // Responsible Gambling
              const Text(
                'Responsible Gambling',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Deposit Limit
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2942),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.cyanAccent),
                        const SizedBox(width: 12),
                        const Text(
                          'Daily Deposit Limit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: KES ${user.dailyDepositLimit.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _depositLimitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'New Limit (KES)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyanAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateDepositLimit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Update Limit'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Self-Exclusion
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2942),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user.isSelfExcluded ? Colors.redAccent : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.block,
                          color: user.isSelfExcluded ? Colors.redAccent : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Self-Exclusion',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.isSelfExcluded
                          ? 'Active until ${user.selfExclusionUntil?.toString().substring(0, 16) ?? "N/A"}'
                          : 'Take a break from gambling',
                      style: TextStyle(
                        color: user.isSelfExcluded ? Colors.redAccent : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: user.isSelfExcluded
                            ? _removeSelfExclusion
                            : () => _setSelfExclusion(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isSelfExcluded
                              ? Colors.green
                              : Colors.orange,
                        ),
                        child: Text(
                          user.isSelfExcluded
                              ? 'Remove Self-Exclusion'
                              : 'Activate Self-Exclusion',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await userProvider.signOut();
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('SIGN OUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _depositLimitController.dispose();
    super.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2942),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExclusionButton extends StatelessWidget {
  final String label;
  final int days;

  const _ExclusionButton({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, days),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A4365),
        ),
        child: Text(label),
      ),
    );
  }
}
