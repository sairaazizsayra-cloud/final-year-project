/**
 * Rename products to match keychain photos + add more catalog items.
 * Run: node scripts/expand_keychain_catalog.js
 */

const PROJECT_ID = 'keychain-shop';
const API_KEY = 'AIzaSyB6kzV-xgyIbIpVaIWdXVFztm_dUk_SNpQ';

const ADMIN = {
  email: 'admin@keychainshop.test',
  password: 'Admin@12345',
};

function u(photoId) {
  return `https://images.unsplash.com/${photoId}?auto=format&fit=crop&w=600&h=600&q=80`;
}

/** Each entry: photo + display name that matches what you see in the image. */
const PHOTO_BANK = [
  {
    id: 'photo-1727154085760-134cc942246e',
    name: 'Metal Heart Keychain',
    material: 'Metal',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1674660638936-c0005c862a0d',
    name: 'Number Charm Keychain Set',
    material: 'Acrylic',
    categoryId: 'cat_acrylic',
    categoryName: 'Acrylic Keychains',
  },
  {
    id: 'photo-1676276550349-580c49631496',
    name: 'Leather Key Fob Tag',
    material: 'Genuine Leather',
    categoryId: 'cat_leather',
    categoryName: 'Leather Keychains',
  },
  {
    id: 'photo-1611006294560-1fab7641e0a3',
    name: 'Silver Heart Pendant Keychain',
    material: 'Silver Alloy',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1687363714985-990685339050',
    name: 'Couple Matching Keychains',
    material: 'Mixed Metal',
    categoryId: 'cat_couple',
    categoryName: 'Couple Sets',
  },
  {
    id: 'photo-1595944356863-e624f8234e1e',
    name: 'Color Pop Charm Keychain',
    material: 'Acrylic',
    categoryId: 'cat_acrylic',
    categoryName: 'Acrylic Keychains',
  },
  {
    id: 'photo-1603508102977-02688e3265fd',
    name: 'Black & Silver Keys Keychain',
    material: 'Stainless Steel',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1714631281605-a849ba8e90b5',
    name: 'Door Hook Metal Keychain',
    material: 'Zinc Alloy',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1741254720220-5fec5d24b546',
    name: 'Cute Anime Girl Keychain',
    material: 'Acrylic',
    categoryId: 'cat_acrylic',
    categoryName: 'Acrylic Keychains',
  },
  {
    id: 'photo-1624505474107-840f25fbfb96',
    name: 'Wooden Name Tag Keychain',
    material: 'Wood',
    categoryId: 'cat_custom',
    categoryName: 'Custom Name',
  },
  {
    id: 'photo-1575908539614-ff89490f4a78',
    name: 'Triple Silver Keys Set',
    material: 'Silver',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1698423955414-fee71b18e0b6',
    name: 'Smiley Face Charm Keychain',
    material: 'Acrylic',
    categoryId: 'cat_acrylic',
    categoryName: 'Acrylic Keychains',
  },
  {
    id: 'photo-1748273734249-604fc3a72b88',
    name: 'Golden Teddy Bear Keychain',
    material: 'Gold Plated',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1678929480581-d8e55cda190b',
    name: 'Handcrafted Metal Charm Keychain',
    material: 'Metal',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
  {
    id: 'photo-1675582090584-4ae9400f7326',
    name: 'Everyday Keys Leather Loop',
    material: 'Leather',
    categoryId: 'cat_leather',
    categoryName: 'Leather Keychains',
  },
  {
    id: 'photo-1582139329536-e7284fece509',
    name: 'Classic House Keys Keychain',
    material: 'Steel',
    categoryId: 'cat_metal',
    categoryName: 'Metal Keychains',
  },
];

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
function ts(date = new Date()) {
  const seconds = Math.floor(date.getTime() / 1000);
  return { timestampValue: new Date(seconds * 1000).toISOString() };
}
function arr(values) {
  return { arrayValue: { values } };
}

function photoUrl(photoId) {
  return u(photoId);
}

function buildCatalog() {
  const products = [];

  // Rename + re-image existing IDs so current app docs stay linked
  const existingIds = [
    'prod_brass_classic',
    'prod_steel_ring',
    'prod_acrylic_heart',
    'prod_acrylic_photo',
    'prod_leather_tag',
    'prod_leather_loop',
    'prod_custom_name',
    'prod_couple_heart',
    'prod_mini_car',
    'prod_initial_disk',
    'prod_feat_only_1',
    'prod_feat_only_2',
    'prod_new_only_1',
    'prod_new_only_2',
    'prod_best_only_1',
    'prod_best_only_2',
    'prod_sale_only_1',
    'prod_sale_only_2',
  ];

  existingIds.forEach((id, i) => {
    const photo = PHOTO_BANK[i % PHOTO_BANK.length];
    const alt = PHOTO_BANK[(i + 5) % PHOTO_BANK.length];
    products.push({
      id,
      name: photo.name,
      description: `${photo.name} — real keychain style for everyday carry. Home-to-home delivery available.`,
      categoryId: photo.categoryId,
      categoryName: photo.categoryName,
      price: 299 + (i % 8) * 80,
      discount: i % 4 === 0 ? 10 : i % 5 === 0 ? 15 : 0,
      stock: 25 + (i % 6) * 10,
      material: photo.material,
      colors: ['Gold', 'Silver', 'Black', 'Rose Gold'].slice(0, 2 + (i % 2)),
      isCustomizable: photo.categoryId === 'cat_custom' || photo.categoryId === 'cat_couple',
      isFeatured: i < 6,
      isBestSeller: i % 3 === 0,
      isNewArrival: i % 4 === 1,
      images: [photoUrl(photo.id), photoUrl(alt.id)],
    });
  });

  // Extra products — unique IDs, same photo bank cycling with variant names
  const extras = [
    { id: 'prod_kc_heart_metal', photo: 0, name: 'Engraved Metal Heart Keychain', price: 549, featured: true, best: true, neu: false, discount: 0 },
    { id: 'prod_kc_number_set', photo: 1, name: 'Lucky Number Keychain Pack', price: 399, featured: false, best: true, neu: true, discount: 5 },
    { id: 'prod_kc_leather_fob', photo: 2, name: 'Premium Leather Key Fob', price: 799, featured: true, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_heart_silver', photo: 3, name: 'Rose Heart Charm Keychain', price: 459, featured: true, best: false, neu: false, discount: 12 },
    { id: 'prod_kc_couple_pair', photo: 4, name: 'His & Hers Couple Keychains', price: 1299, featured: true, best: true, neu: false, discount: 20 },
    { id: 'prod_kc_color_charms', photo: 5, name: 'Rainbow Charm Keychain', price: 349, featured: false, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_black_silver', photo: 6, name: 'Matte Black Key Ring Set', price: 429, featured: false, best: true, neu: false, discount: 8 },
    { id: 'prod_kc_door_hook', photo: 7, name: 'Vintage Door Keychain', price: 389, featured: false, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_anime', photo: 8, name: 'Kawaii Character Keychain', price: 379, featured: true, best: true, neu: true, discount: 10 },
    { id: 'prod_kc_wood_tag', photo: 9, name: 'Custom Wooden Name Keychain', price: 699, featured: true, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_triple_keys', photo: 10, name: 'Silver Trio Key Bundle', price: 519, featured: false, best: true, neu: false, discount: 0 },
    { id: 'prod_kc_smiley', photo: 11, name: 'Happy Smiley Keychain', price: 279, featured: false, best: false, neu: true, discount: 15 },
    { id: 'prod_kc_teddy', photo: 12, name: 'Gold Teddy Keychain Charm', price: 649, featured: true, best: true, neu: false, discount: 5 },
    { id: 'prod_kc_metal_hand', photo: 13, name: 'Artisan Metal Key Pendant', price: 589, featured: false, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_leather_daily', photo: 14, name: 'Daily Carry Leather Keychain', price: 729, featured: false, best: true, neu: false, discount: 0 },
    { id: 'prod_kc_house_keys', photo: 15, name: 'House Keys Classic Keychain', price: 359, featured: false, best: false, neu: false, discount: 25 },
    { id: 'prod_kc_initial_wood', photo: 9, name: 'Initial Wood Disk Keychain', price: 559, featured: false, best: false, neu: true, discount: 0 },
    { id: 'prod_kc_couple_hearts', photo: 4, name: 'Linked Hearts Couple Set', price: 1099, featured: true, best: false, neu: true, discount: 18 },
  ];

  extras.forEach((e, i) => {
    const photo = PHOTO_BANK[e.photo];
    const alt = PHOTO_BANK[(e.photo + 3) % PHOTO_BANK.length];
    products.push({
      id: e.id,
      name: e.name,
      description: `${e.name} — quality keychain inspired by the product photo. Delivered home-to-home.`,
      categoryId: photo.categoryId,
      categoryName: photo.categoryName,
      price: e.price,
      discount: e.discount,
      stock: 30 + i * 2,
      material: photo.material,
      colors: ['Gold', 'Silver', 'Black'],
      isCustomizable: photo.categoryId === 'cat_custom' || photo.categoryId === 'cat_couple',
      isFeatured: e.featured,
      isBestSeller: e.best,
      isNewArrival: e.neu,
      images: [photoUrl(photo.id), photoUrl(alt.id)],
    });
  });

  return products;
}

async function signIn(email, password) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const data = await res.json();
  if (!data.idToken) {
    throw new Error(`Admin sign-in failed: ${JSON.stringify(data.error || data)}`);
  }
  return data.idToken;
}

async function upsertProduct(product, idToken) {
  const path = `products/${product.id}`;
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`;
  const fields = {
    name: str(product.name),
    nameLower: str(product.name.toLowerCase()),
    description: str(product.description),
    categoryId: str(product.categoryId),
    categoryName: str(product.categoryName),
    price: num(product.price),
    discount: num(product.discount),
    stock: int(product.stock),
    images: arr(product.images.map(str)),
    material: str(product.material),
    size: str('Standard'),
    colors: arr(product.colors.map(str)),
    isCustomizable: bool(product.isCustomizable),
    rating: num(4.3 + (product.price % 7) * 0.05),
    totalReviews: int(2 + (product.stock % 10)),
    isFeatured: bool(product.isFeatured),
    isBestSeller: bool(product.isBestSeller),
    isNewArrival: bool(product.isNewArrival),
    isActive: bool(true),
    createdAt: ts(),
    updatedAt: ts(),
  };

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
    throw new Error(`${path}: ${data.error.message}`);
  }
}

async function main() {
  const catalog = buildCatalog();
  console.log(`Signing in as admin… (${catalog.length} products)`);
  const token = await signIn(ADMIN.email, ADMIN.password);

  for (const p of catalog) {
    await upsertProduct(p, token);
    console.log(`  ✓ ${p.id} → ${p.name}`);
  }

  console.log(`Done. ${catalog.length} keychain products ready. Pull-to-refresh the app.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
