# Changelog

All notable changes to SafePull are documented in this file.

## [2.0.0] - 2024-11-27 - Complete Overhaul

### 🎉 Major Features Added

#### Game System
- ✅ **Provably Fair Algorithm** - SHA-256 based crash point generation
- ✅ **Real-time Multiplier Graph** - Smooth 100ms updates with fl_chart
- ✅ **Enhanced Game UI** - Current multiplier, potential win display
- ✅ **Quick Bet Buttons** - 50, 100, 500 KES shortcuts
- ✅ **Sound Effects Support** - Audio player integration ready
- ✅ **Game Recovery** - Proper state management for interruptions

#### Wallet & Payments
- ✅ **Real Wallet System** - Firestore-backed persistent balances
- ✅ **M-Pesa STK Push** - Seamless deposit integration
- ✅ **M-Pesa B2C** - Automated withdrawal system
- ✅ **Transaction History** - Complete audit trail
- ✅ **Atomic Transactions** - Prevent race conditions
- ✅ **Daily Limits** - Configurable deposit/withdrawal limits
- ✅ **Minimum Thresholds** - 10 KES deposit, 100 KES withdrawal

#### Authentication
- ✅ **Phone Authentication** - Firebase Auth with OTP
- ✅ **Auto User Creation** - Seamless onboarding
- ✅ **Referral System** - 50 KES bonus for both parties
- ✅ **Session Management** - Persistent login state

#### Responsible Gambling
- ✅ **Self-Exclusion** - 24h, 7d, 30d, 90d options
- ✅ **Deposit Limits** - User-configurable daily limits
- ✅ **Withdrawal Limits** - Prevent excessive withdrawals
- ✅ **Limit Enforcement** - Checked at service layer

#### Social Features
- ✅ **Leaderboard** - Top 20 players by total winnings
- ✅ **User Statistics** - Win rate, net profit, best multiplier
- ✅ **Game History** - Detailed records with provably fair data
- ✅ **Referral Tracking** - Automatic bonus distribution

#### Backend
- ✅ **Enhanced Backend** - Firebase Admin SDK integration
- ✅ **Webhook Handling** - Automatic balance updates
- ✅ **Transaction Reconciliation** - Payment success/failure handling
- ✅ **Automatic Refunds** - Failed payment handling
- ✅ **Health Check Endpoint** - Monitoring support

#### Technical Improvements
- ✅ **State Management** - Provider pattern implementation
- ✅ **Real-time Updates** - Firestore streams
- ✅ **Error Handling** - Comprehensive error management
- ✅ **Analytics** - Firebase Analytics integration
- ✅ **Crash Reporting** - Firebase Crashlytics
- ✅ **Code Organization** - Services, models, providers separation

### 📦 Dependencies Added

#### Flutter
- `intl: ^0.19.0` - Date/time formatting
- `provider: ^6.1.1` - State management
- `crypto: ^3.0.3` - SHA-256 hashing
- `shared_preferences: ^2.2.2` - Local storage
- `firebase_crashlytics: ^4.1.3` - Error tracking
- `firebase_messaging: ^15.1.3` - Push notifications

#### Backend
- `firebase-admin: ^12.0.0` - Firestore server updates
- `cors: ^2.8.5` - CORS handling
- `nodemon: ^3.0.0` - Development auto-reload

### 🗂️ New Files Created

#### Models
- `lib/models/user_model.dart` - User data structure
- `lib/models/game_model.dart` - Game data structure
- `lib/models/transaction_model.dart` - Transaction data structure

#### Services
- `lib/services/auth_service.dart` - Authentication logic
- `lib/services/wallet_service.dart` - Wallet operations
- `lib/services/game_service.dart` - Game logic & provably fair
- `lib/services/mpesa_service.dart` - M-Pesa API integration

#### Providers
- `lib/providers/user_provider.dart` - User state management

