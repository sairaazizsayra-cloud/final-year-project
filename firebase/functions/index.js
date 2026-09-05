/**
 * Firebase Cloud Functions — Keychain Shop
 * Order notifications, FCM, delivery sync, payment/coupon stubs.
 *
 * Deploy: cd firebase/functions && npm install && firebase deploy --only functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const STATUS_COPY = {
  pending: {
    title: 'Order placed',
    body: 'We received your order and will confirm it shortly.',
  },
  confirmed: {
    title: 'Order confirmed',
    body: 'Your keychain order has been confirmed.',
  },
  preparing: {
    title: 'Preparing your order',
    body: 'Your custom keychains are being prepared.',
  },
  shipped: {
    title: 'Order shipped',
    body: 'Your order is on the way for home-to-home delivery.',
  },
  out_for_delivery: {
    title: 'Out for delivery',
    body: 'Your rider is on the way to your home address.',
  },
  delivered: {
    title: 'Order delivered',
    body: 'Your keychains were delivered. Enjoy!',
  },
  cancelled: {
    title: 'Order cancelled',
    body: 'Your order has been cancelled.',
  },
};

async function createNotification({
  userId,
  title,
  body,
  type = 'order',
  orderId = null,
  productId = null,
  data = null,
}) {
  await db.collection('notifications').add({
    userId,
    title,
    body,
    type,
    orderId,
    productId,
    data,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function sendPushToUser(userId, title, body, data = {}) {
  const userSnap = await db.collection('users').doc(userId).get();
  if (!userSnap.exists) return;
  const token = userSnap.data().fcmToken;
  if (!token) {
    console.log(`[FCM] No token for user ${userId}`);
    return;
  }

  try {
    await messaging.send({
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v ?? '')]),
      ),
    });
  } catch (err) {
    console.error(`[FCM] send failed for ${userId}:`, err.message);
  }
}

async function notifyOrderStatus(userId, orderId, status) {
  const copy = STATUS_COPY[status] || {
    title: 'Order update',
    body: `Your order status is now ${status}.`,
  };
  await createNotification({
    userId,
    title: copy.title,
    body: copy.body,
    type: 'order',
    orderId,
    data: { status },
  });
  await sendPushToUser(userId, copy.title, copy.body, {
    type: 'order',
    orderId,
    status,
  });
}

async function upsertDeliveryForOrder(orderId, order, status) {
  const existing = await db
    .collection('deliveries')
    .where('orderId', '==', orderId)
    .limit(1)
    .get();

  const payload = {
    orderId,
    userId: order.userId,
    deliveryAddress: order.deliveryAddress || {},
    status,
    riderId: order.riderId || null,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (status === 'delivered') {
    payload.deliveredAt = FieldValue.serverTimestamp();
  }

  if (existing.empty) {
    if (
      status === 'shipped' ||
      status === 'out_for_delivery' ||
      status === 'delivered'
    ) {
      const ref = await db.collection('deliveries').add({
        ...payload,
        riderName: null,
        notes: null,
        assignedAt: FieldValue.serverTimestamp(),
        deliveredAt: status === 'delivered' ? FieldValue.serverTimestamp() : null,
      });
      await db.collection('orders').doc(orderId).update({
        deliveryId: ref.id,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return;
  }

  await existing.docs[0].ref.update(payload);
}

exports.healthCheck = onCall(async () => {
  return {
    ok: true,
    service: 'keychain-shop-functions',
    timestamp: new Date().toISOString(),
  };
});

exports.validateCoupon = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const { code, subtotal } = request.data || {};
  if (!code || typeof subtotal !== 'number') {
    throw new HttpsError('invalid-argument', 'code and subtotal are required.');
  }

  const snap = await db
    .collection('coupons')
    .where('code', '==', String(code).toUpperCase())
    .where('isActive', '==', true)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError('not-found', 'Invalid coupon code.');
  }

  const couponDoc = snap.docs[0];
  const coupon = couponDoc.data();
  const now = new Date();

  const validFrom = coupon.validFrom?.toDate ? coupon.validFrom.toDate() : null;
  const validUntil = coupon.validUntil?.toDate
    ? coupon.validUntil.toDate()
    : null;

  if (validFrom && now < validFrom) {
    throw new HttpsError('failed-precondition', 'Coupon is not active yet.');
  }
  if (validUntil && now > validUntil) {
    throw new HttpsError('failed-precondition', 'Coupon has expired.');
  }

  const minOrder = Number(coupon.minOrderAmount || 0);
  if (subtotal < minOrder) {
    throw new HttpsError(
      'failed-precondition',
      `Minimum order is ${minOrder} for this coupon.`,
    );
  }

  const usageLimit = Number(coupon.usageLimit || 0);
  const usedCount = Number(coupon.usedCount || 0);
  if (usageLimit > 0 && usedCount >= usageLimit) {
    throw new HttpsError('resource-exhausted', 'Coupon usage limit reached.');
  }

  const discountType = coupon.discountType || 'percentage';
  const discountValue = Number(coupon.discountValue || 0);
  let discountAmount =
    discountType === 'fixed'
      ? discountValue
      : (subtotal * discountValue) / 100;

  const maxDiscount = coupon.maxDiscount != null
    ? Number(coupon.maxDiscount)
    : null;
  if (maxDiscount != null && !Number.isNaN(maxDiscount)) {
    discountAmount = Math.min(discountAmount, maxDiscount);
  }
  discountAmount = Math.max(0, Math.min(discountAmount, subtotal));

  return {
    valid: true,
    couponId: couponDoc.id,
    code: String(code).toUpperCase(),
    discountType,
    discountValue,
    discountAmount,
    minOrderAmount: minOrder,
  };
});

exports.createPaymentSession = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const { orderId, amount, userId } = request.data || {};
  if (!orderId || typeof amount !== 'number' || !userId) {
    throw new HttpsError(
      'invalid-argument',
      'orderId, amount, and userId are required.',
    );
  }

  if (request.auth.uid !== userId) {
    throw new HttpsError('permission-denied', 'User mismatch.');
  }

  const orderRef = db.collection('orders').doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    throw new HttpsError('not-found', 'Order not found.');
  }

  const order = orderSnap.data();
  if (order.userId !== userId) {
    throw new HttpsError('permission-denied', 'Order does not belong to user.');
  }

  return {
    success: false,
    status: 'failed',
    message:
      'Online payment gateway is not configured yet. Please use Cash on Delivery.',
    orderId,
  };
});

/**
 * When a new order is created: in-app notification + FCM.
 */
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const order = snap.data();
  const orderId = event.params.orderId;
  const status = order.orderStatus || 'pending';

  await notifyOrderStatus(order.userId, orderId, status);
});

