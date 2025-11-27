// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyAUOsqAjjeK_9TrO2HGdLq5xUdEzVirKm4",
  authDomain: "indulink-b2b.firebaseapp.com",
  projectId: "indulink-b2b",
  storageBucket: "indulink-b2b.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:android:abcdef123456"
});

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});