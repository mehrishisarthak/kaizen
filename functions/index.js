/**
 * KAIZEN CLOUD FUNCTIONS (COMPLETE)
 * =====================================
 * 1. exchangeToken: Handles secure device provisioning.
 * 2. logHistory: Automatically creates history for charts from live data.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

// ================================================================
// 1. DEVICE PROVISIONING (The Handshake)
// ================================================================
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
      // 1. Get the provisioning token created by the App
      const tokenRef = db.collection("provisioning_tokens").doc(token);
      const tokenDoc = await tokenRef.get();

      if (!tokenDoc.exists) {
        console.error(`Token not found: ${token}`);
        return res.status(404).send({ error: "Invalid or expired token." });
      }

      const { userId, gridName } = tokenDoc.data();
      
      console.log(`Token data: userId=${userId}, gridName=${gridName}`);

      // Use MAC address as the unique Device ID
      const deviceId = mac_address;

      // 2. Create/Update the device document in the User's collection
      // We initialize it with default values so the dashboard looks good immediately
      const deviceRef = db.doc(`user_devices/${userId}/devices/${deviceId}`);
      await deviceRef.set({
        id: deviceId,
        gridName: gridName,        // Required for App Logic
        name: gridName,            // Required for UI Display
        macAddress: mac_address,
        ownerUid: userId,
        status: "online",          // Set to online immediately
        livePower: 0.0,
        temperature: 0.0,
        humidity: 0.0,
        batteryHealth: 100,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        last_seen: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true }); // merge: true prevents overwriting if it exists

      console.log(`Device linked: user_devices/${userId}/devices/${deviceId}`);

      // 3. Create a Custom Auth Token for the ESP32
      // This allows the ESP to write to the database acting AS the user
      const customToken = await auth.createCustomToken(userId);

      // 4. Return everything the ESP needs to start working
      return res.status(200).send({
        customToken: customToken,
        userId: userId,
        deviceId: deviceId,
        gridName: gridName,
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

// ================================================================
// 2. AUTOMATIC HISTORY LOGGER (The Chart Fix)
// ================================================================
// Triggers whenever the ESP32 updates the "live" document.
// It copies the live values into a subcollection for the chart to read.

exports.logHistory = functions.firestore
    .document('user_devices/{userId}/devices/{deviceId}')
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      // OPTIONAL: Check if data actually changed to save writes
      // if (newValue.livePower === previousValue.livePower && newValue.temperature === previousValue.temperature) return null;

      // 1. Prepare the history object
      // We explicitly map 'livePower' to 'power' to match your Flutter model
      const historyEntry = {
        timestamp: admin.firestore.FieldValue.serverTimestamp(), // Critical for X-Axis
        power: newValue.livePower || 0.0,
        temperature: newValue.temperature || 0.0,
        humidity: newValue.humidity || 0.0,
      };

      // 2. Write to the 'historical_data' subcollection
      try {
        await change.after.ref.collection('historical_data').add(historyEntry);
        console.log(`History logged for device ${context.params.deviceId}`);
      } catch (err) {
        console.error("Error logging history:", err);
      }
      
      return null;
    });