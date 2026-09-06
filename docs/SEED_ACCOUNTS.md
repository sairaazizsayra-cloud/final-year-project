# Demo seed accounts — Keychain Shop

Seed was applied via `scripts/seed_via_rest.js` (works on Spark plan).

Re-seed later:

```bash
# 1) Temporarily open rules (only while seeding)
copy firestore.rules.seed firestore.rules
firebase deploy --only firestore:rules --project keychain-shop

# 2) Seed
node scripts/seed_via_rest.js

# 3) Restore secure rules from git
git checkout -- firestore.rules
firebase deploy --only firestore:rules --project keychain-shop
```

## Login credentials

| Role | Email | Password | Where |
|------|-------|----------|--------|
| **Admin** | `admin@keychainshop.test` | `Admin@12345` | App → **Admin login** |
| **Customer** | `customer@keychainshop.test` | `Customer@12345` | Customer login |
| **Customer 2** | `customer2@keychainshop.test` | `Customer@12345` | Customer login |
| **Rider** | `rider@keychainshop.test` | `Rider@12345` | For admin delivery assignment |

## Coupons to try at checkout

- `WELCOME10` — 10% off (min Rs 500)
- `FLAT100` — Rs 100 off (min Rs 1000)
- `KEYCHAIN15` — 15% off (min Rs 800)

## Seeded content

- 5 categories, 10 products
- Addresses + favorites for main customer
- Orders: `order_demo_pending`, `order_demo_delivered`
- Delivery assigned to rider
- Reviews: 1 pending (approve in Admin), 1 approved
- Welcome notification

## Suggested test path

1. **Customer** → browse → cart → checkout with `WELCOME10` → COD  
2. **Admin** → Orders → update pending order status → assign rider  
3. **Customer** → delivered order → write review  
4. **Admin** → Reviews → approve pending review  
5. **Admin** → Coupons / Products / Reports / Customers  
