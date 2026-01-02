const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Scheduled function to run daily and send expiry notifications to device tokens or topics
// Deploy with: firebase deploy --only functions
exports.dailyExpiryCheck = functions.pubsub.schedule('0 9 * * *')
  .timeZone('Asia/Jakarta')
  .onRun(async (context) => {
    try {
      const now = new Date();
      const sevenDays = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

      // Query all products and group by ownerid
      const productsSnap = await admin.firestore().collection('products').get();
      const owners = {};

      productsSnap.forEach(doc => {
        const data = doc.data();
        const owner = data.ownerid || data.ownerId || 'global';
        if (!owners[owner]) owners[owner] = [];
        owners[owner].push({ id: doc.id, data });
      });

      for (const ownerId of Object.keys(owners)) {
        let expiredCount = 0;
        let nearCount = 0;
        const list = owners[ownerId];
        for (const item of list) {
          const d = item.data;
          let exp = null;
          const candidates = ['tanggal_expired','tanggal_expire','expiredDate','expired_at','expired_date','expired'];
          for (const k of candidates) {
            if (d[k]) { exp = d[k]; break; }
          }
          if (!exp) continue;
          let expDate = null;
          if (exp._seconds) {
            expDate = new Date(exp._seconds * 1000);
          } else if (typeof exp === 'number') {
            // assume seconds
            expDate = new Date(exp * 1000);
          } else if (typeof exp === 'string') {
            expDate = new Date(exp);
          }
          if (!expDate) continue;
          if (expDate < now) expiredCount++; else if (expDate <= sevenDays) nearCount++;
        }

        // fetch tokens for owner
        const tokensSnap = await admin.firestore().collection('device_tokens').where('ownerid','==', ownerId).get();
        const tokens = tokensSnap.docs.map(d => d.data().token).filter(t => !!t);

        // Build notification message
        if (expiredCount === 0 && nearCount === 0) continue;

        const payload = {
          notification: {
            title: expiredCount > 0 ? 'Produk Kedaluwarsa' : 'Produk Hampir Kedaluwarsa',
            body: expiredCount > 0 ? `Ada ${expiredCount} produk yang sudah kedaluwarsa.` : `${nearCount} produk akan kedaluwarsa dalam 7 hari.`
          },
          data: { ownerid: ownerId }
        };

        if (tokens.length > 0) {
          // send to tokens
          const response = await admin.messaging().sendMulticast({ tokens, ...payload });
          console.log('Sent to tokens for owner', ownerId, response.successCount);
        } else {
          // fallback to topic
          const topic = `owner_${ownerId}`;
          await admin.messaging().sendToTopic(topic, payload);
          console.log('Sent to topic', topic);
        }
      }

    } catch (e) {
      console.error('dailyExpiryCheck error', e);
    }
    return null;
  });
