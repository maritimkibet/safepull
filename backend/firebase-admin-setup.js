// Firebase Admin SDK Setup
// Place your service account key JSON file in this directory as 'serviceAccountKey.json'
// Download it from Firebase Console > Project Settings > Service Accounts

const admin = require('firebase-admin');

let firebaseInitialized = false;

function initializeFirebase() {
  if (firebaseInitialized) return admin;

  try {
    const serviceAccount = require('./serviceAccountKey.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    
    firebaseInitialized = true;
    console.log('✅ Firebase Admin initialized');
  } catch (error) {
    console.warn('⚠️  Firebase Admin not initialized:', error.message);
    console.warn('   M-Pesa callbacks will not update Firestore automatically');
  }

  return admin;
}

module.exports = { initializeFirebase, admin };
