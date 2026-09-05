# Phase 6 Completion Report

## Completed

- Admin login (`/admin/login`) via Firebase Auth + `role == admin`
- Admin shell (rail / drawer): Dashboard, Products, Categories, Customers
- Dashboard stats: products, customers, orders, pending/completed/cancelled, revenue, recent orders, best sellers
- Product management: list, search, filters, add/edit form, image upload to Storage, delete
- Category management: list, add/edit sheet, image upload, delete
- Customer management: search, activate/deactivate
- Customer login screen link → Admin login
- Admin can open Customer app from the admin bar

## Create an admin user

1. Firebase Console → Authentication → Add user (email/password)
2. Firestore → `users/{uid}`:

```json
{
  "name": "Admin",
  "email": "admin@example.com",
  "role": "admin",
  "isActive": true,
  "createdAt": "<timestamp>"
}
```

3. Open app → **Admin login** → sign in

## Routes

| Path | Screen |
|------|--------|
| `/admin/login` | Admin auth |
| `/admin` | Dashboard |
| `/admin/products` | Product list |
| `/admin/products/form` | Add / edit product |
| `/admin/categories` | Categories | 
| `/admin/customers` | Customers |

## Next: Phase 7

Admin order management, delivery management, reviews, coupons, reports.

→ See `docs/PHASE_7.md` (completed).

