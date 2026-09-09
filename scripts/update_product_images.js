/**
 * Replace product/category picsum placeholders with real keychain photos (Unsplash).
 * Run: node scripts/update_product_images.js
 */

const PROJECT_ID = 'keychain-shop';
const API_KEY = 'AIzaSyB6kzV-xgyIbIpVaIWdXVFztm_dUk_SNpQ';

const ADMIN = {
  email: 'admin@keychainshop.test',
  password: 'Admin@12345',
};

/** Stable Unsplash keychain / keys / charm photos (w=600 square crop). */
function u(photoId) {
  return `https://images.unsplash.com/${photoId}?auto=format&fit=crop&w=600&h=600&q=80`;
}

const KEYCHAIN_PHOTOS = [
  u('photo-1727154085760-134cc942246e'), // metal heart keychain
  u('photo-1674660638936-c0005c862a0d'), // numbered keychains
  u('photo-1676276550349-580c49631496'), // leather keychain + card holder
  u('photo-1611006294560-1fab7641e0a3'), // heart pendant
  u('photo-1687363714985-990685339050'), // couple key chains
  u('photo-1595944356863-e624f8234e1e'), // colorful hanging charms
  u('photo-1603508102977-02688e3265fd'), // black & silver keys
  u('photo-1714631281605-a849ba8e90b5'), // keychain on door handle
  u('photo-1741254720220-5fec5d24b546'), // cute character keychain
  u('photo-1624505474107-840f25fbfb96'), // wooden pendant / tag
  u('photo-1575908539614-ff89490f4a78'), // three silver keys
  u('photo-1698423955414-fee71b18e0b6'), // smile charms
  u('photo-1748273734249-604fc3a72b88'), // golden teddy keychain
  u('photo-1678929480581-d8e55cda190b'), // metal keychain in hand
  u('photo-1675582090584-4ae9400f7326'), // wallet + keys
  u('photo-1650566121452-c45483458192'), // accessory flat lay
  u('photo-1703589535872-93c3b0f96ba3'), // desk keys / fob
  u('photo-1582139329536-e7284fece509'), // classic keys set
];

const PRODUCT_IDS = [
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

const CATEGORY_IDS = [
  'cat_metal',
  'cat_acrylic',
  'cat_leather',
  'cat_custom',
  'cat_couple',
];

function str(v) {
  return { stringValue: String(v ?? '') };
}

function ts(date = new Date()) {
  const seconds = Math.floor(date.getTime() / 1000);
  return { timestampValue: new Date(seconds * 1000).toISOString() };
}

function arr(values) {
  return { arrayValue: { values } };
}

function imagesFor(index) {
  const a = KEYCHAIN_PHOTOS[index % KEYCHAIN_PHOTOS.length];
  const b = KEYCHAIN_PHOTOS[(index + 7) % KEYCHAIN_PHOTOS.length];
  return [a, b];
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

async function patchFields(path, fields, fieldPaths, idToken) {
  const mask = fieldPaths
    .map((p) => `updateMask.fieldPaths=${encodeURIComponent(p)}`)
    .join('&');
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}?${mask}`;
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
  return data;
}

async function main() {
  console.log('Signing in as admin…');
  const token = await signIn(ADMIN.email, ADMIN.password);

  console.log('Updating product images…');
  for (let i = 0; i < PRODUCT_IDS.length; i++) {
    const id = PRODUCT_IDS[i];
    const imgs = imagesFor(i);
    await patchFields(
      `products/${id}`,
      {
        images: arr(imgs.map(str)),
        updatedAt: ts(),
      },
      ['images', 'updatedAt'],
      token,
    );
    console.log(`  ✓ ${id}`);
  }

  console.log('Updating category images…');
  for (let i = 0; i < CATEGORY_IDS.length; i++) {
    const id = CATEGORY_IDS[i];
    const img = KEYCHAIN_PHOTOS[i % KEYCHAIN_PHOTOS.length];
    await patchFields(
      `categories/${id}`,
      {
        imageUrl: str(img),
      },
      ['imageUrl'],
      token,
    );
    console.log(`  ✓ ${id}`);
  }

  console.log('Done. Pull-to-refresh home in the app.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
