const functions = require("firebase-functions");
const axios = require("axios");

const consumerKey = "muFIKfL0G8aZ4vYHG6hHRYbKrXha8jeqadargXl8ypRBdNj8";
const consumerSecret = "O5DAlbl7GRS5VjzGnJlJQrGxLxD8wAvkJkMvbhpwELnvytgPA76QLj4p9pEmoNzj";
const shortCode = "174379"; // Test Paybill
const passkey = "174379";
const callbackURL = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/mpesaCallback";

exports.initiateMpesa = functions.https.onRequest(async (req, res) => {
  const { phone, amount } = req.body;

  const timestamp = new Date().toISOString().replace(/[-T:.Z]/g, "").slice(0, 14);
  const password = Buffer.from(shortCode + passkey + timestamp).toString("base64");
  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString("base64");

  try {
    const tokenRes = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      {
        headers: { Authorization: `Basic ${auth}` },
      }
    );

    const accessToken = tokenRes.data.access_token;

    const stkPushRes = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        BusinessShortCode: shortCode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: amount,
        PartyA: phone,
        PartyB: shortCode,
        PhoneNumber: phone,
        CallBackURL: callbackURL,
        AccountReference: "SafePull",
        TransactionDesc: "SafePull Payment",
      },
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      }
    );

    res.status(200).send(stkPushRes.data);
  } catch (error) {
    console.error("M-Pesa Error:", error.response?.data || error.message);
    res.status(500).send(error.response?.data || error.message);
  }
});
