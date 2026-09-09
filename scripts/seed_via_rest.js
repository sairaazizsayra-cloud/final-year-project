/**
 * Seed Keychain Shop demo data (Spark-plan friendly).
 * Uses Auth REST + Firestore REST. Temporarily needs open write rules,
 * or run after: firebase deploy --only firestore:rules (seed rules).
 *
 * Usage (from repo root):
 *   node scripts/seed_via_rest.js
 */

const PROJECT_ID = 'keychain-shop';
const API_KEY = 'AIzaSyB6kzV-xgyIbIpVaIWdXVFztm_dUk_SNpQ'; // web key from firebase_options

const ACCOUNTS = [
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

function ts(date = new Date()) {
  const seconds = Math.floor(date.getTime() / 1000);
  return { timestampValue: new Date(seconds * 1000).toISOString() };
}

function str(v) {
  return { stringValue: String(v ?? '') };
}

function num(v) {
  return { doubleValue: Number(v) };
}

function int(v) {
  return { integerValue: String(Math.trunc(v)) };
}

function bool(v) {
  return { booleanValue: !!v };
}

function nullVal() {
  return { nullValue: null };
}

function arr(values) {
  return { arrayValue: { values } };
}

function map(fields) {
  return { mapValue: { fields } };
}

/** Real keychain / keys photos (Unsplash), cropped square. */
function keychainPhoto(index) {
  const photos = [
    'photo-1727154085760-134cc942246e',
    'photo-1674660638936-c0005c862a0d',
    'photo-1676276550349-580c49631496',
    'photo-1611006294560-1fab7641e0a3',
    'photo-1687363714985-990685339050',
    'photo-1595944356863-e624f8234e1e',
    'photo-1603508102977-02688e3265fd',
    'photo-1714631281605-a849ba8e90b5',
    'photo-1741254720220-5fec5d24b546',
    'photo-1624505474107-840f25fbfb96',
    'photo-1575908539614-ff89490f4a78',
    'photo-1698423955414-fee71b18e0b6',
    'photo-1748273734249-604fc3a72b88',
    'photo-1678929480581-d8e55cda190b',
    'photo-1675582090584-4ae9400f7326',
    'photo-1582139329536-e7284fece509',
  ];
  const id = photos[Math.abs(index) % photos.length];
  return `https://images.unsplash.com/${id}?auto=format&fit=crop&w=600&h=600&q=80`;
}

async function signUpOrSignIn(email, password) {
  const signUpUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
  let res = await fetch(signUpUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  let data = await res.json();
  if (data.localId) {
    return { uid: data.localId, idToken: data.idToken };
  }

  const signInUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
  res = await fetch(signInUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  data = await res.json();
  if (!data.localId) {
    throw new Error(`Auth failed for ${email}: ${JSON.stringify(data.error || data)}`);
  }
  return { uid: data.localId, idToken: data.idToken };
}

async function setDoc(path, fields, idToken) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields }),
  });
  const data = await res.json();
  if (data.error) {
    // Retry without auth if rules temporarily allow public write
    const res2 = await fetch(url, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields }),
    });
    const data2 = await res2.json();
    if (data2.error) {
      throw new Error(`${path}: ${data.error.message} | fallback: ${data2.error.message}`);
    }
    return data2;
  }
  return data;
}

