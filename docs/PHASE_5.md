# Phase 5 Completion Report

## Completed

- Orders list with tabs: **Ongoing / Completed / Cancelled**
- Order detail with full **tracking timeline**
- Customer **cancel** while status is `pending`
- Home-to-home **delivery address** + **delivery assignment** card on order detail
- In-app **Notifications** screen (Firestore)
- **FCM** initialization, permission, token sync to `users.fcmToken`
- Foreground FCM snackbars + tap-to-open order
- Cloud Functions:
  - `onOrderCreated` → notification + FCM
  - `onOrderUpdated` → notification + FCM + delivery upsert
  - `updateOrderStatus` (admin) with status history
- Profile / Home / Order success wired to orders & notifications

## Routes

| Path | Screen |
|------|--------|
| `/orders` | Orders tabs (`?tab=0\|1\|2`) |
| `/orders/:id` | Order detail + tracking |
| `/notifications` | Notifications inbox |

## Deploy Cloud Functions (required for push + auto notifications)

```bash
cd firebase/functions
npm install
firebase deploy --only functions
```

Without deploy, orders/tracking still work; in-app notifications & FCM need the triggers.

## Test

1. Place a COD order → open Track order
2. In Firestore, change `orders/{id}.orderStatus` to `confirmed` → `preparing` → …
3. Confirm notification docs appear and timeline updates
4. Cancel a pending order from the app
5. When status is `shipped`, confirm a `deliveries` doc is created

## Next: Phase 6

Admin authentication, dashboard, product/category/customer management.

Reply **"continue Phase 6"** when ready.