/**
 * When order status changes: history note, notification, FCM, delivery sync.
 */
exports.onOrderUpdated = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const orderId = event.params.orderId;
  const prevStatus = before.orderStatus;
  const nextStatus = after.orderStatus;

  if (!nextStatus || prevStatus === nextStatus) return;

  const history = Array.isArray(after.statusHistory)
    ? after.statusHistory
    : [];
  const alreadyLogged = history.some((h) => h && h.status === nextStatus);
  if (!alreadyLogged) {
    await event.data.after.ref.update({
      statusHistory: FieldValue.arrayUnion([
        {
          status: nextStatus,
          timestamp: new Date(),
          note: `Status updated to ${nextStatus}`,
        },
      ]),
      updatedAt: FieldValue.serverTimestamp(),
      ...(nextStatus === 'delivered'
        ? { deliveredAt: FieldValue.serverTimestamp() }
        : {}),
    });
  }

  await notifyOrderStatus(after.userId, orderId, nextStatus);
  await upsertDeliveryForOrder(orderId, after, nextStatus);
});

/**
 * Admin callable — update order status securely.
 */
exports.updateOrderStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const adminDoc = await db.collection('users').doc(request.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data().role !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin only.');
  }

  const { orderId, status, note } = request.data || {};
  const allowed = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];
  if (!orderId || !allowed.includes(status)) {
    throw new HttpsError('invalid-argument', 'Valid orderId and status required.');
  }

  const ref = db.collection('orders').doc(orderId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Order not found.');
  }

  await ref.update({
    orderStatus: status,
    updatedAt: FieldValue.serverTimestamp(),
    statusHistory: FieldValue.arrayUnion([
      {
        status,
        timestamp: new Date(),
        note: note || `Updated by admin to ${status}`,
      },
    ]),
    ...(status === 'delivered'
      ? { deliveredAt: FieldValue.serverTimestamp() }
      : {}),
  });

  // onOrderUpdated trigger handles notification + delivery.
  return { ok: true, orderId, status };
});
