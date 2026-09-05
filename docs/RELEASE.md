# Release Build — Keychain Shop

## Prerequisites

1. Firebase project configured (`flutterfire configure` already done)
2. Rules, indexes, and functions deployed:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

3. At least one admin user in Firestore (`role: admin`, `isActive: true`)

## Analyze & test

```bash
flutter pub get
flutter analyze lib
flutter test
```

## Android release APK (debug signing — demos / FYP viva)

```bash
flutter build apk --release
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

## Android App Bundle (Play Store later)

```bash
flutter build appbundle --release
```

For production, create a real keystore and replace the debug `signingConfig` in `android/app/build.gradle.kts`.

## iOS (macOS only)

```bash
flutter build ios --release
```

Then archive/sign in Xcode.

## Web (optional)

```bash
flutter build web --release
```

## Checklist before demo

- [ ] Email/Password auth enabled
- [ ] Firestore + Storage rules deployed
- [ ] Sample categories/products seeded
- [ ] Admin login works (`/admin/login`)
- [ ] Place COD order → appear in Admin → Orders
- [ ] Update status (functions deployed for FCM)
- [ ] Coupon created in Admin → Coupons, applied at checkout
- [ ] Delivered order → customer review → Admin → Reviews approve
