# Firebase Setup Guide — Keychain Shop

## 1. Create Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Add project → e.g. `keychain-shop`
3. Disable Google Analytics if not needed (optional)

## 2. Register Flutter apps

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select Android (`com.keychainshop.keychain_shop`), iOS, and Web as needed.

This generates `lib/firebase_options.dart` and platform config (`google-services.json`, etc.).

## 3. Enable Authentication

Firebase Console → **Authentication** → **Sign-in method** → enable **Email/Password**.

## 4. Create Firestore

1. **Build → Firestore Database → Create database**
2. Start in **production mode**
3. Deploy rules + indexes from repo root:

```bash
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```

## 5. Enable Storage

1. **Build → Storage → Get started**
2. Deploy:

```bash
firebase deploy --only storage
```

## 6. Cloud Messaging

1. Enable Cloud Messaging API in Google Cloud for the same project
2. Android: ensure `google-services.json` is present
3. Client wiring is in `NotificationService` (saves `fcmToken` on the user doc)

## 7. Cloud Functions

```bash
cd firebase/functions
npm install
firebase deploy --only functions
```

Callables / triggers:

- `healthCheck`
- `validateCoupon` (dates, min order, usage, discount amount)
- `createPaymentSession` (gateway stub)
- `updateOrderStatus` (admin)
- `onOrderCreated` / `onOrderUpdated` (notifications + delivery sync)

## 8. Create admin user

1. Authentication → Add user (email/password)
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

3. App → **Admin login** → `/admin/login`

## 9. Run the app

Firebase is initialized in `lib/main.dart` via `DefaultFirebaseOptions.currentPlatform`.

```bash
flutter pub get
flutter run
```

## Security checklist

- Never use open `allow read, write: if true;`
- Never put payment secret keys in Flutter
- Prefer Cloud Functions for order status, coupons, payment verification
- Customers cannot change `role`, prices, or stock (enforced in `firestore.rules`)
- New reviews start unapproved (`isApproved: false`)

## Release

See `docs/RELEASE.md`.
