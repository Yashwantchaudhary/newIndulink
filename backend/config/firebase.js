const admin = require('firebase-admin');

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
        else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
            const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);

            firebaseApp = admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
            });
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