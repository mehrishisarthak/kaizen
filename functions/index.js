/**
 * KAIZEN CLOUD FUNCTION (COMPLETE FIX)
 * =====================================
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

exports.exchangeToken = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send({ error: "Method Not Allowed" });
    }

    const { token, mac_address } = req.body;

    if (!token || !mac_address) {
      return res.status(400).send({ 
        error: "Missing 'token' or 'mac_address' in request body." 
      });
    }

    try {
      // 1. Get the provisioning token
      const tokenRef = db.collection("provisioning_tokens").doc(token);
      const tokenDoc = await tokenRef.get();

      if (!tokenDoc.exists) {
        console.error(`Token not found: ${token}`);
        return res.status(404).send({ error: "Invalid or expired token." });
      }

      const { userId, gridName } = tokenDoc.data();
      
      console.log(`Token data: userId=${userId}, gridName=${gridName}`);

      // ✅ FIX 1: Use MAC address as device ID (keep it simple)
      const deviceId = mac_address;

      console.log(`Device ID: ${deviceId}`);

      // ✅ FIX 2: Create device document with ALL required fields
      const deviceRef = db.doc(`user_devices/${userId}/devices/${deviceId}`);
      await deviceRef.set({
        id: deviceId,
        gridName: gridName,        // ✅ CRITICAL for AuthWrapper
        name: gridName,            // ✅ CRITICAL for Grid model
        macAddress: mac_address,
        ownerUid: userId,
        status: "connecting",
        livePower: 0.0,
        temperature: 0.0,
        humidity: 0.0,
        batteryHealth: 100,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        last_seen: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Device document created at: user_devices/${userId}/devices/${deviceId}`);

      // Delete token (commented for testing)
      // await tokenRef.delete();

      // ✅ FIX 3: Create token as USER (not as device)
      // This gives ESP permission to write to user_devices/{userId}/...
      const customToken = await auth.createCustomToken(userId);

      // ✅ FIX 4: Return ALL required fields
      console.log(`✓ Successfully provisioned device ${deviceId} for user ${userId}`);
      
      return res.status(200).send({
        customToken: customToken,
        userId: userId,
        deviceId: deviceId,
        gridName: gridName,  // ✅ ADDED
      });

    } catch (error) {
      console.error("Error during token exchange:", error);
      return res.status(500).send({ 
        error: "Internal Server Error.",
        details: error.message
      });
    }
  });
});
