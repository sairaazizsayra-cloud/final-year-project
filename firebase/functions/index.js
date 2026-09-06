/**
 * Firebase Cloud Functions — Keychain Shop
 * Order notifications, FCM, delivery sync, payment/coupon stubs.
 *
 * Deploy: cd firebase/functions && npm install && firebase deploy --only functions
 */

const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const auth = getAuth();
const messaging = getMessaging();

/** One-time / demo seed secret — change after class demo if repo is public. */
const SEED_SECRET = 'KeychainSeed2026!';

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

/**
 * Demo seed — creates role accounts + catalog data.
 * Call once: GET/POST .../seedDemoData?secret=KeychainSeed2026!
 */
exports.seedDemoData = onRequest({ cors: true, timeoutSeconds: 120 }, async (req, res) => {
  try {
    const secret = req.query.secret || (req.body && req.body.secret);
    if (secret !== SEED_SECRET) {
      res.status(403).json({ error: 'Forbidden. Pass ?secret=...' });
      return;
    }

    const accounts = [
      {
        email: 'admin@keychainshop.test',
        password: 'Admin@12345',
        name: 'Shop Admin',
        phone: '03001110001',
        role: 'admin',
      },
      {
        email: 'customer@keychainshop.test',
        password: 'Customer@12345',
        name: 'Ali Customer',
        phone: '03002220002',
        role: 'customer',
      },
      {
        email: 'customer2@keychainshop.test',
        password: 'Customer@12345',
        name: 'Sara Buyer',
        phone: '03003330003',
        role: 'customer',
      },
      {
        email: 'rider@keychainshop.test',
        password: 'Rider@12345',
        name: 'Hamza Rider',
        phone: '03004440004',
        role: 'rider',
      },
    ];

    const createdUsers = [];
    for (const a of accounts) {
      let user;
      try {
        user = await auth.createUser({
          email: a.email,
          password: a.password,
          displayName: a.name,
          emailVerified: true,
        });
      } catch (e) {
        if (e.code === 'auth/email-already-exists') {
          user = await auth.getUserByEmail(a.email);
          await auth.updateUser(user.uid, {
            password: a.password,
            displayName: a.name,
            emailVerified: true,
          });
        } else {
          throw e;
        }
      }

      await db.collection('users').doc(user.uid).set(
        {
          name: a.name,
          email: a.email,
          phone: a.phone,
          profileImage: null,
          role: a.role,
          isActive: true,
          fcmToken: null,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      if (a.role === 'admin') {
        await db.collection('admins').doc(user.uid).set(
          {
            email: a.email,
            name: a.name,
            createdAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      createdUsers.push({
        uid: user.uid,
        email: a.email,
        password: a.password,
        role: a.role,
        name: a.name,
      });
    }

    const customer = createdUsers.find((u) => u.role === 'customer');
    const customer2 = createdUsers.filter((u) => u.role === 'customer')[1];
    const rider = createdUsers.find((u) => u.role === 'rider');

    const categoryDefs = [
      {
        id: 'cat_metal',
        name: 'Metal Keychains',
        description: 'Durable brass & steel designs',
        sortOrder: 1,
      },
      {
        id: 'cat_acrylic',
        name: 'Acrylic Keychains',
        description: 'Colorful custom acrylic charms',
        sortOrder: 2,
      },
      {
        id: 'cat_leather',
        name: 'Leather Keychains',
        description: 'Premium leather tags & holders',
        sortOrder: 3,
      },
      {
        id: 'cat_custom',
        name: 'Custom Name',
        description: 'Personalized name & photo keychains',
        sortOrder: 4,
      },
      {
        id: 'cat_couple',
        name: 'Couple Sets',
        description: 'Matching pair keychains',
        sortOrder: 5,
      },
    ];

    for (const c of categoryDefs) {
      await db.collection('categories').doc(c.id).set({
        name: c.name,
        description: c.description,
        imageUrl: `https://picsum.photos/seed/${c.id}/400/400`,
        sortOrder: c.sortOrder,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    const productDefs = [
      {
        id: 'prod_brass_classic',
        name: 'Classic Brass Keychain',
        categoryId: 'cat_metal',
        categoryName: 'Metal Keychains',
        price: 450,
        discount: 0,
        stock: 40,
        isFeatured: true,
        isBestSeller: true,
        isNewArrival: false,
        isCustomizable: false,
        material: 'Brass',
        colors: ['Gold', 'Antique'],
      },
      {
        id: 'prod_steel_ring',
        name: 'Steel Ring Holder',
        categoryId: 'cat_metal',
        categoryName: 'Metal Keychains',
        price: 350,
        discount: 10,
        stock: 55,
        isFeatured: false,
        isBestSeller: true,
        isNewArrival: false,
        isCustomizable: false,
        material: 'Stainless Steel',
        colors: ['Silver', 'Black'],
      },
      {
        id: 'prod_acrylic_heart',
        name: 'Acrylic Heart Charm',
        categoryId: 'cat_acrylic',
        categoryName: 'Acrylic Keychains',
        price: 299,
        discount: 15,
        stock: 80,
        isFeatured: true,
        isBestSeller: false,
        isNewArrival: true,
        isCustomizable: true,
        material: 'Acrylic',
        colors: ['Pink', 'Clear', 'Red'],
      },
      {
        id: 'prod_acrylic_photo',
        name: 'Photo Acrylic Keychain',
        categoryId: 'cat_acrylic',
        categoryName: 'Acrylic Keychains',
        price: 599,
        discount: 0,
        stock: 35,
        isFeatured: true,
        isBestSeller: true,
        isNewArrival: true,
        isCustomizable: true,
        material: 'Acrylic',
        colors: ['Clear'],
      },
      {
        id: 'prod_leather_tag',
        name: 'Leather Name Tag',
        categoryId: 'cat_leather',
        categoryName: 'Leather Keychains',
        price: 750,
        discount: 5,
        stock: 25,
        isFeatured: false,
        isBestSeller: false,
        isNewArrival: true,
        isCustomizable: true,
        material: 'Genuine Leather',
        colors: ['Brown', 'Black', 'Tan'],
      },
      {
        id: 'prod_leather_loop',
        name: 'Leather Loop Keyring',
        categoryId: 'cat_leather',
        categoryName: 'Leather Keychains',
        price: 650,
        discount: 0,
        stock: 30,
        isFeatured: false,
        isBestSeller: false,
        isNewArrival: false,
        isCustomizable: false,
        material: 'Leather',
        colors: ['Brown', 'Navy'],
      },
      {
        id: 'prod_custom_name',
        name: 'Custom Name Plate',
        categoryId: 'cat_custom',
        categoryName: 'Custom Name',
        price: 899,
        discount: 10,
        stock: 50,
        isFeatured: true,
        isBestSeller: true,
        isNewArrival: true,
        isCustomizable: true,
        material: 'Metal + Engraving',
        colors: ['Gold', 'Silver', 'Rose Gold'],
      },
      {
        id: 'prod_couple_heart',
        name: 'Couple Heart Set',
        categoryId: 'cat_couple',
        categoryName: 'Couple Sets',
        price: 1200,
        discount: 20,
        stock: 20,
        isFeatured: true,
        isBestSeller: true,
        isNewArrival: false,
        isCustomizable: true,
        material: 'Mixed',
        colors: ['Red', 'Gold'],
      },
      {
        id: 'prod_mini_car',
        name: 'Mini Car Charm',
        categoryId: 'cat_metal',
        categoryName: 'Metal Keychains',
        price: 399,
        discount: 0,
        stock: 60,
        isFeatured: false,
        isBestSeller: false,
        isNewArrival: true,
        isCustomizable: false,
        material: 'Zinc Alloy',
        colors: ['Silver', 'Blue'],
      },
      {
        id: 'prod_initial_disk',
        name: 'Initial Disk Keychain',
        categoryId: 'cat_custom',
        categoryName: 'Custom Name',
        price: 499,
        discount: 0,
        stock: 45,
        isFeatured: false,
        isBestSeller: false,
        isNewArrival: false,
        isCustomizable: true,
        material: 'Brass',
        colors: ['Gold', 'Silver'],
      },
    ];

    for (const p of productDefs) {
      await db.collection('products').doc(p.id).set({
        name: p.name,
        nameLower: p.name.toLowerCase(),
        description:
          `${p.name} — quality keychain for everyday carry. ` +
          'Home-to-home delivery available across the city.',
        categoryId: p.categoryId,
        categoryName: p.categoryName,
        price: p.price,
        discount: p.discount,
        stock: p.stock,
        images: [
          `https://picsum.photos/seed/${p.id}/600/600`,
          `https://picsum.photos/seed/${p.id}b/600/600`,
        ],
        material: p.material,
        size: 'Standard',
        colors: p.colors,
        isCustomizable: p.isCustomizable,
        rating: 4.2,
        totalReviews: 3,
        isFeatured: p.isFeatured,
        isBestSeller: p.isBestSeller,
        isNewArrival: p.isNewArrival,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const now = new Date();
    const coupons = [
      {
        id: 'coupon_welcome10',
        code: 'WELCOME10',
        description: '10% off for new customers',
        discountType: 'percentage',
        discountValue: 10,
        minOrderAmount: 500,
        maxDiscount: 300,
        usageLimit: 0,
      },
      {
        id: 'coupon_flat100',
        code: 'FLAT100',
        description: 'Rs 100 off orders over 1000',
        discountType: 'fixed',
        discountValue: 100,
        minOrderAmount: 1000,
        maxDiscount: null,
        usageLimit: 200,
      },
      {
        id: 'coupon_freeShip',
        code: 'KEYCHAIN15',
        description: '15% off keychains',
        discountType: 'percentage',
        discountValue: 15,
        minOrderAmount: 800,
        maxDiscount: 500,
        usageLimit: 50,
      },
    ];

    for (const c of coupons) {
      await db.collection('coupons').doc(c.id).set({
        code: c.code,
        description: c.description,
        discountType: c.discountType,
        discountValue: c.discountValue,
        minOrderAmount: c.minOrderAmount,
        maxDiscount: c.maxDiscount,
        usageLimit: c.usageLimit,
        usedCount: 0,
        validFrom: Timestamp.fromDate(new Date(now.getTime() - 86400000)),
        validUntil: Timestamp.fromDate(
          new Date(now.getTime() + 90 * 86400000),
        ),
        isActive: true,
      });
    }

    await db.collection('banners').doc('banner_home_1').set({
      title: 'Home-to-Home Delivery',
      subtitle: 'Custom keychains delivered to your door',
      imageUrl: 'https://picsum.photos/seed/banner1/1200/500',
      link: '/browse',
      sortOrder: 1,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection('banners').doc('banner_home_2').set({
      title: 'Personalized Gifts',
      subtitle: 'Engrave names & upload photos',
      imageUrl: 'https://picsum.photos/seed/banner2/1200/500',
      link: '/products?section=newArrival',
      sortOrder: 2,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
    });

    if (customer) {
      await db.collection('addresses').doc(`addr_${customer.uid}_home`).set({
        userId: customer.uid,
        fullName: customer.name,
        phone: '03002220002',
        houseStreet: 'House 12, Street 4',
        area: 'Gulshan',
        city: 'Karachi',
        postalCode: '75300',
        isDefault: true,
        createdAt: FieldValue.serverTimestamp(),
      });
      await db.collection('addresses').doc(`addr_${customer.uid}_office`).set({
        userId: customer.uid,
        fullName: customer.name,
        phone: '03002220002',
        houseStreet: 'Office 5, Tech Park',
        area: 'Clifton',
        city: 'Karachi',
        postalCode: '75600',
        isDefault: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      await db.collection('favorites').doc(`${customer.uid}_prod_brass_classic`).set({
        userId: customer.uid,
        productId: 'prod_brass_classic',
        createdAt: FieldValue.serverTimestamp(),
      });
      await db.collection('favorites').doc(`${customer.uid}_prod_custom_name`).set({
        userId: customer.uid,
        productId: 'prod_custom_name',
        createdAt: FieldValue.serverTimestamp(),
      });

      // Sample pending order for admin status testing
      const orderRef = db.collection('orders').doc('order_demo_pending');
      await orderRef.set({
        userId: customer.uid,
        userName: customer.name,
        userEmail: customer.email,
        userPhone: '03002220002',
        items: [
          {
            productId: 'prod_brass_classic',
            productName: 'Classic Brass Keychain',
            productImage: 'https://picsum.photos/seed/prod_brass_classic/600/600',
            price: 450,
            discount: 0,
            unitPrice: 450,
            quantity: 2,
            lineTotal: 900,
          },
        ],
        subtotal: 900,
        deliveryCharges: 150,
        discount: 0,
        totalAmount: 1050,
        couponCode: null,
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'pending',
        orderStatus: 'pending',
        deliveryAddress: {
          fullName: customer.name,
          phone: '03002220002',
          houseStreet: 'House 12, Street 4',
          area: 'Gulshan',
          city: 'Karachi',
          postalCode: '75300',
          formattedAddress: 'House 12, Street 4, Gulshan, Karachi',
        },
        deliveryId: null,
        riderId: null,
        notes: 'Demo order — ring the bell',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        estimatedDeliveryDate: Timestamp.fromDate(
          new Date(now.getTime() + 3 * 86400000),
        ),
        deliveredAt: null,
        statusHistory: [
          {
            status: 'pending',
            timestamp: Timestamp.now(),
            note: 'Order placed (seed)',
          },
        ],
      });

      // Delivered order so customer can test reviews
      await db.collection('orders').doc('order_demo_delivered').set({
        userId: customer.uid,
        userName: customer.name,
        userEmail: customer.email,
        userPhone: '03002220002',
        items: [
          {
            productId: 'prod_acrylic_heart',
            productName: 'Acrylic Heart Charm',
            productImage: 'https://picsum.photos/seed/prod_acrylic_heart/600/600',
            price: 299,
            discount: 15,
            unitPrice: 254.15,
            quantity: 1,
            lineTotal: 254.15,
          },
        ],
        subtotal: 254.15,
        deliveryCharges: 150,
        discount: 0,
        totalAmount: 404.15,
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'paid',
        orderStatus: 'delivered',
        deliveryAddress: {
          fullName: customer.name,
          phone: '03002220002',
          houseStreet: 'House 12, Street 4',
          area: 'Gulshan',
          city: 'Karachi',
          postalCode: '75300',
          formattedAddress: 'House 12, Street 4, Gulshan, Karachi',
        },
        deliveryId: 'delivery_demo_1',
        riderId: rider ? rider.uid : null,
        notes: null,
        createdAt: Timestamp.fromDate(new Date(now.getTime() - 5 * 86400000)),
        updatedAt: FieldValue.serverTimestamp(),
        estimatedDeliveryDate: Timestamp.fromDate(
          new Date(now.getTime() - 2 * 86400000),
        ),
        deliveredAt: FieldValue.serverTimestamp(),
        statusHistory: [
          {
            status: 'pending',
            timestamp: Timestamp.fromDate(new Date(now.getTime() - 5 * 86400000)),
            note: 'Order placed',
          },
          {
            status: 'delivered',
            timestamp: Timestamp.now(),
            note: 'Delivered (seed)',
          },
        ],
      });

      await db.collection('deliveries').doc('delivery_demo_1').set({
        orderId: 'order_demo_delivered',
        userId: customer.uid,
        riderId: rider ? rider.uid : null,
        riderName: rider ? rider.name : null,
        deliveryAddress: {
          fullName: customer.name,
          city: 'Karachi',
          area: 'Gulshan',
        },
        status: 'delivered',
        notes: 'Left with customer',
        assignedAt: Timestamp.fromDate(new Date(now.getTime() - 3 * 86400000)),
        deliveredAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Pending review for admin moderation
      await db.collection('reviews').doc('review_demo_pending').set({
        productId: 'prod_brass_classic',
        userId: customer.uid,
        userName: customer.name,
        userImage: null,
        orderId: 'order_demo_delivered',
        rating: 5,
        comment: 'Beautiful brass finish — waiting for admin approval (seed).',
        images: [],
        isApproved: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Already approved review visible on product
      if (customer2) {
        await db.collection('reviews').doc('review_demo_approved').set({
          productId: 'prod_brass_classic',
          userId: customer2.uid,
          userName: customer2.name,
          orderId: null,
          rating: 4,
          comment: 'Good quality, delivery was on time.',
          images: [],
          isApproved: true,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      await db.collection('notifications').doc(`notif_${customer.uid}_welcome`).set({
        userId: customer.uid,
        title: 'Welcome to Keychain Shop',
        body: 'Browse custom keychains with home-to-home delivery.',
        type: 'general',
        orderId: null,
        productId: null,
        data: {},
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    res.status(200).json({
      ok: true,
      message: 'Seed complete. Use the accounts below to test.',
      accounts: createdUsers.map((u) => ({
        role: u.role,
        email: u.email,
        password: u.password,
        name: u.name,
      })),
      seeded: {
        categories: categoryDefs.length,
        products: productDefs.length,
        coupons: coupons.length,
        banners: 2,
        sampleOrders: ['order_demo_pending', 'order_demo_delivered'],
      },
      tips: [
        'Customer login → browse, cart, checkout, orders, review delivered order',
        'Admin login → /admin/login → manage products, orders, coupons, reviews',
        'Try coupon WELCOME10 or FLAT100 at checkout',
        'Assign rider@keychainshop.test on deliveries in admin',
      ],
    });
  } catch (e) {
    console.error('[seedDemoData]', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});
