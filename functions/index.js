const { onRequest } = require('firebase-functions/v2/https');
const functions = require('firebase-functions');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const cors = require('cors')({ origin: true });

// ---- Config (env or functions:config) ----
let cfg = {};
try {
  cfg = functions.config();
} catch (e) {
  cfg = {};
}

const RZP_KEY_ID = 'przp_live_RBPUYyCmLULAgS';

const RZP_KEY_SECRET =
  process.env.RZP_KEY_SECRET ||
  (cfg.razorpay && cfg.razorpay.key_secret) ||
  '';

const RZP_WEBHOOK_SECRET = '1dO5djP9AdVBK7aWxncbbYdp';

function requireKeys() {
  if (!RZP_KEY_ID || !RZP_KEY_SECRET) {
    const err = new Error('Missing Razorpay keys. Set RZP_KEY_ID and RZP_KEY_SECRET.');
    err.statusCode = 500;
    throw err;
  }
}

// CORS wrapper with safe error handling (no optional chaining)
function withCors(handler) {
  return onRequest(async (req, res) => {
    cors(req, res, async () => {
      try {
        await handler(req, res);
      } catch (err) {
        const code = (err && err.statusCode) ? err.statusCode : 500;
        const message = (err && err.message) ? err.message : 'Server error';
        res.status(code).json({ success: false, error: message });
      }
    });
  });
}

// POST /createOrder  { amount: 1000, currency?: "INR", receipt?: "rcpt-123" }
exports.createOrder = withCors(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  requireKeys();

  const body = req.body || {};
  const amount = Number(body.amount);
  const currency = body.currency || 'INR';
  const receipt = body.receipt || ('rcpt_' + Date.now());

  if (!amount || isNaN(amount) || amount <= 0) {
    return res.status(400).json({ error: 'Valid amount (in paise) is required' });
  }

  const rzp = new Razorpay({ key_id: RZP_KEY_ID, key_secret: RZP_KEY_SECRET });
  const order = await rzp.orders.create({
    amount: amount,
    currency: currency,
    receipt: receipt,
    notes: {}
  });

  return res.json({
    success: true,
    orderId: order.id,
    amount: order.amount,
    currency: order.currency
  });
});

// POST /verifySignature
// Body fields from Flutter success callback:
//   razorpay_order_id, razorpay_payment_id, razorpay_signature
exports.verifySignature = withCors(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  requireKeys();

  const body = req.body || {};
  // Map snake_case fields to camelCase variables to satisfy lint rules
  const rzpOrderId = body['razorpay_order_id'];
  const rzpPaymentId = body['razorpay_payment_id'];
  const rzpSignature = body['razorpay_signature'];

  if (!rzpOrderId || !rzpPaymentId || !rzpSignature) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const hmac = crypto.createHmac('sha256', RZP_KEY_SECRET);
  hmac.update(rzpOrderId + '|' + rzpPaymentId);
  const generated = hmac.digest('hex');

  const valid = (generated === rzpSignature);
  return res.json({ success: true, valid: valid });
});

// GET /getOrderStatus?order_id=order_xxx
exports.getOrderStatus = withCors(async (req, res) => {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  requireKeys();

  const orderId = String((req.query && req.query.order_id) ? req.query.order_id : '').trim();
  if (!orderId) {
    return res.status(400).json({ error: 'order_id is required' });
  }

  const rzp = new Razorpay({ key_id: RZP_KEY_ID, key_secret: RZP_KEY_SECRET });
  try {
    const order = await rzp.orders.fetch(orderId);
    // status: "created" | "attempted" | "paid"
    return res.json({ success: true, status: order.status, order: order });
  } catch (e) {
    return res.status(500).json({ success: false, error: e.message });
  }
});

// (Optional) POST /razorpayWebhook  — set this URL in Razorpay Dashboard
exports.razorpayWebhook = withCors(async (req, res) => {
  if (!RZP_WEBHOOK_SECRET) {
    return res.status(500).json({ ok: false, error: 'Webhook secret not set' });
  }

  const signature = req.get('X-Razorpay-Signature') || '';
  const bodyStr = JSON.stringify(req.body || {});
  const expected = crypto.createHmac('sha256', RZP_WEBHOOK_SECRET).update(bodyStr).digest('hex');

  if (signature !== expected) {
    return res.status(400).json({ ok: false, error: 'Invalid signature' });
  }

  const event = (req.body && req.body.event) ? req.body.event : undefined;
  // TODO: handle specific events like "payment.captured", "order.paid"
  return res.json({ ok: true, event: event || null });
});
