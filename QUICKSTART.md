# SafePull Quick Start Guide

Get SafePull running in 10 minutes (development mode).

## Prerequisites

- Flutter SDK 3.7.2+
- Node.js 16+
- Firebase account
- Code editor (VS Code recommended)

## Step 1: Firebase Setup (5 minutes)

1. Go to https://console.firebase.google.com
2. Create a new project called "SafePull"
3. Enable these services:
   - **Authentication** → Enable Phone provider
   - **Firestore Database** → Create database (start in test mode)
   - **Analytics** → Enable
   - **Crashlytics** → Enable

4. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

5. Configure Firebase:
```bash
cd safepull
flutterfire configure
```
Select your Firebase project and platforms (iOS, Android, Web).

## Step 2: Install Dependencies (2 minutes)

```bash
# Flutter dependencies
flutter pub get

# Backend dependencies
cd backend
npm install
cd ..
```

## Step 3: Backend Setup (2 minutes)

1. Create `backend/.env`:
```env
# M-Pesa Sandbox Credentials (get from https://developer.safaricom.co.ke)
CONSUMER_KEY=your_consumer_key_here
CONSUMER_SECRET=your_consumer_secret_here
SHORTCODE=174379
PASSKEY=your_passkey_here
CALLBACK_URL=http://localhost:3000/mpesaCallback

# B2C (Withdrawals)
B2C_SHORTCODE=600000
B2C_INITIATOR_NAME=testapi
B2C_SECURITY_CREDENTIAL=your_security_credential
B2C_COMMAND_ID=BusinessPayment

PORT=3000
```

2. Start the backend:
```bash
cd backend
node index.js
```

Keep this terminal open.

## Step 4: Run the App (1 minute)

Open a new terminal:

```bash
cd safepull
flutter run
```

Select your device (iOS Simulator, Android Emulator, or Chrome).

## Step 5: Test It Out

1. **Sign Up**: Enter a phone number (use +254... format for Kenya)
2. **Skip OTP** (in development, you can bypass this temporarily)
3. **Explore**: 
   - Check the wallet (starts at 0)
   - View the game page
   - Check settings

## Development Tips

### Testing Without M-Pesa

For development, you can manually add balance to test the game:

1. Open Firebase Console → Firestore
2. Find your user document in the `users` collection
3. Edit the `balance` field to add test money (e.g., 1000)
4. The app will update in real-time!

### Testing the Game

1. Add test balance (see above)
2. Go to the game page
3. Enter a bet amount (e.g., 50)
4. Click "START GAME"
5. Watch the multiplier rise
6. Click "CASH OUT" before it crashes!

### Viewing Data

Firebase Console → Firestore:
- `users` - User accounts and balances
- `games` - Game history
- `transactions` - All financial operations

## Common Issues

### "Firebase not initialized"
Run `flutterfire configure` again.

### "M-Pesa request failed"
Check your `.env` file has valid credentials. For testing, you can skip M-Pesa and manually add balance in Firestore.

### "Phone authentication not working"
Make sure Phone provider is enabled in Firebase Console → Authentication → Sign-in method.

### Backend not starting
Make sure port 3000 is free: `lsof -ti:3000 | xargs kill -9` (Mac/Linux)

## Next Steps

Once everything works:

1. **Read SETUP.md** for production deployment
2. **Get M-Pesa production credentials** from Safaricom
3. **Set up Firebase Admin SDK** for automatic balance updates
4. **Deploy backend** to a server (Heroku, Railway, DigitalOcean)
5. **Configure Firestore security rules** (see SETUP.md)
6. **Test thoroughly** before launching

## Quick Commands

```bash
# Run app
flutter run

# Run backend
cd backend && node index.js

# Check for errors
flutter analyze

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

## Support

- Check SETUP.md for detailed instructions
- Check IMPLEMENTATION_SUMMARY.md for architecture details
- Firebase docs: https://firebase.google.com/docs
- M-Pesa docs: https://developer.safaricom.co.ke

---

**Ready to build?** Start with Step 1 above! 🚀
