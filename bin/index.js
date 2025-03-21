const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();


exports.onUserPresenceStatusChange = functions.database
  .ref('/presence/{uId}')
  .onWrite((change, context) => {
    const data = change.after.val();
    const uid = context.params.uId;

    if (!data) return null;

    // Get API URL from Firebase environment variables
    const apiUrl = process.env.API_MIRROR_URL;
    if (!apiUrl) {
        console.error("❌ API_MIRROR_URL is not set in environment variables!");
        return null;
    }

    const payload = {
      uid: uid,
      online: data.online ?? false,
      lastOnline: data.lastOnline,
    };

    try {
        axios.post(apiUrl, payload).then((response) => {
        console.log("✅ Data mirrored successfully:", response.data);
        });

    } catch (error) {
      console.error("❌ Error mirroring data:", error);
    }

    return null;
  });
