const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("Firebase Admin initialized successfully.");
} catch (error) {
  console.error("Failed to initialize Firebase Admin. Make sure you placed serviceAccountKey.json in this folder.");
  console.error(error);
  process.exit(1);
}

const db = admin.firestore();

console.log("Listening for new relapses...");

// We use collectionGroup to listen to all 'relapses' subcollections
db.collectionGroup('relapses').onSnapshot(snapshot => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === 'added') {
      const relapseData = change.doc.data();
      const relapseRef = change.doc.ref;
      
      // Check if we already processed this relapse to avoid duplicates on restart
      if (relapseData.notificationSent) {
        return;
      }

      // The document path is: users/{userId}/relapses/{relapseId}
      const userId = relapseRef.parent.parent.id;
      
      console.log(`New relapse detected for user: ${userId}`);

      try {
        // Find the user's companion
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.data();
        
        if (!userData || !userData.companionId) {
          console.log(`User ${userId} does not have a companion linked. Skipping notification.`);
          // Mark as processed anyway
          await relapseRef.update({ notificationSent: true });
          return;
        }
        
        const companionId = userData.companionId;
        
        // Find the companion's FCM Token
        const companionDoc = await db.collection('users').doc(companionId).get();
        const companionData = companionDoc.data();
        
        if (!companionData || !companionData.fcmToken) {
          console.log(`Companion ${companionId} does not have an FCM token. Skipping notification.`);
          await relapseRef.update({ notificationSent: true });
          return;
        }
        
        const fcmToken = companionData.fcmToken;
        
        // Prepare the notification message
        const message = {
          notification: {
            title: "BreakFree Alert 🚨",
            body: `Your companion just had a slip-up: ${relapseData.habitTitle}`
          },
          token: fcmToken,
        };
        
        // Send the push notification
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to companion: ${response}`);
        
        // Mark as processed
        await relapseRef.update({ notificationSent: true });
        
      } catch (error) {
        console.error(`Error sending push notification for relapse ${change.doc.id}:`, error);
      }
    }
  });
});
