const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function run() {
  const db = admin.firestore();
  const relapses = await db.collectionGroup('relapses').orderBy('timestamp', 'desc').limit(3).get();
  relapses.forEach(doc => {
    console.log(doc.id, doc.data());
  });
}
run().catch(console.error);
