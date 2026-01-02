const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Scheduled function to run daily and send expiry notifications to device tokens or topics
// Deploy with: firebase deploy --only functions
exports.dailyExpiryCheck = functions.pubsub.schedule('0 9 * * *')
  .timeZone('Asia/Jakarta')
  .onRun(async (context) => {
    try {
      let db;
      try {
        db = admin.firestore();
      } catch (err) {
        console.error('Firestore not available in dailyExpiryCheck:', err);
        return null;
      }
      const now = new Date();
      const sevenDays = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

      // Query all products and group by ownerid
      if (!db || typeof db.collection !== 'function') {
        console.error('Firestore db or db.collection is not available in dailyExpiryCheck', { db });
        return null;
      }
      const productsSnap = await db.collection('products').get();
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
        if (!db || typeof db.collection !== 'function') {
          console.error('Firestore db or db.collection is not available when fetching device_tokens', { ownerId, db });
          continue;
        }
        const tokensSnap = await db.collection('device_tokens').where('ownerid','==', ownerId).get();
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

// HTTP endpoint to get expired and near-expiry counts.
// Query parameter: ?ownerId=<ownerId> to limit to a specific owner.
exports.getExpiredCounts = functions.https.onRequest(async (req, res) => {
  try {
    // Allow CORS from anywhere for simplicity (restrict in production)
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'GET,POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    const ownerId = (req.query.ownerId || req.body?.ownerId || '').toString();
    const now = new Date();
    const sevenDays = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const candidates = ['tanggal_expired','tanggal_expire','expiredDate','expired_at','expired_date','expired'];

    // Build base query (guard Firestore availability)
    let db;
    try {
      db = admin.firestore();
    } catch (err) {
      console.error('Firestore not available in getExpiredCounts:', err);
      res.status(500).json({ error: 'Firestore not available', details: err.toString() });
      return;
    }
    let baseQuery = db.collection('products');
    if (ownerId) baseQuery = baseQuery.where('ownerid','==', ownerId);
    // select only ownerid and candidate fields to minimize data transferred
    const selectFields = ['ownerid', ...candidates];
    if (!db || typeof db.collection !== 'function') {
      console.error('Firestore db or db.collection is not available in getExpiredCounts', { db });
      res.status(500).json({ error: 'Firestore not available' });
      return;
    }
    let q = baseQuery.select(...selectFields);
    let snap;
    try {
      snap = await q.get();
    } catch (err) {
      console.error('Error executing query in getExpiredCounts:', err);
      res.status(500).json({ error: 'Query failed', details: err.toString() });
      return;
    }

    const perOwner = {};
    let totalExpired = 0;
    let totalNear = 0;

    snap.forEach(doc => {
      const data = doc.data() || {};
      const owner = data.ownerid || 'global';
      if (!perOwner[owner]) perOwner[owner] = { expired: 0, near: 0 };

      // find first non-empty expiry field
      let raw = null;
      for (const k of candidates) {
        if (data[k] !== undefined && data[k] !== null && data[k] !== '') { raw = data[k]; break; }
      }
      if (!raw) return;

      let expDate = null;
      try {
        if (raw._seconds) expDate = new Date(raw._seconds * 1000);
        else if (typeof raw === 'number') expDate = new Date(raw * 1000);
        else if (typeof raw === 'string') expDate = new Date(raw);
      } catch (e) { expDate = null; }
      if (!expDate || isNaN(expDate.getTime())) return;

      if (expDate < now) {
        perOwner[owner].expired += 1;
        totalExpired += 1;
      } else if (expDate <= sevenDays) {
        perOwner[owner].near += 1;
        totalNear += 1;
      }
    });

    const result = { total: { expired: totalExpired, near: totalNear }, perOwner };
    if (ownerId) {
      const ownerRes = perOwner[ownerId] || { expired: 0, near: 0 };
      res.json({ ownerId, ...ownerRes });
    } else {
      res.json(result);
    }
  } catch (e) {
    console.error('getExpiredCounts error', e);
    res.status(500).json({ error: e.message || e.toString() });
  }
});
