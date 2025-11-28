# SafePull Setup Guide

## Overview
SafePull is a provably fair crash gambling game with M-Pesa integration for the Kenyan market.

## Features Implemented

### Core Features
- ✅ **Provably Fair Game System** - Cryptographic hash-based crash point generation
- ✅ **Real Wallet System** - Firestore-backed user balances with transaction history
- ✅ **M-Pesa Integration** - STK Push for deposits, B2C for withdrawals
- ✅ **Phone Authentication** - Firebase Auth with OTP verification
- ✅ **Transaction History** - Complete audit trail of all financial operations
- ✅ **Game History** - Detailed records with provably fair verification

### Responsible Gambling
- ✅ **Daily Deposit Limits** - Configurable per-user limits
- ✅ **Daily Withdrawal Limits** - Prevent excessive withdrawals
- ✅ **Self-Exclusion** - Users can temporarily block themselves (24h, 7d, 30d, 90d)
- ✅ **Minimum Limits** - Min deposit: 10 KES, Min withdrawal: 100 KES

### Social Features
- ✅ **Leaderboard** - Top players by total winnings
- ✅ **Referral System** - 50 KES bonus for both referrer and referee
- ✅ **User Stats** - Win rate, total wagered, net profit, best multiplier

### Technical Features
- ✅ **State Management** - Provider pattern for reactive UI
- ✅ **Real-time Updates** - Firestore streams for wallet and game updates
- ✅ **Analytics** - Firebase Analytics integration
- ✅ **Crash Reporting** - Firebase Crashlytics
- ✅ **Sound Effects** - Audio player integration (ready for sound files)

## Setup Instructions

### 1. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable the following services:
   - Authentication (Phone provider)
   - Firestore Database
   - Analytics
   - Crashlytics

3. Run FlutterFire CLI to configure:
```bash
cd safepull
flutterfire configure
```

4. Set up Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /games/{gameId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update: if request.auth.uid == resource.data.userId;
    }
    
    match /transactions/{transactionId} {
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### 2. M-Pesa Setup

1. Register for M-Pesa Daraja API at https://developer.safaricom.co.ke
2. Create an app and get your credentials
3. Update `backend/.env`:
```env
CONSUMER_KEY=your_consumer_key
CONSUMER_SECRET=your_consumer_secret
SHORTCODE=your_paybill_number
PASSKEY=your_passkey
CALLBACK_URL=https://your-domain.com/mpesaCallback

# For withdrawals (B2C)
B2C_SHORTCODE=your_b2c_shortcode
B2C_INITIATOR_NAME=your_initiator_name
B2C_SECURITY_CREDENTIAL=your_security_credential
B2C_COMMAND_ID=BusinessPayment
```

4. Install backend dependencies:
```bash
cd backend
npm install
```

5. Start the backend:
```bash
node index.js
```

### 3. Flutter App Setup

1. Install dependencies:
```bash
cd safepull
flutter pub get
```

2. Update backend URL in `lib/pages/new_wallet_page.dart`:
```dart
final MpesaService _mpesaService = MpesaService(
  backendUrl: 'https://your-backend-url.com', // Change this
);
```

3. Run the app:
```bash
flutter run
```

### 4. Optional: Add Sound Effects

Place sound files in `assets/sounds/`:
- `start.mp3` - Game start sound
- `cashout.mp3` - Successful cashout
- `crash.mp3` - Game crash sound

Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/sounds/
```

## Production Checklist

### Security
- [ ] Move from M-Pesa sandbox to production
- [ ] Set up proper Firebase security rules
- [ ] Enable App Check for API protection
- [ ] Implement rate limiting on backend
- [ ] Add request validation and sanitization
- [ ] Set up SSL/TLS for backend

### Legal & Compliance
- [ ] Obtain gambling license in Kenya
- [ ] Implement KYC verification for large transactions
- [ ] Add terms of service and privacy policy
- [ ] Implement age verification (18+)
- [ ] Set up customer support system
- [ ] Comply with data protection regulations

### Backend Improvements
- [ ] Set up Firebase Admin SDK for M-Pesa callbacks
- [ ] Implement webhook signature verification
- [ ] Add transaction reconciliation system
- [ ] Set up automated refunds for failed transactions
- [ ] Implement proper logging and monitoring
- [ ] Add database backups

### Testing
- [ ] Test M-Pesa integration thoroughly
- [ ] Load test the game system
- [ ] Test provably fair algorithm
- [ ] Verify transaction atomicity
- [ ] Test self-exclusion enforcement
- [ ] Test all edge cases

### Monitoring
- [ ] Set up Firebase Performance Monitoring
- [ ] Configure Crashlytics alerts
- [ ] Monitor M-Pesa transaction success rates
- [ ] Track user retention metrics
- [ ] Monitor wallet balance discrepancies

## Database Structure

### Users Collection
```
users/{userId}
  - phoneNumber: string
  - balance: number
  - createdAt: timestamp
  - lastActive: timestamp
  - isVerified: boolean
  - totalDeposited: number
  - totalWithdrawn: number
  - totalWagered: number
  - totalWon: number
  - gamesPlayed: number
  - referralCode: string
  - referredBy: string
  - dailyDepositLimit: number
  - dailyWithdrawalLimit: number
  - isSelfExcluded: boolean
  - selfExclusionUntil: timestamp
```

### Games Collection
```
games/{gameId}
  - userId: string
  - betAmount: number
  - cashoutMultiplier: number
  - winAmount: number
  - crashPoint: number
  - gameHash: string
  - gameSeed: string
  - status: string (active|completed|crashed|refunded)
  - startedAt: timestamp
  - endedAt: timestamp
  - duration: number
```

### Transactions Collection
```
transactions/{transactionId}
  - userId: string
  - type: string (deposit|withdrawal|bet|win|refund|referralBonus)
  - status: string (pending|completed|failed|cancelled)
  - amount: number
  - balanceBefore: number
  - balanceAfter: number
  - createdAt: timestamp
  - completedAt: timestamp
  - mpesaReceiptNumber: string
  - mpesaTransactionId: string
  - gameId: string
  - description: string
  - metadata: map
```

## Support

For issues or questions, contact: [your-email@example.com]

## License

Proprietary - All rights reserved
