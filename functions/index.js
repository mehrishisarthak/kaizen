/**
 * KAIZEN CLOUD FUNCTION
 * =======================
 * This is the backend "brain" that securely links your ESP32
 * to a user's account.
 */

// Import the necessary Firebase modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

/**
 * @name exchangeToken
 * @description This HTTP function is called by the ESP32 after it connects
 * to the user's WiFi. It exchanges a one-time provisioning token
 * for a permanent, secure Firebase Custom Auth Token.
 *
 * @param {object} req - The HTTP request object.
 * @param {object} req.body - The JSON body from the ESP32.
 * @param {string} req.body.token - The one-time token from the app.
 * @param {string} req.body.mac_address - The unique MAC address of the ESP32.
 *
 * @returns {object} res - The HTTP response object.
 * @returns {string} res.customToken - The secure Firebase Custom Token for the ESP32 to log in with.
 * @returns {string} res.userId - The UID of the user this device belongs to.
 * @returns {string} res.deviceId - The new unique ID for this device (the MAC address).
 */
exports.exchangeToken = functions.https.onRequest((req, res) => {
  // Use CORS to allow the ESP32 (which is on a different domain)
  // to call this function.
  cors(req, res, async () => {
    // 1. We only accept POST requests
    if (req.method !== "POST") {
      return res.status(405).send({ error: "Method Not Allowed" });
    }

    // 2. Get the data from the ESP32's JSON body
    const { token, mac_address } = req.body;

    // 3. Validate the incoming data
    if (!token || !mac_address) {
      return res.status(400).send({ error: "Missing 'token' or 'mac_address' in request body." });
    }

    try {
      // 4. Get the one-time token from Firestore
      const tokenRef = db.collection("provisioning_tokens").doc(token);
      const tokenDoc = await tokenRef.get();

      if (!tokenDoc.exists) {
        return res.status(404).send({ error: "Invalid or expired token." });
      }

      // 5. We found the token! Get the user's info.
      const { userId, gridName } = tokenDoc.data();
      const deviceId = mac_address; // Use the MAC address as the unique device ID

      // 6. This is the "linking" step. Create the new device document
      //    in our main database.
      const deviceRef = db.doc(`user_devices/${userId}/devices/${deviceId}`);
      await deviceRef.set({
        name: gridName,
        ownerUid: userId,
        status: "offline",
        livePower: 0.0,
        batteryHealth: 0,
        last_seen: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 7. Delete the one-time token so it can never be used again
      await tokenRef.delete();

      // 8. THE MAGIC: Create a permanent Firebase Custom Auth Token
      //    This allows the ESP32 to log in AS ITSELF.
      //    We use the deviceId as its UID.
      const customToken = await auth.createCustomToken(deviceId);

      // 9. Send the new token and IDs back to the ESP32
      console.log(`Successfully provisioned device ${deviceId} for user ${userId}`);
      return res.status(200).send({
        customToken: customToken,
        userId: userId,
        deviceId: deviceId,
      });

    } catch (error) {
      console.error("Error during token exchange:", error);
      return res.status(500).send({ error: "Internal Server Error." });
    }
  });
});