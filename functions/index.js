const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ============================================================
// FCM NOTIFICATION FUNCTIONS untuk Owner
// ============================================================

/**
 * Trigger: Ketika dokumen notification baru dibuat
 * Action: Otomatis kirim push notification ke semua device owner
 */
exports.sendNotificationToOwner = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const ownerId = notification.ownerid;
    const title = notification.title || "KGBox Notification";
    const body = notification.body || "";
    const notificationType = notification.type || "info";

    if (!ownerId) {
      console.log("No owner ID in notification document");
      return;
    }

    try {
      // Get all device tokens untuk owner ini
      const tokensSnapshot = await admin
        .firestore()
        .collection("device_tokens")
        .where("ownerid", "==", ownerId)
        .get();

      const tokens = [];
      tokensSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.token) {
          tokens.push(data.token);
        }
      });

      if (tokens.length === 0) {
        console.log(`No device tokens found for owner ${ownerId}`);
        return;
      }

      console.log(`Found ${tokens.length} device tokens for owner ${ownerId}`);

      // Prepare FCM payload
      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: notificationType,
          notificationId: context.params.notificationId,
          ownerId: ownerId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Send multicast ke semua tokens
      const response = await admin.messaging().sendMulticast({
        tokens: tokens,
        ...payload,
      });

      console.log(`Successfully sent to ${response.successCount} devices`);
      console.log(`Failed to send to ${response.failureCount} devices`);

      // Remove invalid tokens dari Firestore
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          console.log(`Failed to send to token ${tokens[idx]}: ${resp.error}`);
        }
      });

      // Delete invalid tokens
      if (failedTokens.length > 0) {
        const batch = admin.firestore().batch();
        for (const token of failedTokens) {
          const docRef = admin.firestore().collection("device_tokens").doc(token);
          batch.delete(docRef);
        }
        await batch.commit();
        console.log(`Deleted ${failedTokens.length} invalid tokens`);
      }

    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });

/**
 * Callable Function untuk mengirim notifikasi via topic
 * Usage: 
 *   const callable = FirebaseFunctions.instance.httpsCallable('sendNotificationByTopic');
 *   await callable.call({
 *     'topic': 'owner_7onp9TZnDGhcwHK9jh0UvsEtkn22',
 *     'title': 'Title',
 *     'body': 'Body',
 *   });
 */
exports.sendNotificationByTopic = functions.https.onCall(async (data, context) => {
  const { topic, title, body, notificationType } = data;

  // Validate input
  if (!topic || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required parameters: topic, title, body"
    );
  }

  // Must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  try {
    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: notificationType || "info",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const response = await admin.messaging().sendToTopic(topic, payload);
    console.log(`Message sent to topic ${topic}: ${response}`);
    
    return { 
      success: true, 
      messageId: response,
      message: `Notification sent successfully to topic ${topic}`
    };
  } catch (error) {
    console.error("Error sending to topic:", error);
    throw new functions.https.HttpsError(
      "internal", 
      `Failed to send notification: ${error.message}`
    );
  }
});

/**
 * Callable Function untuk test notification
 * Usage: Untuk testing saja
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated"
    );
  }

  const ownerId = context.auth.uid;
  
  try {
    // Get device tokens
    const tokensSnapshot = await admin
      .firestore()
      .collection("device_tokens")
      .where("ownerid", "==", ownerId)
      .get();

    const tokens = [];
    tokensSnapshot.forEach((doc) => {
      if (doc.data().token) {
        tokens.push(doc.data().token);
      }
    });

    if (tokens.length === 0) {
      throw new functions.https.HttpsError(
        "not-found",
        `No device tokens found for owner ${ownerId}`
      );
    }

    // Send test message
    const payload = {
      notification: {
        title: "Test Notification",
        body: "This is a test push notification from KGBox",
      },
      data: {
        type: "test",
        ownerId: ownerId,
      },
    };

    const response = await admin.messaging().sendMulticast({
      tokens: tokens,
      ...payload,
    });

    console.log(`Test notification sent to ${response.successCount} devices`);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      message: "Test notification sent successfully",
    };
  } catch (error) {
    console.error("Error sending test notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message
    );
  }
});

// ============================================================
// SCHEDULED NOTIFICATION FUNCTIONS
// ============================================================

/**
 * Scheduled function untuk cek dan kirim notifikasi produk kadaluarsa
 * Jalan setiap hari jam 9 pagi (Asia/Jakarta)
 */
exports.dailyExpiryCheck = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Jakarta')
  .onRun(async (context) => {
    try {
      console.log('Starting daily expiry check...');
      
      const db = admin.firestore();
      const now = new Date();
      
      // Get all products yang sudah kadaluarsa atau akan kadaluarsa 7 hari ke depan
      const expiryDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
      
      const productsSnapshot = await db
        .collection('products')
        .where('tanggal_expired', '<=', expiryDate)
        .get();

      console.log(`Found ${productsSnapshot.size} products with expiry coming up`);

      // Group by owner dan kirim notification
      const ownerNotifications = {};
      
      productsSnapshot.forEach((doc) => {
        const product = doc.data();
        const ownerId = product.ownerid || product.ownerId;
        const productName = product.nama_product || product.nama;
        
        if (!ownerId) return;
        
        if (!ownerNotifications[ownerId]) {
          ownerNotifications[ownerId] = [];
        }
        
        ownerNotifications[ownerId].push({
          productId: doc.id,
          name: productName,
          expiry: product.tanggal_expired,
        });
      });

      // Send notifications
      let notificationCount = 0;
      for (const [ownerId, products] of Object.entries(ownerNotifications)) {
        try {
          const productList = products.map((p) => p.name).join(', ');
          
          await db.collection('notifications').add({
            title: 'Produk Akan Kadaluarsa',
            body: `${products.length} produk akan kadaluarsa dalam 7 hari: ${productList}`,
            type: 'expired_product',
            ownerid: ownerId,
            timestamp: admin.firestore.Timestamp.now(),
            isRead: false,
            productIds: products.map((p) => p.productId),
          });
          
          notificationCount++;
        } catch (err) {
          console.error(`Error creating notification for owner ${ownerId}:`, err);
        }
      }

      console.log(`Created ${notificationCount} expiry notifications`);
      return { success: true, notificationsCreated: notificationCount };
    } catch (error) {
      console.error('Error in daily expiry check:', error);
      return { success: false, error: error.message };
    }
  });

// ============================================================
// EXPIRED COUNT FUNCTION
// ============================================================


// ============================================================
// EXPIRED COUNT FUNCTION
// ============================================================

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