#### Pages
- `lib/pages/auth_page.dart` - Login/signup interface
- `lib/pages/new_game_page.dart` - Enhanced game interface
- `lib/pages/new_wallet_page.dart` - Wallet management
- `lib/pages/new_history_page.dart` - Game history & stats
- `lib/pages/new_settings_page.dart` - Settings & responsible gambling
- `lib/pages/leaderboard_page.dart` - Top players leaderboard

#### Backend
- `backend/index-enhanced.js` - Enhanced backend with Firebase Admin
- `backend/firebase-admin-setup.js` - Firebase Admin initialization

#### Documentation
- `SETUP.md` - Detailed setup instructions
- `QUICKSTART.md` - Quick start guide
- `IMPLEMENTATION_SUMMARY.md` - Architecture overview
- `PRODUCTION_CHECKLIST.md` - Pre-launch checklist
- `CHANGELOG.md` - This file

### 🔧 Modified Files

- `pubspec.yaml` - Added new dependencies
- `lib/main.dart` - Complete rewrite with Provider integration
- `backend/index.js` - Enhanced M-Pesa callback handling
- `backend/package.json` - Added Firebase Admin SDK
- `.gitignore` - Added backend and sensitive file exclusions
- `README.md` - Complete rewrite with feature overview

### 🐛 Bug Fixes

- Fixed missing `intl` dependency causing game page errors
- Fixed deprecated `withOpacity` usage in game page
- Fixed const constructor issues in main.dart
- Removed unused imports in services
- Fixed transaction model enum parsing

### 🔒 Security Improvements

- Atomic Firestore transactions prevent race conditions
- Service layer validation for all operations
- Daily limit enforcement at database level
- Self-exclusion checks before game start
- Proper error handling without information leakage

### 📊 Database Schema

#### Users Collection
```
users/{userId}
  - phoneNumber, balance, stats
  - referralCode, referredBy
  - dailyDepositLimit, dailyWithdrawalLimit
  - isSelfExcluded, selfExclusionUntil
  - totalDeposited, totalWithdrawn, totalWagered, totalWon
```

#### Games Collection
```
games/{gameId}
  - userId, betAmount, crashPoint
  - gameHash, gameSeed (provably fair)
  - cashoutMultiplier, winAmount
  - status, startedAt, endedAt, duration
```

#### Transactions Collection
```
transactions/{transactionId}
  - userId, type, status, amount
  - balanceBefore, balanceAfter
  - mpesaReceiptNumber, mpesaTransactionId
  - gameId, description, metadata
```

### 🎯 Breaking Changes

- Complete rewrite of main.dart - old navigation won't work
- New authentication flow - users must sign in with phone
- Wallet system changed - hardcoded balance removed
- Game mechanics updated - provably fair system
- Backend API changed - new webhook endpoints

### 📝 Migration Notes

If upgrading from v1.0.0:
1. Users will need to sign in again
2. Old game history won't be preserved
3. Backend must be redeployed with new code
4. Firebase must be reconfigured
5. M-Pesa credentials must be updated

### 🚀 Performance Improvements

- Real-time updates via Firestore streams (no polling)
- Indexed queries for fast leaderboard
- Lazy loading for history (limit 50 games)
- Optimized graph rendering (100ms updates)
- Transaction batching where possible

### 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (limited - M-Pesa integration may not work)
- ❌ Desktop (not tested)

### 🔮 Future Enhancements

Planned for future releases:
- [ ] Multiple game modes (slow/medium/fast)
- [ ] Live chat between players
- [ ] Push notifications for deposits/withdrawals
- [ ] KYC verification system
- [ ] Customer support chat
- [ ] More payment methods
- [ ] Tournament mode
- [ ] Achievement system
- [ ] Daily bonuses

---

## [1.0.0] - Previous Version

### Initial Features
- Basic crash game mechanics
- Hardcoded wallet balance
- Simple UI with fl_chart
- M-Pesa integration (basic)
- Firebase setup

---

**Note**: This changelog follows [Keep a Changelog](https://keepachangelog.com/) format.
