const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin SDK
let firebaseApp;

const initializeFirebase = () => {
    if (!firebaseApp) {
        // For production, use service account key from environment
        if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);

            firebaseApp = admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
            });
        }
        // For development, use default credentials (if running on GCP)
        else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
            firebaseApp = admin.initializeApp({
                credential: admin.credential.applicationDefault(),
                projectId: process.env.FIREBASE_PROJECT_ID,
            });
        }
        // For local development with service account file
        else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH && fs.existsSync(path.join(__dirname, 'firebase-service-account.json'))) {
            try {
                const serviceAccount = require(path.join(__dirname, 'firebase-service-account.json'));

                firebaseApp = admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
                });
            } catch (error) {
                console.warn('Failed to initialize Firebase with service account file:', error.message);
                return null;
            }
        }
        else {
            console.warn('Firebase Admin SDK not initialized. Set FIREBASE_SERVICE_ACCOUNT_KEY, GOOGLE_APPLICATION_CREDENTIALS, or FIREBASE_SERVICE_ACCOUNT_PATH environment variable.');
            return null;
        }

        console.log('Firebase Admin SDK initialized successfully');
    }

    return firebaseApp;
};

// Get Firebase messaging instance
const getMessaging = () => {
    if (!firebaseApp) {
        initializeFirebase();
    }
    return firebaseApp ? admin.messaging() : null;
};

// Get Firebase Realtime Database instance
const getDatabase = () => {
    if (!firebaseApp) {
        initializeFirebase();
    }
    return firebaseApp ? admin.database() : null;
};

// Get FCM token for push notifications
const getFCMToken = () => {
    if (!firebaseApp) {
        initializeFirebase();
    }
    return firebaseApp ? admin.messaging() : null;
};

module.exports = {
    initializeFirebase,
    getMessaging,
    getDatabase,
    getFCMToken,
    admin,
};
