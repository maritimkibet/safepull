# SafePull - Provably Fair Crash Game

A production-ready Flutter gambling application with M-Pesa integration for the Kenyan market.

## 🎮 What is SafePull?

SafePull is a crash gambling game where players bet on a rising multiplier and must cash out before it crashes. The longer you wait, the higher the potential payout - but crash too late and you lose everything.

### Key Features

#### 🎲 Core Gaming
- **Provably Fair System** - Cryptographic hash-based crash point generation that players can verify
- **Real-time Multiplier** - Smooth, animated multiplier growth with live graph
- **Instant Cashout** - Cash out at any time before the crash
- **Game History** - Complete record of all games with provably fair verification

#### 💰 Wallet & Payments
- **M-Pesa Integration** - Seamless deposits via STK Push and withdrawals via B2C
- **Real-time Balance** - Firestore-backed wallet with instant updates
- **Transaction History** - Complete audit trail of all financial operations
- **Daily Limits** - Configurable deposit and withdrawal limits

#### 🛡️ Responsible Gambling
- **Self-Exclusion** - Temporarily block yourself (24h, 7d, 30d, 90d)
- **Deposit Limits** - Set your own daily deposit limits
- **Withdrawal Limits** - Prevent excessive withdrawals
- **Minimum Thresholds** - Min deposit: 10 KES, Min withdrawal: 100 KES

#### 👥 Social Features
- **Leaderboard** - Top players by total winnings
- **Referral System** - Earn 50 KES for each friend you invite
- **User Stats** - Track win rate, total wagered, net profit, best multiplier

#### 🔐 Security & Auth
- **Phone Authentication** - Firebase Auth with OTP verification
- **Secure Transactions** - Atomic Firestore transactions prevent race conditions
- **Crash Reporting** - Firebase Crashlytics for error tracking
- **Analytics** - Firebase Analytics for user behavior insights

## 📱 Screenshots

[Add screenshots here]

## 🚀 Quick Start

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Prerequisites
- Flutter SDK (3.7.2+)
- Firebase account
- M-Pesa Daraja API credentials
- Node.js (for backend)

### Installation

1. Clone the repository
2. Set up Firebase (see SETUP.md)
3. Configure M-Pesa credentials
4. Install dependencies:
```bash
flutter pub get
cd backend && npm install
```
5. Run the backend:
```bash
cd backend && node index-enhanced.js
```
6. Run the app:
```bash
flutter run
```

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Provider pattern
- **Database**: Cloud Firestore with real-time streams
- **Authentication**: Firebase Auth (Phone)
- **Analytics**: Firebase Analytics & Crashlytics

### Backend (Node.js/Express)
- **M-Pesa Integration**: STK Push & B2C APIs
- **Database Updates**: Firebase Admin SDK
- **Webhooks**: M-Pesa callback handling

### Database Structure
```
users/
  - balance, stats, limits, self-exclusion
games/
  - bet details, crash points, provably fair data
transactions/
  - deposits, withdrawals, bets, wins, refunds
```

## 🎯 Provably Fair Algorithm

Each game generates a unique seed that determines the crash point:
1. Generate random seed
2. Hash seed with SHA-256
3. Convert hash to crash multiplier (1.0x - 100.0x)
4. Players can verify the hash matches the crash point

## 📊 Features Implemented

✅ Provably fair game system  
✅ Real wallet with Firestore  
✅ M-Pesa deposits & withdrawals  
✅ Phone authentication  
✅ Transaction history  
✅ Game history  
✅ Leaderboard  
✅ Referral system  
✅ Self-exclusion  
✅ Daily limits  
✅ User statistics  
✅ Real-time updates  
✅ Analytics & crash reporting  

## ⚠️ Production Checklist

Before launching:
- [ ] Obtain gambling license
- [ ] Move M-Pesa from sandbox to production
- [ ] Implement KYC verification
- [ ] Add terms of service & privacy policy
- [ ] Set up customer support
- [ ] Enable Firebase App Check
- [ ] Configure proper security rules
- [ ] Set up monitoring & alerts
- [ ] Load test the system
- [ ] Legal compliance review

## 📄 License

Proprietary - All rights reserved

## 🤝 Support

For issues or questions, contact: [your-email@example.com]

## ⚖️ Legal Notice

This is gambling software. Ensure you have proper licensing and comply with all local regulations before deploying. Gambling can be addictive - please gamble responsibly.
