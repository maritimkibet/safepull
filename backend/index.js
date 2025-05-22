require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(bodyParser.json());

const {
  CONSUMER_KEY,
  CONSUMER_SECRET,
  SHORTCODE,
  PASSKEY,
  CALLBACK_URL,
  B2C_SHORTCODE,
  B2C_INITIATOR_NAME,
  B2C_SECURITY_CREDENTIAL,
  B2C_COMMAND_ID,
} = process.env;

function formatPhoneNumber(phone) {
  return phone.replace(/^0/, "254").replace(/\D/g, "");
}

app.post("/initiateMpesa", async (req, res) => {
  const { phone, amount } = req.body;

  if (!phone || !amount) {
    return res.status(400).json({ error: "Missing phone or amount" });
  }

  const formattedPhone = formatPhoneNumber(phone);
  const timestamp = new Date().toISOString().replace(/[-:.TZ]/g, "").slice(0, 14);
  const password = Buffer.from(SHORTCODE + PASSKEY + timestamp).toString("base64");
  const auth = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");

  try {
    const tokenRes = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } }
    );

    const accessToken = tokenRes.data.access_token;

    const stkPushRes = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      {
        BusinessShortCode: SHORTCODE,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: amount,
        PartyA: formattedPhone,
        PartyB: SHORTCODE,
        PhoneNumber: formattedPhone,
        CallBackURL: CALLBACK_URL,
        AccountReference: "SafePull",
        TransactionDesc: "SafePull Payment",
      },
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    res.status(200).json(stkPushRes.data);
  } catch (error) {
    console.error("M-Pesa Error:", error.response?.data || error.message);
    res.status(500).json({ error: "M-Pesa request failed", details: error.response?.data || error.message });
  }
});

app.post("/withdrawMpesa", async (req, res) => {
  const { phone, amount } = req.body;

  if (!phone || !amount) {
    return res.status(400).json({ error: "Missing phone or amount" });
  }

  const formattedPhone = formatPhoneNumber(phone);
  const auth = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");

  try {
    const tokenRes = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${auth}` } }
    );

    const accessToken = tokenRes.data.access_token;

    const b2cRes = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
      {
        InitiatorName: B2C_INITIATOR_NAME,
        SecurityCredential: B2C_SECURITY_CREDENTIAL,
        CommandID: B2C_COMMAND_ID || "BusinessPayment",
        Amount: amount,
        PartyA: B2C_SHORTCODE,
        PartyB: formattedPhone,
        Remarks: "SafePull Withdrawal",
        QueueTimeOutURL: CALLBACK_URL + "/timeout",
        ResultURL: CALLBACK_URL + "/b2cResult",
        Occasion: "SafePull",
      },
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    res.status(200).json(b2cRes.data);
  } catch (error) {
    console.error("M-Pesa B2C Error:", error.response?.data || error.message);
    res.status(500).json({ error: "M-Pesa B2C request failed", details: error.response?.data || error.message });
  }
});

app.post("/mpesaCallback", (req, res) => {
  console.log("M-Pesa Callback Received:", JSON.stringify(req.body, null, 2));
  res.status(200).send("Callback received successfully");
});

app.post("/b2cResult", (req, res) => {
  console.log("M-Pesa B2C Result:", JSON.stringify(req.body, null, 2));
  // TODO: Update DB with withdrawal status
  res.status(200).send("B2C Result received");
});

app.post("/timeout", (req, res) => {
  console.log("M-Pesa B2C Timeout:", JSON.stringify(req.body, null, 2));
  res.status(200).send("Timeout received");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ M-Pesa backend running on http://localhost:${PORT}`);
});
