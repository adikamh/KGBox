# Cloud Functions for KGBox

This folder contains example Firebase Cloud Functions used by the KGBox app.

Available functions:

- `dailyExpiryCheck` (scheduled): runs daily at 09:00 Asia/Jakarta to scan `products` and send push notifications for expired or near-expiry items.
- `getExpiredCounts` (HTTP): returns aggregated expired and near-expiry counts. Query with `?ownerId=<ownerId>` to get counts for a specific owner.

Deployment

1. Install dependencies and Firebase CLI:

```bash
cd functions
npm install
# install firebase-tools globally if you haven't
npm install -g firebase-tools
```

2. Initialize (if not already):

```bash
firebase login
firebase init functions
```

3. Deploy functions:

```bash
firebase deploy --only functions
```

Testing `getExpiredCounts` locally (emulator):

```bash
# from repository root
firebase emulators:start --only functions,firestore
# then call the endpoint at
# http://localhost:5001/<PROJECT_ID>/us-central1/getExpiredCounts
```

Security

- The HTTP endpoint currently allows all origins (CORS: *). Restrict origins and add authentication (Firebase Auth / callable functions) before using in production.
- Ensure Firestore rules limit access as required.