async function main() {
  console.log('Creating Auth users…');
  const users = [];
  for (const a of ACCOUNTS) {
    const { uid, idToken } = await signUpOrSignIn(a.email, a.password);
    users.push({ ...a, uid, idToken });
    console.log(`  ${a.role}: ${a.email} → ${uid}`);
  }

  const admin = users.find((u) => u.role === 'admin');
  const customer = users.find((u) => u.email === 'customer@keychainshop.test');
  const customer2 = users.find((u) => u.email === 'customer2@keychainshop.test');
  const rider = users.find((u) => u.role === 'rider');
  const token = admin.idToken;

  console.log('Writing user profiles…');
  for (const u of users) {
    await setDoc(
      `users/${u.uid}`,
      {
        name: str(u.name),
        email: str(u.email),
        phone: str(u.phone),
        profileImage: nullVal(),
        role: str(u.role),
        isActive: bool(true),
        fcmToken: nullVal(),
        createdAt: ts(),
        updatedAt: ts(),
      },
      token,
    );
  }
  await setDoc(
    `admins/${admin.uid}`,
    {
      email: str(admin.email),
      name: str(admin.name),
      createdAt: ts(),
    },
    token,
  );

  const categories = [
    { id: 'cat_metal', name: 'Metal Keychains', description: 'Brass & steel', sortOrder: 1 },
    { id: 'cat_acrylic', name: 'Acrylic Keychains', description: 'Colorful acrylic', sortOrder: 2 },
    { id: 'cat_leather', name: 'Leather Keychains', description: 'Leather tags', sortOrder: 3 },
    { id: 'cat_custom', name: 'Custom Name', description: 'Personalized', sortOrder: 4 },
    { id: 'cat_couple', name: 'Couple Sets', description: 'Matching pairs', sortOrder: 5 },
  ];

  console.log('Writing categories…');
  for (const c of categories) {
    await setDoc(
      `categories/${c.id}`,
      {
        name: str(c.name),
        description: str(c.description),
        imageUrl: str(keychainPhoto(c.sortOrder)),
        sortOrder: int(c.sortOrder),
        isActive: bool(true),
        createdAt: ts(),
      },
      token,
    );
  }

  const products = [
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
    {
      id: 'prod_feat_only_1',
      name: 'Featured Emblem Keychain',
      categoryId: 'cat_metal',
      categoryName: 'Metal Keychains',
      price: 520,
      discount: 0,
      stock: 40,
      isFeatured: true,
      isBestSeller: false,
      isNewArrival: false,
      isCustomizable: false,
      material: 'Brass',
      colors: ['Gold'],
    },
    {
      id: 'prod_feat_only_2',
      name: 'Featured Crystal Charm',
      categoryId: 'cat_acrylic',
      categoryName: 'Acrylic Keychains',
      price: 480,
      discount: 0,
      stock: 35,
      isFeatured: true,
      isBestSeller: false,
      isNewArrival: false,
      isCustomizable: false,
      material: 'Acrylic',
      colors: ['Clear', 'Purple'],
    },
    {
      id: 'prod_new_only_1',
      name: 'Fresh Drop Motif',
      categoryId: 'cat_acrylic',
      categoryName: 'Acrylic Keychains',
      price: 360,
      discount: 0,
      stock: 70,
      isFeatured: false,
      isBestSeller: false,
      isNewArrival: true,
      isCustomizable: false,
      material: 'Acrylic',
      colors: ['Blue', 'Green'],
    },
    {
      id: 'prod_new_only_2',
      name: 'Just In Leather Tab',
      categoryId: 'cat_leather',
      categoryName: 'Leather Keychains',
      price: 690,
      discount: 0,
      stock: 28,
      isFeatured: false,
      isBestSeller: false,
      isNewArrival: true,
      isCustomizable: true,
      material: 'Leather',
      colors: ['Black'],
    },
    {
      id: 'prod_best_only_1',
      name: 'Top Pick Steel Tag',
      categoryId: 'cat_metal',
      categoryName: 'Metal Keychains',
      price: 410,
      discount: 0,
      stock: 90,
      isFeatured: false,
      isBestSeller: true,
      isNewArrival: false,
      isCustomizable: false,
      material: 'Steel',
      colors: ['Silver'],
    },
    {
      id: 'prod_best_only_2',
      name: 'Bestseller Couple Ring',
      categoryId: 'cat_couple',
      categoryName: 'Couple Sets',
      price: 999,
      discount: 0,
      stock: 22,
      isFeatured: false,
      isBestSeller: true,
      isNewArrival: false,
      isCustomizable: true,
      material: 'Mixed',
      colors: ['Gold', 'Rose Gold'],
    },
    {
      id: 'prod_sale_only_1',
      name: 'Flash Sale Acrylic',
      categoryId: 'cat_acrylic',
      categoryName: 'Acrylic Keychains',
      price: 450,
      discount: 25,
      stock: 55,
      isFeatured: false,
      isBestSeller: false,
      isNewArrival: false,
      isCustomizable: false,
      material: 'Acrylic',
      colors: ['Red'],
    },
    {
      id: 'prod_sale_only_2',
      name: 'Clearance Metal Loop',
      categoryId: 'cat_metal',
      categoryName: 'Metal Keychains',
      price: 380,
      discount: 30,
      stock: 48,
      isFeatured: false,
      isBestSeller: false,
      isNewArrival: false,
      isCustomizable: false,
      material: 'Zinc Alloy',
      colors: ['Black', 'Silver'],
    },
  ];

  console.log('Writing products…');
  for (const p of products) {
    await setDoc(
      `products/${p.id}`,
      {
        name: str(p.name),
        nameLower: str(p.name.toLowerCase()),
        description: str(
          `${p.name} — quality keychain for everyday carry. Home-to-home delivery available.`,
        ),
        categoryId: str(p.categoryId),
        categoryName: str(p.categoryName),
        price: num(p.price),
        discount: num(p.discount),
        stock: int(p.stock),
        images: arr([
          str(keychainPhoto(products.indexOf(p))),
          str(keychainPhoto(products.indexOf(p) + 7)),
        ]),
        material: str(p.material),
        size: str('Standard'),
        colors: arr(p.colors.map(str)),
        isCustomizable: bool(p.isCustomizable),
        rating: num(4.2),
        totalReviews: int(3),
        isFeatured: bool(p.isFeatured),
        isBestSeller: bool(p.isBestSeller),
        isNewArrival: bool(p.isNewArrival),
        isActive: bool(true),
        createdAt: ts(),
        updatedAt: ts(),
      },
      token,
    );
  }

  console.log('Writing coupons & banners…');
  const now = Date.now();
  const couponList = [
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
      id: 'coupon_keychain15',
      code: 'KEYCHAIN15',
      description: '15% off keychains',
      discountType: 'percentage',
      discountValue: 15,
      minOrderAmount: 800,
      maxDiscount: 500,
      usageLimit: 50,
    },
  ];

  for (const c of couponList) {
    const fields = {
      code: str(c.code),
      description: str(c.description),
      discountType: str(c.discountType),
      discountValue: num(c.discountValue),
      minOrderAmount: num(c.minOrderAmount),
      usageLimit: int(c.usageLimit),
      usedCount: int(0),
      validFrom: ts(new Date(now - 86400000)),
      validUntil: ts(new Date(now + 90 * 86400000)),
      isActive: bool(true),
    };
    if (c.maxDiscount == null) fields.maxDiscount = nullVal();
    else fields.maxDiscount = num(c.maxDiscount);
    await setDoc(`coupons/${c.id}`, fields, token);
  }

  await setDoc(
    'banners/banner_home_1',
    {
      title: str('Home-to-Home Delivery'),
      subtitle: str('Custom keychains delivered to your door'),
      imageUrl: str(keychainPhoto(0).replace('w=600&h=600', 'w=1200&h=500')),
      link: str('/browse'),
      sortOrder: int(1),
      isActive: bool(true),
      createdAt: ts(),
    },
    token,
  );
  await setDoc(
    'banners/banner_home_2',
    {
      title: str('Personalized Gifts'),
      subtitle: str('Engrave names & upload photos'),
      imageUrl: str(keychainPhoto(2).replace('w=600&h=600', 'w=1200&h=500')),
      link: str('/products'),
      sortOrder: int(2),
      isActive: bool(true),
      createdAt: ts(),
    },
    token,
  );

  console.log('Writing customer addresses, favorites, orders…');
  await setDoc(
    `addresses/addr_${customer.uid}_home`,
    {
      userId: str(customer.uid),
      fullName: str(customer.name),
      phone: str(customer.phone),
      houseStreet: str('House 12, Street 4'),
      area: str('Gulshan'),
      city: str('Karachi'),
      postalCode: str('75300'),
      isDefault: bool(true),
      createdAt: ts(),
    },
    token,
  );
  await setDoc(
    `addresses/addr_${customer.uid}_office`,
    {
      userId: str(customer.uid),
      fullName: str(customer.name),
      phone: str(customer.phone),
      houseStreet: str('Office 5, Tech Park'),
      area: str('Clifton'),
      city: str('Karachi'),
      postalCode: str('75600'),
      isDefault: bool(false),
      createdAt: ts(),
    },
    token,
  );

  await setDoc(
    `favorites/${customer.uid}_prod_brass_classic`,
    {
      userId: str(customer.uid),
      productId: str('prod_brass_classic'),
      createdAt: ts(),
    },
    token,
  );
  await setDoc(
    `favorites/${customer.uid}_prod_custom_name`,
    {
      userId: str(customer.uid),
      productId: str('prod_custom_name'),
      createdAt: ts(),
    },
    token,
  );

  await setDoc(
    'orders/order_demo_pending',
    {
      userId: str(customer.uid),
      userName: str(customer.name),
      userEmail: str(customer.email),
      userPhone: str(customer.phone),
      items: arr([
        map({
          productId: str('prod_brass_classic'),
          productName: str('Classic Brass Keychain'),
          productImage: str(keychainPhoto(0)),
          price: num(450),
          discount: num(0),
          unitPrice: num(450),
          quantity: int(2),
          lineTotal: num(900),
        }),
      ]),
      subtotal: num(900),
      deliveryCharges: num(150),
      discount: num(0),
      totalAmount: num(1050),
      couponCode: nullVal(),
      paymentMethod: str('cash_on_delivery'),
      paymentStatus: str('pending'),
      orderStatus: str('pending'),
      deliveryAddress: map({
        fullName: str(customer.name),
        phone: str(customer.phone),
        houseStreet: str('House 12, Street 4'),
        area: str('Gulshan'),
        city: str('Karachi'),
        postalCode: str('75300'),
        formattedAddress: str('House 12, Street 4, Gulshan, Karachi'),
      }),
      deliveryId: nullVal(),
      riderId: nullVal(),
      notes: str('Demo order — ring the bell'),
      createdAt: ts(),
      updatedAt: ts(),
      estimatedDeliveryDate: ts(new Date(now + 3 * 86400000)),
      deliveredAt: nullVal(),
      statusHistory: arr([
        map({
          status: str('pending'),
          timestamp: ts(),
          note: str('Order placed (seed)'),
        }),
      ]),
    },
    token,
  );

  await setDoc(
    'orders/order_demo_delivered',
    {
      userId: str(customer.uid),
      userName: str(customer.name),
      userEmail: str(customer.email),
      userPhone: str(customer.phone),
      items: arr([
        map({
          productId: str('prod_acrylic_heart'),
          productName: str('Acrylic Heart Charm'),
          productImage: str(keychainPhoto(2)),
          price: num(299),
          discount: num(15),
          unitPrice: num(254.15),
          quantity: int(1),
          lineTotal: num(254.15),
        }),
      ]),
      subtotal: num(254.15),
      deliveryCharges: num(150),
      discount: num(0),
      totalAmount: num(404.15),
      paymentMethod: str('cash_on_delivery'),
      paymentStatus: str('paid'),
      orderStatus: str('delivered'),
      deliveryAddress: map({
        fullName: str(customer.name),
        phone: str(customer.phone),
        houseStreet: str('House 12, Street 4'),
        area: str('Gulshan'),
        city: str('Karachi'),
        postalCode: str('75300'),
        formattedAddress: str('House 12, Street 4, Gulshan, Karachi'),
      }),
      deliveryId: str('delivery_demo_1'),
      riderId: str(rider.uid),
      notes: nullVal(),
      createdAt: ts(new Date(now - 5 * 86400000)),
      updatedAt: ts(),
      estimatedDeliveryDate: ts(new Date(now - 2 * 86400000)),
      deliveredAt: ts(),
      statusHistory: arr([
        map({
          status: str('pending'),
          timestamp: ts(new Date(now - 5 * 86400000)),
          note: str('Order placed'),
        }),
        map({
          status: str('delivered'),
          timestamp: ts(),
          note: str('Delivered (seed)'),
        }),
      ]),
    },
    token,
  );

  await setDoc(
    'deliveries/delivery_demo_1',
    {
      orderId: str('order_demo_delivered'),
      userId: str(customer.uid),
      riderId: str(rider.uid),
      riderName: str(rider.name),
      deliveryAddress: map({
        fullName: str(customer.name),
        city: str('Karachi'),
        area: str('Gulshan'),
      }),
      status: str('delivered'),
      notes: str('Left with customer'),
      assignedAt: ts(new Date(now - 3 * 86400000)),
      deliveredAt: ts(),
      updatedAt: ts(),
    },
    token,
  );

  await setDoc(
    'reviews/review_demo_pending',
    {
      productId: str('prod_brass_classic'),
      userId: str(customer.uid),
      userName: str(customer.name),
      userImage: nullVal(),
      orderId: str('order_demo_delivered'),
      rating: num(5),
      comment: str('Beautiful brass finish — pending admin approval (seed).'),
      images: arr([]),
      isApproved: bool(false),
      createdAt: ts(),
    },
    token,
  );

  await setDoc(
    'reviews/review_demo_approved',
    {
      productId: str('prod_brass_classic'),
      userId: str(customer2.uid),
      userName: str(customer2.name),
      orderId: nullVal(),
      rating: num(4),
      comment: str('Good quality, delivery was on time.'),
      images: arr([]),
      isApproved: bool(true),
      createdAt: ts(),
    },
    token,
  );

  await setDoc(
    `notifications/notif_${customer.uid}_welcome`,
    {
      userId: str(customer.uid),
      title: str('Welcome to Keychain Shop'),
      body: str('Browse custom keychains with home-to-home delivery.'),
      type: str('general'),
      orderId: nullVal(),
      productId: nullVal(),
      isRead: bool(false),
      createdAt: ts(),
    },
    token,
  );

  console.log('\n✅ Seed complete!\n');
  console.log('CREDENTIALS');
  console.log('-----------');
  for (const u of users) {
    console.log(`${u.role.padEnd(10)} ${u.email}  /  ${u.password}`);
  }
  console.log('\nCoupons: WELCOME10 | FLAT100 | KEYCHAIN15');
  console.log('Admin login path in app: /admin/login');
}

main().catch((e) => {
  console.error('\n❌ Seed failed:', e.message || e);
  console.error(
    '\nIf permission denied: deploy temporary seed rules first:\n' +
      '  copy firestore.rules.seed → firestore.rules (or use the seed file)\n' +
      '  firebase deploy --only firestore:rules\n' +
      '  node scripts/seed_via_rest.js\n' +
      '  restore production firestore.rules and deploy again\n',
  );
  process.exit(1);
});
