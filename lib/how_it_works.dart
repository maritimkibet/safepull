import 'package:flutter/material.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('How SafePull Works')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _SectionTitle('🎯 Objective'),
            _SectionText(
              'Your goal is to pull out before the market crashes. The longer you stay in, the higher your potential payout. But wait too long... and you lose everything!',
            ),
            SizedBox(height: 20),

            _SectionTitle('📈 Live Market'),
            _SectionText(
              'The graph keeps moving, showing rising values. These values are random and unpredictable, simulating a live, volatile market.',
            ),

            SizedBox(height: 20),
            _SectionTitle('💵 Placing a Bet'),
            _SectionText(
              'You choose your stake and enter the game. As the multiplier rises, your potential payout increases in real-time.',
            ),

            SizedBox(height: 20),
            _SectionTitle('🛑 Pulling Out'),
            _SectionText(
              'Cash out any time before the crash to secure your winnings. If you don’t pull out before the crash, you lose your bet.',
            ),

            SizedBox(height: 20),
            _SectionTitle('🧠 Strategy'),
            _SectionText(
              'Watch the graph carefully. Some players prefer early pulls with small profits, others risk it for bigger rewards. It’s all about timing and intuition.',
            ),

            SizedBox(height: 20),
            _SectionTitle('⚠️ Note'),
            _SectionText(
              'This game involves risk and is for entertainment. Please play responsibly and only stake what you can afford to lose.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }
}

